#import <XCTest/XCTest.h>
#import "SwrveTestHelper.h"
#if __has_include(<OCMock/OCMock.h>)
#import <OCMock/OCMock.h>
#endif

#if __has_include(<SwrveSDK/SwrveSDK-Swift.h>)
#import <SwrveSDK/SwrveSDK-Swift.h>
#elif __has_include("SwrveSDK-Swift.h")
#import "SwrveSDK-Swift.h"
#endif

@interface Swrve (Internal)
@property(atomic) SwrveRESTClient *restClient;
@property(atomic) SwrvePushInboxController *pushInbox;
@property (atomic) NSMutableArray *eventBuffer;
- (void)appDidBecomeActive:(NSNotification *)notification;
- (void)updateResources:(NSArray *)resourceJson writeToCache:(BOOL)writeToCache;
- (int)queueEvent:(NSString *)eventType data:(NSMutableDictionary *)eventData triggerCallback:(bool)triggerCallback;
@end

@interface SwrveTestPushInbox : XCTestCase

@end

@implementation SwrveTestPushInbox

NSString *const RESPONSE_MODIFED = @"{\"state\": \"modified\"}";
NSString *const RESPONSE_UNMODIFED = @"{\"state\": \"unmodified\"}";

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
    [SwrveTestHelper tearDown];
}

- (void)testPushInboxMessages_Load {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaigns_push_inbox" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    Swrve *swrveMock = [SwrveTestHelper swrveMockWithMockedRestClientResponseCode:200 mockData:mockData];
    swrveMock = [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey"];
    [swrveMock appDidBecomeActive:nil];
    
    NSArray* inboxMessages =  [swrveMock pushInboxMessages];
    
    //Check there is the expected 8 message in the user's inbox
    XCTAssertEqual(inboxMessages.count, 8);
    
    //Check value of first message is correctly parsed into object properties
    [self compareFirstMessageWithExpected:inboxMessages];
    
    //Check value of second message is read
    SwrvePushInboxMessage *message1 = [inboxMessages objectAtIndex:1];
    XCTAssertEqual(message1.state, SwrvePushInboxMessageStateREAD);
}

- (void)testPushInboxMessages_Caching {
    
    Swrve *swrveMock = (Swrve *) OCMPartialMock([Swrve alloc]);
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaigns_push_inbox" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    
    //Make sure there is no existing inbox cache file to load on sdk startup
    [SwrveTestHelper removeSDKData];
    
    //Start the sdk and verify that there are no cached inbox messages
    swrveMock = [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey"];
    [swrveMock appDidBecomeActive:nil];
    NSArray* inboxMessages =  [swrveMock pushInboxMessages];
    XCTAssertEqual(inboxMessages.count, 0);
    
    //Set the mocked data source and reload inbox (incl. writing it to cache file)
    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
    id mockRestClient = OCMPartialMock(restClient);
    id mockResponse = OCMClassMock([NSHTTPURLResponse class]);
    OCMStub([mockResponse statusCode]).andReturn(200);
    OCMStub([mockRestClient sendHttpRequest:OCMOCK_ANY
                          completionHandler:([OCMArg invokeBlockWithArgs:mockResponse, mockData, [NSNull null], nil])]);
    swrveMock.restClient = mockRestClient;
    [swrveMock refreshCampaignsAndResources];
    inboxMessages =  [swrveMock pushInboxMessages];
    XCTAssertEqual(inboxMessages.count, 8);
    
    //Restart a fresh swrve mock instance, with no mocked data, or in-memory inbox,
    //and verify that the inbox gets loaded correctly from the cachefile into memory
    swrveMock = (Swrve *) OCMPartialMock([Swrve alloc]);
    swrveMock = [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey"];
    [swrveMock appDidBecomeActive:nil];
    inboxMessages =  [swrveMock pushInboxMessages];
    XCTAssertEqual(inboxMessages.count, 8);
    
    //Ensure that a message was written to disk and read back with values as expected.
    [self compareFirstMessageWithExpected:inboxMessages];
}

- (void) testGetPushInboxMessages {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaigns_push_inbox_past_and_future" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    Swrve *swrveMock = [SwrveTestHelper swrveMockWithMockedRestClientResponseCode:200 mockData:mockData];
    [SwrveTestHelper removeSDKData];
    [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey"];
    [swrveMock appDidBecomeActive:nil];
    
    NSArray* inboxMessages =  [swrveMock pushInboxMessages];
    
    // Only 3 messages should be returned which have messageId 1, 3 and 4. The other messages are either expired.
    XCTAssertEqual(inboxMessages.count, 3);
    XCTAssertEqual(((SwrvePushInboxMessage*)inboxMessages[0]).messageId, 1);
    XCTAssertEqual(((SwrvePushInboxMessage*)inboxMessages[1]).messageId, 3);
    XCTAssertEqual(((SwrvePushInboxMessage*)inboxMessages[2]).messageId, 4);
}

- (void) testRead_sdkNotReady {
    Swrve *swrveMock = (Swrve *) OCMPartialMock([Swrve alloc]);
    [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey"];
    [swrveMock appDidBecomeActive:nil];

    [swrveMock stopTracking];
    
    id mockInboxDelegate = OCMProtocolMock(@protocol(SwrvePushInboxDelegate));
    
    [swrveMock readPushInboxMessage:1 listener:mockInboxDelegate];
    
    OCMVerify([mockInboxDelegate onComplete:1 result:[OCMArg checkWithBlock:^BOOL(SwrvePushInboxResult* result) {
        return result.resultCode == SwrvePushInboxResultCodeERROR
        && [result.errorMessage isEqualToString:@"SDK is not ready"];
    }]]);
    
    OCMVerify(never(), [swrveMock sendQueuedEvents]);
}

- (void) testDelete_sdkNotReady {
    Swrve *swrveMock = (Swrve *) OCMPartialMock([Swrve alloc]);
    [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey"];
    [swrveMock appDidBecomeActive:nil];

    [swrveMock stopTracking];
    
    id mockInboxDelegate = OCMProtocolMock(@protocol(SwrvePushInboxDelegate));
    
    [swrveMock deletePushInboxMessage:1 listener:mockInboxDelegate];
    
    OCMVerify([mockInboxDelegate onComplete:1 result:[OCMArg checkWithBlock:^BOOL(SwrvePushInboxResult* result) {
        return result.resultCode == SwrvePushInboxResultCodeERROR
        && [result.errorMessage isEqualToString:@"SDK is not ready"];
    }]]);
    
    OCMVerify(never(), [swrveMock sendQueuedEvents]);
}

- (void) testEngage_sdkNotReady {
    Swrve *swrveMock = (Swrve *) OCMPartialMock([Swrve alloc]);
    [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey"];
    [swrveMock appDidBecomeActive:nil];

    [swrveMock stopTracking];
    
    id mockInboxDelegate = OCMProtocolMock(@protocol(SwrvePushInboxDelegate));
    
    [swrveMock engagePushInboxMessage:1 listener:mockInboxDelegate];
    
    OCMVerify([mockInboxDelegate onComplete:1 result:[OCMArg checkWithBlock:^BOOL(SwrvePushInboxResult* result) {
        return result.resultCode == SwrvePushInboxResultCodeERROR
        && [result.errorMessage isEqualToString:@"SDK is not ready"];
    }]]);
    
    OCMVerify(never(), [swrveMock sendQueuedEvents]);
}


- (void) testRead_restServerError {
    Swrve *swrveMock = [self swrveMockWithResponseCode:500 inboxUpdateResponseBody:RESPONSE_MODIFED];
    SwrvePushInboxMessage *message = [[swrveMock pushInbox] getPushInboxMessage:1];
    XCTAssertNotNil(message);
    XCTAssertEqual(message.state, SwrvePushInboxMessageStateUNREAD);
    
    id mockInboxDelegate = OCMProtocolMock(@protocol(SwrvePushInboxDelegate));
    [swrveMock readPushInboxMessage:1 listener:mockInboxDelegate];
    
    OCMVerify([mockInboxDelegate onComplete:1 result:[OCMArg checkWithBlock:^BOOL(SwrvePushInboxResult* result) {
        XCTAssertEqual(message.state, SwrvePushInboxMessageStateUNREAD);
        return result.resultCode == SwrvePushInboxResultCodeERROR
        && [result.errorMessage isEqualToString:@"Push Inbox Message 1 failed to mark as read. Server response code:500"]
        && result.httpResponseCode == 500;
    }]]);
    
    OCMVerify(never(), [swrveMock sendQueuedEvents]);
}

- (void) testDelete_restServerError {
    Swrve *swrveMock = [self swrveMockWithResponseCode:500 inboxUpdateResponseBody:RESPONSE_MODIFED];
    SwrvePushInboxMessage *message = [[swrveMock pushInbox] getPushInboxMessage:1];
    XCTAssertNotNil(message);
    
    id mockInboxDelegate = OCMProtocolMock(@protocol(SwrvePushInboxDelegate));
    [swrveMock deletePushInboxMessage:1 listener:mockInboxDelegate];
    
    OCMVerify([mockInboxDelegate onComplete:1 result:[OCMArg checkWithBlock:^BOOL(SwrvePushInboxResult* result) {
        return result.resultCode == SwrvePushInboxResultCodeERROR
        && [result.errorMessage isEqualToString:@"Push Inbox Message 1 failed to delete. Server response code:500"]
        && result.httpResponseCode == 500;
    }]]);
    
    OCMVerify(never(), [swrveMock sendQueuedEvents]);
    
    OCMVerifyAll(swrveMock);
}

- (void) testRead_restUserError {
    Swrve *swrveMock = [self swrveMockWithResponseCode:400 inboxUpdateResponseBody:RESPONSE_MODIFED];
    SwrvePushInboxMessage *message = [[swrveMock pushInbox] getPushInboxMessage:1];
    XCTAssertNotNil(message);
    XCTAssertEqual(message.state, SwrvePushInboxMessageStateUNREAD);
    
    id mockInboxDelegate = OCMProtocolMock(@protocol(SwrvePushInboxDelegate));
    [swrveMock readPushInboxMessage:1 listener:mockInboxDelegate];
    
    OCMVerify([mockInboxDelegate onComplete:1 result:[OCMArg checkWithBlock:^BOOL(SwrvePushInboxResult* result) {
        XCTAssertEqual(message.state, SwrvePushInboxMessageStateUNREAD);
        return result.resultCode == SwrvePushInboxResultCodeERROR
        && [result.errorMessage isEqualToString:@"Push Inbox Message 1 failed to mark as read. Server response code:400"]
        && result.httpResponseCode == 400;
    }]]);
    
    OCMVerify(never(), [swrveMock sendQueuedEvents]);
}

- (void) testDelete_restUserError {
    Swrve *swrveMock = [self swrveMockWithResponseCode:400 inboxUpdateResponseBody:RESPONSE_MODIFED];
    SwrvePushInboxMessage *message = [[swrveMock pushInbox] getPushInboxMessage:1];
    XCTAssertNotNil(message);
    
    id mockInboxDelegate = OCMProtocolMock(@protocol(SwrvePushInboxDelegate));
    [swrveMock deletePushInboxMessage:1 listener:mockInboxDelegate];
    
    OCMVerify([mockInboxDelegate onComplete:1 result:[OCMArg checkWithBlock:^BOOL(SwrvePushInboxResult* result) {
        return result.resultCode == SwrvePushInboxResultCodeERROR
        && [result.errorMessage isEqualToString:@"Push Inbox Message 1 failed to delete. Server response code:400"]
        && result.httpResponseCode == 400;
    }]]);
    
    // message should not be deleted
    message = [[swrveMock pushInbox] getPushInboxMessage:1];
    XCTAssertNotNil(message);
    
    OCMVerify(never(), [swrveMock sendQueuedEvents]);
}

- (void) testRead_restUserRetryError {
    Swrve *swrveMock = [self swrveMockWithResponseCode:429 inboxUpdateResponseBody:RESPONSE_MODIFED];
    SwrvePushInboxMessage *message = [[swrveMock pushInbox] getPushInboxMessage:1];
    XCTAssertNotNil(message);
    XCTAssertEqual(message.state, SwrvePushInboxMessageStateUNREAD);
    
    id mockInboxDelegate = OCMProtocolMock(@protocol(SwrvePushInboxDelegate));
    [swrveMock readPushInboxMessage:1 listener:mockInboxDelegate];
    
    OCMVerify([mockInboxDelegate onComplete:1 result:[OCMArg checkWithBlock:^BOOL(SwrvePushInboxResult* result) {
        XCTAssertEqual(message.state, SwrvePushInboxMessageStateUNREAD);  // message should remain unread
        return result.resultCode == SwrvePushInboxResultCodeERROR
        && [result.errorMessage isEqualToString:@"Push Inbox Message 1 failed to mark as read. Server response code:429"]
        && result.httpResponseCode == 429;
    }]]);
    
    OCMVerify(never(), [swrveMock sendQueuedEvents]);
}

- (void) testRead_restSuccess {
    Swrve *swrveMock = [self swrveMockWithResponseCode:200 inboxUpdateResponseBody:RESPONSE_MODIFED];
    SwrvePushInboxMessage *message = [[swrveMock pushInbox] getPushInboxMessage:1];
    XCTAssertNotNil(message);
    XCTAssertEqual(message.state, SwrvePushInboxMessageStateUNREAD);
    
    NSMutableDictionary *eventData = [NSMutableDictionary new];
    [eventData setValue:@"11" forKey:@"id"];
    [eventData setValue:@"read" forKey:@"actionType"];
    [eventData setValue:@"push_inbox" forKey:@"campaignType"];
    NSMutableDictionary *payload = [NSMutableDictionary new];
    [payload setValue:@"1" forKey:@"messageId"];
    [eventData setValue:payload forKey:@"payload"];
    
    OCMExpect([swrveMock queueEvent:@"generic_campaign_event" data:eventData triggerCallback:false]);
        
    id mockInboxDelegate = OCMProtocolMock(@protocol(SwrvePushInboxDelegate));
    [swrveMock readPushInboxMessage:1 listener:mockInboxDelegate];
    
    OCMVerify([mockInboxDelegate onComplete:1 result:[OCMArg checkWithBlock:^BOOL(SwrvePushInboxResult* result) {
        XCTAssertEqual(message.state, SwrvePushInboxMessageStateREAD);  // message should now be marked as read
        return result.resultCode == SwrvePushInboxResultCodeSUCCESS
        && [result.errorMessage isEqualToString:@""]
        && result.httpResponseCode == 200;
    }]]);
    
    OCMVerify(times(1), [swrveMock sendQueuedEvents]);
    
    OCMVerifyAllWithDelay(swrveMock, 1);
}

- (void) testRead_restSuccessAlreadyRead {
    Swrve *swrveMock = [self swrveMockWithResponseCode:200 inboxUpdateResponseBody:RESPONSE_UNMODIFED];
    SwrvePushInboxMessage *message = [[swrveMock pushInbox] getPushInboxMessage:2];
    XCTAssertNotNil(message);
    XCTAssertEqual(message.state, SwrvePushInboxMessageStateREAD);
            
    id mockInboxDelegate = OCMProtocolMock(@protocol(SwrvePushInboxDelegate));
    [swrveMock readPushInboxMessage:2 listener:mockInboxDelegate];
    
    OCMVerify([mockInboxDelegate onComplete:2 result:[OCMArg checkWithBlock:^BOOL(SwrvePushInboxResult* result) {
        XCTAssertEqual(message.state, SwrvePushInboxMessageStateREAD);
        return result.resultCode == SwrvePushInboxResultCodeSUCCESS
        && [result.errorMessage isEqualToString:@""]
        && result.httpResponseCode == 200;
    }]]);
    
    // No read event will be queued
    OCMVerify(never(), [swrveMock queueEvent:@"generic_campaign_event" data:OCMOCK_ANY triggerCallback:false]);
    OCMVerify(never(), [swrveMock sendQueuedEvents]);

    OCMVerifyAllWithDelay(swrveMock, 1);
}

- (void) testEngage_restSuccess {
    Swrve *swrveMock = [self swrveMockWithResponseCode:200 inboxUpdateResponseBody:RESPONSE_MODIFED];
    SwrvePushInboxMessage *message = [[swrveMock pushInbox] getPushInboxMessage:1];
    XCTAssertNotNil(message);
    XCTAssertEqual(message.state, SwrvePushInboxMessageStateUNREAD);
        
    //engaged event is sent first
    NSMutableDictionary *firstEvent = [NSMutableDictionary new];
    [firstEvent setValue:@"11" forKey:@"id"];
    [firstEvent setValue:@"engaged" forKey:@"actionType"];
    [firstEvent setValue:@"push_inbox" forKey:@"campaignType"];
    NSMutableDictionary *firstPayload = [NSMutableDictionary new];
    [firstPayload setValue:@"unread" forKey:@"state"];
    [firstPayload setValue:@"1" forKey:@"messageId"];
    [firstEvent setValue:firstPayload forKey:@"payload"];
    
    NSMutableDictionary *secondEvent = [NSMutableDictionary new];
    [secondEvent setValue:@"11" forKey:@"id"];
    [secondEvent setValue:@"read" forKey:@"actionType"];
    [secondEvent setValue:@"push_inbox" forKey:@"campaignType"];
    NSMutableDictionary *secondPayload = [NSMutableDictionary new];
    [secondPayload setValue:@"1" forKey:@"messageId"];
    [secondEvent setValue:secondPayload forKey:@"payload"];
    
    OCMExpect([swrveMock queueEvent:@"generic_campaign_event" data:firstEvent triggerCallback:false]);
    OCMExpect([swrveMock queueEvent:@"generic_campaign_event" data:secondEvent triggerCallback:false]);

    id mockInboxDelegate = OCMProtocolMock(@protocol(SwrvePushInboxDelegate));
    [swrveMock engagePushInboxMessage:1 listener:mockInboxDelegate];
    
    OCMVerify([mockInboxDelegate onComplete:1 result:[OCMArg checkWithBlock:^BOOL(SwrvePushInboxResult* result) {
        XCTAssertEqual(message.state, SwrvePushInboxMessageStateREAD);  // message should now be marked as read
        return result.resultCode == SwrvePushInboxResultCodeSUCCESS
        && [result.errorMessage isEqualToString:@""]
        && result.httpResponseCode == 200;
    }]]);

    OCMVerify(times(2), [swrveMock sendQueuedEvents]);
    
    OCMVerifyAllWithDelay(swrveMock, 1);
}

- (void) testEngage_restSuccessAlreadyRead {
    Swrve *swrveMock = [self swrveMockWithResponseCode:200 inboxUpdateResponseBody:RESPONSE_UNMODIFED];
    SwrvePushInboxMessage *message = [[swrveMock pushInbox] getPushInboxMessage:2];
    XCTAssertNotNil(message);
    XCTAssertEqual(message.state, SwrvePushInboxMessageStateREAD);
        
    //engaged event is only sent
    NSMutableDictionary *eventData = [NSMutableDictionary new];
    [eventData setValue:@"22" forKey:@"id"];
    [eventData setValue:@"engaged" forKey:@"actionType"];
    [eventData setValue:@"push_inbox" forKey:@"campaignType"];
    NSMutableDictionary *payload = [NSMutableDictionary new];
    [payload setValue:@"read" forKey:@"state"];
    [payload setValue:@"2" forKey:@"messageId"];
    [eventData setValue:payload forKey:@"payload"];
        
    OCMExpect([swrveMock queueEvent:@"generic_campaign_event" data:eventData triggerCallback:false]);

    id mockInboxDelegate = OCMProtocolMock(@protocol(SwrvePushInboxDelegate));
    [swrveMock engagePushInboxMessage:2 listener:mockInboxDelegate];
    
    OCMVerify([mockInboxDelegate onComplete:2 result:[OCMArg checkWithBlock:^BOOL(SwrvePushInboxResult* result) {
        XCTAssertEqual(message.state, SwrvePushInboxMessageStateREAD);  // message should now be marked as read
        return result.resultCode == SwrvePushInboxResultCodeSUCCESS
        && [result.errorMessage isEqualToString:@""]
        && result.httpResponseCode == 200;
    }]]);

    OCMVerify(times(1), [swrveMock sendQueuedEvents]);
    
    OCMVerifyAllWithDelay(swrveMock, 1);
}

- (void) testEngage_restFailure {
    
    Swrve *swrveMock = [self swrveMockWithResponseCode:500 inboxUpdateResponseBody:RESPONSE_MODIFED];
    SwrvePushInboxMessage *message = [[swrveMock pushInbox] getPushInboxMessage:1];
    XCTAssertNotNil(message);
    XCTAssertEqual(message.state, SwrvePushInboxMessageStateUNREAD);
    
    NSMutableDictionary *eventData = [NSMutableDictionary new];
    [eventData setValue:@"11" forKey:@"id"];
    [eventData setValue:@"engaged" forKey:@"actionType"];
    [eventData setValue:@"push_inbox" forKey:@"campaignType"];
    NSMutableDictionary *payload = [NSMutableDictionary new];
    [payload setValue:@"unread" forKey:@"state"];
    [payload setValue:@"1" forKey:@"messageId"];
    [eventData setValue:payload forKey:@"payload"];
    
    OCMExpect([swrveMock queueEvent:@"generic_campaign_event" data:eventData triggerCallback:false]);
        
    id mockInboxDelegate = OCMProtocolMock(@protocol(SwrvePushInboxDelegate));
    [swrveMock engagePushInboxMessage:1 listener:mockInboxDelegate];
    
    OCMVerify([mockInboxDelegate onComplete:1 result:[OCMArg checkWithBlock:^BOOL(SwrvePushInboxResult* result) {
        XCTAssertEqual(message.state, SwrvePushInboxMessageStateUNREAD);
        return result.resultCode == SwrvePushInboxResultCodeERROR
        && [result.errorMessage isEqualToString:@"Push Inbox Message 1 failed to mark as read. Server response code:500"]
        && result.httpResponseCode == 500;
    }]]);
    
    OCMVerify(times(1), [swrveMock sendQueuedEvents]);
    //No read event should be sent, only the engaged event, 
    //which is covered by the above check that only 1 event was sent
    
    OCMVerifyAllWithDelay(swrveMock, 1);
}

- (void) testDelete_restSuccess {
    Swrve *swrveMock = [self swrveMockWithResponseCode:200 inboxUpdateResponseBody:RESPONSE_MODIFED];
    SwrvePushInboxMessage *message = [[swrveMock pushInbox] getPushInboxMessage:1];
    XCTAssertNotNil(message);
    
    NSMutableDictionary *eventData = [NSMutableDictionary new];
    [eventData setValue:@"11" forKey:@"id"];
    [eventData setValue:@"delete" forKey:@"actionType"];
    [eventData setValue:@"push_inbox" forKey:@"campaignType"];
    NSMutableDictionary *payload = [NSMutableDictionary new];
    [payload setValue:@"unread" forKey:@"state"];
    [payload setValue:@"1" forKey:@"messageId"];
    [eventData setValue:payload forKey:@"payload"];
    
    OCMExpect([swrveMock queueEvent:@"generic_campaign_event" data:eventData triggerCallback:false]);
    
    id mockInboxDelegate = OCMProtocolMock(@protocol(SwrvePushInboxDelegate));
    [swrveMock deletePushInboxMessage:1 listener:mockInboxDelegate];
    
    OCMVerify([mockInboxDelegate onComplete:1 result:[OCMArg checkWithBlock:^BOOL(SwrvePushInboxResult* result) {
        return result.resultCode == SwrvePushInboxResultCodeSUCCESS
        && [result.errorMessage isEqualToString:@""]
        && result.httpResponseCode == 200;
    }]]);
    
    // message should be deleted
    message = [[swrveMock pushInbox] getPushInboxMessage:1];
    XCTAssertNil(message);
    
    OCMVerify(times(1), [swrveMock sendQueuedEvents]);
    
    OCMVerifyAllWithDelay(swrveMock, 1);
}

- (void)testPushInboxMessages_RestClient {
    Swrve *swrveMock = [self swrveMockWithResponseCode:200 inboxUpdateResponseBody:RESPONSE_MODIFED];
    NSArray* inboxMessages =  [swrveMock pushInboxMessages];
    SwrvePushInboxMessage* message1 = (SwrvePushInboxMessage *)inboxMessages[0];
    
    id mockSwrvePushInboxDelegate = OCMProtocolMock(@protocol(SwrvePushInboxDelegate));
    
    OCMExpect([mockSwrvePushInboxDelegate onComplete:1 result:[OCMArg checkWithBlock:^BOOL(id result) {
        if (![result isKindOfClass:[SwrvePushInboxResult class]]) { return NO; };
        SwrvePushInboxResult* theResult = (SwrvePushInboxResult*)result;
        return theResult.resultCode == SwrvePushInboxResultCodeSUCCESS
                && theResult.httpResponseCode == 200;
    }]]);
    
    [swrveMock readPushInboxMessage:[message1 messageId] listener:mockSwrvePushInboxDelegate]; //U -> R
    
    OCMVerifyAll(mockSwrvePushInboxDelegate);
}

- (void)testPushInboxMessages_RestClient_Retries {
    Swrve *swrveMock = [self swrveMockWithResponseCode:200 inboxUpdateResponseBody:RESPONSE_MODIFED];
    
    // Create a rest client partial mock so the number of calls to sendHttpRequest can be verified
    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
    id mockRestClient = OCMPartialMock(restClient);
    id mockResponse = OCMClassMock([NSHTTPURLResponse class]);
    id mockData = OCMClassMock([NSData class]);
    OCMStub([mockResponse statusCode]).andReturn(500);
    OCMStub([mockRestClient sendHttpRequest:OCMOCK_ANY
                          completionHandler:([OCMArg invokeBlockWithArgs:mockResponse, mockData, [NSNull null], nil])]);

    SwrvePushInboxController *pushInbox = [[SwrvePushInboxController alloc]init:@"userid"
                                                                        baseUrl:@"https://whatever.swrve.com/api/1/push_inbox_update"
                                                                         apiKey:@"apiKey"
                                                                   signatureKey:@"key"
                                                                     restClient:mockRestClient];
    [swrveMock setPushInbox:pushInbox];

    id mockSwrvePushInboxDelegate = OCMProtocolMock(@protocol(SwrvePushInboxDelegate));
    [swrveMock readPushInboxMessage:123 listener:mockSwrvePushInboxDelegate];
    
    OCMVerify(times(3), [mockRestClient sendHttpRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
}

- (void) testInvokePushInboxUpdateDelegate {
    NSString* json = @"{\"push_inbox_hash\": \"test_hash_1\"}";
    NSData *mockData = [json dataUsingEncoding:NSUTF8StringEncoding];
    Swrve *swrveMock = [SwrveTestHelper swrveMockWithMockedRestClientResponseCode:200 mockData:mockData];
    id mockPushInboxDelegate = OCMProtocolMock(@protocol(SwrvePushInboxUpdateDelegate));
    swrveMock = [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey"];
    [swrveMock pushInboxUpdateListener:mockPushInboxDelegate];
    [swrveMock appDidBecomeActive:nil];
    [swrveMock start];
    
    // verify that the delegate is invoked only once
    OCMVerify(times(1), [mockPushInboxDelegate messagesUpdated]);
    
    [swrveMock refreshCampaignsAndResources];
    // even after refresh, the delegate should not invoked again
    OCMVerify(times(1), [mockPushInboxDelegate messagesUpdated]);
    
    //set-up a new rest client, with a hash change, and verify delegate gets called
    json = @"{\"push_inbox_hash\": \"test_hash_2\"}";
    mockData = [json dataUsingEncoding:NSUTF8StringEncoding];
    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
    id mockRestClient = OCMPartialMock(restClient);
    id mockResponse = OCMClassMock([NSHTTPURLResponse class]);
    OCMStub([mockResponse statusCode]).andReturn(200);
    OCMStub([mockRestClient sendHttpRequest:OCMOCK_ANY
                          completionHandler:([OCMArg invokeBlockWithArgs:mockResponse, mockData, [NSNull null], nil])]);
    swrveMock.restClient = mockRestClient;
    
    [swrveMock refreshCampaignsAndResources];
    OCMVerify(times(2), [mockPushInboxDelegate messagesUpdated]);
    
    [swrveMock refreshCampaignsAndResources];
    // even after refresh, the delegate should not invoked again
    OCMVerify(times(2), [mockPushInboxDelegate messagesUpdated]);
}

- (void) testInvokePushInboxUpdateDelegateOnceFirstTime {
    NSString* json = @"{}";
    NSData *mockData = [json dataUsingEncoding:NSUTF8StringEncoding];
    Swrve *swrveMock = [SwrveTestHelper swrveMockWithMockedRestClientResponseCode:200 mockData:mockData];
    id mockPushInboxDelegate = OCMProtocolMock(@protocol(SwrvePushInboxUpdateDelegate));
    swrveMock = [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey"];
    [swrveMock pushInboxUpdateListener:mockPushInboxDelegate];
    [swrveMock appDidBecomeActive:nil];
    [swrveMock start];
    
    OCMVerify(times(1), [mockPushInboxDelegate messagesUpdated]);
}

- (BOOL) compareFirstMessageWithExpected:(NSArray *) inboxMessages {
    SwrvePushInboxMessage *message0 = [inboxMessages objectAtIndex:0];
    XCTAssertEqual(message0.messageId, 1);
    XCTAssertEqual(message0.variantId, 11);
    XCTAssertEqual(message0.endDate, 32515660796000);
    XCTAssertEqual(message0.state, SwrvePushInboxMessageStateUNREAD);
    XCTAssertEqual(message0.sentDate, 1714555770);
    
    NSString *jsonString = @"{\n"
    "        \"title\": \"New Arrivals!\",\n"
    "        \"body\": \"Check out our latest collection of running shoes and activewear. Stay ahead of the game with FitGear's newest arrivals.\"\n"
    "}";
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    
    id customerJson = message0.customerJson;
    XCTAssert([customerJson isKindOfClass:[NSDictionary class]], @"The CustomerJson is not a Json Dictionary Object!");
    XCTAssertTrue([jsonDict isEqualToDictionary:(NSDictionary *)customerJson]);
    return true;
}

- (id)swrveMockWithResponseCode:(int)httpCode inboxUpdateResponseBody:(NSString *)inboxUpdateResponseBody {
    NSData *mockResponseData = [inboxUpdateResponseBody dataUsingEncoding:NSUTF8StringEncoding];
    Swrve *swrveMock = [SwrveTestHelper swrveMockWithMockedRestClientResponseCode:httpCode mockData:mockResponseData];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:572 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop
    [swrveMock appDidBecomeActive:nil];
    
    // set the inbox messages in the cache
    NSString *jsonFile = @"campaigns_push_inbox";
    NSString *filePath = [[NSBundle mainBundle] pathForResource:jsonFile ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockData options:0 error:nil];
    NSArray *inboxJson = [jsonDict objectForKey:@"push_inbox"];
    [[swrveMock pushInbox] updatePushInbox:inboxJson writeToCache:YES];
    return swrveMock;
}


@end

