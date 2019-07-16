#import <XCTest/XCTest.h>
#import "SwrveProtocol.h"
#import "SwrveConfig.h"
#import "SwrvePermissions.h"
#import "SwrveDeviceProperties.h"
#import "SwrveUtils.h"
#import <OCMock/OCMock.h>

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
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (int)devicePropertyCount {
    return 15;
}

- (int)permissionsCounts {

    int propertyCount = 0;

    // increase depending on what macros have been defined
    #if defined(SWRVE_LOCATION) || defined(SWRVE_LOCATION_SDK)
    propertyCount += 2;
    #endif

    #if defined(SWRVE_PHOTO_LIBRARY)
    propertyCount++;
    #endif

    #if defined(SWRVE_PHOTO_CAMERA)
    propertyCount++;
    #endif

    #if defined(SWRVE_ADDRESS_BOOK)
    propertyCount++;
    #endif

    return propertyCount;
}

- (void)testDevicePropertiesNil {

    SwrveDeviceProperties * swrveDeviceProperties = [[SwrveDeviceProperties alloc]initWithVersion:nil
                                                                               installTimeSeconds:0
                                                                              conversationVersion:0
                                                                                      deviceToken:nil
                                                                                 permissionStatus:nil
                                                                                     sdk_language:nil
                                                                                      carrierInfo:nil];

    NSDictionary * deviceInfo = [swrveDeviceProperties deviceProperties];

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
    XCTAssertEqual([deviceInfo valueForKey:@"swrve.os"], [UIDevice currentDevice].systemName);
    XCTAssertEqual([deviceInfo valueForKey:@"swrve.os_version"], [[UIDevice currentDevice] systemVersion]);
    XCTAssertEqual([deviceInfo valueForKey:@"swrve.timezone_name"], [NSTimeZone localTimeZone].name);
    XCTAssertTrue([deviceInfo valueForKey:@"swrve.utc_offset_seconds"] != nil);

    #if defined(SWRVE_LOG_IDFA)
        XCTAssertTrue([deviceInfo valueForKey:@"swrve.IDFA"] != nil );
    #endif

    #if defined(SWRVE_LOG_IDFV)
        XCTAssertTrue([deviceInfo valueForKey:@"swrve.IDFV"] != nil );
    #endif
}

- (void)testDevicePropertiesNil_WithSDKVersion {

    SwrveDeviceProperties * swrveDeviceProperties = [[SwrveDeviceProperties alloc]initWithVersion:@SWRVE_SDK_VERSION
                                                                               installTimeSeconds:0
                                                                              conversationVersion:0
                                                                                      deviceToken:nil
                                                                                 permissionStatus:nil
                                                                                     sdk_language:nil
                                                                                      carrierInfo:nil];

    NSDictionary * deviceInfo = [swrveDeviceProperties deviceProperties];

    XCTAssertTrue([deviceInfo count] == [self devicePropertyCount] + 1);
    XCTAssertEqual([deviceInfo valueForKey:@"swrve.sdk_version"], @SWRVE_SDK_VERSION);
}

- (void)testDevicePropertiesNil_WithInstallDate {

    int installTimeSecondsTest = 1504774566;

    SwrveDeviceProperties * swrveDeviceProperties = [[SwrveDeviceProperties alloc]initWithVersion:nil
                                                                               installTimeSeconds:installTimeSecondsTest
                                                                              conversationVersion:0
                                                                                      deviceToken:nil
                                                                                 permissionStatus:nil
                                                                                     sdk_language:nil
                                                                                      carrierInfo:nil];


    NSDictionary * deviceInfo = [swrveDeviceProperties deviceProperties];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd"];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:installTimeSecondsTest];

    XCTAssertEqual([deviceInfo valueForKey:@"swrve.install_date"], [dateFormatter stringFromDate:date]);
}

- (void)testDevicePropertiesNil_WithConversationVersion {

    int conversationVersionTest = 6;

    SwrveDeviceProperties * swrveDeviceProperties = [[SwrveDeviceProperties alloc]initWithVersion:nil
                                                                               installTimeSeconds:0
                                                                              conversationVersion:conversationVersionTest
                                                                                      deviceToken:nil
                                                                                 permissionStatus:nil
                                                                                     sdk_language:nil
                                                                                      carrierInfo:nil];


    NSDictionary * deviceInfo = [swrveDeviceProperties deviceProperties];

    XCTAssertEqual([deviceInfo valueForKey:@"swrve.conversation_version"], [NSNumber numberWithInteger:conversationVersionTest]);
}

- (void)testDevicePropertiesNil_WithDeviceToken {

    SwrveDeviceProperties * swrveDeviceProperties = [[SwrveDeviceProperties alloc]initWithVersion:nil
                                                                               installTimeSeconds:0
                                                                              conversationVersion:0
                                                                                      deviceToken:@"TestDeviceToken"
                                                                                 permissionStatus:nil
                                                                                     sdk_language:nil
                                                                                      carrierInfo:nil];


    NSDictionary * deviceInfo = [swrveDeviceProperties deviceProperties];

    XCTAssertEqual([deviceInfo valueForKey:@"swrve.ios_token"] , @"TestDeviceToken");
}

- (void)testDevicePropertiesNil_WithPermissions {

    id swrveMock = OCMProtocolMock(@protocol(SwrveCommonDelegate));

    NSDictionary* permissionStatus = [SwrvePermissions currentStatusWithSDK:swrveMock];

    SwrveDeviceProperties * swrveDeviceProperties = [[SwrveDeviceProperties alloc]initWithVersion:nil
                                                                               installTimeSeconds:0
                                                                              conversationVersion:0
                                                                                      deviceToken:nil
                                                                                 permissionStatus:permissionStatus
                                                                                     sdk_language:nil
                                                                                      carrierInfo:nil];

    NSDictionary * deviceInfo = [swrveDeviceProperties deviceProperties];

    #if defined(SWRVE_LOCATION) || defined(SWRVE_LOCATION_SDK)
        XCTAssertTrue([deviceInfo valueForKey:@"Swrve.permission.ios.location.always"]!= nil);
        XCTAssertTrue([deviceInfo valueForKey:@"Swrve.permission.ios.location.when_in_use"]!= nil);
    #endif

    #if defined(SWRVE_PHOTO_LIBRARY)
        XCTAssertTrue([deviceInfo valueForKey:@"Swrve.permission.ios.photos"]!= nil);
    #endif

    #if defined(SWRVE_PHOTO_CAMERA)
        XCTAssertTrue([deviceInfo valueForKey:@"Swrve.permission.ios.camera"]!= nil);
    #endif

    #if defined(SWRVE_ADDRESS_BOOK)
        XCTAssertTrue([deviceInfo valueForKey:@"Swrve.permission.ios.contacts"] != nil);
    #endif

    XCTAssertTrue([deviceInfo valueForKey:@"Swrve.permission.ios.push_bg_refresh"]!= nil);

    int devicePermissionsCount = [self devicePropertyCount] + [self permissionsCounts];

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {

        // iOS 10+ has async callback in pushAuthorizationWithSDK so its not going to show the
        // Swrve.permission.ios.push_notifications immediately in the permissionsStatus

        XCTAssertTrue([deviceInfo count] == devicePermissionsCount + 1);

    } else {

        XCTAssertTrue([deviceInfo count] == devicePermissionsCount + 2);
        XCTAssertTrue([deviceInfo valueForKey:@"Swrve.permission.ios.push_notifications"]!= nil);
    }
}



- (void)testDevicePropertiesNil_WithLanguage {

    SwrveConfig * config = [[SwrveConfig alloc]init];

    SwrveDeviceProperties * swrveDeviceProperties = [[SwrveDeviceProperties alloc]initWithVersion:nil
                                                                               installTimeSeconds:0
                                                                              conversationVersion:0
                                                                                      deviceToken:nil
                                                                                 permissionStatus:nil
                                                                                     sdk_language:config.language
                                                                                      carrierInfo:nil];


    NSDictionary * deviceInfo = [swrveDeviceProperties deviceProperties];

    XCTAssertTrue([deviceInfo count] == [self devicePropertyCount] + 1);

    XCTAssertEqual([deviceInfo valueForKey:@"swrve.language"] , config.language);
}

- (void)testDevicePropertiesNil_WithDummyCarrierInfo {

    DummyCTCarrier* dummyCTCarrier = [DummyCTCarrier new];

    dummyCTCarrier.carrierName = @"vodafone IE";
    dummyCTCarrier.mobileCountryCode = @"272";
    dummyCTCarrier.mobileNetworkCode = @"01";
    dummyCTCarrier.isoCountryCode = @"ie";

    SwrveDeviceProperties * swrveDeviceProperties = [[SwrveDeviceProperties alloc]initWithVersion:nil
                                                                               installTimeSeconds:0
                                                                              conversationVersion:0
                                                                                      deviceToken:nil
                                                                                 permissionStatus:nil
                                                                                     sdk_language:nil
                                                                                      carrierInfo:dummyCTCarrier];


    NSDictionary * deviceInfo = [swrveDeviceProperties deviceProperties];

    XCTAssertTrue([deviceInfo count] == [self devicePropertyCount] + 3);
    XCTAssertEqual([deviceInfo valueForKey:@"swrve.sim_operator.name"], @"vodafone IE");

    NSString * code = [deviceInfo valueForKey:@"swrve.sim_operator.code"];

    XCTAssertEqual([deviceInfo valueForKey:@"swrve.sim_operator.code"], code);
    XCTAssertEqual([deviceInfo valueForKey:@"swrve.sim_operator.iso_country_code"], @"ie");
}

@end
