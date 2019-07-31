#import <Foundation/Foundation.h>
#import <objc/NSObject.h>
#import "Swrve.h"

@interface SwrveTestHelper : NSObject

+ (void)setUp;
+ (void)tearDown;
+ (void)destroySharedInstance;
+ (NSString *)fileContentsFromURL:(NSURL *)url;
+ (NSMutableArray *)stringArrayFromCachedContent:(NSString *)content;
+ (NSMutableArray *)dicArrayFromCachedFile:(NSURL *)file;
+ (void)deleteFilesInDirectory:(NSString *)directory;
+ (void)createDummyAssets:(NSArray *)assets;
+ (void)removeAssets:(NSArray *)assets;
+ (id)swrveMockWithMockedRestClient;
#if TARGET_OS_IOS
+ (void)changeToOrientation:(UIInterfaceOrientation) orientation;
#endif
+ (NSString *)campaignCacheDirectory;
+ (Swrve *)initializeSwrveWithCampaignsFile:(NSString *)filename andConfig:(SwrveConfig *)config;

@end
