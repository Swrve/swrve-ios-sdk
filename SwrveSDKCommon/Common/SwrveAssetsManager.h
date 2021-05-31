#import "SwrveRESTClient.h"

@interface SwrveAssetsManager : NSObject

@property(nonatomic, retain) SwrveRESTClient *restClient;
@property(nonatomic, retain) NSString *cdnImages;
@property(nonatomic, retain) NSString *cdnFonts;
@property(nonatomic, retain) NSString *cacheFolder;

+ (NSMutableDictionary *)assetQItemWith:(NSString *)name andDigest:(NSString *)digest andIsExternal:(BOOL)isExternal andIsImage:(BOOL)isImage;

- (id)initWithRestClient:(SwrveRESTClient *)swrveRESTClient andCacheFolder:(NSString *)cacheFolder;

- (void)downloadAssets:(NSSet *)assetsQueue withCompletionHandler:(void (^)(void))completionHandler;

- (NSSet*) assetsOnDisk;

@end
