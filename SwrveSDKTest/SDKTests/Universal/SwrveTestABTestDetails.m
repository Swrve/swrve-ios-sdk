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
    
    for (SwrveABTestDetails *details in abTestDetails) {
        if ([details.name isEqualToString:@"AB test Name 1"]) {
            XCTAssertEqualObjects(@"12", details.id);
            XCTAssertEqual(1, details.caseIndex);
        } else if ([details.name isEqualToString:@"AB test Name 2"]) {
            XCTAssertEqualObjects(@"13", details.id);
            XCTAssertEqual(4, details.caseIndex);
        } else {
            XCTFail(@"Unexpected Name");
        }
    }
}

@end
