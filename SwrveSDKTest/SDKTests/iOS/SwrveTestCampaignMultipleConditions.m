#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "Swrve.h"
#import "SwrveTestHelper.h"
#import "SwrveConversation.h"
#import "SwrvePermissions.h"
#import "SwrveMessageController.h"

@interface Swrve(privateAccess)
@property(atomic) SwrveMessageController *messaging;
@end

@interface SwrveMessageController ()

- (id)initWithSwrve:(Swrve*)sdk;
- (void)writeToCampaignCache:(NSData*)campaignData;
- (void)updateCampaigns:(NSDictionary *)campaignDic withLoadingPreviousCampaignState:(BOOL) isLoadingPreviousCampaignState;
- (NSDate *)getNow;
- (SwrveConversation*)conversationForEvent:(NSString *) eventName withPayload:(NSDictionary *)payload;

@property (nonatomic, retain) NSDate *initialisedTime;
@end


@interface SwrveTestCampaignMultipleConditions : XCTestCase

@end

@implementation SwrveTestCampaignMultipleConditions

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
    
    id classMock = OCMClassMock([SwrvePermissions class]);
    OCMStub(ClassMethod([classMock pushAuthorizationWithSDK:OCMOCK_ANY])).andReturn(@"unittest");
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

- (id)swrveMock {
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
    
    // mock date that lies within the start and end time of the campaign in the test json file campaignsMultipleTriggerConditions
    // we do this to pass: checkGlobalRules
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsMultipleTriggerConditions" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockData options:0 error:nil];
    
    // reset the initialised date in SwrveMessageController
    // we do this to pass throttle limits in: checkCampaignRulesForEvent
    [swrveMock messaging].initialisedTime = [mockInitDate dateByAddingTimeInterval:-280];
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO];
    
    return swrveMock;
}

- (void)testConversationMultiTriggerCondition {
    id swrveMock = [self swrveMock];
    NSDictionary *payload = @{
                                @"key1" : @"value1",
                                @"key2" : @"value2"
                                };

    SwrveConversation *conv = [[swrveMock messaging] conversationForEvent:@"Swrve.multivalue" withPayload:payload];
    XCTAssertNotNil(conv, @"conversation was nil");
    
    [swrveMock stopMocking];
}

- (void)testConversationMultiTriggerConditionCaseInsensitive {
    id swrveMock = [self swrveMock];
    NSDictionary *payload = @{
                              @"key1" : @"valUE1",
                              @"key2" : @"VALue2"
                              };

    SwrveConversation* conv = [[swrveMock messaging] conversationForEvent:@"Swrve.multivalue" withPayload:payload];
    XCTAssertNotNil(conv, @"conversation was nil");

    [swrveMock stopMocking];
}

- (void)testConversationTriggerWithHalfConditions {
    id swrveMock = [self swrveMock];
    NSDictionary *payload = @{
                              @"key1" : @"value1"
                              };
    
    SwrveConversation* conv = [[swrveMock messaging] conversationForEvent:@"Swrve.multivalue" withPayload:payload];
    XCTAssertNil(conv, @"conversation displayed, it should be nil");
    
    [swrveMock stopMocking];
}

- (void)testConversationTriggerWithNoConditions {
    id swrveMock = [self swrveMock];
    SwrveConversation* conv = [[swrveMock messaging] conversationForEvent:@"Swrve.multivalue" withPayload:nil];
    XCTAssertNil(conv, @"conversation displayed, it should be nil");
    [swrveMock stopMocking];
}

- (void)testConversationNoConditionTriggerWithPayload {
    id swrveMock = [self swrveMock];
    NSDictionary *payload = @{
                              @"key1" : @"value1",
                              @"key2" : @"value2"
                              };

    SwrveConversation* conv = [[swrveMock messaging] conversationForEvent:@"Swrve.noconditions" withPayload:payload];
    XCTAssertNotNil(conv, @"conversation was nil, it should still pass through with a payload");
    [swrveMock stopMocking];
}

- (void)testConversationSingleConditionTriggerWithPayload {
    id swrveMock = [self swrveMock];
    NSDictionary *payload = @{
                              @"key1" : @"value1"
                              };
    
    SwrveConversation* conv = [[swrveMock messaging] conversationForEvent:@"Swrve.noOP" withPayload:payload];
    XCTAssertNotNil(conv, @"conversation was nil, it should still pass through with a payload");
    [swrveMock stopMocking];
}

- (void)testConversationSingleConditionTriggerWithNonString {
    id swrveMock = [self swrveMock];
    NSDictionary *payload = @{
                              @"key1" : [NSNumber numberWithInt:20]
                              };

    SwrveConversation* conv = [[swrveMock messaging] conversationForEvent:@"Swrve.noOP" withPayload:payload];
    XCTAssertNil(conv, @"conversation displayed, it should be nil (and not crash on the check)");
    [swrveMock stopMocking];
}

- (void)testConversationSingleConditionTriggerWithNilValuePayload {
    id swrveMock = [self swrveMock];
    NSDictionary *payload = @{
                              @"key1" : [NSNull null]
                              };
     SwrveConversation* conv = [[swrveMock messaging] conversationForEvent:@"Swrve.noOP" withPayload:payload];
     XCTAssertNil(conv, @"conversation displayed, it should be nil");
    [swrveMock stopMocking];
}

- (void)testConversationSingleConditionTriggerWithNullKeyPayload {
    id swrveMock = [self swrveMock];
    NSDictionary *payload = @{
                              [NSNull null] : @"value1"
                              };
    SwrveConversation* conv = [[swrveMock messaging] conversationForEvent:@"Swrve.noOP" withPayload:payload];
    XCTAssertNil(conv, @"conversation displayed, it should be nil");
    [swrveMock stopMocking];
}

- (void)testConversationSingleConditionTriggerWithoutPayload {
    id swrveMock = [self swrveMock];
    SwrveConversation* conv = [[swrveMock messaging] conversationForEvent:@"Swrve.noOP" withPayload:nil];
    XCTAssertNil(conv, @"conversation loaded without correct event payload");
    [swrveMock stopMocking];
}

@end
