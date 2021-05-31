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
    XCTAssertFalse([SwrveUtils isValidIDFA:@""]);
    XCTAssertFalse([SwrveUtils isValidIDFA:@"-------"]);
    XCTAssertFalse([SwrveUtils isValidIDFA:@"0000000"]);
    XCTAssertFalse([SwrveUtils isValidIDFA:@"0-0-"]);
    XCTAssertFalse([SwrveUtils isValidIDFA:@"-0-0-"]);
    XCTAssertFalse([SwrveUtils isValidIDFA:@"---00"]);
    XCTAssertFalse([SwrveUtils isValidIDFA:@"00---"]);
    
    // length check for idfa is > 0
    XCTAssertTrue([SwrveUtils isValidIDFA:@"12345-0000"]);
}

- (void)testSha1 {
    NSString *url = @"https://www.url.fake/image.png";
    NSData *data = [url dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    XCTAssertEqualObjects([SwrveUtils sha1:data], @"52712a2126ee461a792bef8fbf29cec68fdf1225");
}

- (void)testCombineDictionary {
    NSDictionary *dictionary1 = @{@"key1": @"replace_me", @"key2": @"value2"};
    NSDictionary *dictionary2 = @{@"key1": @"value1", @"key3": @"value3"};
    
    NSDictionary *combinedDictionary = [SwrveUtils combineDictionary:dictionary1 withDictionary:dictionary2];
    NSDictionary *expectedDictionary = @{@"key1":@"value1", @"key2": @"value2", @"key3":@"value3"};
    XCTAssertEqualObjects(expectedDictionary, combinedDictionary);
    
    combinedDictionary = [SwrveUtils combineDictionary:nil withDictionary:dictionary2];
    XCTAssertEqualObjects(dictionary2, combinedDictionary);
    
    combinedDictionary = [SwrveUtils combineDictionary:dictionary1 withDictionary:nil];
    XCTAssertEqualObjects(dictionary1, combinedDictionary);
    
    // make sure it won't crash
    combinedDictionary = [SwrveUtils combineDictionary:nil withDictionary:nil];
    XCTAssertEqualObjects(combinedDictionary, nil);
}

@end

