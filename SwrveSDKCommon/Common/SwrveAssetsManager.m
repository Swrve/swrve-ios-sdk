#import <CommonCrypto/CommonHMAC.h>
#import "SwrveAssetsManager.h"
#import "SwrveCommon.h"

static NSString* const SWRVE_ASSETQ_ITEM_NAME = @"name";
static NSString* const SWRVE_ASSETQ_ITEM_DIGEST = @"digest";

@implementation SwrveAssetsManager

@synthesize restClient;
@synthesize assetsCurrentlyDownloading;
@synthesize cdnImages;
@synthesize cdnFonts;
@synthesize cacheFolder;
@synthesize assetsOnDisk;

+ (NSMutableDictionary *)assetQItemWith:(NSString *)name andDigest:(NSString *)digest {
    NSMutableDictionary *assetQItem = [[NSMutableDictionary alloc] init];
    [assetQItem setObject:name forKey:SWRVE_ASSETQ_ITEM_NAME];
    [assetQItem setObject:digest forKey:SWRVE_ASSETQ_ITEM_DIGEST];
    return assetQItem;
}

- (id)initWithRestClient:(SwrveRESTClient *)swrveRESTClient andCacheFolder:(NSString *)cache{
    self = [super init];
    if (self) {
        [self setRestClient:swrveRESTClient];
        self.cdnImages = @"";
        self.cdnFonts = @"";
        self.cacheFolder = cache;
        self.assetsOnDisk = [[NSMutableSet alloc] init];
        self.assetsCurrentlyDownloading = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)downloadImageAssets:(NSSet *)assetsQueueImages andFontAssets:(NSSet *)assetsQueueFonts withCompletionHandler:(void (^)(void))completionHandler {
    [self downloadAssets:assetsQueueImages withCdn:cdnImages withCompletionHandler:completionHandler];
    [self downloadAssets:assetsQueueFonts withCdn:cdnFonts withCompletionHandler:completionHandler];
}

- (void)downloadAssets:(NSSet *)assetsQueue withCdn:(NSString *)cdn withCompletionHandler:(void (^)(void))completionHandler {
    if ([cdn length] == 0) {
        DebugLog(@"No cdn configured");
        return;
    }
    if (!assetsQueue || [assetsQueue count] == 0) {
        DebugLog(@"assetsQueue is empty for cdn:%@", cdn);
        return;
    }

    NSSet *assetItemsToDownload = [self filterExistingFiles:assetsQueue];
    for (NSDictionary *assetItem in assetItemsToDownload) {
        [self downloadAsset:assetItem withCdn:cdn withCompletionHandler:completionHandler];
    }
}

- (void)downloadAsset:(NSDictionary *)assetItem withCdn:(NSString *)cdn withCompletionHandler:(void (^)(void))completionHandler {

    NSString *assetItemName = [assetItem objectForKey:SWRVE_ASSETQ_ITEM_NAME];

    BOOL mustDownload = YES;
    @synchronized ([self assetsCurrentlyDownloading]) {
        mustDownload = ![assetsCurrentlyDownloading containsObject:assetItemName];
        if (mustDownload) {
            [[self assetsCurrentlyDownloading] addObject:assetItemName];
        }
    }

    if (mustDownload) {
        NSURL *url = [NSURL URLWithString:assetItemName relativeToURL:[NSURL URLWithString:cdn]];
        DebugLog(@"Downloading asset: %@", url);
        [restClient sendHttpGETRequest:url
                     completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
#pragma unused(response)
                         if (error) {
                             DebugLog(@"Could not download asset: %@", error);
                         } else {
                             NSString *assetItemDigest = [assetItem objectForKey:SWRVE_ASSETQ_ITEM_DIGEST];
                             if (![self verifySHA:data against:assetItemDigest]) {
                                 DebugLog(@"Error downloading %@ – SHA1 does not match.", assetItemName);
                             } else {

                                 NSURL *dst = [NSURL fileURLWithPathComponents:[NSArray arrayWithObjects:self.cacheFolder, assetItemName, nil]];

                                 [data writeToURL:dst atomically:YES];

                                 // Add the asset to the set of assets that we know are downloaded.
                                 [self.assetsOnDisk addObject:assetItemName];
                                 DebugLog(@"Asset downloaded: %@", assetItemName);
                             }
                         }

                         // This asset has finished downloading
                         // Check if all assets are finished and if so call autoShowMessage
                         @synchronized ([self assetsCurrentlyDownloading]) {
                             [[self assetsCurrentlyDownloading] removeObject:assetItemName];
                             if ([[self assetsCurrentlyDownloading] count] == 0) {
                                 completionHandler();
                             }
                         }
                     }];
    }
}

- (NSSet *)filterExistingFiles:(NSSet *)assetSet {
    NSMutableSet *assetItemsToDownload = [[NSMutableSet alloc] initWithCapacity:[assetSet count]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSDictionary *assetItem in assetSet) {
        NSString *assetItemName = [assetItem objectForKey:SWRVE_ASSETQ_ITEM_NAME];
        NSString *target = [self.cacheFolder stringByAppendingPathComponent:assetItemName];
        if (![fileManager fileExistsAtPath:target]) {
            [assetItemsToDownload addObject:assetItem]; // add the item, not the name
        } else {
            [self.assetsOnDisk addObject:assetItemName]; // store the font name
        }
    }

    return [assetItemsToDownload copy];
}

- (bool)verifySHA:(NSData *)data against:(NSString *)expectedDigest {
    const static char hex[] = {'0', '1', '2', '3',
            '4', '5', '6', '7',
            '8', '9', 'a', 'b',
            'c', 'd', 'e', 'f'};

    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    // SHA-1 hash has been calculated and stored in 'digest'
    unsigned int length = (unsigned int) [data length];
    if (CC_SHA1([data bytes], length, digest)) {
        for (unsigned int i = 0; i < [expectedDigest length]; i++) {
            unichar c = [expectedDigest characterAtIndex:i];
            unsigned char e = digest[i >> 1];

            if (i & 1) {
                e = e & 0xF;
            } else {
                e = e >> 4;
            }

            e = (unsigned char) hex[e];

            if (c != e) {
                DebugLog(@"Wrong asset SHA[%d]. Expected: %d Computed %d", i, e, c);
                return false;
            }
        }
    }

    return true;
}

@end
