#import "SwrveRESTClient.h"

@interface SwrveAssetsManager : NSObject

@property(nonatomic, retain) SwrveRESTClient *restClient;
@property(nonatomic, retain) NSMutableSet *assetsCurrentlyDownloading;
@property(nonatomic, retain) NSString *cdnRoot;
@property(nonatomic, retain) NSString *cacheFolder;
@property(nonatomic, retain) NSMutableSet *assetsOnDisk;

- (id)initWithRestClient:(SwrveRESTClient *)restClient;

- (void)downloadAssets:(NSSet *)assetsQueue withCompletionHandler:(void (^)(void))completionHandler;

@end
