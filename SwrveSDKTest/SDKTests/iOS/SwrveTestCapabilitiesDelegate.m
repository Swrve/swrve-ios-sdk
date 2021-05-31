#import <XCTest/XCTest.h>
#import "SwrveSDK.h"
#import "TestCapabilitiesDelegate.h"

@interface SwrveTestCapabilitiesDelegate : XCTestCase

@end

@implementation SwrveTestCapabilitiesDelegate

- (void)testCapabilitiesDelegate {
    SwrveConfig *config = [SwrveConfig new];
    SwrveInAppMessageConfig *inAppMessageConfig = [SwrveInAppMessageConfig new];
    TestCapabilitiesDelegate *testDelegate = [TestCapabilitiesDelegate new];
    inAppMessageConfig.inAppCapabilitiesDelegate = testDelegate;
    config.inAppMessageConfig = inAppMessageConfig;
    
    XCTAssertFalse([testDelegate canRequestCapability:@"Unknown"]);
    XCTAssertTrue([testDelegate canRequestCapability:@"swrve.contacts"]);
    XCTAssertFalse([testDelegate canRequestCapability:@"swrve.photo"]);
    
    __block bool callback = false;
    [testDelegate requestCapability:@"Unknown" completionHandler:^(BOOL success) {
        callback = success;
    }];
    XCTAssertFalse(callback);
    
    [testDelegate requestCapability:@"swrve.contacts" completionHandler:^(BOOL success) {
        callback = success;
    }];
    XCTAssertTrue(callback);
    
    [testDelegate requestCapability:@"swrve.photo" completionHandler:^(BOOL success) {
        callback = success;
    }];
    XCTAssertFalse(callback);
}

@end
