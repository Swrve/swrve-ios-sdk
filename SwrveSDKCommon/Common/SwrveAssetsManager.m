#import <CommonCrypto/CommonHMAC.h>
#import "SwrveAssetsManager.h"
#import "SwrveCommon.h"
#import "SwrveQA.h"

static NSString* const SWRVE_ASSETQ_ITEM_NAME = @"name";
static NSString* const SWRVE_ASSETQ_ITEM_DIGEST = @"digest";
static NSString* const SWRVE_ASSETQ_ITEM_IS_EXTERNAL = @"isExternal";
static NSString* const SWRVE_ASSETQ_ITEM_IS_IMAGE = @"isImage";

@implementation SwrveAssetsManager {
    NSMutableSet *assetsOnDiskSet; // contains both image and font assets
    NSMutableSet* assetsCurrentlyDownloading;
}

@synthesize restClient;
@synthesize cdnImages;
@synthesize cdnFonts;
@synthesize cacheFolder;

+ (NSMutableDictionary *)assetQItemWith:(NSString *)name andDigest:(NSString *)digest andIsExternal:(BOOL)isExternal andIsImage:(BOOL)isImage {
    NSMutableDictionary *assetQItem = [NSMutableDictionary new];
    [assetQItem setObject:name forKey:SWRVE_ASSETQ_ITEM_NAME];
    [assetQItem setObject:digest forKey:SWRVE_ASSETQ_ITEM_DIGEST];
    [assetQItem setObject:[NSNumber numberWithBool:isExternal] forKey:SWRVE_ASSETQ_ITEM_IS_EXTERNAL];
    [assetQItem setObject:[NSNumber numberWithBool:isImage] forKey:SWRVE_ASSETQ_ITEM_IS_IMAGE];
    return assetQItem;
}

- (id)initWithRestClient:(SwrveRESTClient *)swrveRESTClient andCacheFolder:(NSString *)cache{
    self = [super init];
    if (self) {
        [self setRestClient:swrveRESTClient];
        self.cdnImages = @"";
        self.cdnFonts = @"";
        self.cacheFolder = cache;
        self->assetsOnDiskSet = [[NSMutableSet alloc] init];
        self->assetsCurrentlyDownloading = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)downloadAssets:(NSSet *)assetsQueue withCompletionHandler:(void (^)(void))completionHandler {
    if (!assetsQueue || [assetsQueue count] == 0) { completionHandler(); return;}
    
    NSSet *assetItemsToDownload = [self filterExistingFiles:assetsQueue];
    if ([assetItemsToDownload count] == 0 ) { completionHandler(); return;}
    
    for (NSDictionary *assetItem in assetItemsToDownload) {
        NSNumber *isExternal = [assetItem objectForKey:SWRVE_ASSETQ_ITEM_IS_EXTERNAL];
        if ([isExternal boolValue]) {
            [self downloadAssetFromExternalSource:assetItem withCompletionHandler:completionHandler];
        }else{
            [self downloadAsset:assetItem withCompletionHandler:completionHandler];
        }
    }
}

- (void)downloadAsset:(NSDictionary *)assetItem withCompletionHandler:(void (^)(void))completionHandler {
    NSString *assetItemName = [assetItem objectForKey:SWRVE_ASSETQ_ITEM_NAME];

    BOOL mustDownload = YES;
    @synchronized (self->assetsCurrentlyDownloading) {
        mustDownload = ![assetsCurrentlyDownloading containsObject:assetItemName];
        if (mustDownload) {
            [self->assetsCurrentlyDownloading addObject:assetItemName];
        }
    }

    if (mustDownload) {
        NSNumber *isImage = [assetItem objectForKey:SWRVE_ASSETQ_ITEM_IS_IMAGE];
        NSString *cdn = [isImage boolValue] ? cdnImages : cdnFonts;
        if ([cdn length] == 0) {
            [SwrveLogger error:@"No cdn configured", nil];
            return;
        }

        NSURL *url = [NSURL URLWithString:assetItemName relativeToURL:[NSURL URLWithString:cdn]];
        [SwrveLogger debug:@"Downloading asset: %@", url];
        [restClient sendHttpGETRequest:url
                     completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
#pragma unused(response)
                         if (error) {
                             [SwrveLogger error:@"Could not download asset: %@", error];
                         } else {
                             NSString *assetItemDigest = [assetItem objectForKey:SWRVE_ASSETQ_ITEM_DIGEST];
                             if (![self verifySHA:data against:assetItemDigest]) {
                                 [SwrveLogger error:@"Error downloading %@ – SHA1 does not match.", assetItemName];
                             } else {

                                 NSURL *dst = [NSURL fileURLWithPathComponents:[NSArray arrayWithObjects:self.cacheFolder, assetItemName, nil]];

                                 [data writeToURL:dst atomically:YES];

                                 // Add the asset to the set of assets that we know are downloaded.
                                 @synchronized (self->assetsOnDiskSet) {
                                     [self->assetsOnDiskSet addObject:assetItemName];
                                 }
                                 [SwrveLogger debug:@"Asset downloaded: %@", assetItemName];
                             }
                         }

                         // This asset has finished downloading
                         // Check if all assets are finished and if so call completionHandler
                         @synchronized (self->assetsCurrentlyDownloading) {
                             [self->assetsCurrentlyDownloading removeObject:assetItemName];
                             if ([self->assetsCurrentlyDownloading count] == 0) {
                                 completionHandler();
                             }
                         }
                     }];
    }
}

- (void)downloadAssetFromExternalSource:(NSDictionary *)assetItem withCompletionHandler:(void (^)(void))completionHandler {
    NSString *assetItemName = [assetItem objectForKey:SWRVE_ASSETQ_ITEM_NAME];
    NSString *assetDigest   = [assetItem objectForKey:SWRVE_ASSETQ_ITEM_DIGEST];

    BOOL mustDownload = YES;
    @synchronized (self->assetsCurrentlyDownloading) {
        mustDownload = ![assetsCurrentlyDownloading containsObject:assetItemName];
        if (mustDownload) {
            [self->assetsCurrentlyDownloading addObject:assetItemName];
        }
    }

    if (mustDownload) {
        NSURL *url = [NSURL URLWithString:assetDigest];
        [SwrveLogger debug:@"Downloading external asset: %@", url];
        [restClient sendHttpGETRequest:url
                     completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
#pragma unused(response)
                         if (error) {
                             [SwrveLogger debug:@"Could not download external asset: %@", error];
                             [SwrveQA assetFailedToDownload:assetItemName resolvedUrl:assetDigest reason:error.localizedDescription];
                             
                         } else {
                             NSString *fileAssetName = [self fileAssetName:assetItemName mimeType:response];
                             NSURL *dst = [NSURL fileURLWithPathComponents:[NSArray arrayWithObjects:self.cacheFolder, fileAssetName, nil]];
                             [data writeToURL:dst atomically:YES];

                             // Add the asset to the set of assets that we know are downloaded.
                             @synchronized (self->assetsOnDiskSet) {
                                 [self->assetsOnDiskSet addObject:assetItemName];
                             }
                             [SwrveLogger debug:@" External asset downloaded: %@", assetItemName];
                         }

                         // This asset has finished downloading
                         // Check if all assets are finished and if so call completionHandler
                         @synchronized (self->assetsCurrentlyDownloading) {
                             [self->assetsCurrentlyDownloading removeObject:assetItemName];
                             if ([self->assetsCurrentlyDownloading count] == 0) {
                                 completionHandler();
                             }
                         }
                     }];
    }
}

- (NSSet *)filterExistingFiles:(NSSet *)assetSet {
    NSMutableSet *assetItemsToDownload = [[NSMutableSet alloc] initWithCapacity:[assetSet count]];
    for (NSDictionary *assetItem in assetSet) {
        NSString *assetItemName = [assetItem objectForKey:SWRVE_ASSETQ_ITEM_NAME];
        if (![self isDownloaded:assetItemName]) {
            [assetItemsToDownload addObject:assetItem]; // add the item, not the name
        } else {
            @synchronized (self->assetsOnDiskSet) {
                [self->assetsOnDiskSet addObject:assetItemName]; // store the font name
            }
        }
    }

    return [assetItemsToDownload copy];
}

// Check if asset is already downloaded. Some assets will have additional file extension type appended to the asset name
- (BOOL)isDownloaded:(NSString *)assetItemName {
    BOOL isDownloaded = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *target = [self.cacheFolder stringByAppendingPathComponent:assetItemName];
    if ([fileManager fileExistsAtPath:target]) {
        isDownloaded = YES;
    } else {
        NSString *assetNameGif = [assetItemName stringByAppendingString:@".gif"];
        NSString *gifTarget = [self.cacheFolder stringByAppendingPathComponent:assetNameGif];
        if ([fileManager fileExistsAtPath:gifTarget]) {
            isDownloaded = YES;
        }
    }
    return isDownloaded;
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
                [SwrveLogger error:@"Wrong asset SHA[%d]. Expected: %d Computed %d", i, e, c];
                return false;
            }
        }
    }

    return true;
}

- (NSSet*) assetsOnDisk {
    return [self->assetsOnDiskSet copy];
}

// Some mimeTypes are saved with file extension, but default is to just use the assetName
- (NSString *)fileAssetName:(NSString *)assetName mimeType:(NSURLResponse *)response {
    NSString *fileAssetName = assetName;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        NSString *mimeType = [httpResponse MIMEType];
        if (mimeType && [mimeType containsString:@"image/gif"]) {
            fileAssetName = [assetName stringByAppendingString:@".gif"];
        }
    }
    return fileAssetName;
}

@end
