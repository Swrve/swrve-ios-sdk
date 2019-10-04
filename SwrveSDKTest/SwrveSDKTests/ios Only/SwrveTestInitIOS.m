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

@interface SwrveMigrationsManager (SwrveInternalAccess)
+ (void)setCurrentCacheVersion:(int)cacheVersion;
@end

@interface Swrve (Internal)
- (void)appDidBecomeActive:(NSNotification *)notification;
- (UInt64)secondsSinceEpoch;
@property(atomic) SwrveMessageController *messaging;
@end

@interface SwrveMessageController (Internal)
@property(nonatomic, retain) SwrveAssetsManager *assetsManager;
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

-(void)testDeviceInfoWithiOS
{
#if !defined(SWRVE_NO_PUSH)
    id classMock = OCMClassMock([SwrvePermissions class]);
    OCMStub(ClassMethod([classMock pushAuthorizationWithSDK:OCMOCK_ANY])).andReturn(@"unittest");
#endif
    
    // Initialize SDK
    SwrveConfig * config = [[SwrveConfig alloc]init];
#if !defined(SWRVE_NO_PUSH)
    config.pushEnabled = NO;
#endif
    Swrve *swrveMock = [SwrveTestHelper swrveMockWithMockedRestClient];
    swrveMock = [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey"];
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
    XCTAssertEqual([deviceInfo count], 20);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.device_name"]);
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.os"], [UIDevice currentDevice].systemName);
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.os_version"], [[UIDevice currentDevice] systemVersion]);
    XCTAssertTrue([[deviceInfo objectForKey:@"swrve.ios_min_version"] isKindOfClass:[NSNumber class]]);
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.language"],  [swrveMock config].language);
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.device_width"],  device_width);
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.device_height"],  device_height);
    XCTAssertTrue([[deviceInfo objectForKey:@"swrve.device_dpi"] isKindOfClass:[NSNumber class]]);
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.sdk_version"],  @SWRVE_SDK_VERSION);
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.app_store"],  @"apple");
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.utc_offset_seconds"],  [NSNumber numberWithInteger:[[NSTimeZone localTimeZone]secondsFromGMT]]);
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.timezone_name"],  [NSTimeZone localTimeZone].name);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.device_region"]);
    XCTAssertTrue([[deviceInfo objectForKey:@"swrve.install_date"] isKindOfClass:[NSString class]]);
    
    // Permissions
    XCTAssertNotNil([deviceInfo objectForKey:@"Swrve.permission.ios.push_notifications"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"Swrve.permission.ios.push_bg_refresh"]);
    // Extra identifiers
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.IDFA"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.IDFV"]);
    // Feature versions
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.conversation_version"]);
}

-(void)testDeviceInfoWithiOSPermissions
{
#if !defined(SWRVE_NO_PUSH)
    id classMock = OCMClassMock([SwrvePermissions class]);
    OCMStub(ClassMethod([classMock pushAuthorizationWithSDK:OCMOCK_ANY])).andReturn(@"unittest");
#endif
    
    // Initialize SDK
    SwrveConfig * config = [[SwrveConfig alloc]init];
    TestPermissionsDelegate *permissionsDelegate = [[TestPermissionsDelegate alloc] init];
    config.permissionsDelegate = permissionsDelegate;
#if !defined(SWRVE_NO_PUSH)
    config.pushEnabled = NO;
#endif
    Swrve *swrveMock = [SwrveTestHelper swrveMockWithMockedRestClient];
    swrveMock = [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey" config:config];
    [swrveMock appDidBecomeActive:nil];

    NSDictionary * deviceInfo = [(id<SwrveCommonDelegate>)swrveMock deviceInfo];
    XCTAssertNotNil(deviceInfo);
    XCTAssertEqual([deviceInfo count], 25);
    XCTAssertNotNil([deviceInfo objectForKey:@"Swrve.permission.ios.location.always"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"Swrve.permission.ios.location.when_in_use"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"Swrve.permission.ios.photos"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"Swrve.permission.ios.camera"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"Swrve.permission.ios.contacts"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"Swrve.permission.ios.push_notifications"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"Swrve.permission.ios.push_bg_refresh"]);
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

@end
