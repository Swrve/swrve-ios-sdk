#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "SwrveSDK.h"
#import "SwrveTestHelper.h"
#import "SwrveRESTClient.h"

@interface Swrve (Internal)
- (void)appDidBecomeActive:(NSNotification *)notification;

- (NSDate *)getNow;

- (void)setSwrveSessionDelegate:(id <SwrveSessionDelegate>)sessionDelegate;

- (void)registerLifecycleCallbacks;

- (void)initWithUserId:(NSString *)swrveUserId;

- (void)switchUser:(NSString *)newUserID isFirstSession:(BOOL)isFirstSession;

- (void)beginSession;

@property(atomic) SwrveRESTClient *restClient;

- (BOOL)lifecycleCallbacksRegistered;

- (NSString *)swrveInitModeString;

@end

@interface SwrveSDK (InternalAccess)
+ (void)addSharedInstance:(Swrve *)instance;

+ (void)resetSwrveSharedInstance;
@end

@interface SwrveTestInit : XCTestCase

@end

@implementation SwrveTestInit

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

- (void)testSharedInstanceTwice {
    [SwrveTestHelper destroySharedInstance];
    [SwrveSDK sharedInstanceWithAppID:572 apiKey:@"SomeAPIKey"];
    Swrve *swrve = [SwrveSDK sharedInstance];
    XCTAssertNotNil(swrve);

    [SwrveSDK sharedInstanceWithAppID:572 apiKey:@"SomeAPIKey"];
    Swrve *swrve2 = [SwrveSDK sharedInstance];
    XCTAssertEqualObjects(swrve, swrve2);
}

- (void)testSharedInstanceWithConfig {
    [SwrveTestHelper destroySharedInstance];
    SwrveConfig *originalConfig = [[SwrveConfig alloc] init];
    [SwrveSDK sharedInstanceWithAppID:572 apiKey:@"SomeAPIKey" config:originalConfig];
    Swrve *swrve = [SwrveSDK sharedInstance];
    ImmutableSwrveConfig *config = [SwrveSDK config];
    XCTAssertNotNil(swrve);

    Swrve *swrve2 = [SwrveSDK sharedInstance];
    XCTAssertEqualObjects(swrve, swrve2);
    XCTAssertEqualObjects(swrve2.config, config);
}

- (void)testSecondInit {
    Swrve *swrve = [[Swrve alloc] initWithAppID:572 apiKey:@"SomeAPIKey"];
    XCTAssertNotNil(swrve);
    XCTAssertThrows([swrve initWithAppID:572 apiKey:@"AnotherAPIKey"], @"Do not initialize Swrve instance more than once!");
}

- (void)testManyCreations {
    for (int i = 0; i < 5; ++i) {
        Swrve *swrveMock = [SwrveTestHelper swrveMockWithMockedRestClient];
        swrveMock = [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey"];
        [swrveMock appDidBecomeActive:nil];
        NSDate *futureTime = [NSDate dateWithTimeIntervalSinceNow:0.2];
        [[NSRunLoop currentRunLoop] runUntilDate:futureTime];
        [swrveMock shutdown];
    }
}

- (void)testDefaultConfig {
    Swrve *swrve = [[Swrve alloc] initWithAppID:572 apiKey:@"SomeAPIKey"];
    ImmutableSwrveConfig *config = swrve.config;

    XCTAssertNotNil(config);
    XCTAssertEqual(config.httpTimeoutSeconds, 60);
    XCTAssertEqualObjects(config.eventsServer, @"https://572.api.swrve.com");
    XCTAssertEqualObjects(config.contentServer, @"https://572.content.swrve.com");
    XCTAssertEqualObjects(config.language, [[NSLocale preferredLanguages] objectAtIndex:0]);
    XCTAssertNil(config.appVersion);
    XCTAssertTrue(config.autoDownloadCampaignsAndResources);
    XCTAssertTrue(config.autoSaveEventsOnResign);
    XCTAssertTrue(config.autoSendEventsOnResume);
    XCTAssertTrue(config.inAppMessageConfig.prefersStatusBarHidden);
    XCTAssertFalse(config.prefersConversationsStatusBarHidden);
}

- (void)testStackConfig {
    SwrveConfig *config = nil;
    Swrve *swrve = nil;
    config = [[SwrveConfig alloc] init];
    swrve = [[Swrve alloc] initWithAppID:572 apiKey:@"SomeAPIKey" config:config]; // test default
    XCTAssertEqualObjects(swrve.config.eventsServer, @"https://572.api.swrve.com");
    XCTAssertEqualObjects(swrve.config.contentServer, @"https://572.content.swrve.com");

    config = [[SwrveConfig alloc] init];
    config.stack = SWRVE_STACK_EU;
    swrve = [[Swrve alloc] initWithAppID:572 apiKey:@"SomeAPIKey" config:config]; // test EU
    XCTAssertEqualObjects(swrve.config.eventsServer, @"https://572.eu-api.swrve.com");
    XCTAssertEqualObjects(swrve.config.contentServer, @"https://572.eu-content.swrve.com");

    config = [[SwrveConfig alloc] init];
    config.stack = SWRVE_STACK_US;
    swrve = [[Swrve alloc] initWithAppID:572 apiKey:@"SomeAPIKey" config:config]; // test US
    XCTAssertEqualObjects(swrve.config.eventsServer, @"https://572.api.swrve.com");
    XCTAssertEqualObjects(swrve.config.contentServer, @"https://572.content.swrve.com");
}

- (void)testSwrveInitProperties {
    Swrve *swrve = [[Swrve alloc] initWithAppID:123 apiKey:@"AnAPIKey"];
    XCTAssertEqual(swrve.appID, 123);
    XCTAssertEqualObjects(swrve.apiKey, @"AnAPIKey");
}

- (void)testInitUserId {
    // First init, will generate user id
    Swrve *swrve = [[Swrve alloc] initWithAppID:572 apiKey:@"SomeAPIKey"];
    NSString *userId = swrve.userID;
    XCTAssertNotNil(userId);

    // Next initializations should have the same id
    swrve = [[Swrve alloc] initWithAppID:572 apiKey:@"SomeAPIKey"];
    NSString *userId2 = swrve.userID;
    XCTAssertEqualObjects(userId, userId2);
}

- (void)testSessionDelegate {
    id swrveMock = [SwrveTestHelper swrveMockWithMockedRestClient];
    swrveMock = [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey"];

    id mockSwrveSessionDelegate1 = OCMProtocolMock(@protocol(SwrveSessionDelegate)); // mock SessionDelegate for each verify
    XCTestExpectation *completionHandler1 = [self expectationWithDescription:@"SwrveSessionDelegate1"];
    OCMExpect([mockSwrveSessionDelegate1 sessionStarted]).andDo(^(NSInvocation *invocation) {
        [completionHandler1 fulfill];
    });
    [swrveMock setSwrveSessionDelegate:mockSwrveSessionDelegate1];
    [swrveMock appDidBecomeActive:nil];
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Session1 started not invoked");
        }
    }];
    OCMVerifyAll(swrveMock);
    OCMVerifyAll(mockSwrveSessionDelegate1);

    // Calling a second time within the same session should not call the mockSwrveSessionDelegate
    id mockSwrveSessionDelegate2 = OCMProtocolMock(@protocol(SwrveSessionDelegate)); // mock SessionDelegate for each verify
    [swrveMock setSwrveSessionDelegate:mockSwrveSessionDelegate2];
    OCMReject([mockSwrveSessionDelegate2 sessionStarted]);
    [swrveMock appDidBecomeActive:nil];
    OCMVerifyAll(mockSwrveSessionDelegate2);

    // Calling a third time, but fast forward time by 30 seconds. mockSwrveSessionDelegate should be called as its a new session
    id mockSwrveSessionDelegate3 = OCMProtocolMock(@protocol(SwrveSessionDelegate)); // mock SessionDelegate for each verify
    XCTestExpectation *completionHandler3 = [self expectationWithDescription:@"SwrveSessionDelegate3"];
    OCMExpect([mockSwrveSessionDelegate3 sessionStarted]).andDo(^(NSInvocation *invocation) {
        [completionHandler3 fulfill];
    });
    [swrveMock setSwrveSessionDelegate:mockSwrveSessionDelegate3];
    NSDate *date35SecondsLater = [[NSDate date] dateByAddingTimeInterval:35];
    OCMStub([swrveMock getNow]).andReturn(date35SecondsLater);
    [swrveMock appDidBecomeActive:nil];
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Session3 started not invoked");
        }
    }];
    OCMVerifyAll(mockSwrveSessionDelegate3);
    
    // Change in identity with new user id can also begin a new session
    id mockSwrveSessionDelegate4 = OCMProtocolMock(@protocol(SwrveSessionDelegate)); // mock SessionDelegate for each verify
    XCTestExpectation *completionHandler4 = [self expectationWithDescription:@"mockSwrveSessionDelegate4"];
    OCMExpect([mockSwrveSessionDelegate4 sessionStarted]).andDo(^(NSInvocation *invocation) {
         [completionHandler4 fulfill];
    });
    [swrveMock setSwrveSessionDelegate:mockSwrveSessionDelegate4];
    [swrveMock beginSession];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Session4 started not invoked");
        }
    }];
    OCMVerifyAll(mockSwrveSessionDelegate4);
}

- (void)testSdkStartedAutoMode {
    id swrveMockAuto = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO];
    XCTAssertNotNil(swrveMockAuto);
    XCTAssertTrue([SwrveSDK started]);
}

- (void)testSdkStartedManagedModeAndAutoStartFalse {
    id swrveMockManaged1 = OCMPartialMock([Swrve alloc]);
    [self initSwrveMock:swrveMockManaged1 mode:SWRVE_INIT_MODE_MANAGED autoStart:false];
    XCTAssertFalse([SwrveSDK started]);
    [SwrveSDK start];
    //events are flushed on different thread in startWithUserId, once complete back on the main thread, need to delay for a moment.
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDK Started"];
    [SwrveTestHelper waitForBlock:0.005 conditionBlock:^BOOL(){
        return [SwrveSDK started];

    } expectation:expectation];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    XCTAssertTrue([SwrveSDK started]);

    id swrveMockManaged2 = OCMPartialMock([Swrve alloc]);
    [self initSwrveMock:swrveMockManaged2 mode:SWRVE_INIT_MODE_MANAGED autoStart:false];
    XCTAssertFalse([SwrveSDK started]); // Should be false because the sdk should NOT be autostarted
    [SwrveSDK start];
    //events are flushed on different thread in startWithUserId, once complete back on the main thread, need to delay for a moment.
    expectation = [self expectationWithDescription:@"SDK Started"];
    [SwrveTestHelper waitForBlock:0.005 conditionBlock:^BOOL(){
        return [SwrveSDK started];

    } expectation:expectation];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    XCTAssertTrue([SwrveSDK started]);
}

- (void)testSdkStartedManagedModeAndAutoStartTrue {
    id swrveMockManaged1 = OCMPartialMock([Swrve alloc]);
    [self initSwrveMock:swrveMockManaged1 mode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    XCTAssertFalse([SwrveSDK started]);
    [SwrveSDK start];
    //events are flushed on different thread in startWithUserId, once complete back on the main thread, need to delay for a moment.
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDK Started"];
    [SwrveTestHelper waitForBlock:0.005 conditionBlock:^BOOL(){
        return [SwrveSDK started];

    } expectation:expectation];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    XCTAssertTrue([SwrveSDK started]);

    id swrveMockManagedOnce2 = OCMPartialMock([Swrve alloc]);
    [self initSwrveMock:swrveMockManagedOnce2 mode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    XCTAssertTrue([SwrveSDK started]); // the second instance is started upon init.
}

- (void)testInitModeManaged {

    id swrveMockManaged = OCMPartialMock([Swrve alloc]);
    OCMReject([swrveMockManaged registerLifecycleCallbacks]);
    OCMReject([swrveMockManaged initWithUserId:OCMOCK_ANY]);
    [self initSwrveMock:swrveMockManaged mode:SWRVE_INIT_MODE_MANAGED autoStart:false];
    OCMVerifyAll(swrveMockManaged);
}

- (void)testInitModeManagedAndAutoStart {

    // create instance first time but don't call start api
    id swrveMockManaged1 = OCMPartialMock([Swrve alloc]);
    OCMReject([swrveMockManaged1 registerLifecycleCallbacks]);
    OCMReject([swrveMockManaged1 initWithUserId:OCMOCK_ANY]);
    [self initSwrveMock:swrveMockManaged1 mode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    OCMVerifyAll(swrveMockManaged1);

    // second instance created but note that start api still hasn't been called so registerLifecycleCallbacks, etc still not called yet
    id swrveMockManaged2 = OCMPartialMock([Swrve alloc]);
    OCMReject([swrveMockManaged2 registerLifecycleCallbacks]);
    OCMReject([swrveMockManaged2 initWithUserId:OCMOCK_ANY]);
    [self initSwrveMock:swrveMockManaged2 mode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    OCMVerifyAll(swrveMockManaged2);

    //third instance created and sdk was started previously and userId created, therefore autostarted this time
    id swrveMockManaged3 = OCMPartialMock([Swrve alloc]);
    OCMExpect([swrveMockManaged3 registerLifecycleCallbacks]);
    OCMExpect([swrveMockManaged3 initWithUserId:OCMOCK_ANY]);
    [self initSwrveMock:swrveMockManaged3 mode:SWRVE_INIT_MODE_MANAGED autoStart:true];

    // start the sdk
    [SwrveSDK start];

    //events are flushed on different thread in startWithUserId, once complete back on the main thread, need to delay for a moment.
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDK Started"];
    [SwrveTestHelper waitForBlock:0.005 conditionBlock:^BOOL(){
        return [SwrveSDK started];

    } expectation:expectation];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];

    OCMVerifyAll(swrveMockManaged3);

}

- (void)testInitModeManagedStart {

    id swrveMockManaged = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED];
    XCTAssertNotNil(swrveMockManaged);

    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
    id mockRestClient = OCMPartialMock(restClient);
    Swrve *swrve = (Swrve *) swrveMockManaged;
    swrve.restClient = mockRestClient;

    [SwrveSDK start];

    //events are flushed on different thread in startWithUserId, once complete back on the main thread, need to delay for a moment.
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDK Started"];
    [SwrveTestHelper waitForBlock:0.005 conditionBlock:^BOOL(){
        return [SwrveSDK started];

    } expectation:expectation];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];

    OCMVerify([swrveMockManaged registerLifecycleCallbacks]);
    NSString *userId = [SwrveSDK userID];
    OCMVerify([swrveMockManaged switchUser:userId isFirstSession:true]);
    OCMVerify([swrveMockManaged beginSession]);
    OCMVerify([mockRestClient sendHttpGETRequest:[OCMArg checkWithBlock:^BOOL(NSURL *value) {
        XCTAssertNotNil(value);
        XCTAssertTrue([[value absoluteString] containsString:@"https://123.content.swrve.com/api/1/user_content"], @"Missing a refresh of campaigns");
        XCTAssertTrue([[value absoluteString] containsString:userId], @"refresh campaigns for incorrect userid");
        return true; // asserts above are more descriptive so returning true
    }]                         completionHandler:OCMOCK_ANY]);

    //Check if start called again it doesn't begin another session.
    OCMReject([swrveMockManaged beginSession]);
    [SwrveSDK start];
    OCMVerifyAll(swrveMockManaged);
}

- (void)testInitModeManagedStartWithSameUser {

    id swrveMockManaged = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED];
    XCTAssertNotNil(swrveMockManaged);

    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
    id mockRestClient = OCMPartialMock(restClient);
    Swrve *swrve = (Swrve *) swrveMockManaged;
    swrve.restClient = mockRestClient;

    NSString *userId = [SwrveSDK userID];
    XCTAssertNotEqualObjects(userId, @"SomeUserId");

    [SwrveSDK startWithUserId:@"SomeUserId"];

    //events are flushed on different thread in startWithUserId, once complete back on the main thread, need to delay for a moment.
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDK Started"];
    [SwrveTestHelper waitForBlock:0.005 conditionBlock:^BOOL(){
        return [SwrveSDK started];

    } expectation:expectation];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];

    OCMVerify([swrveMockManaged registerLifecycleCallbacks]);
    OCMVerify([swrveMockManaged switchUser:@"SomeUserId" isFirstSession:true]);
    OCMVerify([swrveMockManaged beginSession]);
    OCMVerify([mockRestClient sendHttpGETRequest:[OCMArg checkWithBlock:^BOOL(NSURL *value) {
        XCTAssertNotNil(value);
        XCTAssertTrue([[value absoluteString] containsString:@"https://123.content.swrve.com/api/1/user_content"], @"Missing a refresh of campaigns");
        XCTAssertTrue([[value absoluteString] containsString:@"user=SomeUserId"], @"refresh campaigns for incorrect userid");
        return true; // asserts above are more descriptive so returning true
    }]                         completionHandler:OCMOCK_ANY]);

    //Check if startWithUserId called again it doesn't begin another session for the same user
    OCMReject([swrveMockManaged beginSession]);
    [SwrveSDK startWithUserId:@"SomeUserId"];

    userId = [SwrveSDK userID];
    XCTAssertEqualObjects(userId, @"SomeUserId");
}

- (void)testAutoCantCallStartWithUserMethod {
    id swrveMockAuto = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_AUTO];
    XCTAssertNotNil(swrveMockAuto);
    BOOL pass = false;
    @try {
        [SwrveSDK startWithUserId:@"SomeUserId"];
    } @catch (NSException *exception) {
        pass = true;
    }
    XCTAssertTrue(pass);
}

- (void)testManagedCantCallIdentityMethod {
    id swrveMockManaged = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED];
    BOOL pass = false;
    @try {
        [swrveMockManaged identify:@"SomeUser" onSuccess:nil onError:nil];
    } @catch (NSException *exception) {
        pass = true;
    }
    XCTAssertTrue(pass);
}

- (void)testRegisterLifecycleCallbacks {
    // Test to make sure the lifecycleCallbacksRegistered BOOL gets set when registerLifecycleCallbacks method is called.
    id swrveMockManaged = [self initSwrveSDKWithMode:SWRVE_INIT_MODE_MANAGED];
    XCTAssertFalse([swrveMockManaged lifecycleCallbacksRegistered]);
    [swrveMockManaged registerLifecycleCallbacks];
    XCTAssertTrue([swrveMockManaged lifecycleCallbacksRegistered]);
}

- (void)testInitModeString {
    id swrveMockAutoAutostartFalse = OCMPartialMock([Swrve alloc]);
    [self initSwrveMock:swrveMockAutoAutostartFalse mode:SWRVE_INIT_MODE_AUTO autoStart:false];
    XCTAssertEqualObjects([swrveMockAutoAutostartFalse swrveInitModeString], @"auto");

    id swrveMockAutoAutostartTrue = OCMPartialMock([Swrve alloc]);
    [self initSwrveMock:swrveMockAutoAutostartTrue mode:SWRVE_INIT_MODE_AUTO autoStart:true];
    XCTAssertEqualObjects([swrveMockAutoAutostartTrue swrveInitModeString], @"auto_auto");

    id swrveMockManagedAutostartFalse = OCMPartialMock([Swrve alloc]);
    [self initSwrveMock:swrveMockManagedAutostartFalse mode:SWRVE_INIT_MODE_MANAGED autoStart:false];
    XCTAssertEqualObjects([swrveMockManagedAutostartFalse swrveInitModeString], @"managed");

    id swrveMockManagedAutostartTrue = OCMPartialMock([Swrve alloc]);
    [self initSwrveMock:swrveMockManagedAutostartTrue mode:SWRVE_INIT_MODE_MANAGED autoStart:true];
    XCTAssertEqualObjects([swrveMockManagedAutostartTrue swrveInitModeString], @"managed_auto");
}

- (id)initSwrveSDKWithMode:(SwrveInitMode)mode {

    [SwrveSDK resetSwrveSharedInstance];

    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.initMode = mode;
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
    [SwrveSDK addSharedInstance:swrveMock];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey" config:config];
#pragma clang diagnostic pop

    return swrveMock;
}

- (void)initSwrveMock:(id)swrveMock mode:(SwrveInitMode)mode autoStart:(BOOL) autoStart {

    [SwrveSDK resetSwrveSharedInstance];

    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.initMode = mode;
    config.autoStartLastUser = autoStart;
    Swrve *swrve = (Swrve *) swrveMock;
    [SwrveSDK addSharedInstance:swrveMock];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey" config:config];
#pragma clang diagnostic pop
}

@end
