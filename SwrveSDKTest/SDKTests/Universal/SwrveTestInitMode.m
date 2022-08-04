#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SwrveCommon.h"
#import "SwrveSDK.h"
#import "SwrveTestHelper.h"

@interface SwrveTestInitMode : XCTestCase {
    
}
@end

@interface SwrveSDK (InternalAccess)
+ (void)addSharedInstance:(Swrve*)instance;
+ (void)resetSwrveSharedInstance;
@end

@interface Swrve (InternalAccess)
- (BOOL)sdkReady;
- (BOOL)started;
- (UInt64)getTime;
- (void)sendQueuedEventsWithCallback:(void (^)(NSURLResponse *response, NSData *data, NSError *error))eventBufferCallback
                   eventFileCallback:(void (^)(NSURLResponse *response, NSData *data, NSError *error))eventFileCallback;
- (void)handleNotificationToCampaign:(NSString *)campaignId;
- (void)initSwrveDeeplinkManager;
- (void)beginSession;
- (NSDate *)getNow;
- (void)startCampaignsAndResourcesTimer;
@property(atomic) NSMutableArray *eventBuffer;
@property(atomic) SwrveDeeplinkManager *swrveDeeplinkManager;
@end

@implementation SwrveTestInitMode

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

- (void)testSdkReadyAutoStartTrue {
    id swrveMock = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO autoStart:true];
    BOOL sdkReady = [swrveMock sdkReady];
    XCTAssertTrue(sdkReady);
}
- (void)testSdkReadyAutoStartFalse {
    id swrveMock = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO autoStart:false];
    BOOL sdkReady = [swrveMock sdkReady];
    XCTAssertFalse(sdkReady);
}

- (void)testSdkReadyStopped {
    id swrveMock = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO autoStart:true];
    BOOL sdkReady = [swrveMock sdkReady];
    XCTAssertTrue(sdkReady);

    [SwrveLocalStorage saveTrackingState:STOPPED];

    swrveMock = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO autoStart:true];
    sdkReady = [swrveMock sdkReady];
    XCTAssertFalse(sdkReady);
}

- (id)initSwrveSDKWithMode:(SwrveInitMode)mode autoStart:(BOOL) autoStart{

    [SwrveSDK resetSwrveSharedInstance];

    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.initMode = mode;
    config.autoStartLastUser = autoStart;
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
    [SwrveSDK addSharedInstance:swrveMock];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey" config:config];
#pragma clang diagnostic pop

    return swrveMock;
}

- (void)testPurchaseItem {

    id swrveMockManaged = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    OCMExpect([swrveMockManaged sdkReady]).andForwardToRealObject();
    int successManaged = [SwrveSDK purchaseItem:@"item" currency:@"dollar" cost:100 quantity:5];
    XCTAssertEqual(SWRVE_FAILURE, successManaged);
    OCMVerifyAll(swrveMockManaged);

    id swrveMockAuto = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO autoStart:true];
    OCMExpect([swrveMockAuto sdkReady]).andForwardToRealObject();;
    int successAuto = [SwrveSDK purchaseItem:@"item" currency:@"dollar" cost:100 quantity:5];
    XCTAssertEqual(SWRVE_SUCCESS, successAuto);
    OCMVerifyAll(swrveMockAuto);
}

- (void)testIap1 {
    
    SKProduct *dummyProduct =  OCMClassMock([SKProduct class]);
    SKPaymentTransaction *dummyTransaction =  OCMClassMock([SKPaymentTransaction class]);
    OCMStub([dummyTransaction transactionState]).andReturn(SKPaymentTransactionStateDeferred); // SDK doens't handle SKPaymentTransactionStateDeferred

    id swrveMockManaged = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    OCMExpect([swrveMockManaged sdkReady]).andForwardToRealObject();
    int successManaged = [SwrveSDK iap:dummyTransaction product:dummyProduct];
    XCTAssertEqual(SWRVE_FAILURE, successManaged);
    OCMVerifyAll(swrveMockManaged);
    
    id swrveMockAuto = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO autoStart:true];
    OCMExpect([swrveMockAuto sdkReady]).andForwardToRealObject();;
    int successAuto = [SwrveSDK iap:dummyTransaction product:dummyProduct];
    XCTAssertEqual(SWRVE_SUCCESS, successAuto);
    OCMVerifyAll(swrveMockAuto);
}

- (void)testIap2 {
    
    SwrveIAPRewards *dummyRewards =  OCMClassMock([SwrveIAPRewards class]);
    SKProduct *dummyProduct =  OCMClassMock([SKProduct class]);
    SKPaymentTransaction *dummyTransaction =  OCMClassMock([SKPaymentTransaction class]);
    OCMStub([dummyTransaction transactionState]).andReturn(SKPaymentTransactionStateDeferred); // SDK doens't handle SKPaymentTransactionStateDeferred

    id swrveMockManaged = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    OCMExpect([swrveMockManaged sdkReady]).andForwardToRealObject();
    int successManaged = [SwrveSDK iap:dummyTransaction product:dummyProduct rewards:dummyRewards];
    XCTAssertEqual(SWRVE_FAILURE, successManaged);
    OCMVerifyAll(swrveMockManaged);
    
    id swrveMockAuto = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO autoStart:true];
    OCMExpect([swrveMockAuto sdkReady]).andForwardToRealObject();;
    int successAuto = [SwrveSDK iap:dummyTransaction product:dummyProduct rewards:dummyRewards];
    XCTAssertEqual(SWRVE_SUCCESS, successAuto);
    OCMVerifyAll(swrveMockAuto);
}

- (void)testUnvalidatedIap {
    
    SwrveIAPRewards *dummyRewards =  OCMClassMock([SwrveIAPRewards class]);

    id swrveMockManaged = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    OCMExpect([swrveMockManaged sdkReady]).andForwardToRealObject();
    int successManaged = [SwrveSDK unvalidatedIap:dummyRewards localCost:0.0 localCurrency:@"dollar" productId:@"productId" productIdQuantity:1];
    XCTAssertEqual(SWRVE_FAILURE, successManaged);
    OCMVerifyAll(swrveMockManaged);

    id swrveMockAuto = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO autoStart:true];
    OCMExpect([swrveMockAuto sdkReady]).andForwardToRealObject();;
    int successAuto = [SwrveSDK unvalidatedIap:dummyRewards localCost:0.0 localCurrency:@"dollar" productId:@"productId" productIdQuantity:1];
    XCTAssertEqual(SWRVE_SUCCESS, successAuto);
    OCMVerifyAll(swrveMockAuto);
}

- (void)testEvent {

    id swrveMockManaged = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    OCMExpect([swrveMockManaged sdkReady]).andForwardToRealObject();
    int successManaged = [SwrveSDK event:@"event1"];
    XCTAssertEqual(SWRVE_FAILURE, successManaged);
    OCMVerifyAll(swrveMockManaged);

    id swrveMockAuto = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO autoStart:true];
    OCMExpect([swrveMockAuto sdkReady]).andForwardToRealObject();;
    int successAuto = [SwrveSDK event:@"event1"];
    XCTAssertEqual(SWRVE_SUCCESS, successAuto);
    OCMVerifyAll(swrveMockAuto);
}

- (void)testEventWithPayload {

    id swrveMockManaged = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    OCMExpect([swrveMockManaged sdkReady]).andForwardToRealObject();
    int successManaged = [SwrveSDK event:@"event1" payload:[NSMutableDictionary new]];
    XCTAssertEqual(SWRVE_FAILURE, successManaged);
    OCMVerifyAll(swrveMockManaged);
    
    id swrveMockAuto = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO autoStart:true];
    OCMExpect([swrveMockAuto sdkReady]).andForwardToRealObject();;
    int successAuto = [SwrveSDK event:@"event1" payload:[NSMutableDictionary new]];
    XCTAssertEqual(SWRVE_SUCCESS, successAuto);
    OCMVerifyAll(swrveMockAuto);
}

- (void)testCurrencyGiven {

    id swrveMockManaged = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    OCMExpect([swrveMockManaged sdkReady]).andForwardToRealObject();
    int successManaged = [SwrveSDK currencyGiven:@"" givenAmount:1];
    XCTAssertEqual(SWRVE_FAILURE, successManaged);
    OCMVerifyAll(swrveMockManaged);
    
    id swrveMockAuto = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO autoStart:true];
    OCMExpect([swrveMockAuto sdkReady]).andForwardToRealObject();;
    int successAuto = [SwrveSDK currencyGiven:@"" givenAmount:1];
    XCTAssertEqual(SWRVE_SUCCESS, successAuto);
    OCMVerifyAll(swrveMockAuto);
}

- (void)testUserUpdate1 {

    id swrveMockManaged = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    OCMExpect([swrveMockManaged sdkReady]).andForwardToRealObject();
    int successManaged = [SwrveSDK userUpdate:[NSMutableDictionary new]];
    XCTAssertEqual(SWRVE_FAILURE, successManaged);
    OCMVerifyAll(swrveMockManaged);

    id swrveMockAuto = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO autoStart:true];
    OCMExpect([swrveMockAuto sdkReady]).andForwardToRealObject();;
    int successAuto = [SwrveSDK userUpdate:[NSMutableDictionary new]];
    XCTAssertEqual(SWRVE_SUCCESS, successAuto);
    OCMVerifyAll(swrveMockAuto);
}

- (void)testUserUpdateWithDate {

    id swrveMockManaged = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    OCMExpect([swrveMockManaged sdkReady]).andForwardToRealObject();
    int successManaged = [SwrveSDK userUpdate:@"prop" withDate:[NSDate new]];
    XCTAssertEqual(SWRVE_FAILURE, successManaged);
    OCMVerifyAll(swrveMockManaged);
    
    id swrveMockAuto = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO autoStart:true];
    OCMExpect([swrveMockAuto sdkReady]).andForwardToRealObject();;
    int successAuto = [SwrveSDK userUpdate:@"prop" withDate:[NSDate new]];
    XCTAssertEqual(SWRVE_SUCCESS, successAuto);
    OCMVerifyAll(swrveMockAuto);
}

- (void)testRefreshCampaignsAndResources {

    id swrveMockManaged = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    OCMExpect([swrveMockManaged sdkReady]).andForwardToRealObject();
    [SwrveSDK refreshCampaignsAndResources];
    OCMVerifyAll(swrveMockManaged);
    
    id swrveMockAuto = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO autoStart:true];
    OCMExpect([swrveMockAuto sdkReady]).andForwardToRealObject();;
    [SwrveSDK refreshCampaignsAndResources];
    OCMVerifyAll(swrveMockAuto);
}

- (void)testResourceManager {

    id swrveMockManaged = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    OCMExpect([swrveMockManaged sdkReady]).andForwardToRealObject();
    SwrveResourceManager *resourceManagerManaged = [SwrveSDK resourceManager];
    XCTAssertNotNil(resourceManagerManaged);
    OCMVerifyAll(swrveMockManaged);
    
    id swrveMockAuto = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO autoStart:true];
    OCMExpect([swrveMockAuto sdkReady]).andForwardToRealObject();
    SwrveResourceManager *resourceManagerAuto = [SwrveSDK resourceManager];
    XCTAssertNotNil(resourceManagerAuto);
    OCMVerifyAll(swrveMockAuto);
}

- (void)testUserResources {

    id swrveMockManaged = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    OCMExpect([swrveMockManaged sdkReady]).andForwardToRealObject();
    [SwrveSDK userResources:^(NSDictionary *resources, NSString *resourcesAsJSON) {}];
    OCMVerifyAll(swrveMockManaged);
    
    id swrveMockAuto = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO autoStart:true];
    OCMExpect([swrveMockAuto sdkReady]).andForwardToRealObject();
    [SwrveSDK userResources:^(NSDictionary *resources, NSString *resourcesAsJSON) {}];
    OCMVerifyAll(swrveMockAuto);
}

- (void)testUserResourcesDiffWithListener {

    id swrveMockManaged = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    OCMExpect([swrveMockManaged sdkReady]).andForwardToRealObject();
    [SwrveSDK userResourcesDiffWithListener:^(NSDictionary *oldResourcesValues,
            NSDictionary *newResourcesValues,
            NSString *resourcesAsJSON,
            BOOL fromServer,
            NSError *error) {
    }];
    OCMVerifyAll(swrveMockManaged);

    id swrveMockAuto = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO autoStart:true];
    OCMExpect([swrveMockAuto sdkReady]).andForwardToRealObject();
    [SwrveSDK userResourcesDiffWithListener:^(NSDictionary *oldResourcesValues,
            NSDictionary *newResourcesValues,
            NSString *resourcesAsJSON,
            BOOL fromServer,
            NSError *error) {
    }];
    OCMVerifyAll(swrveMockAuto);
}

- (void)testSendQueuedEvents {

    id swrveMockManaged = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    OCMExpect([swrveMockManaged sdkReady]).andForwardToRealObject();
    [SwrveSDK sendQueuedEvents];
    OCMVerifyAll(swrveMockManaged);
    
    id swrveMockAuto = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO autoStart:true];
    OCMExpect([swrveMockAuto sdkReady]).andForwardToRealObject();
    [SwrveSDK sendQueuedEvents];
    OCMVerifyAll(swrveMockAuto);
}

- (void)testSaveEventsToDisk {

    id swrveMockManaged = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    OCMExpect([swrveMockManaged sdkReady]).andForwardToRealObject();
    [SwrveSDK saveEventsToDisk];
    OCMVerifyAll(swrveMockManaged);
    
    id swrveMockAuto = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO autoStart:true];
    OCMExpect([swrveMockAuto sdkReady]).andForwardToRealObject();
    [SwrveSDK saveEventsToDisk];
    OCMVerifyAll(swrveMockAuto);
}

- (void)testSetEventQueuedCallback {

    id swrveMockManaged = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    OCMExpect([swrveMockManaged sdkReady]).andForwardToRealObject();
    [SwrveSDK setEventQueuedCallback:^(NSDictionary *eventPayload, NSString *eventsPayloadAsJSON) {}];
    OCMVerifyAll(swrveMockManaged);
    
    id swrveMockAuto = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO autoStart:true];
    OCMExpect([swrveMockAuto sdkReady]).andForwardToRealObject();
    [SwrveSDK setEventQueuedCallback:^(NSDictionary *eventPayload, NSString *eventsPayloadAsJSON) {}];
    OCMVerifyAll(swrveMockAuto);
}

- (void)testEventWithNoCallback {

    id swrveMockManaged = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    OCMExpect([swrveMockManaged sdkReady]).andForwardToRealObject();
    int successManaged = [SwrveSDK eventWithNoCallback:@"event1" payload:[NSMutableDictionary new]];
    XCTAssertEqual(SWRVE_FAILURE, successManaged);
    OCMVerifyAll(swrveMockManaged);
    
    id swrveMockAuto = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO autoStart:true];
    OCMExpect([swrveMockAuto sdkReady]).andForwardToRealObject();;
    int successAuto = [SwrveSDK eventWithNoCallback:@"event1" payload:[NSMutableDictionary new]];
    XCTAssertEqual(SWRVE_SUCCESS, successAuto);
    OCMVerifyAll(swrveMockAuto);
}

- (void)testHandleDeeplink {

    id swrveMockManaged = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    OCMExpect([swrveMockManaged sdkReady]).andForwardToRealObject();
    [SwrveSDK handleDeeplink:[NSURL new]];
    OCMVerifyAll(swrveMockManaged);
    
    id swrveMockAuto = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO autoStart:true];
    OCMExpect([swrveMockAuto sdkReady]).andForwardToRealObject();
    [SwrveSDK handleDeeplink:[NSURL new]];
    OCMVerifyAll(swrveMockAuto);
}

- (void)testHandleDeferredDeeplink {

    id swrveMockManaged = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    OCMExpect([swrveMockManaged sdkReady]).andForwardToRealObject();
    [SwrveSDK handleDeferredDeeplink:[NSURL new]];
    OCMVerifyAll(swrveMockManaged);
    
    id swrveMockAuto = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO autoStart:true];
    OCMExpect([swrveMockAuto sdkReady]).andForwardToRealObject();
    [SwrveSDK handleDeferredDeeplink:[NSURL new]];
    OCMVerifyAll(swrveMockAuto);
}

- (void)testInstallAction {

    id swrveMockManaged = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    OCMExpect([swrveMockManaged sdkReady]).andForwardToRealObject();
    [SwrveSDK installAction:[NSURL new]];
    OCMVerifyAll(swrveMockManaged);
    
    id swrveMockAuto = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO autoStart:true];
    OCMExpect([swrveMockAuto sdkReady]).andForwardToRealObject();
    [SwrveSDK installAction:[NSURL new]];
    OCMVerifyAll(swrveMockAuto);
}

- (void)testExternalUserId {

    id swrveMockManaged = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    OCMExpect([swrveMockManaged sdkReady]).andForwardToRealObject();
    [SwrveSDK externalUserId];
    OCMVerifyAll(swrveMockManaged);
    
    id swrveMockAuto = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO autoStart:true];
    OCMExpect([swrveMockAuto sdkReady]).andForwardToRealObject();;
    [SwrveSDK externalUserId];
    OCMVerifyAll(swrveMockAuto);
}

- (void)testSetCustomPayloadForConversationInput {

    id swrveMockManaged = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    OCMExpect([swrveMockManaged sdkReady]).andForwardToRealObject();
    [SwrveSDK setCustomPayloadForConversationInput:[NSMutableDictionary new]];
    OCMVerifyAll(swrveMockManaged);
    
    id swrveMockAuto = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO autoStart:true];
    OCMExpect([swrveMockAuto sdkReady]).andForwardToRealObject();;
    [SwrveSDK setCustomPayloadForConversationInput:[NSMutableDictionary new]];
    OCMVerifyAll(swrveMockAuto);
}

- (void)testPushToCampaignBlocked {
    [SwrveLocalStorage saveSwrveUserId:@"SomeUser"];

    NSURL *url = [NSURL URLWithString:@"swrve://app?param1=1&ad_content=2"];

    id swrveMockManagedAutostartFalse = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED autoStart:false];
    OCMReject([swrveMockManagedAutostartFalse initSwrveDeeplinkManager]);
    id deeplinkManagerManagedMock = OCMClassMock([SwrveDeeplinkManager class]);
    [swrveMockManagedAutostartFalse setSwrveDeeplinkManager:deeplinkManagerManagedMock];
    OCMReject([deeplinkManagerManagedMock handleNotificationToCampaign:OCMOCK_ANY]);
    [swrveMockManagedAutostartFalse handleNotificationToCampaign:[url absoluteString]];
    OCMVerifyAll(swrveMockManagedAutostartFalse);
    OCMVerifyAll(deeplinkManagerManagedMock);

    id swrveMockManagedAutostartTrue = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    OCMExpect([swrveMockManagedAutostartTrue initSwrveDeeplinkManager]);
    id deeplinkManagerkManagedAutostartTrue = OCMClassMock([SwrveDeeplinkManager class]);
    [swrveMockManagedAutostartTrue setSwrveDeeplinkManager:deeplinkManagerkManagedAutostartTrue];
    OCMExpect([deeplinkManagerkManagedAutostartTrue handleNotificationToCampaign:OCMOCK_ANY]);
    [swrveMockManagedAutostartTrue handleNotificationToCampaign:[url absoluteString]];
    OCMVerifyAll(swrveMockManagedAutostartTrue);
    OCMVerifyAll(deeplinkManagerkManagedAutostartTrue);

    id swrveMockAuto = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO autoStart:true];
    OCMExpect([swrveMockAuto initSwrveDeeplinkManager]);
    id deeplinkManagerAutoMock = OCMClassMock([SwrveDeeplinkManager class]);
    [swrveMockAuto setSwrveDeeplinkManager:deeplinkManagerAutoMock];
    OCMExpect([deeplinkManagerAutoMock handleNotificationToCampaign:OCMOCK_ANY]);
    [swrveMockAuto handleNotificationToCampaign:[url absoluteString]];
    OCMVerifyAll(swrveMockAuto);
    OCMVerifyAll(deeplinkManagerAutoMock);
}

- (void)testPushToCampaignBlockedStopped {
    [SwrveLocalStorage saveSwrveUserId:@"SomeUser"];

    NSURL *url = [NSURL URLWithString:@"swrve://app?param1=1&ad_content=2"];

    id swrveMockManagedAutostartFalse = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    [swrveMockManagedAutostartFalse stopTracking];
    
    OCMReject([swrveMockManagedAutostartFalse initSwrveDeeplinkManager]);
    id deeplinkManagerManagedMock = OCMClassMock([SwrveDeeplinkManager class]);
    [swrveMockManagedAutostartFalse setSwrveDeeplinkManager:deeplinkManagerManagedMock];
    OCMReject([deeplinkManagerManagedMock handleNotificationToCampaign:OCMOCK_ANY]);
    [swrveMockManagedAutostartFalse handleNotificationToCampaign:[url absoluteString]];
    OCMVerifyAll(swrveMockManagedAutostartFalse);
    OCMVerifyAll(deeplinkManagerManagedMock);

    id swrveMockAuto = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO autoStart:true];
    [swrveMockAuto stopTracking];
    
    OCMReject([swrveMockAuto initSwrveDeeplinkManager]);
    id deeplinkManagerAutoMock = OCMClassMock([SwrveDeeplinkManager class]);
    [swrveMockAuto setSwrveDeeplinkManager:deeplinkManagerAutoMock];
    OCMReject([deeplinkManagerAutoMock handleNotificationToCampaign:OCMOCK_ANY]);
    [swrveMockAuto handleNotificationToCampaign:[url absoluteString]];
    OCMVerifyAll(swrveMockAuto);
    OCMVerifyAll(deeplinkManagerAutoMock);

}

- (void)testFirstSessionEvent {

    // verify Swrve.first_session fired with new user and start api called
    id swrveMock1 = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED autoStart:false];
    OCMExpect([swrveMock1 eventInternal:@"Swrve.first_session" payload:nil triggerCallback:false]);
    [SwrveSDK start];
    OCMVerifyAllWithDelay(swrveMock1, 5);

    // Calling begin session later (to simulate 30 seconds in background and new session) should not send a Swrve.first_session again
    OCMReject([swrveMock1 eventInternal:@"Swrve.first_session" payload:nil triggerCallback:false]);
    [swrveMock1 beginSession];
    OCMVerifyAll(swrveMock1);

    // verify Swrve.first_session is not fired in next new instance
    id swrveMock2 = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED autoStart:false];
    OCMReject([swrveMock2 eventInternal:@"Swrve.first_session" payload:nil triggerCallback:false]);
    
    //startCampaignsAndResourcesTimer is the next thing to be called after the check for Swrve.first_session
    OCMExpect([swrveMock2 startCampaignsAndResourcesTimer]);
    [SwrveSDK start];

    OCMVerifyAllWithDelay(swrveMock2, 5);
}

@end
