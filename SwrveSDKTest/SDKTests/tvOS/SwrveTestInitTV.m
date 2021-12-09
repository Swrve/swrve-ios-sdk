#import <XCTest/XCTest.h>
#import "SwrveProtocol.h"
#import "SwrvePermissions.h"
#import <OCMock/OCMock.h>
#import "SwrveSDK.h"
#import "SwrveTestHelper.h"
#import "SwrveMigrationsManager.h"

@interface SwrveMigrationsManager (SwrveInternalAccess)
+ (void)setCurrentCacheVersion:(int)cacheVersion;
@end

@interface Swrve (Internal)
- (void)appDidBecomeActive:(NSNotification *)notification;
- (UInt64)secondsSinceEpoch;
@end

@interface SwrveTestInitTV : XCTestCase

@end

@implementation SwrveTestInitTV

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

- (void)testDeviceInfoWithtvOS {
    // Initialize SDK
    Swrve *swrveMock = [SwrveTestHelper swrveMockWithMockedRestClient];
    swrveMock = [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey"];
    [swrveMock idfa:@"12345"];
    [swrveMock appDidBecomeActive:nil];

    UIScreen *screen = [UIScreen mainScreen];
    CGRect screen_bounds = [screen bounds];
    float screen_scale = screen_scale = [[UIScreen mainScreen] scale];
    screen_bounds.size.width = screen_bounds.size.width * screen_scale;
    screen_bounds.size.height = screen_bounds.size.height * screen_scale;
    const int side_a = (int) screen_bounds.size.width;
    const int side_b = (int) screen_bounds.size.height;
    screen_bounds.size.width = (side_a > side_b) ? side_b : side_a;
    screen_bounds.size.height = (side_a > side_b) ? side_a : side_b;

    NSNumber *device_width = [NSNumber numberWithFloat:screen_bounds.size.width];
    NSNumber *device_height = [NSNumber numberWithFloat:screen_bounds.size.height];

    NSDictionary *deviceInfo = ((id <SwrveCommonDelegate>) swrveMock).deviceInfo;
    XCTAssertNotNil(deviceInfo);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.device_name"]);
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.os"], @"tvos");
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.os_version"], [[UIDevice currentDevice] systemVersion]);
    XCTAssertTrue([[deviceInfo objectForKey:@"swrve.ios_min_version"] isKindOfClass:[NSNumber class]]);
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.language"], swrveMock.config.language);
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.device_width"], device_width);
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.device_height"], device_height);
    XCTAssertTrue([[deviceInfo objectForKey:@"swrve.device_dpi"] isKindOfClass:[NSNumber class]]);
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.sdk_version"], [@"iOS " stringByAppendingString:@SWRVE_SDK_VERSION]);
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.app_store"], @"apple");
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.utc_offset_seconds"], [NSNumber numberWithInteger:[[NSTimeZone localTimeZone] secondsFromGMT]]);
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.timezone_name"], [NSTimeZone localTimeZone].name);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.device_region"]);
    XCTAssertTrue([[deviceInfo objectForKey:@"swrve.install_date"] isKindOfClass:[NSString class]]);
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.sdk_init_mode"], @"auto_auto");
    XCTAssertEqualObjects([deviceInfo objectForKey:@"swrve.device_type"], @"tv");
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.tracking_state"]);
    
    // IDFA & Device Info count
    XCTAssertEqual([deviceInfo count], 18);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.IDFA"]);
    
    // Wont collect unless config is set to auto collect.
    XCTAssertNil([deviceInfo objectForKey:@"swrve.IDFV"]);
}

- (void)testInstallDateForTvOS {

    // No data, install time should be "now" 2016/1/1 1:00:00
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *fileNameDocuments = [SwrveLocalStorage userInitDateFilePath:@"bob"];
    [fileManager removeItemAtPath:fileNameDocuments error:nil];

    [SwrveLocalStorage saveSwrveUserId:@"bob"];
    
    Swrve *swrveMock = [SwrveTestHelper swrveMockWithMockedRestClient];
    OCMStub([swrveMock secondsSinceEpoch]).andReturn(1451610000);
    swrveMock = [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey"];
    [swrveMock appDidBecomeActive:nil];
    XCTAssertEqualObjects([((id <SwrveCommonDelegate>) swrveMock).deviceInfo objectForKey:@"swrve.install_date"], @"20160101");

    // Simulate app had legacy file but no new file
    [fileManager removeItemAtPath:fileNameDocuments error:nil];
    [SwrveLocalStorage saveUserJoinedTime:1420074000 forUserId:@"bob"];

    [SwrveMigrationsManager setCurrentCacheVersion:0];
    Swrve *swrveMock2 = [SwrveTestHelper swrveMockWithMockedRestClient];
    OCMStub([swrveMock2 secondsSinceEpoch]).andReturn(1451610000);
    swrveMock2 = [swrveMock2 initWithAppID:123 apiKey:@"SomeAPIKey"];
    [swrveMock2 appDidBecomeActive:nil];
    XCTAssertEqualObjects([((id <SwrveCommonDelegate>) swrveMock2).deviceInfo objectForKey:@"swrve.install_date"], @"20150101");

    // Simulate app had legacy file AND new file
    [fileManager removeItemAtPath:fileNameDocuments error:nil];
    [SwrveLocalStorage saveUserJoinedTime:1427850000 forUserId:@"bob"];

    [SwrveMigrationsManager setCurrentCacheVersion:0];
    Swrve *swrveMock3 = [SwrveTestHelper swrveMockWithMockedRestClient];
    OCMStub([swrveMock3 secondsSinceEpoch]).andReturn(1451610000);
    swrveMock3 = [swrveMock3 initWithAppID:123 apiKey:@"SomeAPIKey"];
    [swrveMock3 appDidBecomeActive:nil];
    XCTAssertEqualObjects([((id <SwrveCommonDelegate>) swrveMock3).deviceInfo objectForKey:@"swrve.install_date"], @"20150401");

    // Simulate app had new file only (never run the legacy SDK)
    [fileManager removeItemAtPath:fileNameDocuments error:nil];
    [SwrveLocalStorage saveUserJoinedTime:1420074000 forUserId:@"bob"];

    [SwrveMigrationsManager setCurrentCacheVersion:0];
    Swrve *swrveMock4 = [SwrveTestHelper swrveMockWithMockedRestClient];
    OCMStub([swrveMock4 secondsSinceEpoch]).andReturn(1451610000);
    swrveMock4 = [swrveMock4 initWithAppID:123 apiKey:@"SomeAPIKey"];
    [swrveMock4 appDidBecomeActive:nil];
    XCTAssertEqualObjects([((id <SwrveCommonDelegate>) swrveMock4).deviceInfo objectForKey:@"swrve.install_date"], @"20150101");

    // Simulate app was storing the install_date in milliseconds (< 4.7 legacy bug)
    [fileManager removeItemAtPath:fileNameDocuments error:nil];
    [SwrveLocalStorage saveUserJoinedTime:1420074000000 forUserId:@"bob"];

    [SwrveMigrationsManager setCurrentCacheVersion:0];
    Swrve *swrveMock5 = [SwrveTestHelper swrveMockWithMockedRestClient];
    OCMStub([swrveMock5 secondsSinceEpoch]).andReturn(1451610000);
    swrveMock5 = [swrveMock5 initWithAppID:123 apiKey:@"SomeAPIKey"];
    [swrveMock5 appDidBecomeActive:nil];
    XCTAssertEqualObjects([((id <SwrveCommonDelegate>) swrveMock5).deviceInfo objectForKey:@"swrve.install_date"], @"20150101");
}

@end
