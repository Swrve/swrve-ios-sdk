#import <XCTest/XCTest.h>
#import "SwrveUtils.h"

@interface SwrveTestUtilsTV : XCTestCase

@end

@implementation SwrveTestUtilsTV

- (void)testPlatformDeviceType {
    NSString *deviceType = [SwrveUtils platformDeviceType];
    XCTAssertEqualObjects(deviceType, @"tv");
}

@end
