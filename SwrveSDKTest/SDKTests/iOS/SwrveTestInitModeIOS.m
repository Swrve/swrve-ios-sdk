#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SwrveSDK.h"
#import "SwrveTestHelper.h"

@interface SwrveTestInitModeIOS : XCTestCase {
    
}
@end

@interface SwrveSDK (InternalAccess)
+ (void)addSharedInstance:(Swrve*)instance;
+ (void)resetSwrveSharedInstance;
@end

@interface Swrve (InternalAccess)
- (BOOL)sdkReady;
@end

@implementation SwrveTestInitModeIOS

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

- (id)initSwrveSDKWithMode:(SwrveInitMode) mode{
    
    [SwrveSDK resetSwrveSharedInstance];
    
    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.initMode = mode;
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
    [SwrveSDK addSharedInstance:swrveMock];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey" config:config];
#pragma clang diagnostic pop
    
    return swrveMock;
}

- (void)testSetDeviceToken {

    id swrveMockManaged = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED];
    OCMExpect([swrveMockManaged sdkReady]).andForwardToRealObject();
    [SwrveSDK setDeviceToken:[NSData new]];
    OCMVerifyAll(swrveMockManaged);
    
    id swrveMockAuto = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO];
    OCMExpect([swrveMockAuto sdkReady]).andForwardToRealObject();
    [SwrveSDK setDeviceToken:[NSData new]];
    OCMVerifyAll(swrveMockAuto);
}

- (void)testDeviceToken {

    id swrveMockManaged = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED];
    NSString *deviceTokenManaged = [SwrveSDK deviceToken];
    XCTAssertNil(deviceTokenManaged);
    
    id swrveMockAuto = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO];
    NSString *deviceTokenAuto = [SwrveSDK deviceToken];
    XCTAssertNil(deviceTokenAuto);
    
    //Mock/Set the internal instance varaible _deviceToken
    [swrveMockManaged setValue:@"SomeUserToken" forKeyPath:@"_deviceToken"];
    [swrveMockAuto setValue:@"SomeUserToken" forKeyPath:@"_deviceToken"];
    
    deviceTokenManaged = [SwrveSDK deviceToken];
    XCTAssertEqualObjects(deviceTokenManaged, @"SomeUserToken");
    deviceTokenAuto = [SwrveSDK deviceToken];
    XCTAssertEqualObjects(deviceTokenManaged, @"SomeUserToken");
    
    //Stop tracking, check device token still available
    [swrveMockManaged stopTracking];
    [swrveMockAuto stopTracking];
    
    deviceTokenManaged = [SwrveSDK deviceToken];
    XCTAssertEqualObjects(deviceTokenManaged, @"SomeUserToken");
    
    deviceTokenAuto = [SwrveSDK deviceToken];
    XCTAssertEqualObjects(deviceTokenAuto, @"SomeUserToken");
    
}

@end

