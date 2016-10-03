#import <CommonCrypto/CommonHMAC.h>
#import "SwrveAssetsManager.h"
#import "SwrveCommon.h"

static NSString *swrve_folder = @"com.ngt.msgs";

@implementation SwrveAssetsManager

@synthesize restClient;
@synthesize assetsCurrentlyDownloading;
@synthesize cdnRoot;
@synthesize cacheFolder;
@synthesize assetsOnDisk;

- (id)initWithRestClient:(SwrveRESTClient *)swrveRESTClient {
    self = [super init];
    if (self) {
        [self setRestClient:swrveRESTClient];
        self.cdnRoot = @"https://content-cdn.swrve.com/messaging/message_image/";
        NSString *cacheRoot = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        self.cacheFolder = [cacheRoot stringByAppendingPathComponent:swrve_folder];
        self.assetsOnDisk = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)downloadAssets:(NSSet *)assetsQueue withCompletionHandler:(void (^)(void))completionHandler {
    NSSet *assetsToDownload = [self filterExistingFiles:assetsQueue];
    for (NSString *asset in assetsToDownload) {
        [self downloadAsset:asset];
    }

    completionHandler();
}

- (void)downloadAsset:(NSString *)asset {

    BOOL mustDownload = YES;
    @synchronized ([self assetsCurrentlyDownloading]) {
        mustDownload = ![assetsCurrentlyDownloading containsObject:asset];
        if (mustDownload) {
            [[self assetsCurrentlyDownloading] addObject:asset];
        }
    }

    if (mustDownload) {
        NSURL *url = [NSURL URLWithString:asset relativeToURL:[NSURL URLWithString:self.cdnRoot]];
        DebugLog(@"Downloading asset: %@", url);
        [restClient sendHttpGETRequest:url
                     completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
#pragma unused(response)
                         if (error) {
                             DebugLog(@"Could not download asset: %@", error);
                         } else {
                             if (![self verifySHA:data against:asset]) {
                                 DebugLog(@"Error downloading %@ – SHA1 does not match.", asset);
                             } else {

                                 NSURL *dst = [NSURL fileURLWithPathComponents:[NSArray arrayWithObjects:self.cacheFolder, asset, nil]];

                                 [data writeToURL:dst atomically:YES];

                                 // Add the asset to the set of assets that we know are downloaded.
                                 [self.assetsOnDisk addObject:asset];
                                 DebugLog(@"Asset downloaded: %@", asset);
                             }
                         }

                         // This asset has finished downloading
                         // Check if all assets are finished and if so call autoShowMessage
                         @synchronized ([self assetsCurrentlyDownloading]) {
                             [[self assetsCurrentlyDownloading] removeObject:asset];
                             if ([[self assetsCurrentlyDownloading] count] == 0) {
                                 // [self autoShowMessages]; TODO use a callback here to call autoShowMessages
                             }
                         }
                     }];
    }
}

- (NSSet *)filterExistingFiles:(NSSet *)assetSet {
    NSMutableSet *result = [[NSMutableSet alloc] initWithCapacity:[assetSet count]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSString *file in assetSet) {
        NSString *target = [self.cacheFolder stringByAppendingPathComponent:file];
        if (![fileManager fileExistsAtPath:target]) {
            [result addObject:file];
        } else {
            [self.assetsOnDisk addObject:file];
        }
    }

    return [result copy];
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
