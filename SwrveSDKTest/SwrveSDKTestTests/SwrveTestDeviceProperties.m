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

    //  initial install property count
    int propertyCount = 13;

    // increase depending on what macros have been defined
#if defined(SWRVE_LOG_IDFA)
    propertyCount++;
#endif

#if defined(SWRVE_LOG_IDFA)
    propertyCount++;
#endif

    return propertyCount;
}


- (void)testDevicePropertiesNil {

    SwrveDeviceProperties * swrveDeviceProperties = [[SwrveDeviceProperties alloc]initWithVersion:nil
                                                                               appInstallTimeSeconds:0
                                                                              conversationVersion:0
                                                                                      deviceToken:nil
                                                                                 permissionStatus:nil
                                                                                     sdk_language:nil
                                                                                      carrierInfo:nil];

    NSDictionary *deviceInfo = [swrveDeviceProperties deviceProperties];

    XCTAssertTrue(deviceInfo != nil);
    XCTAssertTrue([deviceInfo count] == [self devicePropertyCount]);

    XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.app_store"], @"apple");
    XCTAssertTrue([deviceInfo valueForKey:@"swrve.conversation_version"] != nil);
    XCTAssertTrue([deviceInfo valueForKey:@"swrve.device_dpi"]!= nil);
    XCTAssertTrue([deviceInfo valueForKey:@"swrve.device_height"] != nil);
    XCTAssertTrue([deviceInfo valueForKey:@"swrve.device_name"] != nil);
    XCTAssertTrue([deviceInfo valueForKey:@"swrve.device_width"] != nil);
    XCTAssertTrue([deviceInfo valueForKey:@"swrve.install_date"] != nil);
    XCTAssertTrue([deviceInfo valueForKey:@"swrve.ios_min_version"] != nil);
    XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.os"], [UIDevice currentDevice].systemName);
    XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.os_version"], [[UIDevice currentDevice] systemVersion]);
    XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.timezone_name"], [NSTimeZone localTimeZone].name);
    XCTAssertTrue([deviceInfo valueForKey:@"swrve.utc_offset_seconds"] != nil);

#if defined(SWRVE_LOG_IDFA)
    XCTAssertTrue([deviceInfo valueForKey:@"swrve.IDFA"] != nil );
#endif

#if defined(SWRVE_LOG_IDFV)
    XCTAssertTrue([deviceInfo valueForKey:@"swrve.IDFV"] != nil );
#endif
}

- (void)testDevicePropertiesNil_WithSDKVersion {

    SwrveDeviceProperties *swrveDeviceProperties = [[SwrveDeviceProperties alloc]initWithVersion:@SWRVE_SDK_VERSION
                                                                               appInstallTimeSeconds:0
                                                                              conversationVersion:0
                                                                                      deviceToken:nil
                                                                                 permissionStatus:nil
                                                                                     sdk_language:nil
                                                                                      carrierInfo:nil];

    NSDictionary *deviceInfo = [swrveDeviceProperties deviceProperties];

    XCTAssertTrue([deviceInfo count] == [self devicePropertyCount] + 1);
    XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.sdk_version"], @SWRVE_SDK_VERSION);
}

- (void)testDevicePropertiesNil_WithInstallDate {

    int installTimeSecondsTest = 1504774566;

    SwrveDeviceProperties * swrveDeviceProperties = [[SwrveDeviceProperties alloc]initWithVersion:nil
                                                                               appInstallTimeSeconds:installTimeSecondsTest
                                                                              conversationVersion:0
                                                                                      deviceToken:nil
                                                                                 permissionStatus:nil
                                                                                     sdk_language:nil
                                                                                      carrierInfo:nil];


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
                                                                                      carrierInfo:nil];


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
                                                                                      carrierInfo:nil];


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
                                                                                      carrierInfo:nil];

    NSDictionary *deviceInfo = [swrveDeviceProperties deviceProperties];

    XCTAssertTrue([deviceInfo valueForKey:@"Swrve.permission.ios.location.always"]!= nil);
    XCTAssertTrue([deviceInfo valueForKey:@"Swrve.permission.ios.location.when_in_use"]!= nil);
    XCTAssertTrue([deviceInfo valueForKey:@"Swrve.permission.ios.photos"]!= nil);
    XCTAssertTrue([deviceInfo valueForKey:@"Swrve.permission.ios.camera"]!= nil);
    XCTAssertTrue([deviceInfo valueForKey:@"Swrve.permission.ios.contacts"] != nil);
    XCTAssertTrue([deviceInfo valueForKey:@"Swrve.permission.ios.push_bg_refresh"]!= nil);
    XCTAssertTrue([deviceInfo valueForKey:@"Swrve.permission.ios.push_notifications"]!= nil);

    XCTAssertTrue([deviceInfo count] == [self devicePropertyCount] + 7);
    
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
                                                                                      carrierInfo:nil];


    NSDictionary *deviceInfo = [swrveDeviceProperties deviceProperties];

    XCTAssertTrue([deviceInfo count] == [self devicePropertyCount] + 1);

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
                                                                                      carrierInfo:dummyCTCarrier];


    NSDictionary *deviceInfo = [swrveDeviceProperties deviceProperties];

    XCTAssertTrue([deviceInfo count] == [self devicePropertyCount] + 3);
    XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.sim_operator.name"], @"vodafone IE");

    NSString *code = [deviceInfo valueForKey:@"swrve.sim_operator.code"];

    XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.sim_operator.code"], code);
    XCTAssertEqualObjects([deviceInfo valueForKey:@"swrve.sim_operator.iso_country_code"], @"ie");
}

@end
