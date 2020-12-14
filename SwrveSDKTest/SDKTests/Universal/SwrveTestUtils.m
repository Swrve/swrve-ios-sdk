#import <XCTest/XCTest.h>
#import "SwrveUtils.h"

@interface SwrveTestUtils : XCTestCase

@end

@implementation SwrveTestUtils

- (void)testGetStringFromDic {
    NSDictionary *dicWithString = @{ @"value":@"123" };
    NSDictionary *dicWithNumber = @{ @"value":@123 };
    XCTAssertEqualObjects([SwrveUtils getStringFromDic:dicWithString withKey:@"value"], @"123");
    XCTAssertEqualObjects([SwrveUtils getStringFromDic:dicWithNumber withKey:@"value"], @"123");
}

- (void)testIDFAValid {
    XCTAssertFalse([SwrveUtils isValidIDFA:nil]);
    XCTAssertFalse([SwrveUtils isValidIDFA:@"-------"]);
    XCTAssertFalse([SwrveUtils isValidIDFA:@"0000000"]);
    XCTAssertFalse([SwrveUtils isValidIDFA:@"0-0-"]);
    XCTAssertFalse([SwrveUtils isValidIDFA:@"-0-0-"]);
    XCTAssertFalse([SwrveUtils isValidIDFA:@"---00"]);
    XCTAssertFalse([SwrveUtils isValidIDFA:@"00---"]);
    
    //lenght check for idfa is > 0
    XCTAssertTrue([SwrveUtils isValidIDFA:@"12345-0000"]);
}

@end

