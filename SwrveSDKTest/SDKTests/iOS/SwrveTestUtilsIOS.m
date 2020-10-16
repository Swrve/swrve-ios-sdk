#import <XCTest/XCTest.h>
#import "SwrveUtils.h"

@interface SwrveTestUtilsIOS : XCTestCase

@end

@implementation SwrveTestUtilsIOS

- (void)testPlatformDeviceType {
    NSString *deviceType = [SwrveUtils platformDeviceType];
    XCTAssertEqualObjects(deviceType, @"mobile");
}


@end
