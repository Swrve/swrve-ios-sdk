#import <XCTest/XCTest.h>
#import "SwrvePush.h"
#import "SwrveTestHelper.h"
#import "AppDelegate.h"
#import "SwrveEmpty.h"
#import "TestableSwrve.h"
#import "SwrveCampaignInfluence.h"
#import "SwrveNotificationConstants.h"
#import "SwrveNotificationManager.h"

#import <OCMock/OCMock.h>

@interface SwrveNotificationManager (InternalAccess)
+ (void)downloadAttachment:(NSString *)mediaUrl withCompletedContentCallback:(void (^)(UNNotificationAttachment *attachment, NSError *error))callback;
+ (void)updateLastProcessedPushId:(NSString *)pushId;
+ (void)sendEngagedEventForNotificationId:(NSString *)notificationId andUserInfo:(NSDictionary *)userInfo;
@end


#if TARGET_OS_IOS
@interface SwrvePush (SwrvePushInternalAccess)

+ (SwrvePush *)sharedInstance;
+ (SwrvePush *)sharedInstanceWithPushDelegate:(id<SwrvePushDelegate>) pushDelegate andCommonDelegate:(id<SwrveCommonDelegate>) commonDelegate;
+ (void)resetSharedInstance;

- (void)setCommonDelegate:(id<SwrveCommonDelegate>) commonDelegate;
- (void)setPushDelegate:(id<SwrvePushDelegate>) pushDelegate;
- (void)setResponseDelegate:(id<SwrvePushResponseDelegate>) responseDelegate;

- (void)registerForPushNotifications;
- (BOOL)observeSwizzling;
- (void)deswizzlePushMethods;

- (void)setPushNotificationsDeviceToken:(NSData *) newDeviceToken;
- (BOOL)didReceiveRemoteNotification:(NSDictionary *)userInfo withBackgroundCompletionHandler:(void (^)(UIBackgroundFetchResult, NSDictionary*))completionHandler;

@end
#endif //TARGET_OS_IOS

@interface SwrveTestSwrvePushSDK : XCTestCase <SwrvePushDelegate, SwrvePushResponseDelegate>
{
    SwrvePush *_pushSDK;
    BOOL _callbackInvoked;
    XCTestExpectation *swizzlerInvokedExpectation;
    XCTestExpectation *swizzlerRemoteNotificationInvokedExpectation;
    XCTestExpectation *pushDelegateInvokedExpectation;
    AppDelegate* target;
    SwrveEmpty* swrveEmpty;
    BOOL isSwizzling;
}
@end

@implementation SwrveTestSwrvePushSDK

- (void)setUp {
    [super setUp];
    swrveEmpty = OCMClassMock([SwrveEmpty class]);
    _pushSDK = [SwrvePush sharedInstance];
    [_pushSDK setPushDelegate:self];
    [_pushSDK setCommonDelegate:(id <SwrveCommonDelegate>)swrveEmpty];
    _callbackInvoked = NO;
    target = (AppDelegate *)[UIApplication sharedApplication].delegate;
    isSwizzling = [_pushSDK observeSwizzling];
    [SwrveNotificationManager updateLastProcessedPushId:@""];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [_pushSDK deswizzlePushMethods];
    [SwrvePush resetSharedInstance];
    swrveEmpty = nil;
    _callbackInvoked = NO;
    target = nil;
    swizzlerInvokedExpectation = nil;
    swizzlerRemoteNotificationInvokedExpectation = nil;
    [super tearDown];
}

- (void)testPushSDKSharedInstance {
    SwrvePush *otherPush = [SwrvePush sharedInstance];
    XCTAssertEqual(otherPush, _pushSDK);
}

- (void) testDeviceTokenUpdated {
    [_pushSDK setPushNotificationsDeviceToken:[@"fake_token" dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void) testPushEngagementEventIncoming {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"_p", @"protocol://custom", @"_sd", @"oldprotocol://custom", @"_d", nil];
    [SwrveNotificationManager notificationResponseReceived:@"1" withUserInfo:userInfo];
    // TODO there are no assertions on this test!?!
}

- (void) testDeviceTokenIncomingFromSwizzling {
    swizzlerInvokedExpectation = [self expectationWithDescription:@"swizzling called [SwrvePuskSDK didRegisterForRemoteNotificationsWithDeviceToken]"];
    //package and produce an error
    NSData* fakeToken = [@"fake_token" dataUsingEncoding:NSUTF8StringEncoding];
    [target application:[UIApplication sharedApplication] didRegisterForRemoteNotificationsWithDeviceToken:fakeToken];
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        self->swizzlerInvokedExpectation = nil;
        if (error) {
            NSLog(@"deviceTokenIncoming: did not fire %@", error);
        }
        XCTAssertTrue(self->_callbackInvoked);
    }];
}

- (void) testRegistrationErrorFromSwizzling {
    XCTAssertTrue(isSwizzling);
    NSError* fakeError = [NSError errorWithDomain:@"SwrvePushSDK" code:100 userInfo:nil];
    // Invoke did register for notification
    [target application:[UIApplication sharedApplication] didFailToRegisterForRemoteNotificationsWithError:fakeError];
    XCTAssertEqualObjects(target.swizzleError, fakeError);
}

#pragma mark - Test Public Facing Service Extension Method

- (void)testHandleNotiificationContent_WrongVersion {
    XCTestExpectation *expectation = [self expectationWithDescription:@"[SwrvePush testHandleNotiificationContent: Success]"];

    NSDictionary* mediaLayer = @{SwrveNotificationTitleKey:@"rich_title", SwrveNotificationSubtitleKey:@"rich_subtitle", SwrveNotificationBodyKey:@"rich_body"};
    NSDictionary* sw = @{SwrveNotificationMediaKey:mediaLayer, SwrveNotificationContentVersionKey:[NSString stringWithFormat:@"%d", SwrveNotificationContentVersion + 1]};
    NSDictionary *userInfo = @{SwrveNotificationIdentifierKey : @"1", SwrveInfluencedWindowMinsKey: @"12", SwrveNotificationContentIdentifierKey : sw};

    UNNotificationContent *content = [self createTestNotificationContentWithUserInfo:userInfo];

    [SwrvePush handleNotificationContent:content withAppGroupIdentifier:nil withCompletedContentCallback:^(UNMutableNotificationContent * content) {
        XCTAssertEqualObjects(content.title, @"test_title");
        XCTAssertEqualObjects(content.subtitle, @"test_subtitle");
        XCTAssertEqualObjects(content.body, @"test_body");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];

    /** Check if influenced has been written , even with failed version**/
    NSDictionary *influnencedData = [[NSUserDefaults standardUserDefaults] objectForKey:SwrveInfluenceDataKey];
    XCTAssertNil(influnencedData, @"influenced data should be nil if the version is wrong");
}

- (void)testHandleNotiificationContent_invalidPushIdentifier {
    XCTestExpectation *expectation = [self expectationWithDescription:@"[SwrveNotification testHandleNotiificationContent: Success]"];

    NSDictionary* mediaLayer = @{SwrveNotificationTitleKey:@"rich_title", SwrveNotificationSubtitleKey:@"rich_subtitle", SwrveNotificationBodyKey:@"rich_body"};
    NSDictionary* sw = @{SwrveNotificationMediaKey:mediaLayer, SwrveNotificationContentVersionKey:[NSString stringWithFormat:@"%d", SwrveNotificationContentVersion]};
    NSDictionary *userInfo = @{SwrveNotificationIdentifierKey : @{@"hello!": @"dictionary!"}, SwrveInfluencedWindowMinsKey: @"12", SwrveNotificationContentIdentifierKey : sw};

    UNNotificationContent *content = [self createTestNotificationContentWithUserInfo:userInfo];

    [SwrvePush handleNotificationContent:content withAppGroupIdentifier:nil withCompletedContentCallback:^(UNMutableNotificationContent * content) {
        XCTAssertEqualObjects(content.title, @"test_title");
        XCTAssertEqualObjects(content.subtitle, @"test_subtitle");
        XCTAssertEqualObjects(content.body, @"test_body");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];

    /** influence data should not be written to **/
    NSDictionary *influnencedData = [[NSUserDefaults standardUserDefaults] objectForKey:SwrveInfluenceDataKey];
    XCTAssertNil(influnencedData, @"influenced data should be nil");
}

- (void)testHandleNotiificationContent_SuccessText {
    XCTestExpectation *expectation = [self expectationWithDescription:@"[SwrvePush testHandleNotiificationContent: Success]"];

    NSDictionary* mediaLayer = @{SwrveNotificationTitleKey:@"rich_title", SwrveNotificationSubtitleKey:@"rich_subtitle", SwrveNotificationBodyKey:@"rich_body"};
    NSDictionary* sw = @{SwrveNotificationMediaKey:mediaLayer, SwrveNotificationContentVersionKey:[NSString stringWithFormat:@"%d", SwrveNotificationContentVersion]};
    NSDictionary *userInfo = @{SwrveNotificationIdentifierKey : @"1", SwrveInfluencedWindowMinsKey: @"12", SwrveNotificationContentIdentifierKey : sw};

    UNNotificationContent *content = [self createTestNotificationContentWithUserInfo:userInfo];

    [SwrvePush handleNotificationContent:content withAppGroupIdentifier:nil withCompletedContentCallback:^(UNMutableNotificationContent * content) {
        // There was no image shown, so we keep the default text
        XCTAssertEqual(content.title, @"test_title");
        XCTAssertEqual(content.subtitle, @"test_subtitle");
        XCTAssertEqual(content.body, @"test_body");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];

    /** Check if influenced has been written **/
    NSDictionary *influnencedData = [[NSUserDefaults standardUserDefaults] objectForKey:SwrveInfluenceDataKey];
    XCTAssertNotNil(influnencedData, @"influenced data with the correct credentials should not be nil");
}

- (void)testHandleNotiificationContent_FallbackText {
    XCTestExpectation *expectation = [self expectationWithDescription:@"[SwrvePush testHandleNotiificationContent: fallbackText]"];

    NSDictionary* mediaLayer = @{SwrveNotificationTitleKey:@"rich_title", SwrveNotificationSubtitleKey:@"rich_subtitle", SwrveNotificationBodyKey:@"rich_body", SwrveNotificationUrlKey:@"https://secure-and-right-url/test-image.png"};
    NSDictionary* sw = @{SwrveNotificationMediaKey:mediaLayer, SwrveNotificationContentVersionKey:[NSString stringWithFormat:@"%d", SwrveNotificationContentVersion]};
    NSDictionary *userInfo = @{SwrveNotificationIdentifierKey : @"1", SwrveInfluencedWindowMinsKey: @"12", SwrveNotificationContentIdentifierKey : sw};

    UNNotificationContent *content = [self createTestNotificationContentWithUserInfo:userInfo];

    id mediaHelperMock = OCMClassMock([SwrveNotificationManager class]);
    OCMExpect([mediaHelperMock downloadAttachment:OCMOCK_ANY withCompletedContentCallback:OCMOCK_ANY]).andDo(^(NSInvocation *invoke) {

        void (^withCompletedContentCallback)(UNNotificationAttachment *attachment, NSError *error);
        //deliberately retun no attachement indicating a failure.
        UNNotificationAttachment *attachment = nil;
        NSError *mockedError = nil;
        [invoke getArgument:&withCompletedContentCallback atIndex:3];
        withCompletedContentCallback(attachment, mockedError);

    });

    [SwrvePush handleNotificationContent:content withAppGroupIdentifier:nil withCompletedContentCallback:^(UNMutableNotificationContent * content) {
        XCTAssertEqual(content.title, @"test_title");
        XCTAssertEqual(content.subtitle, @"test_subtitle");
        XCTAssertEqual(content.body, @"test_body");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];

    /** Check if influenced has been written **/
    NSDictionary *influnencedData = [[NSUserDefaults standardUserDefaults] objectForKey:SwrveInfluenceDataKey];
    XCTAssertNotNil(influnencedData, @"influenced data with the correct credentials should not be nil");

    OCMVerifyAll(mediaHelperMock);
    [mediaHelperMock stopMocking];
}

- (void)testHandleNotiificationContent_SuccessMedia {
    XCTestExpectation *expectation = [self expectationWithDescription:@"[SwrvePush testHandleNotiificationContent: Success]"];

    NSDictionary* mediaLayer = @{SwrveNotificationTitleKey:@"rich_title", SwrveNotificationSubtitleKey:@"rich_subtitle", SwrveNotificationBodyKey:@"rich_body", SwrveNotificationUrlKey:@"https://secure-and-right-url/test-image.png"};
    NSDictionary* sw = @{SwrveNotificationMediaKey:mediaLayer, SwrveNotificationContentVersionKey:[NSString stringWithFormat:@"%d", SwrveNotificationContentVersion]};
    NSDictionary *userInfo = @{SwrveNotificationIdentifierKey : @"1", SwrveInfluencedWindowMinsKey: @"12", SwrveNotificationContentIdentifierKey : sw};

    UNNotificationContent *content = [self createTestNotificationContentWithUserInfo:userInfo];

    id mediaHelperMock = OCMClassMock([SwrveNotificationManager class]);
    OCMStub([mediaHelperMock downloadAttachment:OCMOCK_ANY withCompletedContentCallback:OCMOCK_ANY]).andDo(^(NSInvocation *invoke) {

        void (^withCompletedContentCallback)(UNNotificationAttachment *attachment, NSError *error);
        UNNotificationAttachment *attachment = [self createTestAttachmentWithFileName:@"swrve_logo" andExtension:@"png"];
        NSError *mockedError = nil;
        [invoke getArgument:&withCompletedContentCallback atIndex:3];
        withCompletedContentCallback(attachment, mockedError);

    });

    [SwrvePush handleNotificationContent:content withAppGroupIdentifier:nil withCompletedContentCallback:^(UNMutableNotificationContent * content) {
        XCTAssertNotNil(content.attachments);
        XCTAssertEqualObjects(content.title, @"rich_title");
        XCTAssertEqualObjects(content.subtitle, @"rich_subtitle");
        XCTAssertEqualObjects(content.body, @"rich_body");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];

    /** Check if influenced has been written **/
    NSDictionary *influnencedData = [[NSUserDefaults standardUserDefaults] objectForKey:SwrveInfluenceDataKey];
    XCTAssertNotNil(influnencedData, @"influenced data with the correct credentials should not be nil");

    [mediaHelperMock stopMocking];
}

- (void)testHandleNotiificationContent_FallbackMedia {
    XCTestExpectation *expectation = [self expectationWithDescription:@"[SwrvePush testHandleNotiificationContent: fallback Media]"];

    NSDictionary* mediaLayer = @{SwrveNotificationTitleKey:@"rich_title", SwrveNotificationSubtitleKey:@"rich_subtitle", SwrveNotificationBodyKey:@"rich_body", SwrveNotificationUrlKey:@"https://FAILME.png", SwrveNotificationFallbackUrlKey:@"https://www.doesntmattergunnamock/swrve_logo.png"};
    NSDictionary* sw = @{SwrveNotificationMediaKey:mediaLayer, SwrveNotificationContentVersionKey:[NSString stringWithFormat:@"%d", SwrveNotificationContentVersion]};
    NSDictionary *userInfo = @{SwrveNotificationIdentifierKey : @"0", SwrveInfluencedWindowMinsKey: @"12", SwrveNotificationContentIdentifierKey : sw};

    /** set up mocking **/
    id passingMediaHelperMock = OCMClassMock([SwrveNotificationManager class]);
    OCMStub([passingMediaHelperMock downloadAttachment:@"https://www.doesntmattergunnamock/swrve_logo.png" withCompletedContentCallback:OCMOCK_ANY]).andDo(^(NSInvocation *invoke) {

        void (^withCompletedContentCallback)(UNNotificationAttachment *attachment, NSError *error);
        UNNotificationAttachment *attachment = [self createTestAttachmentWithFileName:@"swrve_logo" andExtension:@"png"];
        NSError *mockedError = nil;
        [invoke getArgument:&withCompletedContentCallback atIndex:3];
        withCompletedContentCallback(attachment, mockedError);

    });

    UNNotificationContent *content = [self createTestNotificationContentWithUserInfo:userInfo];
    [SwrvePush handleNotificationContent:content withAppGroupIdentifier:nil withCompletedContentCallback:^(UNMutableNotificationContent * content) {
        XCTAssertNotNil(content.attachments);
        XCTAssertEqualObjects(content.title, @"rich_title");
        XCTAssertEqualObjects(content.subtitle, @"rich_subtitle");
        XCTAssertEqualObjects(content.body, @"rich_body");
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];

    /** Check if influenced has been written **/
    NSDictionary *influencedData = [[NSUserDefaults standardUserDefaults] objectForKey:SwrveInfluenceDataKey];
    XCTAssertNotNil(influencedData, @"influenced data with the correct credentials should not be nil");

    // Cleanup
    OCMVerifyAll(passingMediaHelperMock);
    [passingMediaHelperMock stopMocking];
}

- (void)testPushNotificationResponseRecievedWithUrlAction {
    id mockApplication = [self mockApplicationStateWith:UIApplicationStateBackground];

    //Put something in the influencedData to be emptied

    NSDictionary *influenceDict = @{@"1":@"8787042243", @"33": @"3343445"};
    [[NSUserDefaults standardUserDefaults] setValue:influenceDict forKey:SwrveInfluenceDataKey];

    // Put something else in to ensure that the influencedData is the only thing emptied
    [[NSUserDefaults standardUserDefaults] setValue:@"STUFF" forKey:@"other-item"];

    // Check that the field passed makes it to the delegate method
    OCMExpect([mockApplication canOpenURL:OCMOCK_ANY]).andReturn(YES);    

    NSDictionary* mediaLayer = @{SwrveNotificationTitleKey:@"rich_title", SwrveNotificationSubtitleKey:@"rich_subtitle", SwrveNotificationBodyKey:@"rich_body", SwrveNotificationUrlKey:@"https://FAILME.png", SwrveNotificationFallbackUrlKey:@"https://www.doesntmattergunnamock/swrve_logo.png"};
    NSArray<NSDictionary*>* buttonlayer = @[@{SwrveNotificationButtonTitleKey:@"btn1", SwrveNotificationButtonTypeKey:@[@"foreground"],
                                              SwrveNotificationButtonActionTypeKey:@"open_url", SwrveNotificationButtonActionKey:@"protocol://custom"}];
    NSDictionary* sw = @{SwrveNotificationMediaKey:mediaLayer, SwrveNotificationButtonListKey:buttonlayer, SwrveNotificationContentVersionKey:[NSString stringWithFormat:@"%d", SwrveNotificationContentVersion]};
    NSDictionary* userInfo = @{SwrveNotificationIdentifierKey: @"1", SwrveNotificationContentIdentifierKey: sw};
    [SwrveNotificationManager notificationResponseReceived:@"0" withUserInfo:userInfo];

    /** Check if influenced has been cleared **/
    NSDictionary *influnencedData = [[NSUserDefaults standardUserDefaults] objectForKey:SwrveInfluenceDataKey];
    XCTAssertNil([influnencedData objectForKey:@"1"]);
    XCTAssertNotNil([influnencedData objectForKey:@"33"]);

    NSString *otherData = [[NSUserDefaults standardUserDefaults] objectForKey:@"other-item"];
    XCTAssertNotNil(otherData, @"only influenced data should be wiped from the NSUserDefault");

    // Cleanup
    OCMVerifyAll(mockApplication);
    [mockApplication stopMocking];
    pushDelegateInvokedExpectation = nil;
}

#pragma mark - SwrvePushResponseDelegate
- (void) didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    XCTAssert(completionHandler);
    completionHandler();
}

- (void) willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    XCTAssert(completionHandler);
}


#pragma mark - SwrvePushSDKDelegate

- (void) sendPushEngagedEvent:(NSString *)pushId {
    XCTAssert([pushId isEqualToString:@"1"], @"Push Id should be 1");
    _callbackInvoked = YES;

    if(pushDelegateInvokedExpectation){
        [pushDelegateInvokedExpectation fulfill];
    }
}

- (void) deviceTokenIncoming:(NSData *)newDeviceToken {
    _callbackInvoked = YES;
    NSString *newDeviceTokenString = [[NSString alloc] initWithData:newDeviceToken encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(@"fake_token", newDeviceTokenString);
    if(swizzlerInvokedExpectation){
        [swizzlerInvokedExpectation fulfill];
    }
}
- (void)deviceTokenUpdated:(NSString *)newDeviceToken {

    NSData *fakeTokenData = [@"fake_token" dataUsingEncoding:NSUTF8StringEncoding];
    const char *bytes = [fakeTokenData bytes];
    NSMutableString *deviceTokenString = [NSMutableString string];
    for (NSUInteger i = 0; i < [fakeTokenData length]; i++) {
        [deviceTokenString appendFormat:@"%02.2hhX", bytes[i]];
    }
    
    NSString *fakeTokenString = [[deviceTokenString copy] lowercaseString];

    XCTAssertEqualObjects(newDeviceToken, fakeTokenString);
    _callbackInvoked = YES;
}
- (void) remoteNotificationReceived:(NSDictionary *)notificationInfo {
    _callbackInvoked = YES;

    NSString *pushId = [NSString stringWithFormat:@"%@", [notificationInfo objectForKey:SwrveNotificationIdentifierKey]];
    NSString *deeplink = [NSString stringWithFormat:@"%@", [notificationInfo objectForKey:SwrveNotificationDeeplinkKey]];
    NSString *deprecatedDeeplink = [NSString stringWithFormat:@"%@", [notificationInfo objectForKey:SwrveNotificationDeprecatedDeeplinkKey]];

    XCTAssertEqualObjects(pushId, @"1");
    XCTAssertEqualObjects(deeplink, @"protocol://custom");
    XCTAssertEqualObjects(deprecatedDeeplink, @"oldprotocol://custom");

    if(swizzlerRemoteNotificationInvokedExpectation){
        NSLog(@"Calling Fulfill on Expectation: %@", swizzlerRemoteNotificationInvokedExpectation);
        [swizzlerRemoteNotificationInvokedExpectation fulfill];
    }
}

- (void) deeplinkReceived:(NSURL *)url {
    NSString *urlString = [NSString stringWithFormat:@"%@", [url absoluteString]];
    XCTAssertEqualObjects(urlString, @"protocol://custom");
}

#pragma mark - private / helper methods

- (UNNotificationAttachment *) createTestAttachmentWithFileName:(NSString *)filename andExtension:(NSString *)extension {
    NSBundle *bundle = [NSBundle bundleForClass:[TestableSwrve class]];
    NSURL *attachmentURL = [bundle URLForResource:filename withExtension:extension];
    UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:@"" URL:attachmentURL options:nil error:nil];
    return attachment;
}

- (UNNotificationContent *) createTestNotificationContentWithUserInfo:(NSDictionary *)userInfo {
    UNMutableNotificationContent *testContent = [[UNMutableNotificationContent alloc] init];
    testContent.title = @"test_title";
    testContent.subtitle = @"test_subtitle";
    testContent.body = @"test_body";
    testContent.userInfo = userInfo;
    return [testContent copy];
}

- (id) mockApplicationStateWith:(UIApplicationState)uiApplicationState {
    id mockApplication = OCMPartialMock([UIApplication sharedApplication]);
    OCMStub([mockApplication applicationState]).andReturn(uiApplicationState);
    // We have gotten failures in the form of "[UIApplication statusBarOrientation]: unrecognized selector sent to instance" so lets try and always mock it
    OCMStub([mockApplication statusBarOrientation]).andReturn(UIInterfaceOrientationPortrait);
    return mockApplication;
}

@end
