

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SwrveCommon.h"
#import "SwrveQA.h"
#import "SwrveLocalStorage.h"
#import "SwrveUtils.h"
#import "SwrveQAEventsQueueManager.h"

@interface SwrveTestQAEventsQueueManager : XCTestCase {
    id classSwrveUtilsMock;
    id swrveCommonMock;
    NSNumber *expectedMockedTime;
}

@end

@interface SwrveQAEventsQueueManager (private_acess)

@property(atomic) SwrveRESTClient *restClient;
@property(atomic) NSMutableArray  *queue;
@property(nonatomic) NSString     *sessionToken;
@property(atomic) NSTimer         *flushTimer;
- (void)makeRequest;

@end

@interface SwrveQA (private_acess)
@property(nonatomic) SwrveQAEventsQueueManager *queueManager;
@end


@implementation SwrveTestQAEventsQueueManager

- (void)setUp {
    [super setUp];
    expectedMockedTime = @1592239308915;
    // Mock getTimeEpoch at SwrveUtils.
    classSwrveUtilsMock = OCMClassMock([SwrveUtils class]);
    OCMStub([classSwrveUtilsMock getTimeEpoch])._andReturn(expectedMockedTime);

    swrveCommonMock = OCMProtocolMock(@protocol(SwrveCommonDelegate));
    OCMStub([swrveCommonMock appVersion]).andReturn(@"myAppVersion");
    OCMStub([swrveCommonMock eventsServer]).andReturn(@"https://myevents.server");
    [SwrveCommon addSharedInstance:swrveCommonMock];
}

- (void)tearDown {
    [SwrveLocalStorage saveQaUser:nil];
    [SwrveLocalStorage saveSwrveUserId:nil];
    [super tearDown];
}

- (void)testQueueEventsTimerStartAndStop {
    [self enableQaLogging];
    SwrveQA *qa = [SwrveQA sharedInstance];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Timer Not working as it should"];

    // Mock rest client that will be used by our "queueManager" at QA class.
    id mockRestClient = OCMPartialMock([[SwrveRESTClient alloc] initWithTimeoutInterval:60]);
    OCMExpect([mockRestClient sendHttpPOSTRequest:[OCMArg checkWithBlock:^BOOL(NSURL *urlValue) {
       return urlValue;
    }]
                                        jsonData:[OCMArg checkWithBlock:^BOOL(NSData *jsonValue) {
        [expectation fulfill];
       return jsonValue;
    }]completionHandler:OCMOCK_ANY]);
    [[qa queueManager] setRestClient:mockRestClient];

    // Timer should be nil and start just after we queue the first event.
    XCTAssertNil([[qa queueManager] flushTimer]);
    [SwrveQA campaignButtonClicked:@12 variantId:@2 buttonName:@"button" actionType:@"custom" actionValue:@"https://url.com"];
    XCTAssertNotNil([[qa queueManager] flushTimer]);
    
    [self waitForExpectationsWithTimeout:200.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        } else {
            // If we force a flush it should set timer to nil, because there are no more events to send.
            [[qa queueManager] flushEvents];
            XCTAssertNil([[qa queueManager] flushTimer]);
            XCTAssertTrue([[[qa queueManager] queue] count] == 0, @"Should have flush our events as well");
        }
    }];
}

- (void)testQueueAddEventsAndFlushThem {
    [self enableQaLogging];
    SwrveQA *qa = [SwrveQA sharedInstance];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Flush event didn't happen as it should."];
    // Mock rest client that will be used by our "queueManager" at QA class.
    id mockRestClient = OCMPartialMock([[SwrveRESTClient alloc] initWithTimeoutInterval:60]);
    OCMExpect([mockRestClient sendHttpPOSTRequest:[OCMArg checkWithBlock:^BOOL(NSURL *urlValue) {
       return urlValue;
    }]
                                        jsonData:[OCMArg checkWithBlock:^BOOL(NSData *jsonValue) {
        [expectation fulfill];
        return jsonValue;
    }]completionHandler:OCMOCK_ANY]);
    [[qa queueManager] setRestClient:mockRestClient];

    [SwrveQA campaignButtonClicked:@12 variantId:@2 buttonName:@"button" actionType:@"custom" actionValue:@"https://url.com"];
    XCTAssertTrue([[[qa queueManager] queue] count] == 1, @"Should have one event at queue at this stage.");
    // shouldn't add the event bellow because it has and invalid event dic type.
    [[qa queueManager] queueEvent:[@{@"someInvalidDic":@"whatver"} mutableCopy]];
    XCTAssertTrue([[[qa queueManager] queue] count] == 1, @"Should have one event at queue at this stage.");

    [SwrveQA campaignButtonClicked:@20 variantId:@3 buttonName:@"button" actionType:@"custom" actionValue:@"https://url.com"];
    XCTAssertTrue([[[qa queueManager] queue] count] == 2, @"Should have two queued events at this stage.");
    // Also the timer to flush should be already running.
    XCTAssertNotNil([[qa queueManager] flushTimer]);

    [self waitForExpectationsWithTimeout:200.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        } else {
            // Events Timer shouldn't be nill yet.
            XCTAssertNotNil([[qa queueManager] flushTimer]);
            XCTAssertTrue([[[qa queueManager] queue] count] == 0, @"Should not have any event on queue");
            // Check events that send.
        }
    }];
}

- (void)testQueuesAddEventsAndFlushThem {
    [self enableQaLogging];
    SwrveQA *qa = [SwrveQA sharedInstance];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Flush event didn't happen as it should."];
    // Mock rest client that will be used by our "queueManager" at QA class.
    id mockRestClient = OCMPartialMock([[SwrveRESTClient alloc] initWithTimeoutInterval:60]);
    __block NSURL *capturedUrl;
    __block NSData *capturedJson;
    OCMExpect([mockRestClient sendHttpPOSTRequest:[OCMArg checkWithBlock:^BOOL(NSURL *urlValue) {
       capturedUrl = urlValue;
       return urlValue;
    }]
                                        jsonData:[OCMArg checkWithBlock:^BOOL(NSData *jsonValue) {
       capturedJson = jsonValue;
        [expectation fulfill];
       return jsonValue;
    }]completionHandler:OCMOCK_ANY]);
    [[qa queueManager] setRestClient:mockRestClient];

    NSMutableDictionary *firstExpectedLoggedEvent = [self createExpectedEventWithLogDetails:@{
              @"action_type":@"custom",
              @"action_value":@"https://url.com",
              @"button_name":@"button",
              @"campaign_id":@12,
              @"variant_id":@2
    } withLogType:@"campaign-button-clicked" withlogSource:@"sdk"];
    [SwrveQA campaignButtonClicked:@12 variantId:@2 buttonName:@"button" actionType:@"custom" actionValue:@"https://url.com"];
    XCTAssertTrue([[[qa queueManager] queue] count] == 1, @"Should have one event at queue at this stage.");


    NSMutableDictionary *secondExpectedLoggedEvent = [self createExpectedEventWithLogDetails:@{
              @"action_type":@"custom",
              @"action_value":@"https://url.com",
              @"button_name":@"button",
              @"campaign_id":@20,
              @"variant_id":@3
    } withLogType:@"campaign-button-clicked" withlogSource:@"sdk"];
    [SwrveQA campaignButtonClicked:@20 variantId:@3 buttonName:@"button" actionType:@"custom" actionValue:@"https://url.com"];
    XCTAssertTrue([[[qa queueManager] queue] count] == 2, @"Should have two queued events at this stage.");
    // Also the timer to flush should be already running.
    XCTAssertNotNil([[qa queueManager] flushTimer]);


    [self waitForExpectationsWithTimeout:200.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        } else {
            // Events Timer shouldn't be nill yet.
            XCTAssertNotNil([[qa queueManager] flushTimer]);
            XCTAssertTrue([[[qa queueManager] queue] count] == 0, @"Should not have any event on queue");

            NSArray *loggedEvents = [self verifyQaLogEvents:capturedJson withlogSource:@"sdk"];
            XCTAssertTrue([loggedEvents count] == 2, @"Should log two events");
            XCTAssertNotNil(loggedEvents);
            XCTAssertEqualObjects([loggedEvents objectAtIndex:0], firstExpectedLoggedEvent, @"fist logged event don't match as expectation");
            XCTAssertEqualObjects([loggedEvents objectAtIndex:1], secondExpectedLoggedEvent, @"second logged event don't match as expectation");
            
        }
    }];
}

#pragma mark - helpers

- (void)enableQaLogging {
    NSDictionary *jsonQa = @{
                             @"logging": @true,
                             @"logging_url": @"http://123.swrve.com",
                             @"campaigns": @{}
                             };
    [SwrveQA updateQAUser:jsonQa andSessionToken:@"myToken"];
}

- (NSArray*)verifyQaLogEvents:(NSData*) capturedJson withlogSource:(NSString *) logSource {

    NSError *error;
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:capturedJson options:kNilOptions error:&error];
    XCTAssertEqual(4, [json count]);
    XCTAssertTrue([json objectForKey:@"app_version"]);
    XCTAssertEqualObjects([json objectForKey:@"app_version"], @"myAppVersion");
    XCTAssertTrue([json objectForKey:@"session_token"]);
    XCTAssertEqualObjects([json objectForKey:@"session_token"], @"myToken");
    XCTAssertTrue([json objectForKey:@"version"]);
    XCTAssertEqualObjects([json objectForKey:@"version"], [NSNumber numberWithInt:3]);

    XCTAssertTrue([json objectForKey:@"data"]);
    NSArray *dataArray = [json objectForKey:@"data"];
    XCTAssertEqual(2, [dataArray count]);

    NSDictionary *data = [dataArray objectAtIndex:0];
    XCTAssertEqual(5, [data count]);
    XCTAssertTrue([data objectForKey:@"log_source"]);
    XCTAssertTrue([data objectForKey:@"log_type"]);
    XCTAssertEqualObjects([data objectForKey:@"time"], expectedMockedTime);
    XCTAssertTrue([data objectForKey:@"type"]);
    XCTAssertEqualObjects([data objectForKey:@"type"], @"qa_log_event");
    XCTAssertTrue([data objectForKey:@"log_details"]);
    return dataArray;
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

