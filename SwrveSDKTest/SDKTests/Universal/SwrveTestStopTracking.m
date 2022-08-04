#import <XCTest/XCTest.h>
#import "SwrveProfileManager.h"
#import "SwrveSDK.h"
#import "SwrveTestHelper.h"
#import "SwrveRESTClient.h"
#import "SwrveSEConfig.h"

#if __has_include(<OCMock/OCMock.h>)
#import <OCMock/OCMock.h>
#import <SwrveSEConfig.h>

#endif

@interface Swrve (Internal)
- (BOOL)sdkReady;
- (void)appDidBecomeActive:(NSNotification *)notification;
- (void)initSwrveRestClient:(NSTimeInterval)timeOut urlSssionDelegate:(id <NSURLSessionDelegate>)urlSssionDelegate;
@property(atomic) NSTimer *campaignsAndResourcesTimer;
@property(atomic) SwrveProfileManager *profileManager;
@property (atomic) SwrveRESTClient *restClient;

@end

@interface SwrveSDK (InternalAccess)
+ (void)addSharedInstance:(Swrve *)instance;
@end

@interface SwrveTestStopTracking : XCTestCase

@end

@implementation SwrveTestStopTracking

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

- (void)testStopTracking {
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"whatever.group"];
    [userDefaults setBool:NO forKey:@"swrve.is_tracking_state_stopped"];

    Swrve *swrveMock = [SwrveTestHelper swrveMockWithMockedRestClient];
    [SwrveSDK addSharedInstance:swrveMock];
    [SwrveCommon addSharedInstance:swrveMock];

    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.appGroupIdentifier = @"whatever.group";
    swrveMock = [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey" config:config];
    [swrveMock idfa:@"12345"];
    [swrveMock appDidBecomeActive:nil];
    XCTAssertTrue(swrveMock.profileManager.trackingState == STARTED);
    XCTAssertTrue([SwrveSDK started]);
    XCTAssertNotNil([swrveMock campaignsAndResourcesTimer], "Timer will be not be nil after session is started.");
    XCTAssertTrue([[swrveMock campaignsAndResourcesTimer] isValid]);

    //check device update stopped property queued
    XCTestExpectation *deviceUpdateStopped = [self expectationWithDescription:@"Device update with Stopped state"];
    [self listenToDeviceUpdateEvents:swrveMock withBlock:^(NSDictionary *attributes) {
        if ([[attributes objectForKey:@"swrve.tracking_state"] isEqualToString:@"STOPPED"]) {
            [deviceUpdateStopped fulfill];
        }
    }];
    XCTAssertFalse([SwrveSEConfig isTrackingStateStopped:config.appGroupIdentifier]);

    [SwrveSDK stopTracking];
    XCTAssertTrue([SwrveSEConfig isTrackingStateStopped:config.appGroupIdentifier]);

    XCTAssertTrue(swrveMock.profileManager.trackingState == STOPPED);
    XCTAssertFalse([SwrveSDK started]);
    XCTAssertFalse([[swrveMock campaignsAndResourcesTimer] isValid]);
        
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];
}

- (void)testStartStopStartAgainDeviceUpdate {
    // mock all rest calls with success
    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
    id mockRestClient = OCMPartialMock(restClient);
    id mockResponse = OCMClassMock([NSHTTPURLResponse class]);
    OCMStub([mockResponse statusCode]).andReturn(200);
    
    Swrve *swrveMock = (Swrve *) OCMPartialMock([Swrve alloc]);
    OCMStub([swrveMock initSwrveRestClient:60 urlSssionDelegate:nil]).andDo(^(NSInvocation *invocation) {
        swrveMock.restClient = mockRestClient;
    });
    
    NSData *mockData = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
    
    __block  bool started = false;
    __block  bool stopped = false;
    __block  bool startedagain = false;
    
    __block NSData *capturedJson;
     id jsonData = [OCMArg checkWithBlock:^BOOL(NSData *jsonValue)  {
         capturedJson = jsonValue;
         NSDictionary *json = [NSJSONSerialization JSONObjectWithData:capturedJson options:0 error:nil];
         NSArray *data = [json objectForKey:@"data"];
         for (NSDictionary *dic in data) {
             if ([[dic objectForKey:@"type"] isEqualToString:@"device_update"]) {
                 NSDictionary *attributes = [dic objectForKey:@"attributes"];
                 if ([[attributes objectForKey:@"swrve.tracking_state"] isEqualToString:@"STARTED"]) {
                     started = true;
                 }
                 
                 if ([[attributes objectForKey:@"swrve.tracking_state"] isEqualToString:@"STOPPED"]) {
                     stopped = true;
                 }
                 
                 if ([[attributes objectForKey:@"swrve.tracking_state"] isEqualToString:@"STARTED"] && stopped) {
                     startedagain = true;
                 }
             }
         }
                  
         return true;
     }];
     
    OCMStub([mockRestClient sendHttpPOSTRequest:OCMOCK_ANY
                                       jsonData:jsonData
                              completionHandler:([OCMArg invokeBlockWithArgs:mockResponse, mockData, [NSNull null], nil])]);

    Swrve *swrve = (Swrve *) swrveMock;
    [SwrveSDK addSharedInstance:swrveMock];
    SwrveConfig *config = [SwrveConfig new];
    config.autoDownloadCampaignsAndResources = false;
    (void)[swrve initWithAppID:123 apiKey:@"SomeAPIKey" config:config];

    [swrve appDidBecomeActive:nil];

    [swrve stopTracking];

    [swrve start];

    XCTestExpectation *expectation = [self expectationWithDescription:@"event 0 sent with user id 1234"];
    [SwrveTestHelper waitForBlock:0.5 conditionBlock:^BOOL(){
        return (started && stopped && startedagain);
    } expectation:expectation];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}


- (void)testStopTrackingAppDidBecomeActive {
    Swrve *swrveMock = [SwrveTestHelper swrveMockWithMockedRestClient];
    [SwrveSDK addSharedInstance:swrveMock];
    [SwrveCommon addSharedInstance:swrveMock];

    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.autoDownloadCampaignsAndResources = NO;
    swrveMock = [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey" config:config];
    [swrveMock appDidBecomeActive:nil];
    
    XCTAssertTrue(swrveMock.profileManager.trackingState == STARTED);
    XCTAssertTrue([SwrveSDK started]);

    [SwrveSDK stopTracking];
   
    XCTAssertTrue(swrveMock.profileManager.trackingState == STOPPED);
    XCTAssertFalse([SwrveSDK started]);
    
    //Simulate coming back from the background in a stopped state.
    [swrveMock appDidBecomeActive:nil];

    XCTAssertTrue(swrveMock.profileManager.trackingState == STOPPED);
    XCTAssertFalse([SwrveSDK started]);
}

- (void)listenToDeviceUpdateEvents:(id)mock withBlock:(void (^)(NSDictionary *))attributesBlock {
    void (^eventObserver)(NSInvocation *) = ^(NSInvocation *invoke) {
        __unsafe_unretained NSString *eventType = nil;
        [invoke getArgument:&eventType atIndex:2];
        __unsafe_unretained NSMutableDictionary *eventData = nil;
        [invoke getArgument:&eventData atIndex:3];

        NSDictionary *attributes = [eventData objectForKey:@"attributes"];
        if (attributes != nil) {
            attributesBlock(attributes);
        }
    };
    OCMStub([mock queueEvent:@"device_update" data:OCMOCK_ANY triggerCallback:NO]).andDo(eventObserver).andForwardToRealObject();
}

- (void)testAPISWhileStopped {
    Swrve *swrveMock = [SwrveTestHelper swrveMockWithMockedRestClient];
    [SwrveSDK addSharedInstance:swrveMock];

    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.autoDownloadCampaignsAndResources = NO;
    swrveMock = [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey" config:config];
    [swrveMock appDidBecomeActive:nil];
    
    [swrveMock stopTracking];
        
    id logger = OCMClassMock([SwrveLogger class]);
    __block int loggerCount = 0;
    OCMStub([logger warning:[OCMArg isEqual:@"Warning: SwrveSDK is stopped and needs to be started before calling this api."]]).andDo(^(NSInvocation *invocation) {
        ++loggerCount;
    });
        
    XCTAssertEqual([swrveMock purchaseItem:@"" currency:@"" cost:0 quantity:0],SWRVE_FAILURE);
    XCTAssertEqual([swrveMock iap:[SKPaymentTransaction new] product:[SKProduct new]],SWRVE_FAILURE);
    XCTAssertEqual([swrveMock iap:[SKPaymentTransaction new] product:[SKProduct new] rewards:[SwrveIAPRewards new]],SWRVE_FAILURE);
    XCTAssertEqual([swrveMock unvalidatedIap:[SwrveIAPRewards new] localCost:0 localCurrency:@"" productId:@"" productIdQuantity:0],SWRVE_FAILURE);
    XCTAssertEqual([swrveMock event:@"Test Event"],SWRVE_FAILURE);
    XCTAssertEqual([swrveMock event:@"Test Event" payload:@{}],SWRVE_FAILURE);
    XCTAssertEqual([swrveMock currencyGiven:@"" givenAmount:0],SWRVE_FAILURE);
    XCTAssertEqual([swrveMock userUpdate:@{}],SWRVE_FAILURE);
    XCTAssertEqual([swrveMock userUpdate:@"" withDate:[NSDate new]],SWRVE_FAILURE);
    [swrveMock refreshCampaignsAndResources];
    XCTAssertNotNil([swrveMock resourceManager]);
    [swrveMock userResources:^(NSDictionary *resources, NSString *resourcesAsJSON) {
    }];
    [swrveMock userResourcesDiffWithListener:^(NSDictionary *oldResourcesValues, NSDictionary *newResourcesValues, NSString *resourcesAsJSON, BOOL fromServer, NSError *error) {
    }];
    [swrveMock realTimeUserProperties:^(NSDictionary *properties) {
    }];
    [swrveMock sendQueuedEvents];
    [swrveMock handleDeeplink:nil];
    [swrveMock handleDeferredDeeplink:nil];
    [swrveMock installAction:nil];
    
    XCTAssertEqualObjects([swrveMock externalUserId],@"");
    [swrveMock setCustomPayloadForConversationInput:[NSMutableDictionary new]];
    [swrveMock embeddedMessageWasShownToUser:[SwrveEmbeddedMessage new]];
    [swrveMock embeddedButtonWasPressed:[SwrveEmbeddedMessage new] buttonName:@""];
    [swrveMock personalizeEmbeddedMessageData:[SwrveEmbeddedMessage new] withPersonalization:@{}];
    [swrveMock personalizeText:@"" withPersonalization:@{}];
    XCTAssertEqualObjects([swrveMock messageCenterCampaigns],@[]);
    [swrveMock messageCenterCampaignsWithPersonalization:@{}];

    [swrveMock showMessageCenterCampaign:[SwrveCampaign new]];
    [swrveMock showMessageCenterCampaign:[SwrveCampaign new] withPersonalization:@{}];
    [swrveMock removeMessageCenterCampaign:[SwrveCampaign new]];
    [swrveMock markMessageCenterCampaignAsSeen:[SwrveCampaign new]];
    
    int expectedNumberOfCalls;
    
#if TARGET_OS_IOS
    expectedNumberOfCalls = 33;
    [swrveMock setDeviceToken:nil];
    [swrveMock messageCenterCampaignsThatSupportOrientation:0];
    [swrveMock messageCenterCampaignsThatSupportOrientation:0 withPersonalization:@{}];
#else
    expectedNumberOfCalls = 30;
#endif
    XCTAssertEqual(loggerCount, expectedNumberOfCalls);
}

@end
