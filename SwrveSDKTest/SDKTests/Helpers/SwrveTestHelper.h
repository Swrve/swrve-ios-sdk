#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import <objc/NSObject.h>
#import <UIKit/UIKit.h>
#import "OCMock.h"
@import SwrveSDK;
@import SwrveSDKCommon;

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)


@interface Swrve ()
- (NSDate *)getNow;
- (void)initSwrveRestClient:(NSTimeInterval)timeOut urlSssionDelegate:(id <NSURLSessionDelegate>)urlSssionDelegate;
@property(atomic) SwrveRESTClient *restClient;
@property (atomic) NSURL *campaignsAndResourcesURL;
@end

@interface SwrveProfileManager ()
@property(atomic) SwrveRESTClient *restClient;
@end

@interface SwrveMessageController ()
- (id)initWithSwrve:(Swrve*)sdk;
- (void)writeToCampaignCache:(NSData*)campaignData;

- (void)updateCampaigns:(NSDictionary *)campaignJson withLoadingPreviousCampaignState:(BOOL)isLoadingPreviousCampaignState;
- (void)showMessage:(SwrveMessage *)message withPersonalization:(NSDictionary *)personalization;
- (SwrveBaseMessage *)baseMessageForEvent:(NSString *)eventName withPayload:(NSDictionary *)payload;
- (NSDate *)getNow;

@property(nonatomic, retain) UIWindow *inAppMessageWindow;
@property(nonatomic, retain) NSArray *campaigns;
@property(nonatomic, retain) SwrveMessageFocus *messageFocus;
@property (nonatomic, retain) NSDate *initialisedTime;

@end

@interface SwrveMigrationsManager ()
+ (void)markAsMigrated;
@end

@interface SwrveSDK (InternalAccess)
+ (void)resetSwrveSharedInstance;
+ (void)addSharedInstance:(Swrve*)instance;
@end

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
+ (void)createDummyAssets:(NSArray*)assets withResourceName: (NSString *) resourceName ofType: (NSString *) type;

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

+ (id)swrveBasicMockResponse;
+ (id)swrveMockResponse:(int)httpCode mockData:(NSData *)mockData;

+ (Swrve *)initializeSwrveWithCampaignsFile:(NSString *)filename andConfig:(SwrveConfig *)config;
+ (Swrve *)initializeSwrveWithCampaignsFile:(NSString *)filename andConfig:(SwrveConfig *)config;
+ (Swrve *)initializeSwrveWithRealTimeUserPropertiesFile:(NSString *)filename andConfig:(SwrveConfig *)config;

#if TARGET_OS_IOS
+ (void)setScreenOrientation:(enum UIInterfaceOrientation)orientation;
#endif //TARGET_OS_IOS

+ (BOOL)tryBlock:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error;

@end
