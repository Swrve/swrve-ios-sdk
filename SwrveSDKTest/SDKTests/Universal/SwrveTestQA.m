#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SwrveCommon.h"
#import "SwrveQA.h"
#import "SwrveLocalStorage.h"
#import "SwrveUtils.h"
#import "SwrveQAEventsQueueManager.h"

@interface SwrveTestQA : XCTestCase {
    id classSwrveUtilsMock;
    NSNumber *expectedMockedTime;
}
@end

@interface SwrveQAEventsQueueManager (private_acess)

@property(nonatomic) SwrveQAEventsQueueManager *queueManager;
@property(atomic) NSMutableArray  *queue;
@end

@interface SwrveQA (private_acess)
@property(nonatomic) SwrveQAEventsQueueManager *queueManager;
@end

@implementation SwrveTestQA

- (void)setUp {
    [super setUp];
    expectedMockedTime = @1592239308915;
    // Mock getTimeEpoch at SwrveUtils.
    classSwrveUtilsMock = OCMClassMock([SwrveUtils class]);
    OCMStub([classSwrveUtilsMock getTimeEpoch])._andReturn(expectedMockedTime);
}

- (void)tearDown {
    [SwrveLocalStorage saveQaUser:nil];
    [SwrveLocalStorage saveSwrveUserId:nil];
    [classSwrveUtilsMock stopMocking];
    [super tearDown];
}

- (void)testSwrveQADisabledByDefault {
    SwrveQA *qa = [SwrveQA sharedInstance];
    XCTAssertTrue(qa.isQALogging == false);
}

- (void)testSwrveQADisabledAfterEmptyUpdate {
    [SwrveQA updateQAUser:@{} andSessionToken:@"whatEver"];
    SwrveQA *qa = [SwrveQA sharedInstance];
    XCTAssertTrue(qa.isQALogging == false);
}

- (void)testInitSwrveQA {
    NSDictionary *jsonQa = @{
                             @"logging": @true,
                             @"logging_url": @"http://123.swrve.com",
                             @"campaigns": @{}
                             };
    [SwrveQA updateQAUser:jsonQa andSessionToken:@"whatEver"];
    SwrveQA *qa = [SwrveQA sharedInstance];
    XCTAssertTrue(qa.isQALogging);
}

- (void)testInitSwrveQAWithValidCachedQAUser {

    id mockSwrveCommon = OCMProtocolMock(@protocol(SwrveCommonDelegate));
    OCMStub([mockSwrveCommon userID]).andReturn(@"SomeID");
    [SwrveCommon addSharedInstance:mockSwrveCommon];

    // Force valid QA user available on cache.
    [SwrveLocalStorage saveQaUser:@{
        @"logging": @true,
        @"reset_device_state": @true,
    }];

    [SwrveQA updateQAUser:nil andSessionToken:@"whatEver"];

    SwrveQA *qa = [SwrveQA sharedInstance];
    XCTAssertTrue(qa.isQALogging);
    XCTAssertTrue(qa.resetDeviceState);
}

- (void)testInitSwrveQAWithNoCachedQAUser {

    id mockSwrveCommon = OCMProtocolMock(@protocol(SwrveCommonDelegate));
    OCMStub([mockSwrveCommon userID]).andReturn(@"SomeID");
    [SwrveCommon addSharedInstance:mockSwrveCommon];

    // No valid cache should resturn as Non QA user
    [SwrveLocalStorage saveQaUser:@{
        @"logging": @false,
        @"reset_device_state": @false,
    }];

    [SwrveQA updateQAUser:nil andSessionToken:@"whatEver"];
    SwrveQA *qa = [SwrveQA sharedInstance];
    XCTAssertFalse(qa.isQALogging);
    XCTAssertFalse(qa.resetDeviceState);
}


#pragma mark - SDK

- (void)testCampaignButtonClicked {
    [self enableQaLogging];
    SwrveQA *qa = [SwrveQA sharedInstance];
    id swrveQAEventsQueueMock = OCMPartialMock([[SwrveQAEventsQueueManager alloc] initWithSessionToken:@"whatEver"]);
    // Stub flushEvents so it would not try any request at all or clear our queue.
    OCMStub([swrveQAEventsQueueMock flushEvents]).andDo(nil);
    [qa setQueueManager:swrveQAEventsQueueMock];

    NSDictionary *logDetails = @{
            @"action_type":@"custom",
            @"action_value":@"https://url.com",
            @"button_name":@"button",
            @"campaign_id":@12,
            @"variant_id":@2
    };
    NSMutableDictionary *expecectedQALoggedEvent = [self createExpectedEventWithLogDetails:logDetails withLogType:@"campaign-button-clicked" withlogSource:@"sdk"];

    [SwrveQA campaignButtonClicked:@12 variantId:@2 buttonName:@"button" actionType:@"custom" actionValue:@"https://url.com"];

    OCMVerify([swrveQAEventsQueueMock queueEvent:expecectedQALoggedEvent]);
    // Check if the event is on queue.
    XCTAssertEqual([[swrveQAEventsQueueMock queue] count], 1);
    XCTAssertEqualObjects([[swrveQAEventsQueueMock queue] objectAtIndex:0], expecectedQALoggedEvent);
}

- (void)testMessageCampaignTrigger {
    [self enableQaLogging];
    SwrveQA *qa = [SwrveQA sharedInstance];
    id swrveQAEventsQueueMock = OCMPartialMock([[SwrveQAEventsQueueManager alloc] initWithSessionToken:@"whatEver"]);
    // Stub flushEvents so it would not try any request at all or clear our queue.
    OCMStub([swrveQAEventsQueueMock flushEvents]).andDo(nil);
    [qa setQueueManager:swrveQAEventsQueueMock];

    // Mock campaign that will be used as part of this test.
    NSString *expectedReason1 = @"Reason passed";
    NSString *expectedReason2 = @"Whatever expected passed";
    SwrveQACampaignInfo *expectedCampaign1 = [[SwrveQACampaignInfo alloc] initWithCampaignID:10 variantID:200 type:SWRVE_CAMPAIGN_IAM displayed:NO reason:expectedReason1];
    SwrveQACampaignInfo *expectedCampaign2 = [[SwrveQACampaignInfo alloc] initWithCampaignID:11 variantID:102 type:SWRVE_CAMPAIGN_IAM displayed:YES reason:expectedReason2];
    NSMutableArray<SwrveQACampaignInfo *> *campaignInfoExpected = [@[expectedCampaign1, expectedCampaign2 ] mutableCopy];

    NSDictionary *payloadExpected = @{@"hello": @"test"};
    NSString *eventNameExpected = @"event";

    // Mock expected Log details for the event that will be generated
    NSDictionary *expectedLogDetails = @{
        @"campaigns":@[@{
                          @"displayed": [NSNumber numberWithBool:expectedCampaign1.displayed],
                          @"id": [NSNumber numberWithInteger:expectedCampaign1.campaignID],
                          @"reason": expectedReason1,
                          @"type": swrveCampaignTypeToString(expectedCampaign1.type),
                          @"variant_id": [NSNumber numberWithInteger:expectedCampaign1.variantID]},
                      @{
                          @"displayed": [NSNumber numberWithBool:expectedCampaign2.displayed],
                          @"id": [NSNumber numberWithInteger:expectedCampaign2.campaignID],
                          @"reason": expectedReason2,
                          @"type": swrveCampaignTypeToString(expectedCampaign2.type),
                          @"variant_id": [NSNumber numberWithInteger:expectedCampaign2.variantID],
                      }],
        @"displayed":@YES,
        @"event_name":eventNameExpected,
        @"event_payload": payloadExpected,
        @"reason":@""
    };
    // Test again with displayed:YES
    [SwrveQA messageCampaignTriggered:eventNameExpected eventPayload:payloadExpected displayed:YES campaignInfoDict:campaignInfoExpected];
    NSMutableDictionary *expecectedQAEvent = [self createExpectedEventWithLogDetails:expectedLogDetails withLogType:@"campaign-triggered" withlogSource:@"sdk"];
    // verify the expected event got queue and check its count.
    OCMVerify([swrveQAEventsQueueMock queueEvent:expecectedQAEvent]);
    XCTAssertEqual([[swrveQAEventsQueueMock queue] count], 1);
    XCTAssertEqualObjects([[swrveQAEventsQueueMock queue] objectAtIndex:0], expecectedQAEvent);
}

- (void)testConversationCampaignTrigger {
    [self enableQaLogging];

    id swrveQAEventsQueueMock = OCMPartialMock([[SwrveQAEventsQueueManager alloc] initWithSessionToken:@"whatEver"]);
    [[SwrveQA sharedInstance] setQueueManager:swrveQAEventsQueueMock];
    // Stub flushEvents so it would not try any request at all or clear our queue.
    OCMStub([swrveQAEventsQueueMock flushEvents]).andDo(nil);

    // Mock campaign that will be used as part of this test.
    NSString *expectedReason1 = @"Reason passed";
    NSString *expectedReason2 = @"Whatever expected passed";
    SwrveQACampaignInfo *expectedCampaign1 = [[SwrveQACampaignInfo alloc] initWithCampaignID:10 variantID:200 type:SWRVE_CAMPAIGN_CONVERSATION displayed:NO reason:expectedReason1];
    SwrveQACampaignInfo *expectedCampaign2 = [[SwrveQACampaignInfo alloc] initWithCampaignID:11 variantID:102 type:SWRVE_CAMPAIGN_CONVERSATION displayed:YES reason:expectedReason2];
    NSMutableArray<SwrveQACampaignInfo *> *campaignInfoExpected = [@[expectedCampaign1, expectedCampaign2 ] mutableCopy];

    NSDictionary *payloadExpected = @{@"hello": @"test"};
    NSString *eventNameExpected = @"event";

    // Mock expected Log details for the event that will be generated
    NSDictionary *expectedLogDetails = @{
        @"campaigns":@[@{
                          @"displayed": [NSNumber numberWithBool:expectedCampaign1.displayed],
                          @"id": [NSNumber numberWithInteger:expectedCampaign1.campaignID],
                          @"reason": expectedReason1,
                          @"type": swrveCampaignTypeToString(expectedCampaign1.type),
                          @"variant_id": [NSNumber numberWithInteger:expectedCampaign1.variantID]},
                      @{
                          @"displayed": [NSNumber numberWithBool:expectedCampaign2.displayed],
                          @"id": [NSNumber numberWithInteger:expectedCampaign2.campaignID],
                          @"reason": expectedReason2,
                          @"type": swrveCampaignTypeToString(expectedCampaign2.type),
                          @"variant_id": [NSNumber numberWithInteger:expectedCampaign2.variantID],
                      }],
        @"displayed":@YES,
        @"event_name":eventNameExpected,
        @"event_payload": payloadExpected,
        @"reason":@""
    };
    // Test again with displayed:YES
    [SwrveQA conversationCampaignTriggered:eventNameExpected eventPayload:payloadExpected displayed:YES campaignInfoDict:campaignInfoExpected];
    NSMutableDictionary *expecectedQAEvent = [self createExpectedEventWithLogDetails:expectedLogDetails withLogType:@"campaign-triggered" withlogSource:@"sdk"];
    // verify the expected event got queue and check its count.
    OCMVerify([swrveQAEventsQueueMock queueEvent:expecectedQAEvent]);
    XCTAssertEqual([[swrveQAEventsQueueMock queue] count], 1);
    XCTAssertEqualObjects([[swrveQAEventsQueueMock queue] objectAtIndex:0], expecectedQAEvent);
}

- (void)testConversationCampaignTriggeredNoDisplay {
    [self enableQaLogging];

    id swrveQAEventsQueueMock = OCMPartialMock([[SwrveQAEventsQueueManager alloc] initWithSessionToken:@"whatEver"]);
    [[SwrveQA sharedInstance] setQueueManager:swrveQAEventsQueueMock];
    // Stub flushEvents so it would not try any request at all or clear our queue.
    OCMStub([swrveQAEventsQueueMock flushEvents]).andDo(nil);

    NSDictionary *payloadExpected = @{@"hello": @"test"};
    NSString *eventNameExpected = @"event";
    NSDictionary *expectedLogDetails = @{
            @"campaigns":@[],
            @"displayed":@NO,
            @"event_name":eventNameExpected,
            @"event_payload": payloadExpected,
            @"reason":@"No Conversation triggered because In App Message displayed"
    };

    [SwrveQA conversationCampaignTriggeredNoDisplay:eventNameExpected eventPayload:payloadExpected];

    NSMutableDictionary *expecectedQAEvent = [self createExpectedEventWithLogDetails:expectedLogDetails withLogType:@"campaign-triggered" withlogSource:@"sdk"];
    // verify the expected event got queue and check its count.
    OCMVerify([swrveQAEventsQueueMock queueEvent:expecectedQAEvent]);
    XCTAssertEqual([[swrveQAEventsQueueMock queue] count], 1);
    XCTAssertEqualObjects([[swrveQAEventsQueueMock queue] objectAtIndex:0], expecectedQAEvent);
}

- (void)testAssetFailedToDownload {
    [self enableQaLogging];

    id swrveQAEventsQueueMock = OCMPartialMock([[SwrveQAEventsQueueManager alloc] initWithSessionToken:@"whatEver"]);
    [[SwrveQA sharedInstance] setQueueManager:swrveQAEventsQueueMock];
    // Stub flushEvents so it would not try any request at all or clear our queue.
    OCMStub([swrveQAEventsQueueMock flushEvents]).andDo(nil);


    NSDictionary *expectedLogDetails = @{@"asset_name": @"asset1",
            @"image_url":@"https://fake_url.com/asset1.jpg",
            @"reason":@"test reason"
    };

    [SwrveQA assetFailedToDownload:@"asset1" resolvedUrl:@"https://fake_url.com/asset1.jpg" reason:@"test reason"];

    NSMutableDictionary *expecectedQAEvent = [self createExpectedEventWithLogDetails:expectedLogDetails withLogType:@"asset-failed-to-download" withlogSource:@"sdk"];
    // verify the expected event got queue and check its count.
    OCMVerify([swrveQAEventsQueueMock queueEvent:expecectedQAEvent]);
    XCTAssertEqual([[swrveQAEventsQueueMock queue] count], 1);
    XCTAssertEqualObjects([[swrveQAEventsQueueMock queue] objectAtIndex:0], expecectedQAEvent);
}

- (void)testAssetFailedToDisplay {
    [self enableQaLogging];

    id swrveQAEventsQueueMock = OCMPartialMock([[SwrveQAEventsQueueManager alloc] initWithSessionToken:@"whatEver"]);
    [[SwrveQA sharedInstance] setQueueManager:swrveQAEventsQueueMock];
    // Stub flushEvents so it would not try any request at all or clear our queue.
    OCMStub([swrveQAEventsQueueMock flushEvents]).andDo(nil);

    NSDictionary *expectedLogDetails = @{
        @"campaign_id": @123,
        @"variant_id": @1,
        @"has_fallback": @NO,
        @"unresolved_url": @"https://fake_url.com/${test_id}.jpg",
        @"reason":@"test reason",
        @"asset_name": @"asset1",
        @"image_url": @"https://fake_url.com/asset1.jpg"
    };
    
    SwrveQAImagePersonalizationInfo *testQAInfo = [[SwrveQAImagePersonalizationInfo alloc] initWithCampaign:123
                                                                                 variantID:1
                                                                               hasFallback:NO
                                                                             unresolvedUrl:@"https://fake_url.com/${test_id}.jpg"];
    testQAInfo.assetName = @"asset1";
    testQAInfo.resolvedUrl = @"https://fake_url.com/asset1.jpg";
    testQAInfo.reason = @"test reason";

    [SwrveQA assetFailedToDisplay:testQAInfo];

    NSMutableDictionary *expecectedQAEvent = [self createExpectedEventWithLogDetails:expectedLogDetails withLogType:@"asset-failed-to-display" withlogSource:@"sdk"];
    // verify the expected event got queue and check its count.
    OCMVerify([swrveQAEventsQueueMock queueEvent:expecectedQAEvent]);
    XCTAssertEqual([[swrveQAEventsQueueMock queue] count], 1);
    XCTAssertEqualObjects([[swrveQAEventsQueueMock queue] objectAtIndex:0], expecectedQAEvent);
}

- (void)testEmbeddedPersonalizationFailed {
    [self enableQaLogging];

    id swrveQAEventsQueueMock = OCMPartialMock([[SwrveQAEventsQueueManager alloc] initWithSessionToken:@"whatEver"]);
    [[SwrveQA sharedInstance] setQueueManager:swrveQAEventsQueueMock];
    // Stub flushEvents so it would not try any request at all or clear our queue.
    OCMStub([swrveQAEventsQueueMock flushEvents]).andDo(nil);

    NSDictionary *expectedLogDetails = @{
        @"campaign_id": @123,
        @"variant_id": @1,
        @"unresolved_data": @"${test_id}",
        @"reason":@"test reason"
    };

    [SwrveQA embeddedPersonalizationFailed:@123 variantId:@1 unresolvedData:@"${test_id}" reason:@"test reason"];

    NSMutableDictionary *expecectedQAEvent = [self createExpectedEventWithLogDetails:expectedLogDetails withLogType:@"embedded-personalization-failed" withlogSource:@"sdk"];
    // verify the expected event got queue and check its count.
    OCMVerify([swrveQAEventsQueueMock queueEvent:expecectedQAEvent]);
    XCTAssertEqual([[swrveQAEventsQueueMock queue] count], 1);
    XCTAssertEqualObjects([[swrveQAEventsQueueMock queue] objectAtIndex:0], expecectedQAEvent);
}

- (void)testCampaignTrigger {
    [self enableQaLogging];

    id swrveQAEventsQueueMock = OCMPartialMock([[SwrveQAEventsQueueManager alloc] initWithSessionToken:@"whatEver"]);
    [[SwrveQA sharedInstance] setQueueManager:swrveQAEventsQueueMock];
    // Stub flushEvents so it would not try any request at all or clear our queue.
    OCMStub([swrveQAEventsQueueMock flushEvents]).andDo(nil);

    // Mock campaign that will be used as part of this test.
    NSString *expectedReason1 = @"Reason passed";
    NSString *expectedReason2 = @"Whatever expected passed";
    NSString *expectedNotDisplayReason = @"Whatever expected passed";

    SwrveQACampaignInfo *expectedCampaign1 = [[SwrveQACampaignInfo alloc] initWithCampaignID:10 variantID:200 type:SWRVE_CAMPAIGN_CONVERSATION displayed:NO reason:expectedReason1];
    SwrveQACampaignInfo *expectedCampaign2 = [[SwrveQACampaignInfo alloc] initWithCampaignID:11 variantID:102 type:SWRVE_CAMPAIGN_CONVERSATION displayed:NO reason:expectedReason2];
    NSMutableArray<SwrveQACampaignInfo *> *campaignInfoExpected = [@[expectedCampaign1, expectedCampaign2 ] mutableCopy];

    NSDictionary *payloadExpected = @{@"hello": @"test"};
    NSString *eventNameExpected = @"event";

    // Mock expected Log details for the event that will be generated
    NSDictionary *expectedLogDetails = @{
        @"campaigns":@[@{
                          @"displayed": [NSNumber numberWithBool:expectedCampaign1.displayed],
                          @"id": [NSNumber numberWithInteger:expectedCampaign1.campaignID],
                          @"reason": expectedReason1,
                          @"type": swrveCampaignTypeToString(expectedCampaign1.type),
                          @"variant_id": [NSNumber numberWithInteger:expectedCampaign1.variantID]},
                      @{
                          @"displayed": [NSNumber numberWithBool:expectedCampaign2.displayed],
                          @"id": [NSNumber numberWithInteger:expectedCampaign2.campaignID],
                          @"reason": expectedReason2,
                          @"type": swrveCampaignTypeToString(expectedCampaign2.type),
                          @"variant_id": [NSNumber numberWithInteger:expectedCampaign2.variantID],
                      }],
        @"displayed":@NO,
        @"event_name":eventNameExpected,
        @"event_payload": payloadExpected,
        @"reason":expectedNotDisplayReason
    };
    // Test with displayed:NO
    [SwrveQA campaignTriggered:eventNameExpected eventPayload:payloadExpected displayed:NO reason:expectedNotDisplayReason campaignInfo:campaignInfoExpected];
    NSMutableDictionary *expecectedQAEvent = [self createExpectedEventWithLogDetails:expectedLogDetails withLogType:@"campaign-triggered" withlogSource:@"sdk"];
    // verify the expected event got queue and check its count.
    OCMVerify([swrveQAEventsQueueMock queueEvent:expecectedQAEvent]);
    XCTAssertEqual([[swrveQAEventsQueueMock queue] count], 1);
    XCTAssertEqualObjects([[swrveQAEventsQueueMock queue] objectAtIndex:0], expecectedQAEvent);
}

#pragma mark - helpers

- (void)enableQaLogging {
    NSDictionary *jsonQa = @{
                             @"logging": @true,
                             @"logging_url": @"http://123.swrve.com",
                             @"campaigns": @{}
                             };
    [SwrveQA updateQAUser:jsonQa andSessionToken:@"whatEver"];
}

// Helper method that return the a "NSMutableDictionary *" that would be the exepecte event logged
- (NSMutableDictionary *)createExpectedEventWithLogDetails:(NSDictionary *) logDetails withLogType:(NSString *) logType withlogSource:(NSString *) logSource {
    return [@{
        @"log_details":logDetails,
        @"log_source":logSource,
        @"log_type":logType,
        @"time":@1592239308915, // mocked with this value at "setUp" method
        @"type":@"qa_log_event"
    } mutableCopy];;
}

@end
