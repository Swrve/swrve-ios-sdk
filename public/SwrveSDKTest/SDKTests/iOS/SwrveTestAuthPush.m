#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SwrveTestHelper.h"

@interface SwrveNotificationManager()
+ (void)downloadAttachment:(NSString *)mediaUrl withCompletedContentCallback:(void (^)(UNNotificationAttachment *attachment, NSError *error))callback;
@end

@interface SwrvePush ()
+ (BOOL)isValidNotificationContent:(NSDictionary *)userInfo;
+ (SwrvePush *)sharedInstance;
- (void)setCommonDelegate:(id<SwrveCommonDelegate>) commonDelegate;
- (BOOL)handleAuthenticatedPushNotification:(NSDictionary *)userInfo
                            withLocalUserId:(NSString *)localUserId
                      withCompletionHandler:(void (^)(UIBackgroundFetchResult, NSDictionary *))completionHandler API_AVAILABLE(ios(12.0));
@end

@interface TestNotificationFilterDelegate : NSObject <SwrveNotificationFilterDelegate>
@end
@implementation TestNotificationFilterDelegate
- (UNMutableNotificationContent *)filterNotification:(UNMutableNotificationContent *)notification withPayload:(NSDictionary *)payload {
    notification.title = @"TestNotificationFilterDelegate Title Change";
    NSNumber *filterMeNumber = payload[@"filter_me"];
    BOOL filterMe = NO;
    if ([filterMeNumber isKindOfClass:[NSNumber class]]) {
        filterMe = [filterMeNumber boolValue];
    }
    if (filterMe) {
        return nil;
    }
    return notification;
}
@end

@interface SwrveTestAuthPush : XCTestCase

@end

@implementation SwrveTestAuthPush

- (void)setUp {
    [super setUp];
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:nil];
    [userDefaults setObject:nil forKey:@"swrve.is_tracking_state_stopped"];
}

- (void)testAuthPushMediaDownloadSucceeds {
    id currentMockCenter = OCMClassMock([UNUserNotificationCenter class]);
    OCMStub([currentMockCenter currentNotificationCenter]).andReturn(currentMockCenter);
    
    id mediaHelperMock = OCMClassMock([SwrveNotificationManager class]);
    OCMStub([mediaHelperMock downloadAttachment:OCMOCK_ANY withCompletedContentCallback:OCMOCK_ANY]).andDo(^(NSInvocation *invoke) {
   
        void (^withCompletedContentCallback)(UNNotificationAttachment *attachment, NSError *error);
        
        NSURL *attachmentURL = [[NSBundle mainBundle] URLForResource:@"logo" withExtension:@"gif"];
        UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:@"" URL:attachmentURL options:nil error:nil];
        
        NSError *mockedError = nil;
        [invoke getArgument:&withCompletedContentCallback atIndex:3];
        withCompletedContentCallback(attachment, mockedError);
    });
    
    id swrvePushMock = OCMPartialMock([SwrvePush sharedInstance]);
    
    [SwrveLocalStorage saveSwrveUserId:@"1234"];
    
    NSDictionary *userInfo = @{
                               @"_p":@"1",
                               @"_aui": @"1234",
                               @"_sw":@{
                                       @"media": @{
                                               @"title": @"rich_title",
                                               @"body":  @"rich_body",
                                               @"subtitle": @"rich_subtitle",
                                               @"url": @"media download will succeed"
                                               }
                                       },
                               @"version": @1
                               };
    
    XCTestExpectation *addNotificationRequest = [self expectationWithDescription:@"addNotificationRequest"];

    void (^addNotificationRequestObserver)(NSInvocation *) = ^(NSInvocation *invoke) {
        __unsafe_unretained UNNotificationRequest * request = nil;
        [invoke getArgument:&request atIndex:2];

        XCTAssertEqualObjects(request.content.userInfo[@"_sw"][@"media"][@"title"],@"rich_title");
        [addNotificationRequest fulfill];
    };
    
    OCMStub([currentMockCenter addNotificationRequest:OCMOCK_ANY withCompletionHandler:OCMOCK_ANY]).andDo(addNotificationRequestObserver);

    XCTAssertTrue([swrvePushMock handleAuthenticatedPushNotification:userInfo
                                                     withLocalUserId:[SwrveLocalStorage swrveUserId]
                                               withCompletionHandler:nil]);
    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"addNotificationRequest not called");
        }
    }];
    OCMVerify([currentMockCenter addNotificationRequest:OCMOCK_ANY withCompletionHandler:OCMOCK_ANY]);
    OCMVerifyAll(currentMockCenter);
    [currentMockCenter stopMocking];
}

- (void)testAuthPushCompletionHandlerCallback {
    id currentMockCenter = OCMClassMock([UNUserNotificationCenter class]);
    OCMStub([currentMockCenter currentNotificationCenter]).andReturn(currentMockCenter);
    
    id swrvePushMock = OCMPartialMock([SwrvePush sharedInstance]);
    id mediaHelperMock = OCMClassMock([SwrveNotificationManager class]);
    OCMStub([mediaHelperMock downloadAttachment:OCMOCK_ANY withCompletedContentCallback:OCMOCK_ANY]).andDo(^(NSInvocation *invoke) {

        void (^withCompletedContentCallback)(UNNotificationAttachment *attachment, NSError *error);

        NSURL *attachmentURL = [[NSBundle mainBundle] URLForResource:@"logo" withExtension:@"gif"];
        UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:@"" URL:attachmentURL options:nil error:nil];

        NSError *mockedError = nil;
        [invoke getArgument:&withCompletedContentCallback atIndex:3];
        withCompletedContentCallback(attachment, mockedError);
    });

    [SwrveLocalStorage saveSwrveUserId:@"1234"];
    NSDictionary *userInfo = @{
                               @"_p":@"1",
                               @"_aui": @"1234",
                               @"_sw":@{
                                       @"media": @{
                                               @"title": @"rich_title",
                                               @"body":  @"rich_body",
                                               @"subtitle": @"rich_subtitle",
                                               @"url": @"media download will succeed"
                                               }
                                       },
                               @"version": @1
                               };

    void (^addNotificationRequestObserver)(NSInvocation *) = ^(NSInvocation *invoke) {
        void (^completionHandlerIntercepted)(UIBackgroundFetchResult fetch, NSDictionary *dic);
        [invoke getArgument:&completionHandlerIntercepted atIndex:3];
        
        // Mimic what the inside block of SwrvePush
        completionHandlerIntercepted(UIBackgroundFetchResultNewData, nil);
    };
    
    OCMStub([currentMockCenter addNotificationRequest:OCMOCK_ANY withCompletionHandler:OCMOCK_ANY]).andDo(addNotificationRequestObserver);

    XCTestExpectation *completionHandler = [self expectationWithDescription:@"completionHandler"];
    BOOL isPushHandledBySwrve = [swrvePushMock handleAuthenticatedPushNotification:userInfo
                                                                   withLocalUserId:[SwrveLocalStorage swrveUserId]
                                                             withCompletionHandler:^(UIBackgroundFetchResult fetch, NSDictionary *dic) {
                                                                 XCTAssertTrue(fetch == UIBackgroundFetchResultNewData);
                                                                 XCTAssertEqualObjects(dic, nil);
                                                                 [completionHandler fulfill];
                                                             }];

    XCTAssertTrue(isPushHandledBySwrve);
    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"completionHandler not called");
        }
    }];

    OCMReject([currentMockCenter addNotificationRequest:OCMOCK_ANY withCompletionHandler:OCMOCK_ANY]);
    OCMVerifyAll(currentMockCenter);
    [currentMockCenter stopMocking];
}

// Auth push does not suppport fallback text for media, when media download fails, the auth push won't show
- (void)testAuthPushMediaDownloadFails {
    id currentMockCenter = OCMClassMock([UNUserNotificationCenter class]);
    OCMStub([currentMockCenter currentNotificationCenter]).andReturn(currentMockCenter);
    
    XCTestExpectation *mediaFailedDownload = [self expectationWithDescription:@"mediaFailedDownload"];
    
    id mediaHelperMock =  OCMPartialMock([SwrveNotificationManager new]);
    OCMExpect([mediaHelperMock downloadAttachment:OCMOCK_ANY withCompletedContentCallback:OCMOCK_ANY]).andDo(^(NSInvocation *invoke) {
        
        void (^withCompletedContentCallback)(UNNotificationAttachment *attachment, NSError *error);
        //deliberately return no attachement indicating a failure.
        UNNotificationAttachment *attachment = nil;
        NSError *mockedError = nil;
        [invoke getArgument:&withCompletedContentCallback atIndex:3];
        withCompletedContentCallback(attachment, mockedError);
        [mediaFailedDownload fulfill];
    });
    
    id swrvePushMock = OCMPartialMock([SwrvePush sharedInstance]);
    
    [SwrveLocalStorage saveSwrveUserId:@"1234"];
    
    NSDictionary *userInfo = @{
                               @"_p":@"1",
                               @"_aui": @"1234",
                               @"_sw":@{
                                       @"media": @{
                                               @"title": @"rich_title",
                                               @"body":  @"rich_body",
                                               @"subtitle": @"rich_subtitle",
                                               @"url": @"media download will fail"
                                               }
                                       },
                               @"version": @1
                               };

    XCTestExpectation *completionHandler = [self expectationWithDescription:@"completionHandler"];
    BOOL isPushHandledBySwrve = [swrvePushMock handleAuthenticatedPushNotification:userInfo
                                                                   withLocalUserId:[SwrveLocalStorage swrveUserId]
                                                             withCompletionHandler:^(UIBackgroundFetchResult fetch, NSDictionary *dic) {
                                                                 XCTAssertTrue(fetch == UIBackgroundFetchResultFailed);
                                                                 XCTAssertEqualObjects(dic, nil);
                                                                 [completionHandler fulfill];
                                                             }];

    XCTAssertTrue(isPushHandledBySwrve);
    if (!isPushHandledBySwrve) {
        XCTFail(@"isPushHandledBySwrve should be true");
    }

    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"addNotificationRequest not called");
        }
    }];
    
    OCMReject([currentMockCenter addNotificationRequest:OCMOCK_ANY withCompletionHandler:OCMOCK_ANY]);
    OCMVerifyAll(currentMockCenter);
    [currentMockCenter stopMocking];
}

// Test not using SwrveNotificationFilter does not change notification contents.
- (void)testAuthPushWithNoFilter {
    
    NSDictionary *userInfo = @{
        @"_p":@"1",
        @"_aui": @"1234",
        @"_sw":@{
            @"media": @{
                @"title": @"rich_title",
                @"body":  @"rich_body",
                @"subtitle": @"rich_subtitle"
            }
        },
        @"version": @1
    };
    
    // assert that the captured request's content title is unchanged with nil filter
    UNNotificationRequest *capturedRequest = [self handleAuthPushWithUserInfo:userInfo
                                                                    andFilter:nil
                                                                     suppress:false];
    XCTAssertEqualObjects(capturedRequest.content.title, @"rich_title", @"The notification title should not have changed.");
}

// Test SwrveNotificationFilter changes the notification contents.
- (void)testAuthPushFilteredWithContentsChanged {
    
    NSDictionary *userInfo = @{
        @"_p":@"1",
        @"_aui": @"1234",
        @"_sw":@{
            @"media": @{
                @"title": @"rich_title",
                @"body":  @"rich_body",
                @"subtitle": @"rich_subtitle"
            }
        },
        @"version": @1
    };
    
    // assert that the captured request's content title is "TestNotificationFilterDelegate Title Change" with the filter
    UNNotificationRequest *capturedRequest = [self handleAuthPushWithUserInfo:userInfo
                                                                    andFilter:[TestNotificationFilterDelegate new]
                                                                     suppress:false];
    XCTAssertEqualObjects(capturedRequest.content.title, @"TestNotificationFilterDelegate Title Change", @"The notification title should have been changed by the filter delegate.");
}

// Test SwrveNotificationFilter stops or supresses the notification.
- (void)testAuthPushFilteredAndSuppressed {
    
    //  "filter_me" is used in TestNotificationFilterDelegate
    NSDictionary *userInfoWithFilterMePayload = @{
        @"_p":@"1",
        @"_aui": @"1234",
        @"_sw":@{
            @"media": @{
                @"title": @"rich_title",
                @"body":  @"rich_body",
                @"subtitle": @"rich_subtitle"
            }
        },
        @"version": @1,
        @"filter_me": @true
    };
    
    // assert that the captured request's content title is "TestNotificationFilterDelegate Title Change" with the filter
    UNNotificationRequest *capturedRequest = [self handleAuthPushWithUserInfo:userInfoWithFilterMePayload
                                                                    andFilter:[TestNotificationFilterDelegate new]
                                                                     suppress:true];
    XCTAssertNil(capturedRequest, @"The TestNotificationFilterDelegate should suppress the notification if it has filter_me payload");
}

- (UNNotificationRequest*)handleAuthPushWithUserInfo:(NSDictionary *) userInfo
                                           andFilter:(TestNotificationFilterDelegate *) notificationFilterDelegate
                                            suppress:(BOOL) suppress{
    
    [SwrveLocalStorage saveSwrveUserId:@"1234"];
    
    // stub the notification center
    id currentMockCenter = OCMClassMock([UNUserNotificationCenter class]);
    OCMStub([currentMockCenter currentNotificationCenter]).andReturn(currentMockCenter);
    
    // stub/reject the addNotificationRequest API rerquest
    XCTestExpectation *addNotificationRequest = nil;
    __block UNNotificationRequest *capturedRequest = nil;
    if(suppress) {
        OCMReject([currentMockCenter addNotificationRequest:OCMOCK_ANY withCompletionHandler:OCMOCK_ANY]);
    } else {
        addNotificationRequest = [self expectationWithDescription:@"addNotificationRequest"];
        void (^addNotificationRequestObserver)(NSInvocation *) = ^(NSInvocation *invoke) {
            __unsafe_unretained UNNotificationRequest * request = nil;
            [invoke getArgument:&request atIndex:2];
            capturedRequest = request; // Capture the request
            
            // Initially check the userInfo to ensure the original title was "rich_title"
            XCTAssertEqualObjects(request.content.userInfo[@"_sw"][@"media"][@"title"],@"rich_title");
            [addNotificationRequest fulfill];
        };
        OCMStub([currentMockCenter addNotificationRequest:OCMOCK_ANY withCompletionHandler:OCMOCK_ANY]).andDo(addNotificationRequestObserver);
    }
    
    // Set the Test SwrveNotificationFilterDelegate in SwrveCommon
    id mockSwrveCommon = OCMProtocolMock(@protocol(SwrveCommonDelegate));
    OCMStub([mockSwrveCommon notificationFilterDelegate]).andReturn(notificationFilterDelegate);
    [SwrveCommon addSharedInstance:mockSwrveCommon];
    
    // call handleAuthenticatedPushNotification with valid user
    id swrvePushMock = OCMPartialMock([SwrvePush sharedInstance]);
    [swrvePushMock setCommonDelegate:mockSwrveCommon];
    void (^completionHandler)(UIBackgroundFetchResult, NSDictionary *) = ^(UIBackgroundFetchResult result, NSDictionary *dictionary) {
        if (suppress) {
            XCTAssertEqual(result, UIBackgroundFetchResultFailed, @"Completion result should be Failed for suppressed notification.");
        } else {
            // because of the way the UNUserNotificationCenter is mocked, the completionHandler doesn't get called for successful addNotificationRequest so nothing to assert here
        }
    };
    BOOL handled = [swrvePushMock handleAuthenticatedPushNotification:userInfo
                                                      withLocalUserId:[SwrveLocalStorage swrveUserId]
                                                withCompletionHandler:completionHandler];
    XCTAssertTrue(handled);
    
    if(suppress == false) {
        [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
            if (error) {
                XCTFail(@"addNotificationRequest not called"); // verify no errors and addNotificationRequest called
            }
        }];
        OCMVerify([currentMockCenter addNotificationRequest:OCMOCK_ANY withCompletionHandler:OCMOCK_ANY]);
    }
    OCMVerifyAll(currentMockCenter);
    [currentMockCenter stopMocking];
    
    return capturedRequest;
}

- (void)testNotHandlePushAuthDifferentUserId {
    id currentMockCenter = OCMClassMock([UNUserNotificationCenter class]);
    OCMStub([currentMockCenter currentNotificationCenter]).andReturn(currentMockCenter);
    
    id swrvePushMock = OCMPartialMock([SwrvePush sharedInstance]);
    // should not handle the push, different user.
    [SwrveLocalStorage saveSwrveUserId:@"4321"];
    NSDictionary *userInfo = @{
                               @"_p":@"1",
                               @"_aui": @"1234",
                               @"_sw":@{
                                       @"media": @{
                                               @"title": @"rich_title",
                                               @"body":  @"rich_body",
                                               @"subtitle": @"rich_subtitle",
                                               @"url": @"media download will fail"
                                               }
                                       },
                               @"version": @1
                               };

    XCTestExpectation *notHandledPushExpectation = [self expectationWithDescription:@"completionHandler"];
    BOOL isPushHandledBySwrve = [swrvePushMock handleAuthenticatedPushNotification:userInfo
                                                                   withLocalUserId:[SwrveLocalStorage swrveUserId]
                                                             withCompletionHandler:^(UIBackgroundFetchResult fetch, NSDictionary *dic) {
                                                                 XCTFail(@"completionHandler should not called");
                                                             }];

    XCTAssertFalse(isPushHandledBySwrve);
    if (!isPushHandledBySwrve) {
        [notHandledPushExpectation fulfill];
    }

    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"addNotificationRequest not called");
        }
    }];

    OCMReject([currentMockCenter addNotificationRequest:OCMOCK_ANY withCompletionHandler:OCMOCK_ANY]);
    OCMVerifyAll(currentMockCenter);
    [currentMockCenter stopMocking];
}

- (void)testNotHandlePushAuth_SDKStopped {

    [SwrveSEConfig saveTrackingStateStopped:nil isTrackingStateStopped:YES]; // should not handle because stopped
    [SwrveLocalStorage saveSwrveUserId:@"1234"]; // same user

    [self assertAuthPush: NO];
}

- (void)testHandlePushAuth {

    [SwrveSEConfig saveTrackingStateStopped:nil isTrackingStateStopped:NO]; // should handle because NOT stopped
    [SwrveLocalStorage saveSwrveUserId:@"1234"]; // same user

    [self assertAuthPush: YES];
}

- (void)assertAuthPush:(BOOL) shouldHandle {

    id currentMockCenter = OCMClassMock([UNUserNotificationCenter class]);
    OCMStub([currentMockCenter currentNotificationCenter]).andReturn(currentMockCenter);

    id swrvePushMock = OCMPartialMock([SwrvePush sharedInstance]);
    NSDictionary *userInfo = @{
            @"_p":@"1",
            @"_aui": @"1234",
            @"_sw":@{
                    @"media": @{
                            @"title": @"rich_title",
                            @"body":  @"rich_body",
                            @"subtitle": @"rich_subtitle",
                            @"url": @"media download will fail"
                    }
            },
            @"version": @1
    };

    XCTestExpectation *completionHandlerExpectation = [self expectationWithDescription:@"completionHandler"];
    BOOL isPushHandledBySwrve = [swrvePushMock handleAuthenticatedPushNotification:userInfo
                                                                   withLocalUserId:[SwrveLocalStorage swrveUserId]
                                                             withCompletionHandler:^(UIBackgroundFetchResult fetch, NSDictionary *dic) {
                                                                 if (shouldHandle) {
                                                                     [completionHandlerExpectation fulfill];
                                                                 } else {
                                                                     XCTFail(@"completionHandler should not be called");
                                                                 }
                                                             }];

    XCTAssertTrue(isPushHandledBySwrve == shouldHandle);
    if (!isPushHandledBySwrve) {
        [completionHandlerExpectation fulfill];
    }

    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"completionHandler not called");
        }
    }];

    OCMReject([currentMockCenter addNotificationRequest:OCMOCK_ANY withCompletionHandler:OCMOCK_ANY]);
    OCMVerifyAll(currentMockCenter);
    [currentMockCenter stopMocking];
}

- (void)testNotHandleAuthPushWithoutSwrveKey {
    id swrvePushMock = OCMPartialMock([SwrvePush sharedInstance]);
    // should not handle the push, missing SwrveNotificationIdentifierKey key.
    [SwrveLocalStorage saveSwrveUserId:@"1234"];
    NSDictionary *userInfo = @{
                               @"_aui": @"1234",
                               @"_sw":@{
                                       @"media": @{
                                               @"title": @"rich_title",
                                               @"body":  @"rich_body",
                                               @"subtitle": @"rich_subtitle",
                                               @"url": @"media download will fail"
                                               }
                                       },
                               @"version": @1
                               };

    XCTestExpectation *notHandledPushExpectation = [self expectationWithDescription:@"completionHandler"];
    BOOL isPushHandledBySwrve = [swrvePushMock handleAuthenticatedPushNotification:userInfo
                                                                   withLocalUserId:[SwrveLocalStorage swrveUserId]
                                                             withCompletionHandler:^(UIBackgroundFetchResult fetch, NSDictionary *dic) {
                                                                 XCTFail(@"completionHandler should not called");
                                                             }];

    XCTAssertFalse(isPushHandledBySwrve);
    if (!isPushHandledBySwrve) {
        [notHandledPushExpectation fulfill];
    }

    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"addNotificationRequest not called");
        }
    }];
}


- (void)testIsValidNotificationContent {
    //Invalid cases
    NSDictionary *invalid = nil;
    XCTAssertFalse([SwrvePush isValidNotificationContent:invalid]);
    
    invalid = @{};
    XCTAssertFalse([SwrvePush isValidNotificationContent:invalid]);
    
    invalid = @{
        @"_sp" : @"1"
    };
    XCTAssertFalse([SwrvePush isValidNotificationContent:invalid]);

    invalid = @{
        @"_sw" : @{@"version" : @3},
    };
    XCTAssertFalse([SwrvePush isValidNotificationContent:invalid]);

    invalid = @{
        @"_sp" : @"1",
        @"_sw" : @{@"version" : @3},
    };
    XCTAssertFalse([SwrvePush isValidNotificationContent:invalid]);

    //Valid cases
    NSDictionary *valid = @{
        @"_p" : @"1"
    };
    XCTAssertTrue([SwrvePush isValidNotificationContent:valid]);
    
    valid = @{
        @"_p" : @"1",
        @"_sw" : @{@"version" : @1}
    };
    XCTAssertTrue([SwrvePush isValidNotificationContent:valid]);
}

@end
