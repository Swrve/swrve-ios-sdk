#import <Foundation/Foundation.h>
#import <objc/NSObject.h>
#import <XCTest/XCTest.h>
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
+ (NSString *)campaignCacheDirectory;
+ (Swrve *)initializeSwrveWithCampaignsFile:(NSString *)filename andConfig:(SwrveConfig *)config;
+ (void)waitForBlock:(float)deltaSecs conditionBlock:(BOOL (^)(void))conditionBlock expectation:(XCTestExpectation *)expectation;

@end
