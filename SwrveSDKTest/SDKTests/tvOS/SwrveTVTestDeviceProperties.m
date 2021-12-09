#import <XCTest/XCTest.h>
#import "SwrveProtocol.h"
#import "SwrveConfig.h"
#import "SwrvePermissions.h"
#import "SwrveDeviceProperties.h"
#import "SwrveUtils.h"
#import <OCMock/OCMock.h>
#import "TestPermissionsDelegate.h"
#import "SwrveMockNSURLProtocol.h"
#import "SwrveSDK.h"
#import "SwrveTestHelper.h"

@interface SwrveTVTestDeviceProperties : XCTestCase

@end

@implementation SwrveTVTestDeviceProperties

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

- (int)devicePropertyCount {
    return 14;
}

- (void)testDevicePropertiesNil {
    
    SwrveDeviceProperties *swrveDeviceProperties = [[SwrveDeviceProperties alloc]initWithVersion:nil
                                                                            appInstallTimeSeconds:0
                                                                                 permissionStatus:nil
                                                                                     sdk_language:nil
                                                                                    swrveInitMode:nil];
    
    NSDictionary *deviceInfo = [swrveDeviceProperties deviceProperties];
    
    XCTAssertTrue(deviceInfo != nil);
    XCTAssertEqual([deviceInfo count],[self devicePropertyCount]);
    
    XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.app_store"], @"apple");
    XCTAssertNil([deviceInfo objectForKey:@"swrve.conversation_version"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.device_dpi"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.device_name"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.device_width"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.device_height"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.device_type"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.device_region"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.install_date"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.ios_min_version"]);
    XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.os"], @"tvos");
    XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.os_version"], [[UIDevice currentDevice] systemVersion]);
    XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.timezone_name"], [NSTimeZone localTimeZone].name);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.utc_offset_seconds"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.tracking_state"]);
    
    // Needs to be manually set, after permission requested
    XCTAssertNil([deviceInfo objectForKey:@"swrve.IDFV"]);
    
    // Needs to be manually set, if autoCollectIDFV is true in config
    XCTAssertNil([deviceInfo objectForKey:@"swrve.IDFA"]);
}

- (void)testDevicePropertiesNil_WithSDKVersion {
    
    SwrveDeviceProperties *swrveDeviceProperties = [[SwrveDeviceProperties alloc]initWithVersion:@SWRVE_SDK_VERSION
                                                                           appInstallTimeSeconds:0
                                                                                permissionStatus:nil
                                                                                    sdk_language:nil
                                                                                   swrveInitMode:nil];
    
    NSDictionary *deviceInfo = [swrveDeviceProperties deviceProperties];
    
    XCTAssertTrue([deviceInfo count] == [self devicePropertyCount] + 1);
    XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.sdk_version"], [@"iOS " stringByAppendingString:@SWRVE_SDK_VERSION]);
}

- (void)testDevicePropertiesNil_WithInstallDate {
    
    int installTimeSecondsTest = 1504774566;
    
    SwrveDeviceProperties * swrveDeviceProperties = [[SwrveDeviceProperties alloc]initWithVersion:nil
                                                                            appInstallTimeSeconds:installTimeSecondsTest
                                                                                 permissionStatus:nil
                                                                                     sdk_language:nil
                                                                                    swrveInitMode:nil];
    
    
    NSDictionary *deviceInfo = [swrveDeviceProperties deviceProperties];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd"];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:installTimeSecondsTest];
    
    XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.install_date"], [dateFormatter stringFromDate:date]);
}


- (void)testDevicePropertiesNil_WithPermissions {
    
    [NSURLProtocol registerClass:[SwrveMockNSURLProtocol class]];
    TestPermissionsDelegate *permissionsDelegate = [[TestPermissionsDelegate alloc] init];
    SwrveConfig* config = [[SwrveConfig alloc] init];
    config.autoCollectIDFV = true;
    config.autoDownloadCampaignsAndResources = false;
    config.permissionsDelegate = permissionsDelegate;
    [SwrveSDK sharedInstanceWithAppID:1 apiKey:@"Key" config:config];
    Swrve *sdk = [SwrveSDK sharedInstance];
    [sdk idfa:@"12345"];
    
    NSDictionary *permissionStatus = [SwrvePermissions currentStatusWithSDK:(id<SwrveCommonDelegate>)sdk];
    
    SwrveDeviceProperties *swrveDeviceProperties = [[SwrveDeviceProperties alloc]initWithVersion:nil
                                                                           appInstallTimeSeconds:0
                                                                                permissionStatus:permissionStatus
                                                                                    sdk_language:nil
                                                                                   swrveInitMode:nil];
    
    swrveDeviceProperties.autoCollectIDFV = config.autoCollectIDFV;
    
    NSDictionary *deviceInfo = [swrveDeviceProperties deviceProperties];
    
    XCTAssertTrue([deviceInfo valueForKey:@"Swrve.permission.ios.location.always"]!= nil);
    XCTAssertTrue([deviceInfo valueForKey:@"Swrve.permission.ios.location.when_in_use"]!= nil);
    XCTAssertTrue([deviceInfo valueForKey:@"Swrve.permission.ios.photos"]!= nil);
    XCTAssertTrue([deviceInfo valueForKey:@"Swrve.permission.ios.camera"]!= nil);
    XCTAssertTrue([deviceInfo valueForKey:@"Swrve.permission.ios.contacts"] != nil);
    XCTAssertTrue([deviceInfo valueForKey:@"swrve.permission.ios.ad_tracking"] != nil);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.IDFV"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.IDFA"]);
    
    
    XCTAssertTrue([deviceInfo count] == [self devicePropertyCount] + 8);
    
    [NSURLProtocol unregisterClass:[SwrveMockNSURLProtocol class]];
}



- (void)testDevicePropertiesNil_WithLanguage {
    
    SwrveConfig *config = [[SwrveConfig alloc]init];
    
    SwrveDeviceProperties *swrveDeviceProperties = [[SwrveDeviceProperties alloc]initWithVersion:nil
                                                                           appInstallTimeSeconds:0
                                                                                permissionStatus:nil
                                                                                    sdk_language:config.language
                                                                                   swrveInitMode:nil];
    
    
    NSDictionary *deviceInfo = [swrveDeviceProperties deviceProperties];
    
    XCTAssertTrue([deviceInfo count] == [self devicePropertyCount] + 1);
    
    XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.language"] , config.language);
}

@end
