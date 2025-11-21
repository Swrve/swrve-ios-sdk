#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SwrveTestHelper.h"

@interface SwrvePush()
+ (SwrvePush *)sharedInstance;
- (BOOL)handleSilentPushNotification:(NSDictionary *)userInfo withCompletionHandler:(void (^)(UIBackgroundFetchResult, NSDictionary *)) completionHandler API_AVAILABLE(ios(12.0));
@end

@interface SwrveTestSilentPush : XCTestCase

@end

@implementation SwrveTestSilentPush

- (void)testNotHandleSilentPushMissingSilentKey {
    id swrvePushMock = OCMPartialMock([SwrvePush sharedInstance]);
    // should not handle the push, missing @"_sp" key.
    NSString *silentPayloadString = @"{\"New Group 1\":{\"a\":\"b\"},\"New Group 2\":{\"c\":\"b\"}}";
    NSDictionary *userInfo = @{
                               @"_s.SilentPayload" : silentPayloadString,
                               @"version": @1
                               };

    XCTestExpectation *notHandledPushExpectation = [self expectationWithDescription:@"completionHandler"];
    BOOL isPushHandledBySwrve = [swrvePushMock handleSilentPushNotification:userInfo withCompletionHandler:^(UIBackgroundFetchResult fetch, NSDictionary *dic) {
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
    [swrvePushMock stopMocking];
}

- (void)testNotHandleSilentAlreadyProcessedPush {
    id swrvePushMock = OCMPartialMock([SwrvePush sharedInstance]);
    // Force the lastProcessedPushId to be the same as the push on this test.
    [swrvePushMock setValue:@"999" forKey:@"lastProcessedPushId"];
    // Should not handle the push, regarding the pushId @"999" is the lastProcessedPushId.

    NSString *silentPayloadString = @"{\"New Group 1\":{\"a\":\"b\"},\"New Group 2\":{\"c\":\"b\"}}";
    NSDictionary *userInfo = @{
                               @"_sp": @999,
                               @"_s.SilentPayload" : silentPayloadString,
                               @"version": @1
                               };

    XCTestExpectation *notHandledPushExpectation = [self expectationWithDescription:@"completionHandler"];
    BOOL isPushHandledBySwrve = [swrvePushMock handleSilentPushNotification:userInfo withCompletionHandler:^(UIBackgroundFetchResult fetch, NSDictionary *dic) {
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

    [swrvePushMock stopMocking];
}

- (void)testHandleSilentPushWithPayload {
    
    id swrvePushMock = OCMPartialMock([SwrvePush sharedInstance]);
    
    NSString *silentPayloadString = @"{\"New Group 1\":{\"a\":\"b\"},\"New Group 2\":{\"c\":\"b\"}}";
    NSDictionary *userInfo = @{
                               @"_sp": @999,
                               @"_s.SilentPayload": silentPayloadString,
                               @"version": @1
                               };

    XCTestExpectation *isHandledSilentPushExpectation = [self expectationWithDescription:@"completionHandler"];
    BOOL isPushHandledBySwrve = [swrvePushMock handleSilentPushNotification:userInfo withCompletionHandler:^(UIBackgroundFetchResult fetch, NSDictionary *dic) {
        XCTAssertEqual(fetch, UIBackgroundFetchResultNoData);
        NSDictionary *expectedpayload = @{
            @"New Group 1": @{ @"a": @"b"},
            @"New Group 2": @{ @"c": @"b"}
        };
        XCTAssertEqualObjects(dic, expectedpayload);
        [isHandledSilentPushExpectation fulfill];
    }];

    XCTAssertTrue(isPushHandledBySwrve);
    if (!isPushHandledBySwrve) {
        XCTFail(@"Its a silentPush that should be expected handled by Swrve.");
    }

    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"addNotificationRequest not called");
        }
    }];
    [swrvePushMock stopMocking];
}

- (void)testHandleSilentPushWithoutPayload {
    id swrvePushMock = OCMPartialMock([SwrvePush sharedInstance]);
    NSDictionary *userInfo = @{
                               @"_sp": @"0",
                               @"_siw": @720,
                               @"version": @1
                               };

    XCTestExpectation *isHandledSilentPushExpectation = [self expectationWithDescription:@"completionHandler"];
    BOOL isPushHandledBySwrve = [swrvePushMock handleSilentPushNotification:userInfo withCompletionHandler:^(UIBackgroundFetchResult fetch, NSDictionary *dic) {
        XCTAssertEqual(fetch, UIBackgroundFetchResultNoData);
        XCTAssertNil(dic);
        [isHandledSilentPushExpectation fulfill];
    }];

    XCTAssertTrue(isPushHandledBySwrve);
    if (!isPushHandledBySwrve) {
        XCTFail(@"Its a silentPush that should be expected handled by Swrve.");
    }

    [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"addNotificationRequest not called");
        }
    }];
    [swrvePushMock stopMocking];
}

@end
