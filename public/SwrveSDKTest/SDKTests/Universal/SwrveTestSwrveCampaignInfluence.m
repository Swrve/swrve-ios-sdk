#import <XCTest/XCTest.h>
#import "OCMock/OCMock.h"
#import "SwrveCommon.h"
#import "SwrveCampaignInfluence.h"
#import "SwrveNotificationConstants.h"

@interface SwrveTestSwrveCampaignInfluence : XCTestCase

@property (nonatomic) NSString *trackingData;

@end

@implementation SwrveTestSwrveCampaignInfluence

- (void)setUp {
    [super setUp];
    self.trackingData = @"5ea0fb1b8a24b8f9f76f675b7350200f314312fa";
}

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
        @"trackingData": self.trackingData,
        @"platform": @"iOS",
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

- (void)testProcessPushInfluence {
    id mockSwrveCommon = OCMProtocolMock(@protocol(SwrveCommonDelegate));
    [SwrveCommon addSharedInstance:mockSwrveCommon];
    
    OCMStub([mockSwrveCommon appGroupIdentifier]).andReturn(@"app.groupid");
    
    NSDictionary *userInfo = @{
        @"_td": self.trackingData,
        @"_smp": @"iOS",
        SwrveNotificationIdentifierKey : @"2",
        SwrveInfluencedWindowMinsKey: @"5"
    };

    [SwrveCampaignInfluence saveInfluencedData:userInfo withId:@"2" withAppGroupID:@"app.groupid" atDate:[NSDate date]];
     
    [SwrveCampaignInfluence processInfluenceDataWithDate:[NSDate new]];
                                  
    NSDictionary *expectedPayload = @{
        @"actionType": @"influenced",
            @"campaignType": @"push",
            @"id": @2,
            @"payload":   @{
                @"delta": @"4",
                @"platform": @"iOS",
                @"silent": [NSNumber numberWithBool:0],
                @"trackingData": self.trackingData
            }
    };
     
    OCMVerify([mockSwrveCommon queueEvent:@"generic_campaign_event" data:[expectedPayload mutableCopy] triggerCallback:false]);
}

@end
