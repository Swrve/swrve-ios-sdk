#import <XCTest/XCTest.h>
#import "SwrveCampaignInfluence.h"
#import "SwrveNotificationConstants.h"

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

- (void)testSavePushInfluence {

    // Force an empty info into our storage.
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"app.groupid"];
    [userDefaults removeObjectForKey:SwrveInfluenceDataKey];
    NSDictionary *pushInfluencedCached = [userDefaults dictionaryForKey:SwrveInfluenceDataKey];
    XCTAssertNil(pushInfluencedCached);

    // Test again normal push
    NSDictionary *userInfo = @{
        SwrveNotificationIdentifierKey : @"1",
        SwrveInfluencedWindowMinsKey: @"5"
    };

    [SwrveCampaignInfluence saveInfluencedData:userInfo withId:@"1" withAppGroupID:@"app.groupid" atDate:[NSDate date]];
    pushInfluencedCached = [userDefaults dictionaryForKey:SwrveInfluenceDataKey];

    XCTAssertNotNil(pushInfluencedCached, @"Could not save influence event on cache");
    XCTAssertEqual([pushInfluencedCached count], 1);

    NSDictionary *influencedItem = pushInfluencedCached[@"1"];


    XCTAssertNotNil([influencedItem objectForKey:@"maxInfluencedMillis"]);
    XCTAssertFalse([[influencedItem objectForKey:@"silent"] boolValue]);
}

- (void)testSavePushInfluenceSilentPush {

    // Force an empty info into our storage.
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"app.groupid"];
    [userDefaults removeObjectForKey:SwrveInfluenceDataKey];
    NSDictionary *pushInfluencedCached = [userDefaults dictionaryForKey:SwrveInfluenceDataKey];
    XCTAssertNil(pushInfluencedCached);

    // Test again normal SilentPush
    NSDictionary *userInfo = @{
        SwrveNotificationSilentPushIdentifierKey : @"2",
        SwrveInfluencedWindowMinsKey: @"5"
    };

    [SwrveCampaignInfluence saveInfluencedData:userInfo withId:@"2" withAppGroupID:@"app.groupid" atDate:[NSDate date]];
    pushInfluencedCached = [userDefaults dictionaryForKey:SwrveInfluenceDataKey];

    XCTAssertNotNil(pushInfluencedCached, @"Could not save influence event on cache");
    XCTAssertEqual([pushInfluencedCached count], 1);

    NSDictionary *influencedItem = pushInfluencedCached[@"2"];
    XCTAssertNotNil([influencedItem objectForKey:@"maxInfluencedMillis"]);
    XCTAssertTrue([[influencedItem objectForKey:@"silent"] boolValue]);
}

- (void)testSavePushInfluenceMultipleCalls {

    // Force an empty info into our storage.
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"app.groupid"];
    [userDefaults removeObjectForKey:SwrveInfluenceDataKey];
    NSDictionary *pushInfluencedCached = [userDefaults dictionaryForKey:SwrveInfluenceDataKey];
    XCTAssertNil(pushInfluencedCached);

    // Test again normal SilentPush
    NSDictionary *userInfo1 = @{
        SwrveNotificationIdentifierKey : @"11",
        SwrveInfluencedWindowMinsKey: @"5"
    };

    // Test again normal SilentPush
    NSDictionary *userInfo2 = @{
        SwrveNotificationSilentPushIdentifierKey : @"22",
        SwrveInfluencedWindowMinsKey: @"5"
    };

    [SwrveCampaignInfluence saveInfluencedData:userInfo1 withId:@"11" withAppGroupID:@"app.groupid" atDate:[NSDate date]];
    [SwrveCampaignInfluence saveInfluencedData:userInfo2 withId:@"22" withAppGroupID:@"app.groupid" atDate:[NSDate date]];

    pushInfluencedCached = [userDefaults dictionaryForKey:SwrveInfluenceDataKey];
    XCTAssertNotNil(pushInfluencedCached);
    XCTAssertEqual([pushInfluencedCached count], 2);

    NSDictionary *influencedItem1 = pushInfluencedCached[@"11"];
    XCTAssertNotNil([influencedItem1 objectForKey:@"maxInfluencedMillis"]);
    XCTAssertFalse([[influencedItem1 objectForKey:@"silent"] boolValue]);

    NSDictionary *influencedItem2 = pushInfluencedCached[@"22"];
    XCTAssertNotNil([influencedItem2 objectForKey:@"maxInfluencedMillis"]);
    XCTAssertTrue([[influencedItem2 objectForKey:@"silent"] boolValue]);
}
@end
