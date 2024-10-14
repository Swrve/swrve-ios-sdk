#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "Swrve.h"
#import "SwrveTestHelper.h"
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
- (SwrveBaseMessage *)baseMessageForEvent:(NSString *)eventName withPayload:(NSDictionary *)payload;

@property (nonatomic, retain) NSDate *initialisedTime;
@end


@interface SwrveTestCampaignMultipleConditions : XCTestCase

@end

@implementation SwrveTestCampaignMultipleConditions

+ (NSArray *)testJSONAssets {
    static NSArray *assets = nil;
    if (!assets) {
        assets = @[
                @"8f984a803374d7c03c97dd122bce3ccf565bbdb5",
                @"8721fd4e657980a5e12d498e73aed6e6a565dfca",
                @"97c5df26c8e8fcff8dbda7e662d4272a6a94af7e",
        ];
    }
    return assets;
}

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
    [SwrveTestHelper createDummyAssets:[SwrveTestCampaignMultipleConditions testJSONAssets]];
    
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

- (void)testMessageTriggerWithHalfConditions {
    id swrveMock = [self swrveMock];
    NSDictionary *payload = @{
                              @"key1" : @"value1"
                              };
    
    SwrveBaseMessage *message = [[swrveMock messaging] baseMessageForEvent:@"Swrve.multivalue" withPayload:payload];
    XCTAssertNil(message, @"message displayed, it should be nil");
    
    [swrveMock stopMocking];
}

- (void)testMessageTriggerWithNoConditions {
    id swrveMock = [self swrveMock];
    SwrveBaseMessage *message = [[swrveMock messaging] baseMessageForEvent:@"Swrve.multivalue" withPayload:nil];
    XCTAssertNil(message, @"message displayed, it should be nil");
    [swrveMock stopMocking];
}

- (void)testMessageNoConditionTriggerWithPayload {
    id swrveMock = [self swrveMock];
    NSDictionary *payload = @{
                              @"key1" : @"value1",
                              @"key2" : @"value2"
                              };

    SwrveBaseMessage *message = [[swrveMock messaging] baseMessageForEvent:@"Swrve.noconditions" withPayload:payload];
    XCTAssertNotNil(message, @"message was nil, it should still pass through with a payload");
    [swrveMock stopMocking];
}

- (void)testMessageSingleConditionTriggerWithPayload {
    id swrveMock = [self swrveMock];
    NSDictionary *payload = @{
                              @"key1" : @"value1"
                              };
    
    SwrveBaseMessage *message = [[swrveMock messaging] baseMessageForEvent:@"Swrve.noOP" withPayload:payload];
    XCTAssertNotNil(message, @"message was nil, it should still pass through with a payload");
    [swrveMock stopMocking];
}

- (void)testMessageSingleConditionTriggerWithNonString {
    id swrveMock = [self swrveMock];
    NSDictionary *payload = @{
                              @"key1" : [NSNumber numberWithInt:20]
                              };

    SwrveBaseMessage *message = [[swrveMock messaging] baseMessageForEvent:@"Swrve.noOP" withPayload:payload];
    XCTAssertNil(message, @"message displayed, it should be nil (and not crash on the check)");
    [swrveMock stopMocking];
}



- (void)testMessageSingleConditionTriggerWithNilValuePayload {
    id swrveMock = [self swrveMock];
    NSDictionary *payload = @{
                              @"key1" : [NSNull null]
                              };
    SwrveBaseMessage *message = [[swrveMock messaging] baseMessageForEvent:@"Swrve.noOP" withPayload:payload];
    XCTAssertNil(message, @"message displayed, it should be nil");
    [swrveMock stopMocking];
}

- (void)testMessageSingleConditionTriggerWithNullKeyPayload {
    id swrveMock = [self swrveMock];
    NSDictionary *payload = @{
                              [NSNull null] : @"value1"
                              };
    SwrveBaseMessage *message = [[swrveMock messaging] baseMessageForEvent:@"Swrve.noOP" withPayload:payload];
    XCTAssertNil(message, @"message displayed, it should be nil");
    [swrveMock stopMocking];
}

- (void)testMessageSingleConditionTriggerWithoutPayload {
    id swrveMock = [self swrveMock];
    SwrveBaseMessage *message = [[swrveMock messaging] baseMessageForEvent:@"Swrve.noOP" withPayload:nil];
    XCTAssertNil(message, @"message loaded without correct event payload");
    [swrveMock stopMocking];
}

@end
