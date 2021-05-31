#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SwrveSDK.h"
#import "SwrveUtils.h"
#import "SwrveTestHelper.h"
#import "SwrveNotificationConstants.h"

@interface Swrve (Internal)
- (void)appDidBecomeActive:(NSNotification *)notification;
- (NSInteger)nextEventSequenceNumber;
- (void)processNotificationResponseWithIdentifier:(NSString *)identifier andUserInfo:(NSDictionary *)userInfo;
- (void)sendQueuedEventsWithCallback:(void (^)(NSURLResponse *response, NSData *data, NSError *error))eventBufferCallback
                   eventFileCallback:(void (^)(NSURLResponse *response, NSData *data, NSError *error))eventFileCallback;
@property(atomic, readonly) SwrvePush *push;
@property NSMutableArray *eventBuffer;
@end

@interface SwrveTestPushNotifications : XCTestCase {

}
@end

@interface SwrveSDK (InternalAccess)
+ (void)addSharedInstance:(Swrve *)instance;

+ (void)resetSwrveSharedInstance;
@end

@interface Swrve (InternalAccess)
- (BOOL)sdkReady;
@end

@implementation SwrveTestPushNotifications

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

- (void)testPushEngagedEventManagedModeAutoStartFalse {

    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.initMode = SWRVE_INIT_MODE_MANAGED;
    config.autoStartLastUser = false;
    config.pushEnabled = YES;
    config.autoSendEventsOnResume = false;
    config.pushNotificationEvents = nil;

    id classSwrveUtilsMock = OCMClassMock([SwrveUtils class]);
    OCMStub(ClassMethod([classSwrveUtilsMock getTimeEpoch])).andReturn(987654321);

    id swrveMockManaged = [SwrveTestHelper swrveMockWithMockedRestClient];
    [SwrveSDK addSharedInstance:swrveMockManaged];
    [SwrveCommon addSharedInstance:swrveMockManaged];
    OCMStub([swrveMockManaged nextEventSequenceNumber]).andReturn(456);

    // expect engaged event to be added to eventBuffer queue
    id eventBufferMock = OCMPartialMock([NSMutableArray array]);
    [self expectEngagedEvent:swrveMockManaged inBuffer:eventBufferMock withPushId:@"1111"];
    OCMExpect([swrveMockManaged sendQueuedEventsWithCallback:nil eventFileCallback:nil]);

    [SwrveSDK sendPushEngagedEvent:@"1111"];

    OCMVerifyAll(eventBufferMock);
    OCMVerifyAll(swrveMockManaged);
}

- (void)testPushEngagedEventManagedModeInManagedMode {

    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.initMode = SWRVE_INIT_MODE_MANAGED;
    config.pushEnabled = YES;
    config.autoSendEventsOnResume = false;
    config.pushNotificationEvents = nil;

    id classSwrveUtilsMock = OCMClassMock([SwrveUtils class]);
    OCMStub(ClassMethod([classSwrveUtilsMock getTimeEpoch])).andReturn(987654321);

    id swrveMockManaged = [SwrveTestHelper swrveMockWithMockedRestClient];
    [SwrveSDK addSharedInstance:swrveMockManaged];
    [SwrveCommon addSharedInstance:swrveMockManaged];
    OCMStub([swrveMockManaged nextEventSequenceNumber]).andReturn(456);

    // expect engaged event to be added to eventBuffer queue
    id eventBufferMock = OCMPartialMock([NSMutableArray array]);
    [self expectEngagedEvent:swrveMockManaged inBuffer:eventBufferMock withPushId:@"1111"];
    OCMExpect([swrveMockManaged sendQueuedEventsWithCallback:nil eventFileCallback:nil]);

    [SwrveSDK sendPushEngagedEvent:@"1111"];

    OCMVerifyAll(eventBufferMock);
    OCMVerifyAll(swrveMockManaged);
}


- (void)testPushNotificationReceivedEvent {

    id mockApplication = [self mockApplicationStateWith:UIApplicationStateBackground];

    [SwrveSDK resetSwrveSharedInstance];
    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.pushEnabled = YES;
    config.autoSendEventsOnResume = false;
    config.pushNotificationEvents = nil;

    id classSwrveUtilsMock = OCMClassMock([SwrveUtils class]);
    OCMStub(ClassMethod([classSwrveUtilsMock getTimeEpoch])).andReturn(987654321);

    Swrve *swrveMock = [SwrveTestHelper swrveMockWithMockedRestClient];
    [SwrveSDK addSharedInstance:swrveMock];
    OCMStub([swrveMock nextEventSequenceNumber]).andReturn(456);
    swrveMock = [swrveMock initWithAppID:123 apiKey:@"456" config:config];
    [swrveMock appDidBecomeActive:nil];

    // expect engaged event to be added to eventBuffer queue
    id eventBufferMock = OCMPartialMock([NSMutableArray array]);
    [self expectEngagedEvent:swrveMock inBuffer:eventBufferMock withPushId:@"1"];

    // engage the push
    SwrvePush *puskSDK = [swrveMock push];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"_p", nil];
    UNNotification *notification = [self unNotificationWithUserInfo:userInfo andIdentifer:@"com.apple.UNNotificationDefaultActionIdentifier"];
    UNNotificationResponse *notificationResponse = [UNNotificationResponse alloc];
    [notificationResponse setValue:notification forKeyPath:@"notification"];
    [notificationResponse setValue:@"com.apple.UNNotificationDefaultActionIdentifier" forKeyPath:@"actionIdentifier"];
    void (^fakeCompletion)(void);
    [puskSDK userNotificationCenter:[UNUserNotificationCenter currentNotificationCenter]
     didReceiveNotificationResponse:notificationResponse withCompletionHandler:fakeCompletion];

    OCMVerifyAll(eventBufferMock);
    [mockApplication stopMocking];
}

- (void)testPushNotificationReceivedEventNSString {
    id mockApplication = [self mockApplicationStateWith:UIApplicationStateBackground];

    Swrve *swrveMock = [self swrveMockWithPushAndStubs];

    // expect engaged event to be added to eventBuffer queue
    id eventBufferMock = OCMPartialMock([NSMutableArray array]);
    [self expectEngagedEvent:swrveMock inBuffer:eventBufferMock withPushId:@"2"];

    // no buttons payload so pass SwrveNotificationResponseDefaultActionKey
    [swrveMock processNotificationResponseWithIdentifier:SwrveNotificationResponseDefaultActionKey andUserInfo:@{@"_p": @"2"}];

    OCMVerifyAll(eventBufferMock);
    [mockApplication stopMocking];
}

- (void)testPushNotificationReceivedMultipleTimes {
    id mockApplication = [self mockApplicationStateWith:UIApplicationStateBackground];

    Swrve *swrveMock = [self swrveMockWithPushAndStubs];

    // expect 2 engaged event to be added to eventBuffer queue
    id eventBufferMock = OCMPartialMock([NSMutableArray array]);
    [self expectEngagedEvent:swrveMock inBuffer:eventBufferMock withPushId:@"3"];
    [self expectEngagedEvent:swrveMock inBuffer:eventBufferMock withPushId:@"4"];

    // no buttons payload so pass SwrveNotificationResponseDefaultActionKey
    [swrveMock processNotificationResponseWithIdentifier:SwrveNotificationResponseDefaultActionKey andUserInfo:@{@"_p": @"3"}];
    [swrveMock processNotificationResponseWithIdentifier:SwrveNotificationResponseDefaultActionKey andUserInfo:@{@"_p": @"4"}];

    OCMVerifyAll(eventBufferMock);
    [mockApplication stopMocking];
}

- (void)testPushNotificationResponseReceivedWithDeeplink {
    id mockApplication = [self mockApplicationStateWith:UIApplicationStateBackground];

    /** Tell the mockApplication to listen for calls to openURL. Test fails if it's not called **/
    OCMExpect([mockApplication openURL:OCMOCK_ANY options:OCMOCK_ANY completionHandler:OCMOCK_ANY]);

    Swrve *swrveMock = [self swrveMockWithPushAndStubs];

    // expect engaged event and generic to be added to eventBuffer queue
    id eventBufferMock = OCMPartialMock([NSMutableArray array]);
    [self expectEngagedEvent:swrveMock inBuffer:eventBufferMock withPushId:@"5"];
    [self expectGenericEventButtonClick:swrveMock inBuffer:eventBufferMock withPushId:@"5" contextId:@"0" buttonText:@"btn1"];
    OCMExpect([mockApplication canOpenURL:OCMOCK_ANY]).andReturn(YES);

    NSDictionary *userInfo = @{
            @"_p": @"5",
            @"_sw": @{
                    @"media": @{
                            @"title": @"rich_title",
                            @"body": @"rich_body",
                            @"subtitle": @"rich_subtitle"
                    },
                    @"buttons": @[@{
                            @"title": @"btn1",
                            @"button_type": @[@"foreground"],
                            @"action_type": @"open_url",
                            @"action": @"oldprotocol://custom"
                    }],
            }
    };
    [swrveMock processNotificationResponseWithIdentifier:@"0" andUserInfo:userInfo];

    OCMVerifyAll(eventBufferMock);
    OCMVerifyAll(mockApplication);
    [mockApplication stopMocking];
}


- (void)testPushNotificationResponseReceivedWithDefaultAction {
    /** This test is ensure that a regular event occurs when a push is directly clicked **/
    id mockApplication = [self mockApplicationStateWith:UIApplicationStateBackground];

    Swrve *swrveMock = [self swrveMockWithPushAndStubs];

    // expect only one engaged event to be added to eventBuffer queue
    id eventBufferMock = OCMPartialMock([NSMutableArray array]);
    [swrveMock setEventBuffer:eventBufferMock];
    __block int callCount = 0;
    OCMStub([eventBufferMock addObject:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        ++callCount;
    });

    NSDictionary *userInfo = @{
            @"_p": @"6",
            @"_sw": @{
                    @"media": @{
                            @"title": @"rich_title",
                            @"body": @"rich_body",
                            @"subtitle": @"rich_subtitle"
                    },
                    @"buttons": @[@{
                            @"title": @"btn1",
                            @"button_type": @[@"foreground"],
                            @"action_type": @"open_url",
                            @"action": @"oldprotocol://custom"
                    }],
            }
    };
    [swrveMock processNotificationResponseWithIdentifier:SwrveNotificationResponseDefaultActionKey andUserInfo:userInfo];

    XCTAssertEqual(callCount, 1);
    OCMVerifyAll(eventBufferMock);
    OCMVerifyAll(mockApplication);
    [mockApplication stopMocking];
}

- (void)testPushNotificationResponseReceivedWithDismiss {
    id mockApplication = [self mockApplicationStateWith:UIApplicationStateBackground];

    Swrve *swrveMock = [self swrveMockWithPushAndStubs];

    // expect engaged event and generic to be added to eventBuffer queue
    id eventBufferMock = OCMPartialMock([NSMutableArray array]);
    [self expectEngagedEvent:swrveMock inBuffer:eventBufferMock withPushId:@"7"];
    [self expectGenericEventButtonClick:swrveMock inBuffer:eventBufferMock withPushId:@"7" contextId:@"1" buttonText:@"btn2"];

    NSDictionary *userInfo = @{
            @"_p": @"7",
            @"_sw": @{
                    @"media": @{
                            @"title": @"rich_title",
                            @"body": @"rich_body",
                            @"subtitle": @"rich_subtitle"
                    },
                    @"buttons": @[@{
                            @"title": @"btn1",
                            @"button_type": @[@"foreground"],
                            @"action_type": @"open_url",
                            @"action": @"oldprotocol://custom"
                    },
                            @{
                                    @"title": @"btn2",
                                    @"action_type": @"dismiss",
                            },
                            @{
                                    @"title": @"btn3",
                                    @"button_type": @[@"foreground"],
                                    @"action_type": @"open_app",
                            }
                    ],
            }
    };
    [swrveMock processNotificationResponseWithIdentifier:@"1" andUserInfo:userInfo];

    OCMVerifyAll(eventBufferMock);
    OCMVerifyAll(mockApplication);
    [mockApplication stopMocking];
}

- (void)testPushNotificationResponseReceivedWithOpenApp {
    id mockApplication = [self mockApplicationStateWith:UIApplicationStateBackground];

    Swrve *swrveMock = [self swrveMockWithPushAndStubs];

    // expect engaged event and generic to be added to eventBuffer queue
    id eventBufferMock = OCMPartialMock([NSMutableArray array]);
    [self expectEngagedEvent:swrveMock inBuffer:eventBufferMock withPushId:@"8"];
    [self expectGenericEventButtonClick:swrveMock inBuffer:eventBufferMock withPushId:@"8" contextId:@"2" buttonText:@"btn3"];

    NSDictionary *userInfo = @{
            @"_p": @"8",
            @"_sw": @{
                    @"media": @{
                            @"title": @"rich_title",
                            @"body": @"rich_body",
                            @"subtitle": @"rich_subtitle"
                    },
                    @"buttons": @[@{
                            @"title": @"btn1",
                            @"button_type": @[@"foreground"],
                            @"action_type": @"open_url",
                            @"action": @"oldprotocol://custom"
                    },
                            @{
                                    @"title": @"btn2",
                                    @"action_type": @"dismiss",
                            },
                            @{
                                    @"title": @"btn3",
                                    @"button_type": @[@"foreground"],
                                    @"action_type": @"open_app",
                            }
                    ],
            }
    };
    [swrveMock processNotificationResponseWithIdentifier:@"2" andUserInfo:userInfo];

    OCMVerifyAll(eventBufferMock);
    OCMVerifyAll(mockApplication);
    [mockApplication stopMocking];
}

- (void)testSamePushReceivedOnlyProcessedOnce {
    id mockApplication = [self mockApplicationStateWith:UIApplicationStateBackground];

    Swrve *swrveMock = [self swrveMockWithPushAndStubs];

    // expect only one engaged event to be added to eventBuffer queue
    id eventBufferMock = OCMPartialMock([NSMutableArray array]);
    [swrveMock setEventBuffer:eventBufferMock];
    __block int callCount = 0;
    OCMStub([eventBufferMock addObject:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        ++callCount;
    });

    // no buttons payload so pass SwrveNotificationResponseDefaultActionKey
    [swrveMock processNotificationResponseWithIdentifier:SwrveNotificationResponseDefaultActionKey andUserInfo:@{@"_p": @"9"}];
    [swrveMock processNotificationResponseWithIdentifier:SwrveNotificationResponseDefaultActionKey andUserInfo:@{@"_p": @"9"}];

    XCTAssertEqual(callCount, 1);
    OCMVerifyAll(eventBufferMock);
    OCMVerifyAll(mockApplication);
    [mockApplication stopMocking];
}


/*
 * HELPER METHODS BELOW
 */

- (Swrve *)swrveMockWithPushAndStubs {
    [SwrveSDK resetSwrveSharedInstance];
    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.pushEnabled = YES;
    config.autoSendEventsOnResume = false;
    config.pushNotificationEvents = nil;

    id classSwrveUtilsMock = OCMClassMock([SwrveUtils class]);
    OCMStub(ClassMethod([classSwrveUtilsMock getTimeEpoch])).andReturn(987654321);

    id swrveMock = [SwrveTestHelper swrveMockWithMockedRestClient];
    [SwrveSDK addSharedInstance:swrveMock];
    [SwrveCommon addSharedInstance:swrveMock];
    OCMStub([swrveMock nextEventSequenceNumber]).andReturn(456);
    return swrveMock;
}

- (void)expectEngagedEvent:(Swrve *)swrveMock inBuffer:(id)eventBufferMock withPushId:(NSString *)pushId {
    // expect engaged event to be added to eventBuffer queue
    [swrveMock setEventBuffer:eventBufferMock];
    NSString *expectedEvent = @"{\"payload\":{},\"seqnum\":456,\"name\":\"Swrve.Messages.Push-";
    expectedEvent = [expectedEvent stringByAppendingString:pushId];
    expectedEvent = [expectedEvent stringByAppendingString:@".engaged\",\"type\":\"event\",\"time\":"];
    expectedEvent = [expectedEvent stringByAppendingString:@"987654321"];
    expectedEvent = [expectedEvent stringByAppendingString:@"}"];
    OCMExpect([eventBufferMock addObject:expectedEvent]).andForwardToRealObject();
}

- (void)expectGenericEventButtonClick:(Swrve *)swrveMock inBuffer:(id)eventBufferMock withPushId:(NSString *)pushId contextId:(NSString *)contextId buttonText:(NSString *)buttonText {
    // expect generic button click event to be added to eventBuffer queue
    [swrveMock setEventBuffer:eventBufferMock];
    NSString *expectedEvent = @"{\"actionType\":\"button_click\",\"campaignType\":\"push\",\"time\":";
    expectedEvent = [expectedEvent stringByAppendingString:@"987654321"];
    expectedEvent = [expectedEvent stringByAppendingString:@",\"id\":\""];
    expectedEvent = [expectedEvent stringByAppendingString:pushId];
    expectedEvent = [expectedEvent stringByAppendingString:@"\",\"seqnum\":456,\"contextId\":\""];
    expectedEvent = [expectedEvent stringByAppendingString:contextId];
    expectedEvent = [expectedEvent stringByAppendingString:@"\",\"payload\":{\"buttonText\":\""];
    expectedEvent = [expectedEvent stringByAppendingString:buttonText];
    expectedEvent = [expectedEvent stringByAppendingString:@"\"},\"type\":\"generic_campaign_event\"}"];
    OCMExpect([eventBufferMock addObject:expectedEvent]).andForwardToRealObject();
}

- (UNNotification *)unNotificationWithUserInfo:(NSDictionary *)userInfo andIdentifer:(NSString *)identifier {
    UNNotificationContent *unNotificationContent = [UNNotificationContent alloc];
    [unNotificationContent setValue:userInfo forKey:@"userInfo"];

    UNNotificationRequest *unNotificationRequest = [UNNotificationRequest alloc];
    [unNotificationRequest setValue:unNotificationContent forKeyPath:@"content"];
    [unNotificationRequest setValue:identifier forKeyPath:@"identifier"];

    UNNotification *unNotification = [UNNotification alloc];
    [unNotification setValue:unNotificationRequest forKeyPath:@"request"];

    return unNotification;
}

- (id)mockApplicationStateWith:(UIApplicationState)uiApplicationState {
    id mockApplication = OCMPartialMock([UIApplication sharedApplication]);
    OCMStub([mockApplication applicationState]).andReturn(uiApplicationState);
    // We have gotten failures in the form of "[UIApplication statusBarOrientation]: unrecognized selector sent to instance" so lets try and always mock it
    OCMStub([mockApplication statusBarOrientation]).andReturn(UIInterfaceOrientationPortrait);
    return mockApplication;
}

@end
