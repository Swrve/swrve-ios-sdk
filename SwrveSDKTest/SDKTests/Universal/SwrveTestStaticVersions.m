#import <XCTest/XCTest.h>
#import "SwrveMessageController+Private.h"
#import "SwrveCommon.h"

@interface SwrveTestStaticVersions : XCTestCase

@end

@implementation SwrveTestStaticVersions

- (void)testVersionStrings {
    XCTAssertEqual(CAMPAIGN_VERSION, 9);
    XCTAssertEqual(CAMPAIGN_RESPONSE_VERSION, 2);
    XCTAssertEqual(EMBEDDED_CAMPAIGN_VERSION, 2);
    XCTAssertEqual(IN_APP_CAMPAIGN_VERSION, 9);
    XCTAssertEqual(CONVERSATION_VERSION, 4);
    XCTAssertEqual(SWRVE_VERSION, 3);
}

@end
