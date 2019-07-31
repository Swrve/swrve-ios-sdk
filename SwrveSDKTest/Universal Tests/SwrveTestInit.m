#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "AppDelegate.h"

#import "SwrveSDK.h"
#import "SwrveTestHelper.h"
#import "SwrveRESTClient.h"

@interface Swrve (Internal)
- (void)appDidBecomeActive:(NSNotification *)notification;
- (NSDate *)getNow;
- (void)setSwrveSessionDelegate:(id<SwrveSessionDelegate>)sessionDelegate;
- (void)initSwrveRestClient:(NSTimeInterval)timeOut;
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

- (void)testMessagingEnabledByDefault {
    Swrve *swrveMock = [SwrveTestHelper swrveMockWithMockedRestClient];
    swrveMock = [swrveMock initWithAppID:123 apiKey:@"456"];
    [swrveMock appDidBecomeActive:nil];
    XCTAssertNotNil(swrveMock.messaging);
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
    for (int i = 0; i < 10; ++i) {
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
    XCTAssertTrue(config.prefersIAMStatusBarHidden);
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
    [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey"];
    
    id mockSwrveSessionDelegate1 = OCMProtocolMock(@protocol(SwrveSessionDelegate)); // mock SessionDelegate for each verify
    XCTestExpectation *completionHandler1 = [self expectationWithDescription:@"SwrveSessionDelegate1"];
    OCMExpect([mockSwrveSessionDelegate1 sessionStarted]).andDo(^(NSInvocation *invocation) {
        [completionHandler1 fulfill];
    });
    [swrveMock setSwrveSessionDelegate:mockSwrveSessionDelegate1];
    [swrveMock appDidBecomeActive:nil];
    [self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {
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
    NSDate *date30SecondsLater = [[NSDate date] dateByAddingTimeInterval:30];
    OCMStub([swrveMock getNow]).andReturn(date30SecondsLater);
    [swrveMock appDidBecomeActive:nil];
    [self waitForExpectationsWithTimeout:2 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Session3 started not invoked");
        }
    }];
    OCMVerifyAll(mockSwrveSessionDelegate3);
}

@end
