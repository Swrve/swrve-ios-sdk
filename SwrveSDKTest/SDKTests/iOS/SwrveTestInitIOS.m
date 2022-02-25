#import <XCTest/XCTest.h>
#import "SwrveProtocol.h"
#import "SwrveTestHelper.h"
#import "SwrveAssetsManager.h"
#import <OCMock/OCMock.h>
#import "SwrveSDK.h"
#import "SwrveMigrationsManager.h"
#import "SwrvePermissions.h"
#import "TestPermissionsDelegate.h"
#import "AppDelegate.h"
#import "SwrveEventQueueItem.h"
#import "SwrveCampaignInfluence.h"
#import "SwrveMessageController.h"

@interface SwrveSDK (InternalAccess)
+ (void)addSharedInstance:(Swrve*)instance;
+ (void)resetSwrveSharedInstance;
@end

@interface SwrveMigrationsManager (SwrveInternalAccess)
+ (void)setCurrentCacheVersion:(int)cacheVersion;
- (int)currentCacheVersion;
+ (void)markAsMigrated;
@end

@interface Swrve (Internal)
- (void)appDidBecomeActive:(NSNotification *)notification;
- (UInt64)secondsSinceEpoch;
@property(atomic) SwrveMessageController *messaging;
@property(atomic) SwrvePush *push;
@property(atomic) NSMutableArray *pausedEventsArray;
@property(atomic) SwrveSignatureProtectedFile *resourcesFile;
@property(atomic) SwrveSignatureProtectedFile *resourcesDiffFile;
@property(atomic) SwrveSignatureProtectedFile *realTimeUserPropertiesFile;
- (UInt64)joinedDateMilliSeconds;
- (UInt64)appInstallTimeSeconds;
- (UInt64)userJoinedTimeSeconds;
- (NSString *)signatureKey;
@property(atomic) NSURL *eventFilename;
- (void)initSwrveRestClient:(NSTimeInterval)timeOut urlSssionDelegate:(id <NSURLSessionDelegate>)urlSssionDelegate;

@property (atomic) SwrveRESTClient *restClient;
- (void)initRealTimeUserProperties;
- (void)invalidateETag;

@end

@interface SwrveMessageController (SwrveMessageControllerInternal)

@property (nonatomic, retain) SwrveSignatureProtectedFile* campaignFile;

@property (atomic) SwrveRESTClient *restClient;
@end

@interface SwrveMessageController (Internal)
@property(nonatomic, retain) SwrveAssetsManager *assetsManager;
@end

@interface SwrvePush (Internal)
- (void)saveConfigForPushDelivery;
@end

@interface SwrveTestInitIOS : XCTestCase

@end

@implementation SwrveTestInitIOS

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
    [SwrveLocalStorage resetDirectoryCreation];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

- (void)testSharedInstance {
    [SwrveTestHelper destroySharedInstance];
    [SwrveTestHelper setAlreadyInstalledUserId:@"SomeUser"];
    [SwrveSDK sharedInstanceWithAppID:572 apiKey:@"SomeAPIKey"];
    Swrve *swrve = [SwrveSDK sharedInstance];
    XCTAssertNotNil(swrve);
    
    Swrve *swrve2 = [SwrveSDK sharedInstance];
    XCTAssertEqualObjects(swrve, swrve2);
    
    // Test method swizzling as it is the first shared instance created
    AppDelegate *target = (AppDelegate *) [UIApplication sharedApplication].delegate;
    NSData *fakeToken = [@"fake_token" dataUsingEncoding:NSUTF8StringEncoding];
    // Invoke did register for notification
    [target application:[UIApplication sharedApplication] didRegisterForRemoteNotificationsWithDeviceToken:fakeToken];
    XCTAssertEqualObjects(target.swizzleDeviceToken, fakeToken);
    //assertThat(target.swizzleDeviceToken, equalTo(fakeToken));
    
    NSError *fakeError = [NSError errorWithDomain:@"myDomain" code:100 userInfo:nil];
    // Invoke did register for notification
    [target application:[UIApplication sharedApplication] didFailToRegisterForRemoteNotificationsWithError:fakeError];
    XCTAssertEqualObjects(target.swizzleError, fakeError);
}

-(void)testDeviceInfo
{
    id classMock = OCMClassMock([SwrvePermissions class]);
    OCMStub(ClassMethod([classMock pushAuthorizationWithSDK:OCMOCK_ANY])).andReturn(@"unittest");
    
    // Initialize SDK
    SwrveConfig * config = [[SwrveConfig alloc]init];
    config.autoCollectIDFV = true;
    Swrve *swrveMock = [SwrveTestHelper swrveMockWithMockedRestClient];
    
    [SwrveTestHelper setAlreadyInstalledUserId:@"SomeUser"];
    swrveMock = [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey" config:config];
    [swrveMock idfa:@"12345"];
    [swrveMock appDidBecomeActive:nil];

    UIScreen* screen   = [UIScreen mainScreen];
    CGRect screen_bounds = [screen bounds];
    float screen_scale = [[UIScreen mainScreen] scale];
    screen_bounds.size.width  = screen_bounds.size.width  * screen_scale;
    screen_bounds.size.height = screen_bounds.size.height * screen_scale;
    const int side_a = (int)screen_bounds.size.width;
    const int side_b = (int)screen_bounds.size.height;
    screen_bounds.size.width  = (side_a > side_b)? side_b : side_a;
    screen_bounds.size.height = (side_a > side_b)? side_a : side_b;
    
    NSNumber* device_width = [NSNumber numberWithFloat: screen_bounds.size.width];
    NSNumber* device_height = [NSNumber numberWithFloat: screen_bounds.size.height];
    
    NSDictionary * deviceInfo = [(id<SwrveCommonDelegate>)swrveMock deviceInfo];
    XCTAssertNotNil(deviceInfo);
    
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.device_name"]);
    
    NSString *osVersion = [[UIDevice currentDevice] systemVersion];
    if ([osVersion floatValue] >= 15 && [[[UIDevice currentDevice] name] containsString:@"iPad"]) {
        XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.os"], @"ipados");
    } else {
        XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.os"], @"ios");
    }

    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.os_version"], osVersion);
    XCTAssertTrue([[deviceInfo objectForKey:@"swrve.ios_min_version"] isKindOfClass:[NSNumber class]]);
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.language"], [swrveMock config].language);
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.device_width"], device_width);
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.device_height"], device_height);
    XCTAssertTrue([[deviceInfo objectForKey:@"swrve.device_dpi"] isKindOfClass:[NSNumber class]]);
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.sdk_version"], [@"iOS " stringByAppendingString:@SWRVE_SDK_VERSION]);
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.app_store"], @"apple");
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.utc_offset_seconds"], [NSNumber numberWithInteger:[[NSTimeZone localTimeZone]secondsFromGMT]]);
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.timezone_name"], [NSTimeZone localTimeZone].name);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.device_region"]);
    XCTAssertTrue([[deviceInfo objectForKey:@"swrve.install_date"] isKindOfClass:[NSString class]]);
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.sdk_init_mode"], @"auto_auto");

    NSString *expectedDeviceType = @"mobile";
#if TARGET_OS_TV
    expectedDeviceType = @"tv";
#elif TARGET_OS_OSX
    expectedDeviceType = @"desktop";
#endif
    
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.device_type"], expectedDeviceType);
    
    // Permissions
    XCTAssertNotNil([deviceInfo objectForKey:@"Swrve.permission.ios.push_notifications"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"Swrve.permission.ios.push_bg_refresh"]);
    
    // IDFA & Device Info count
    XCTAssertEqual([deviceInfo count], 22);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.IDFA"]);

    // Extra identifiers
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.IDFV"]);
    // Feature versions
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.conversation_version"]);
}

-(void)testDeviceInfoWithiOSPermissions
{
    id classMock = OCMClassMock([SwrvePermissions class]);
    OCMStub(ClassMethod([classMock pushAuthorizationWithSDK:OCMOCK_ANY])).andReturn(@"unittest");
    
    // Initialize SDK
    SwrveConfig * config = [[SwrveConfig alloc] init];
    config.autoCollectIDFV = true;
    TestPermissionsDelegate *permissionsDelegate = [[TestPermissionsDelegate alloc] init];
    config.permissionsDelegate = permissionsDelegate;
    Swrve *swrveMock = [SwrveTestHelper swrveMockWithMockedRestClient];
    [SwrveTestHelper setAlreadyInstalledUserId:@"SomeUser"];
    swrveMock = [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey" config:config];
    [swrveMock idfa:@"12345"];
    [swrveMock appDidBecomeActive:nil];

    NSDictionary * deviceInfo = [(id<SwrveCommonDelegate>)swrveMock deviceInfo];
    
    XCTAssertNotNil(deviceInfo);

    XCTAssertEqual([deviceInfo count], 28);

    XCTAssertNotNil([deviceInfo objectForKey:@"Swrve.permission.ios.location.always"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"Swrve.permission.ios.location.when_in_use"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"Swrve.permission.ios.photos"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"Swrve.permission.ios.camera"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"Swrve.permission.ios.contacts"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"Swrve.permission.ios.push_notifications"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"Swrve.permission.ios.push_bg_refresh"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.permission.ios.ad_tracking"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.IDFV"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.IDFA"]);
}

-(void)testSavePushInfoWithStart
{
    id currentMockCenter = OCMClassMock([UNUserNotificationCenter class]);
    OCMStub([currentMockCenter currentNotificationCenter]).andReturn(currentMockCenter);
    
    OCMStub([currentMockCenter getNotificationSettingsWithCompletionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invoke) {
        void (^callback)(UNNotificationSettings *_Nonnull settings);
        [invoke getArgument:&callback atIndex:2];

        id notificationSettingsMock = OCMClassMock([UNNotificationSettings class]);
        OCMStub([notificationSettingsMock authorizationStatus]).andReturn(UNAuthorizationStatusAuthorized);
        callback(notificationSettingsMock);
    });
    
    // Initialize SDK
    SwrveConfig *config = [SwrveConfig new];
    config.pushEnabled = YES;

    Swrve *swrveMock = [SwrveTestHelper swrveMockWithMockedRestClient];
    [SwrveTestHelper setAlreadyInstalledUserId:@"SomeUser"];
    swrveMock = [swrveMock initWithAppID:123 apiKey:@"Neverson" config:config];

    id pushPartialMock = OCMPartialMock([swrveMock push]);
    XCTAssertNotNil(swrveMock);

    [swrveMock appDidBecomeActive:nil]; // This call will force a "BeginSession" call that should trigger the [push saveConfigForPushDelivery];
    XCTAssertNotNil(pushPartialMock);
    OCMVerify([pushPartialMock saveConfigForPushDelivery]);
    [currentMockCenter stopMocking];
}

-(void)testInstallDateForiOS {
    
    UInt64 date20160101 = 1451610000;
    NSString *date20150101 = @"1420074000";
    NSString *date20150101_millis = @"1420074000000";
    NSString *documentPath = [SwrveLocalStorage documentPath];
    
    // No data, install time should be "now" 2016/1/1 1:00:00
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString* cachePath = [SwrveLocalStorage cachePath];
    NSString *fileNameDocuments = [SwrveLocalStorage userInitDateFilePath:@"bob"];
    [fileManager removeItemAtPath:fileNameDocuments error:nil];

    [SwrveLocalStorage saveSwrveUserId:@"bob"];

    Swrve *swrveMock = [SwrveTestHelper swrveMockWithMockedRestClient];
    OCMStub([swrveMock secondsSinceEpoch]).andReturn(date20160101);
    swrveMock = [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey"];
    [swrveMock appDidBecomeActive:nil];
    XCTAssertEqualObjects([((id<SwrveCommonDelegate>)swrveMock).deviceInfo objectForKey:@"swrve.install_date"], @"20160101");

    // Simulate app had legacy file but no new file
    [self deleteAllItemsinFolder:documentPath];
    [fileManager removeItemAtPath:fileNameDocuments error:nil];
    [date20150101 writeToFile:[cachePath stringByAppendingPathComponent: @"swrve_install.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    [SwrveMigrationsManager setCurrentCacheVersion:0];
    Swrve *swrveMock2 = [SwrveTestHelper swrveMockWithMockedRestClient];
    OCMStub([swrveMock2 secondsSinceEpoch]).andReturn(date20160101);
    swrveMock2 = [swrveMock2 initWithAppID:123 apiKey:@"SomeAPIKey"];
    [swrveMock2 appDidBecomeActive:nil];
    XCTAssertEqualObjects([((id<SwrveCommonDelegate>)swrveMock2).deviceInfo objectForKey:@"swrve.install_date"], @"20150101");
    
    // Simulate app had legacy file AND new file
    [self deleteAllItemsinFolder:documentPath];
    [@"1427850000" writeToFile:[cachePath stringByAppendingPathComponent: @"swrve_install.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    [SwrveMigrationsManager setCurrentCacheVersion:0];
    Swrve *swrveMock3 = [SwrveTestHelper swrveMockWithMockedRestClient];
    OCMStub([swrveMock3 secondsSinceEpoch]).andReturn(1451610000);
    swrveMock3 = [swrveMock3 initWithAppID:123 apiKey:@"SomeAPIKey"];
    [swrveMock3 appDidBecomeActive:nil];
    XCTAssertEqualObjects([((id<SwrveCommonDelegate>)swrveMock3).deviceInfo objectForKey:@"swrve.install_date"], @"20150401");

    // Simulate app had new file only (never run the legacy SDK)
    [self deleteAllItemsinFolder:documentPath];
    [date20150101 writeToFile:[cachePath stringByAppendingPathComponent: @"swrve_install.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    [SwrveMigrationsManager setCurrentCacheVersion:0];
    Swrve *swrveMock4 = [SwrveTestHelper swrveMockWithMockedRestClient];
    OCMStub([swrveMock4 secondsSinceEpoch]).andReturn(1451610000);
    swrveMock4 = [swrveMock4 initWithAppID:123 apiKey:@"SomeAPIKey"];
    [swrveMock4 appDidBecomeActive:nil];
    XCTAssertEqualObjects([((id<SwrveCommonDelegate>)swrveMock4).deviceInfo objectForKey:@"swrve.install_date"], @"20150101");
    
    // Simulate app was storing the install_date in milliseconds (< 4.7 legacy bug)
    [self deleteAllItemsinFolder:documentPath];
    [date20150101_millis writeToFile:[cachePath stringByAppendingPathComponent: @"swrve_install.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    [SwrveMigrationsManager setCurrentCacheVersion:0];
    Swrve *swrveMock5 = [SwrveTestHelper swrveMockWithMockedRestClient];
    OCMStub([swrveMock5 secondsSinceEpoch]).andReturn(1451610000);
    swrveMock5 = [swrveMock5 initWithAppID:123 apiKey:@"SomeAPIKey"];
    [swrveMock5 appDidBecomeActive:nil];
    XCTAssertEqualObjects([((id<SwrveCommonDelegate>)swrveMock5).deviceInfo objectForKey:@"swrve.install_date"], @"20150101");
}

- (void)deleteAllItemsinFolder:(NSString *)folder {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSString *file in [fileManager contentsOfDirectoryAtPath:folder error:nil]) {
        NSString * item = [NSString stringWithFormat:@"%@/%@", folder, file];
        [fileManager removeItemAtPath:item error:nil];
    }
}

-(void)testCacheFilesAreMigratedToApplicationData {

    //add files at old cache location
    [SwrveLocalStorage saveSwrveUserId:@"bob"];
    NSString* cachePath = [SwrveLocalStorage cachePath];
    NSString *eventCacheSecondaryFile = [cachePath stringByAppendingPathComponent: @"swrve_events.txt"];
    [@"[]" writeToFile:eventCacheSecondaryFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSString *userResourcesCacheSecondaryFile = [cachePath stringByAppendingPathComponent: @"srcngt2.txt"];
    [@"[]" writeToFile:userResourcesCacheSecondaryFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSString *userResourcesCacheSignatureSecondaryFile = [cachePath stringByAppendingPathComponent: @"srcngtsgt2.txt"];
    [@"fake_signature" writeToFile:userResourcesCacheSignatureSecondaryFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSString *userResourcesDiffCacheSecondaryFile = [cachePath stringByAppendingPathComponent: @"rsdfngt2.txt"];
    [@"[]" writeToFile:userResourcesDiffCacheSecondaryFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSString *userResourcesDiffCacheSignatureSecondaryFile = [cachePath stringByAppendingPathComponent: @"rsdfngtsgt2.txt"];
    [@"fake_signature" writeToFile:userResourcesDiffCacheSignatureSecondaryFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSString *installDateSecondaryFile = [cachePath stringByAppendingPathComponent: @"swrve_install.txt"];
    [@"1234567" writeToFile:installDateSecondaryFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    // third: reset cache version number
    [SwrveMigrationsManager setCurrentCacheVersion:0];

    Swrve *swrveMock = [SwrveTestHelper swrveMockWithMockedRestClient];
    swrveMock = [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey"];
    [swrveMock appDidBecomeActive:nil];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    XCTAssertTrue([fileManager fileExistsAtPath:[SwrveLocalStorage eventsFilePathForUserId:@"bob"]]);
    XCTAssertTrue([fileManager fileExistsAtPath:[SwrveLocalStorage userResourcesFilePathForUserId:@"bob"]]);
    XCTAssertTrue([fileManager fileExistsAtPath:[SwrveLocalStorage userResourcesSignatureFilePathForUserId:@"bob"]]);
    XCTAssertTrue([fileManager fileExistsAtPath:[SwrveLocalStorage userResourcesDiffFilePathForUserId:@"bob"]]);
    XCTAssertTrue([fileManager fileExistsAtPath:[SwrveLocalStorage userResourcesDiffSignatureFilePathForUserId:@"bob"]]);
    XCTAssertTrue([fileManager fileExistsAtPath:[SwrveLocalStorage userInitDateFilePath:@"bob"]]);
    UInt64 installTime = [SwrveLocalStorage userJoinedTimeSeconds:@"bob"];
    XCTAssertEqual(installTime, 1234567);

    SwrveAssetsManager *assetsManager = [[swrveMock messaging] assetsManager];
    XCTAssertTrue([fileManager fileExistsAtPath:assetsManager.cacheFolder]);
}

// The below test requires Data Encryption capability to be enabled, and a passcode set.
// Therefore this test is manually executed on a REAL device with a passcode. Simulators do not support passcode so it will always pass in CI.
// This test will fail on 6.5.2 and pass in 6.5.3
- (void)testReadFilesDuringInitWhileLocked {
#if !(TARGET_IPHONE_SIMULATOR) //File Protection does not appear for simulators, can only test against device
    [SwrveTestHelper setAlreadyInstalledUserId:@"SomeUser"];
    Swrve *swrve1 = [[Swrve alloc] initWithAppID:572 apiKey:@"SomeAPIKey"];

    // joined
    UInt64 joined = swrve1.joinedDateMilliSeconds;
    // appInstallTime
    UInt64 appInstallTimeSeconds = swrve1.appInstallTimeSeconds;
    // userInstallFilePath
    UInt64 userJoinedTimeSeconds = swrve1.userJoinedTimeSeconds;
    // resources
    NSArray *resources = [NSArray arrayWithObjects:@{@"uid": @"resources.example"}, nil];
    NSData *resourceData = [NSJSONSerialization dataWithJSONObject:resources options:0 error:nil];
    [swrve1.resourcesFile writeWithRespectToPlatform:resourceData];
    // resources diff
    NSArray *resourcesDiff = [NSArray arrayWithObjects:@{@"uid": @"resourcesdiff.example"}, nil];
    NSData *resourceDiffData = [NSJSONSerialization dataWithJSONObject:resourcesDiff options:0 error:nil];
    [swrve1.resourcesDiffFile writeWithRespectToPlatform:resourceDiffData];
    // campaigns
    NSDictionary *campaigns = @{@"campaigns": @{}, @"fake1": @"value1"};
    NSData *campaignsData = [NSJSONSerialization dataWithJSONObject:campaigns options:0 error:nil];
    [swrve1.messaging.campaignFile writeWithRespectToPlatform:campaignsData];
    // offline notification campaigns
    SwrveSignatureProtectedFile *campaignsOfflineFile1 = [[SwrveSignatureProtectedFile alloc] protectedFileType:SWRVE_NOTIFICATION_CAMPAIGNS_FILE
                                                                                                         userID:swrve1.userID
                                                                                                   signatureKey:swrve1.signatureKey
                                                                                                  errorDelegate:nil];
    NSDictionary *campaignsOffline = @{@"campaigns": @{}, @"fake2": @"value2"};
    NSData *campaignsOfflineData = [NSJSONSerialization dataWithJSONObject:campaignsOffline options:0 error:nil];
    [campaignsOfflineFile1 writeWithRespectToPlatform:campaignsOfflineData];
    // realtime user properties
    NSDictionary *realTimeUserProperties = @{@"fake3": @"value3"};
    NSData *realTimeUserPropertiesData = [NSJSONSerialization dataWithJSONObject:realTimeUserProperties options:0 error:nil];
    [swrve1.realTimeUserPropertiesFile writeWithRespectToPlatform:realTimeUserPropertiesData];
    // swrve_events
    [swrve1 event:@"my_event"];
    [swrve1 saveEventsToDisk];

    [[NSNotificationCenter defaultCenter] removeObserver:swrve1]; // this will stop events being sents upon suspend and locking of the device.

    // lock the device
#pragma GCC diagnostic ignored "-Wundeclared-selector"
    if ([XCUIDevice.sharedDevice respondsToSelector:@selector(pressLockButton)]) {
        [XCUIDevice.sharedDevice performSelector:@selector(pressLockButton)];
    }

    // reset swrve and leave it locked for at least 10 seconds.
    [SwrveSDK resetSwrveSharedInstance];
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:10]];

    // start swrve again while locked, and then read the various files
    Swrve *swrve2 = [[Swrve alloc] initWithAppID:572 apiKey:@"SomeAPIKey"];

    // cacheversion
    SwrveConfig *swrveConfig = [[SwrveConfig alloc] init];
    ImmutableSwrveConfig *immutableSwrveConfig = [[ImmutableSwrveConfig alloc] initWithMutableConfig:swrveConfig];
    SwrveMigrationsManager *migrationsManager = [[SwrveMigrationsManager alloc] initWithConfig:immutableSwrveConfig];
    XCTAssertTrue([migrationsManager currentCacheVersion] > 2);

    // joined
    XCTAssertEqual(joined, swrve2.joinedDateMilliSeconds);
    // appInstallTime
    XCTAssertEqual(appInstallTimeSeconds, swrve2.appInstallTimeSeconds);
    // userJoinedTimeSeconds
    XCTAssertEqual(userJoinedTimeSeconds, swrve2.userJoinedTimeSeconds);
    // resources
    NSData *resourceFileData = [swrve2.resourcesFile readFromFile];
    XCTAssertNotNil(resourceFileData);
    if (resourceFileData != nil) {
        NSArray *resourcesArray = [NSJSONSerialization JSONObjectWithData:resourceFileData options:NSJSONReadingMutableContainers error:nil];
        XCTAssertNotNil(resourcesArray);
        XCTAssertEqualObjects(@"resources.example", [[resourcesArray objectAtIndex:0] objectForKey:@"uid"]);
    }
    // resources diff
    NSData *resourceDiffFileData = [swrve2.resourcesDiffFile readFromFile];
    XCTAssertNotNil(resourceDiffFileData);
    if (resourceDiffFileData != nil) {
        NSArray *resourcesDiffArray = [NSJSONSerialization JSONObjectWithData:resourceDiffFileData options:NSJSONReadingMutableContainers error:nil];
        XCTAssertNotNil(resourcesDiffArray);
        XCTAssertEqualObjects(@"resourcesdiff.example", [[resourcesDiffArray objectAtIndex:0] objectForKey:@"uid"]);
    }
    // campaigns file
    NSData *campaignData = [swrve2.messaging.campaignFile readFromFile];
    XCTAssertNotNil(campaignData);
    if (campaignData != nil) {
        NSDictionary *campaignsDict = [NSJSONSerialization JSONObjectWithData:campaignData options:NSJSONReadingMutableContainers error:nil];
        XCTAssertNotNil(campaignsDict);
        XCTAssertEqualObjects(@"value1", [campaignsDict objectForKey:@"fake1"]);
    }
    // offline notification campaigns
    SwrveSignatureProtectedFile *campaignsOfflineFile2 = [[SwrveSignatureProtectedFile alloc] protectedFileType:SWRVE_NOTIFICATION_CAMPAIGNS_FILE
                                                                                                         userID:swrve2.userID
                                                                                                   signatureKey:swrve2.signatureKey
                                                                                                  errorDelegate:nil];
    NSData *campaignsOfflineFileData = [campaignsOfflineFile2 readFromFile];
    XCTAssertNotNil(campaignsOfflineFileData);
    if (campaignsOfflineFileData != nil) {
        NSDictionary *campaignsOfflineDict = [NSJSONSerialization JSONObjectWithData:campaignsOfflineFileData options:NSJSONReadingMutableContainers error:nil];
        XCTAssertNotNil(campaignsOfflineDict);
        XCTAssertEqualObjects(@"value2", [campaignsOfflineDict objectForKey:@"fake2"]);
    }
    // realtime user properties
    NSData *realTimeUserPropertiesFileData = [swrve2.realTimeUserPropertiesFile readFromFile];
    XCTAssertNotNil(realTimeUserPropertiesFileData);
    if (realTimeUserPropertiesFileData != nil) {
        NSDictionary *realTimeUserPropertiesDict = [NSJSONSerialization JSONObjectWithData:realTimeUserPropertiesFileData options:NSJSONReadingMutableContainers error:nil];
        XCTAssertNotNil(realTimeUserPropertiesDict);
        XCTAssertEqualObjects(@"value3", [realTimeUserPropertiesDict objectForKey:@"fake3"]);
    }
    // swrve_events
    NSString *eventFilePath = [[swrve2 eventFilename] path];
    NSString *events = [NSString stringWithContentsOfFile:eventFilePath encoding:NSUTF8StringEncoding error:nil];
    XCTAssertNotNil(events);
    if (events != nil) {
        XCTAssertTrue([events containsString:@"my_event"]);
    }
#endif
}

- (void)testQueingAttributesWhileIdentifying {
    [SwrveTestHelper setAlreadyInstalledUserId:@"SomeUser"];
    
    // Confirming:
    // event 0 and user update 0 sent to swrve id A
    // event 1 and user update 1 added to paused event queue
    // event 1 and user update 1 sent to swrve id B
    
    id mockSwrveCommon = OCMProtocolMock(@protocol(SwrveCommonDelegate));
    OCMStub([mockSwrveCommon apiKey]).andReturn(@"SomeAPIKey");
    [SwrveCommon addSharedInstance:mockSwrveCommon];
    
    id localStorage = OCMClassMock([SwrveLocalStorage class]);
    OCMStub([localStorage swrveUserId]).andReturn(@"A");
    
    // mock all rest calls with success
    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
    id mockRestClient = OCMPartialMock(restClient);
    id mockResponse = OCMClassMock([NSHTTPURLResponse class]);
    OCMStub([mockResponse statusCode]).andReturn(200);
    
    Swrve *swrveMock = (Swrve *) OCMPartialMock([Swrve alloc]);
    OCMStub([swrveMock initSwrveRestClient:60 urlSssionDelegate:nil]).andDo(^(NSInvocation *invocation) {
        swrveMock.restClient = mockRestClient;
    });
    
    // this will change swrve user id on identity callback
    NSData *mockData = [@"{ \"swrve_id\": \"B\" }" dataUsingEncoding:NSUTF8StringEncoding];
    
    __block  bool event0_SentForUserA = false;
    __block  bool userUpdate0_SentForUserA = false;
    __block  bool event1_InPausedEventQueue = false;
    __block  bool userUpdate1_InPausedEventQueue = false;
    __block  bool event1_SentForUserB = false;
    __block  bool userUpdate1_SentForUserB = false;
    
    __block NSData *capturedJson;
     id jsonData = [OCMArg checkWithBlock:^BOOL(NSData *jsonValue)  {
         capturedJson = jsonValue;
         NSDictionary *json = [NSJSONSerialization JSONObjectWithData:capturedJson options:0 error:nil];
         NSString *userId = [json objectForKey:@"user"];
         NSArray *data = [json objectForKey:@"data"];
         for (NSDictionary *dic in data) {
             if ([[dic objectForKey:@"name"] isEqualToString:@"0"] && [userId isEqualToString:@"A"] ) {
                 event0_SentForUserA = true;
             }
             else if ([[dic objectForKey:@"attributes"] isEqualToDictionary:@{@"0":@"0"}] && [userId isEqualToString:@"A"]) {
                 userUpdate0_SentForUserA = true;
             }
             else if ([[dic objectForKey:@"name"] isEqualToString:@"1"] && [userId isEqualToString:@"B"] ) {
                 event1_SentForUserB = true;
             }
             else if ([[dic objectForKey:@"attributes"] isEqualToDictionary:@{@"1":@"1"}] && [userId isEqualToString:@"B"]) {
                 userUpdate1_SentForUserB = true;
             }
         }
         
         for (SwrveEventQueueItem *item in [swrveMock pausedEventsArray] ) {
             if ([[item.eventData objectForKey:@"name"] isEqualToString:@"1"]) {
                 event1_InPausedEventQueue = true;
             }
             else if ([[item.eventData objectForKey:@"attributes"] isEqualToDictionary:@{@"1":@"1"}]) {
                 userUpdate1_InPausedEventQueue = true;
             }
         }
         
         return true;
     }];
     
    OCMStub([mockRestClient sendHttpPOSTRequest:OCMOCK_ANY
                                       jsonData:jsonData
                              completionHandler:([OCMArg invokeBlockWithArgs:mockResponse, mockData, [NSNull null], nil])]);
    
    Swrve *swrve = (Swrve *) swrveMock;
    [SwrveSDK addSharedInstance:swrveMock];
 
    (void)[swrve initWithAppID:123 apiKey:@"SomeAPIKey"];
    
    // swrve id is A.
    [swrve event:@"0"];
    [swrve userUpdate:@{@"0":@"0"}];
    [swrve identify:@"SomeExternalId" onSuccess:nil onError:nil]; // on completition changes to swrve id: B
    [swrve event:@"1"];
    [swrve userUpdate:@{@"1":@"1"}];
        
    XCTestExpectation *expectation = [self expectationWithDescription:@"event 0 sent with user id 1234"];
    [SwrveTestHelper waitForBlock:0.5 conditionBlock:^BOOL(){
        return (event0_SentForUserA && userUpdate0_SentForUserA && event1_InPausedEventQueue && userUpdate1_InPausedEventQueue && event1_SentForUserB && userUpdate1_SentForUserB);
    } expectation:expectation];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

- (void)testProcessInfluenceData {
    id currentMockCenter = OCMClassMock([UNUserNotificationCenter class]);
    OCMStub([currentMockCenter currentNotificationCenter]).andReturn(currentMockCenter);
    
    OCMStub([currentMockCenter getNotificationSettingsWithCompletionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invoke) {
        void (^callback)(UNNotificationSettings *_Nonnull settings);
        [invoke getArgument:&callback atIndex:2];

        id notificationSettingsMock = OCMClassMock([UNNotificationSettings class]);
        OCMStub([notificationSettingsMock authorizationStatus]).andReturn(UNAuthorizationStatusAuthorized);
        callback(notificationSettingsMock);
    });
    
    [SwrveTestHelper setAlreadyInstalledUserId:@"SomeUser"];
    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.pushEnabled = YES;
    Swrve *swrve = [Swrve alloc];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey" config:config];

    // expect processInfluenceDataWithDate called from cold start
    id campaignInfluenceMock = OCMClassMock([SwrveCampaignInfluence class]);
    OCMExpect([campaignInfluenceMock processInfluenceDataWithDate:OCMOCK_ANY]);
    [swrve appDidBecomeActive:nil];
    OCMVerifyAll(campaignInfluenceMock);

    // expect processInfluenceDataWithDate called from resuming the app
    OCMExpect([campaignInfluenceMock processInfluenceDataWithDate:OCMOCK_ANY]);
    [swrve appDidBecomeActive:nil];
    OCMVerifyAll(campaignInfluenceMock);
    [currentMockCenter stopMocking];
}

- (void)testRTUPDontInvalidateEtag {
    //Version 6.4.0 - 7.2.0 was invalidating etag when no RTUP
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
    
    OCMStub([swrveMock resourcesFile]).andReturn([SwrveSignatureProtectedFile new]);
    OCMReject([swrveMock invalidateETag]);
    
    [swrveMock initRealTimeUserProperties];
    
    OCMVerifyAll(swrveMock);
}


@end
