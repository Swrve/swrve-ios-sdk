#import <XCTest/XCTest.h>
#import "SwrveProtocol.h"
#import "SwrvePermissions.h"
#import "SwrveDeviceProperties.h"
#import <OCMock/OCMock.h>
#import "TestPermissionsDelegate.h"
#import "SwrveMockNSURLProtocol.h"
#import "SwrveSDK.h"
#import "SwrveTestHelper.h"

@interface SwrveDeviceProperties ()
- (NSString *)installDate:(UInt64)appInstallTimeSeconds;
@end

@interface DummyCTCarrier : CTCarrier

@property (nonatomic) NSString *carrierName;
@property (nonatomic) NSString *mobileCountryCode;
@property (nonatomic) NSString *mobileNetworkCode;
@property (nonatomic) NSString *isoCountryCode;

@end

@implementation DummyCTCarrier

@synthesize carrierName;
@synthesize mobileCountryCode;
@synthesize mobileNetworkCode;
@synthesize isoCountryCode;

@end

@interface SwrveTestDeviceProperties : XCTestCase

@end

@implementation SwrveTestDeviceProperties

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

- (int)devicePropertyCount {
    return 15;
}

- (void)testDevicePropertiesNil {
    
    SwrveDeviceProperties *swrveDeviceProperties = [[SwrveDeviceProperties alloc] initWithVersion:nil
                                                                            appInstallTimeSeconds:0
                                                                              conversationVersion:0
                                                                                      deviceToken:nil
                                                                                 permissionStatus:nil
                                                                                     sdk_language:nil
                                                                                      carrierInfo:nil
                                                                                    swrveInitMode:nil];
    
    NSDictionary *deviceInfo = [swrveDeviceProperties deviceProperties];
    
    XCTAssertTrue(deviceInfo != nil);
    XCTAssertEqual([deviceInfo count], [self devicePropertyCount]);
    
    XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.app_store"], @"apple");
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.conversation_version"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.device_dpi"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.device_name"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.device_width"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.device_height"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.device_type"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.device_region"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.install_date"]);
    XCTAssertNotNil([deviceInfo objectForKey:@"swrve.ios_min_version"]);
    
    NSString *osVersion = [[UIDevice currentDevice] systemVersion];
    if ([osVersion floatValue] >= 15 && [[[UIDevice currentDevice] name] containsString:@"iPad"]) {
        XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.os"], @"ipados");
    } else {
        XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.os"], @"ios");
    }

    XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.os_version"], osVersion);
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
                                                                             conversationVersion:0
                                                                                     deviceToken:nil
                                                                                permissionStatus:nil
                                                                                    sdk_language:nil
                                                                                     carrierInfo:nil
                                                                                   swrveInitMode:nil];
    
    NSDictionary *deviceInfo = [swrveDeviceProperties deviceProperties];
    
    XCTAssertEqual([deviceInfo count], [self devicePropertyCount] + 1);
    XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.sdk_version"], [@"iOS " stringByAppendingString:@SWRVE_SDK_VERSION]);
}

- (void)testDevicePropertiesNil_WithInstallDate {
    
    int installTimeSecondsTest = 1504774566;
    
    SwrveDeviceProperties * swrveDeviceProperties = [[SwrveDeviceProperties alloc]initWithVersion:nil
                                                                            appInstallTimeSeconds:installTimeSecondsTest
                                                                              conversationVersion:0
                                                                                      deviceToken:nil
                                                                                 permissionStatus:nil
                                                                                     sdk_language:nil
                                                                                      carrierInfo:nil
                                                                                    swrveInitMode:nil];
    
    
    NSDictionary *deviceInfo = [swrveDeviceProperties deviceProperties];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd"];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:installTimeSecondsTest];
    
    XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.install_date"], [dateFormatter stringFromDate:date]);
}

- (void)testDevicePropertiesNil_WithConversationVersion {
    
    int conversationVersionTest = 6;
    
    SwrveDeviceProperties * swrveDeviceProperties = [[SwrveDeviceProperties alloc]initWithVersion:nil
                                                                            appInstallTimeSeconds:0
                                                                              conversationVersion:conversationVersionTest
                                                                                      deviceToken:nil
                                                                                 permissionStatus:nil
                                                                                     sdk_language:nil
                                                                                      carrierInfo:nil
                                                                                    swrveInitMode:nil];
    
    
    NSDictionary *deviceInfo = [swrveDeviceProperties deviceProperties];
    
    XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.conversation_version"], [NSNumber numberWithInteger:conversationVersionTest]);
}

- (void)testDevicePropertiesNil_WithDeviceToken {
    
    SwrveDeviceProperties *swrveDeviceProperties = [[SwrveDeviceProperties alloc]initWithVersion:nil
                                                                           appInstallTimeSeconds:0
                                                                             conversationVersion:0
                                                                                     deviceToken:@"TestDeviceToken"
                                                                                permissionStatus:nil
                                                                                    sdk_language:nil
                                                                                     carrierInfo:nil
                                                                                   swrveInitMode:nil];
    
    
    NSDictionary *deviceInfo = [swrveDeviceProperties deviceProperties];
    
    XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.ios_token"] , @"TestDeviceToken");
}

- (void)testDevicePropertiesNil_WithPermissions {
    // setting Swrve.permission.ios.push_notifications is async operation, so might not happen in time for the checks below
    [SwrveLocalStorage savePermissions:@{@"Swrve.permission.ios.push_notifications":@"authorized"}];
    
    [NSURLProtocol registerClass:[SwrveMockNSURLProtocol class]];
    TestPermissionsDelegate *permissionsDelegate = [[TestPermissionsDelegate alloc] init];
    SwrveConfig* config = [[SwrveConfig alloc] init];
    config.autoDownloadCampaignsAndResources = false;
    config.permissionsDelegate = permissionsDelegate;
    [SwrveSDK sharedInstanceWithAppID:1 apiKey:@"Key" config:config];
    Swrve *sdk = [SwrveSDK sharedInstance];
    
    NSDictionary *permissionStatus = [SwrvePermissions currentStatusWithSDK:(id<SwrveCommonDelegate>)sdk];
    
    SwrveDeviceProperties *swrveDeviceProperties = [[SwrveDeviceProperties alloc]initWithVersion:nil
                                                                           appInstallTimeSeconds:0
                                                                             conversationVersion:0
                                                                                     deviceToken:nil
                                                                                permissionStatus:permissionStatus
                                                                                    sdk_language:nil
                                                                                     carrierInfo:nil
                                                                                   swrveInitMode:nil];
    
    NSDictionary *deviceInfo = [swrveDeviceProperties deviceProperties];
    
    XCTAssertTrue([deviceInfo valueForKey:@"Swrve.permission.ios.location.always"]!= nil);
    XCTAssertTrue([deviceInfo valueForKey:@"Swrve.permission.ios.location.when_in_use"]!= nil);
    XCTAssertTrue([deviceInfo valueForKey:@"Swrve.permission.ios.photos"]!= nil);
    XCTAssertTrue([deviceInfo valueForKey:@"Swrve.permission.ios.camera"]!= nil);
    XCTAssertTrue([deviceInfo valueForKey:@"Swrve.permission.ios.contacts"] != nil);
    XCTAssertTrue([deviceInfo valueForKey:@"Swrve.permission.ios.push_bg_refresh"]!= nil);
    XCTAssertTrue([deviceInfo valueForKey:@"Swrve.permission.ios.push_notifications"]!= nil);
    XCTAssertTrue([deviceInfo valueForKey:@"swrve.permission.ios.ad_tracking"]!= nil);
    
    XCTAssertEqual([deviceInfo count], [self devicePropertyCount] + 8);
    [NSURLProtocol unregisterClass:[SwrveMockNSURLProtocol class]];
}



- (void)testDevicePropertiesNil_WithLanguage {
    
    SwrveConfig *config = [[SwrveConfig alloc]init];
    
    SwrveDeviceProperties *swrveDeviceProperties = [[SwrveDeviceProperties alloc]initWithVersion:nil
                                                                           appInstallTimeSeconds:0
                                                                             conversationVersion:0
                                                                                     deviceToken:nil
                                                                                permissionStatus:nil
                                                                                    sdk_language:config.language
                                                                                     carrierInfo:nil
                                                                                   swrveInitMode:nil];
    
    
    NSDictionary *deviceInfo = [swrveDeviceProperties deviceProperties];
    
    XCTAssertEqual([deviceInfo count], [self devicePropertyCount] + 1);
    XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.language"] , config.language);
}

- (void)testDevicePropertiesNil_WithDummyCarrierInfo {
    
    DummyCTCarrier *dummyCTCarrier = [DummyCTCarrier new];
    
    dummyCTCarrier.carrierName = @"vodafone IE";
    dummyCTCarrier.mobileCountryCode = @"272";
    dummyCTCarrier.mobileNetworkCode = @"01";
    dummyCTCarrier.isoCountryCode = @"ie";
    
    SwrveDeviceProperties * swrveDeviceProperties = [[SwrveDeviceProperties alloc]initWithVersion:nil
                                                                            appInstallTimeSeconds:0
                                                                              conversationVersion:0
                                                                                      deviceToken:nil
                                                                                 permissionStatus:nil
                                                                                     sdk_language:nil
                                                                                      carrierInfo:dummyCTCarrier
                                                                                    swrveInitMode:nil];
    
    
    NSDictionary *deviceInfo = [swrveDeviceProperties deviceProperties];
    
    XCTAssertEqual([deviceInfo count], [self devicePropertyCount] + 3);
    XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.sim_operator.name"], @"vodafone IE");
    
    NSString *code = [deviceInfo valueForKey:@"swrve.sim_operator.code"];
    
    XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.sim_operator.code"], code);
    XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.sim_operator.iso_country_code"], @"ie");
}

- (void)testDevicePropertiesNil_WithInitMode {

    SwrveConfig *configManagedAutostartFalse = [[SwrveConfig alloc]init];
    [configManagedAutostartFalse setInitMode:SWRVE_INIT_MODE_MANAGED];
    [configManagedAutostartFalse setAutoStartLastUser:false];
    SwrveDeviceProperties *swrveDevicePropertiesManagedAutostartFalse = [[SwrveDeviceProperties alloc]initWithVersion:nil
                                                                                  appInstallTimeSeconds:0
                                                                                    conversationVersion:0
                                                                                            deviceToken:nil
                                                                                       permissionStatus:nil
                                                                                           sdk_language:nil
                                                                                            carrierInfo:nil
                                                                                          swrveInitMode:@"auto"];
    NSDictionary *deviceInfoManagedAutostartFalse = [swrveDevicePropertiesManagedAutostartFalse deviceProperties];
    XCTAssertEqual([deviceInfoManagedAutostartFalse count], [self devicePropertyCount] + 1);
    XCTAssertEqualObjects([deviceInfoManagedAutostartFalse valueForKey:@"swrve.sdk_init_mode"] , @"auto");
}

- (void)testDeviceProperties_InstallDateLocal {
    id swrveDeviceProperties = OCMPartialMock([SwrveDeviceProperties new]);
    OCMStub([swrveDeviceProperties appInstallTimeSeconds]).andReturn(5000);
    id nsLocale = OCMClassMock([NSLocale class]);
    
    //if local calender was set o japanese and appInstallTimeSeconds = 5000 yyyyMMdd would be 00450101
    NSLocale *systemLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US@calendar=japanese"];
    OCMStub([nsLocale currentLocale]).andReturn(systemLocale);

    NSString *installDate = [swrveDeviceProperties installDate:[swrveDeviceProperties appInstallTimeSeconds]];
    XCTAssertEqualObjects(installDate,@"19700101");
}
@end
