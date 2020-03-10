#import <XCTest/XCTest.h>
#import "SwrveTestHelper.h"

@interface SwrveTestABTestDetails : XCTestCase

@end

@implementation SwrveTestABTestDetails

- (void) testABTestDetails {
    SwrveConfig* config = [[SwrveConfig alloc] init];
    config.abTestDetailsEnabled = YES;
    
    Swrve *swrve = [SwrveTestHelper initializeSwrveWithCampaignsFile:@"abTestDetails" andConfig:config];
    
    // Assert it has the loaded AB Test Details
    NSArray* abTestDetails = [swrve.resourceManager abTestDetails];
    XCTAssertEqual(2, [abTestDetails count]);
    
    SwrveABTestDetails* details1 = [abTestDetails objectAtIndex:0];
    XCTAssertEqualObjects(@"12", details1.id);
    XCTAssertEqualObjects(@"AB test Name 1", details1.name);
    XCTAssertEqual(1, details1.caseIndex);
    
    SwrveABTestDetails* details2 = [abTestDetails objectAtIndex:1];
    XCTAssertEqualObjects(@"13", details2.id);
    XCTAssertEqualObjects(@"AB test Name 2", details2.name);
    XCTAssertEqual(4, details2.caseIndex);
}

@end
