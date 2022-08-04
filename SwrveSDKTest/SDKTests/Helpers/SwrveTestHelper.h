#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import <objc/NSObject.h>
#import <UIKit/UIKit.h>
#import "SwrveSignatureProtectedFile.h"
#import "Swrve.h"
#import "OCMock.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface SwrveTestHelper : NSObject

// Setup data as if the user was already present and migration was the latest
+ (void)setAlreadyInstalledUserId:(NSString*)userId;

+ (NSString*)fileContentsFromURL:(NSURL*)url;
+ (NSString*)fileContentsFromPath:(NSString*)path;
+ (NSString*)fileContentsFromProtectedFile:(SwrveSignatureProtectedFile*)file;

+ (void)writeData:(NSString*)content toURL:(NSURL*)url;
+ (void)writeData:(NSString*)content toPath:(NSString*)path;
+ (void)writeData:(NSString*)content toProtectedFile:(SwrveSignatureProtectedFile*)file;

+ (NSString*)rootCacheDirectory;
+ (NSString*)campaignCacheDirectory;

+ (void)removeSDKData;
+ (void)deleteFilesInDirectory:(NSString*)directory;
+ (void)createDirectory:(NSString*)path;
+ (NSArray*)getFilesInDirectory:(NSString*)directory;

+ (void)deleteUserDefaults;

+ (void)createDummyAssets:(NSArray*)asset;
+ (void)createDummyGifAssets:(NSArray*)assets;
+ (void)createDummyPngAssets:(NSArray*)assets;

+ (void)removeAssets:(NSArray*)assets;
+ (void)removeAllAssets;

+ (NSDictionary*)makeDictionaryFromEventBufferEntry:(NSString*)entry;

+ (void)destroySharedInstance;

+ (NSDictionary*)makeDictionaryFromEventRequest:(NSString*)eventRequest;

+ (NSArray*)makeArrayFromEventFileContents:(NSMutableData*)storedEvents;

+ (void)setUp;
+ (void)tearDown;
+ (NSMutableArray *)dicArrayFromCachedFile:(NSURL *)file;

+ (id)mockPushRequest;

+ (void)waitForBlock:(float)deltaSecs conditionBlock:(BOOL (^)(void))conditionBlock expectation:(XCTestExpectation *)expectation;
+ (id)swrveMockWithMockedRestClient;
+ (id)swrveMockWithMockedRestClientResponseCode:(int)httpCode mockData:(NSData *)mockData;
+ (Swrve *)initializeSwrveWithCampaignsFile:(NSString *)filename andConfig:(SwrveConfig *)config;
+ (Swrve *)initializeSwrveWithRealTimeUserPropertiesFile:(NSString *)filename andConfig:(SwrveConfig *)config;

#if TARGET_OS_IOS
+ (void)setScreenOrientation:(enum UIInterfaceOrientation)orientation;
#endif //TARGET_OS_IOS


@end
