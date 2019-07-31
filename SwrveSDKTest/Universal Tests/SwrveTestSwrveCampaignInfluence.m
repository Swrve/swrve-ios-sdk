#import <XCTest/XCTest.h>
#import "SwrveCampaignInfluence.h"

@interface SwrveTestSwrveCampaignInfluence : XCTestCase

@end

@implementation SwrveTestSwrveCampaignInfluence

- (void)testInfluenceDataClearedWithPushId {
    NSDictionary *influenceData = @{@"12": @"493243", @"13": @"8373434", @"14": @"9858555"};
    [[NSUserDefaults standardUserDefaults] setValue:influenceData forKey:SwrveInfluenceDataKey];
    [SwrveCampaignInfluence removeInfluenceDataForId:@"12" fromAppGroupId:nil];

    NSDictionary *clearedInfluenceData = [[NSUserDefaults standardUserDefaults] objectForKey:SwrveInfluenceDataKey];
    XCTAssertNotNil([clearedInfluenceData objectForKey:@"13"]);
    XCTAssertNotNil([clearedInfluenceData objectForKey:@"14"]);
    XCTAssertNil([clearedInfluenceData objectForKey:@"12"]);
}

- (void)testInfluenceDataClearedWithPushIdNoData {
    NSDictionary *influenceData = nil;
    [[NSUserDefaults standardUserDefaults] setValue:influenceData forKey:SwrveInfluenceDataKey];
    [SwrveCampaignInfluence removeInfluenceDataForId:@"12" fromAppGroupId:nil];
    XCTAssertNil([[NSUserDefaults standardUserDefaults] objectForKey:SwrveInfluenceDataKey]);
}

@end
