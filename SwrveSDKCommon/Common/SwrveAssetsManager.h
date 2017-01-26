#import "SwrveRESTClient.h"

@interface SwrveAssetsManager : NSObject

@property(nonatomic, retain) SwrveRESTClient *restClient;
@property(nonatomic, retain) NSMutableSet *assetsCurrentlyDownloading;
@property(nonatomic, retain) NSString *cdnImages;
@property(nonatomic, retain) NSString *cdnFonts;
@property(nonatomic, retain) NSString *cacheFolder;
@property(nonatomic, retain) NSMutableSet *assetsOnDisk; // contains both image and font assets

+ (NSMutableDictionary *)assetQItemWith:(NSString *)name andDigest:(NSString *)digest andIsImage:(BOOL)isImage;

- (id)initWithRestClient:(SwrveRESTClient *)swrveRESTClient andCacheFolder:(NSString *)cacheFolder;

- (void)downloadAssets:(NSSet *)assetsQueue withCompletionHandler:(void (^)(void))completionHandler;

@end
