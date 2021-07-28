#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "Swrve.h"
#import "SwrveTestHelper.h"
#import "SwrveLocalStorage.h"
#import "SwrveMockNSURLProtocol.h"
#import "SwrvePermissions.h"
#import "SwrveSDK.h"


@interface TestDeeplinkDelegate:NSObject<SwrveDeeplinkDelegate>
@end

@implementation TestDeeplinkDelegate
- (void)handleDeeplink:(NSURL *)nsurl {}
@end

// Internal access to hidden Swrve methods for test only
@interface Swrve (InternalAccess)

- (void) appDidBecomeActive:(NSNotification*)notification;
- (int)queueEvent:(NSString *)eventType data:(NSMutableDictionary *)eventData triggerCallback:(bool)triggerCallback;

@end

@interface SwrveSDK (InternalAccess)
+ (void)addSharedInstance:(Swrve *)instance;
+ (void)resetSwrveSharedInstance;
@end

@interface SwrveTestPushSDK : XCTestCase

@end

// Note: This test cannot be run in parallel due to its use of static variables (currentMockCenter, currentPushStatus)
@implementation SwrveTestPushSDK

static NSInteger currentPushStatus;

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];

    [NSURLProtocol registerClass:[SwrveMockNSURLProtocol class]];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

// Test that when push is disabled no requests are done to request the push authorization
- (void)testStartWithNoPush {
    id currentMockCenter = OCMClassMock([UNUserNotificationCenter class]);
    OCMStub([currentMockCenter currentNotificationCenter]).andReturn(currentMockCenter);
    
    OCMReject([currentMockCenter setDelegate:OCMOCK_ANY]);
    OCMReject([currentMockCenter setNotificationCategories:OCMOCK_ANY]);
    currentPushStatus = UNAuthorizationStatusNotDetermined;
    [self mockNotificationCenterNotificationSettings:currentMockCenter];

    // Should not request push permission
    [self rejectNotificationCenterRequestAuth:currentMockCenter];
    [self rejectNotificationCenterRequestAuthProvisional:currentMockCenter];
    id mockUIApplication = OCMPartialMock([UIApplication sharedApplication]);
    OCMReject([mockUIApplication registerForRemoteNotifications]);

    Swrve *swrve = [Swrve alloc];
    // Start the SDK
    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.pushEnabled = NO;
    swrve = [swrve initWithAppID:123 apiKey:@"SomeAPIKey" config:config];
    // Mimic app being started
    [swrve appDidBecomeActive:nil];
    [swrve sendQueuedEvents];

    OCMVerifyAll(currentMockCenter);
    OCMVerifyAll(mockUIApplication);
    [currentMockCenter stopMocking];
}

// Test that when push is enabled and configured to trigger on a certain event:
// - The delegate is set
// - An event with the current status is queued
// - We don't set categories (because they are empty)
// - We don't request push permission
// - We don't request a fresh token
- (void)testStartWithPushButNoTriggeredByEvent {
    id currentMockCenter = OCMClassMock([UNUserNotificationCenter class]);
    OCMStub([currentMockCenter currentNotificationCenter]).andReturn(currentMockCenter);
    
    OCMExpect([currentMockCenter setDelegate:OCMOCK_ANY]);
    OCMReject([currentMockCenter setNotificationCategories:OCMOCK_ANY]);
    currentPushStatus = UNAuthorizationStatusNotDetermined;
    [self mockNotificationCenterNotificationSettings:currentMockCenter];

    // Should not request push permission
    [self rejectNotificationCenterRequestAuth:currentMockCenter];
    [self rejectNotificationCenterRequestAuthProvisional:currentMockCenter];
    id mockUIApplication = OCMPartialMock([UIApplication sharedApplication]);
    OCMReject([mockUIApplication registerForRemoteNotifications]);

    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);

    // Intercept the event queue system to determine if the correct events are sent
    XCTestExpectation *eventWithPushUnknownQueued = [self expectationWithDescription:@"Event with push unknown status queued"];
    eventWithPushUnknownQueued.assertForOverFulfill = NO;
    [self listenToDeviceUpdateEvents:swrveMock withBlock:^(NSDictionary *attributes) {
        if ([[attributes objectForKey:@"Swrve.permission.ios.push_notifications"] isEqualToString:@"unknown"]) {
            [eventWithPushUnknownQueued fulfill];
        }
    }];

    // Start the SDK
    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.pushEnabled = YES;
    config.autoCollectDeviceToken = NO; // Disable swizzling
    config.pushNotificationEvents = [[NSSet alloc] initWithArray:@[@"subscribe"]];
    swrve = [swrve initWithAppID:123 apiKey:@"SomeAPIKey" config:config];
    // Mimic app being started
    [swrve appDidBecomeActive:nil];
    [swrve sendQueuedEvents];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];

    OCMVerifyAll(currentMockCenter);
    OCMVerifyAll(swrveMock);
    OCMVerifyAll(mockUIApplication);
    [currentMockCenter stopMocking];
}

// Test that when push is enabled and set to be requested at start:
// - The delegate is set
// - An event with the new authorized status is queued
// - We set categories (because they are not empty)
// - We request push permission
// - We request a fresh token
- (void)testPushRegistration {
    NSSet *customCategories = [NSSet setWithObject:@"my_category"];

    id currentMockCenter = OCMClassMock([UNUserNotificationCenter class]);
    OCMStub([currentMockCenter currentNotificationCenter]).andReturn(currentMockCenter);
    
    OCMExpect([currentMockCenter setDelegate:OCMOCK_ANY]);
    OCMExpect([currentMockCenter setNotificationCategories:customCategories]);
    currentPushStatus = UNAuthorizationStatusNotDetermined;
    [self mockNotificationCenterNotificationSettings:currentMockCenter];

    // Should request normal push permission (and we mock a success)
    [self mockExpectRequestAuthorization:currentMockCenter withOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound + UNAuthorizationOptionBadge) andReturn:true withError:nil andPushStatus:UNAuthorizationStatusAuthorized];

    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
    id mockUIApplication = OCMPartialMock([UIApplication sharedApplication]);
    OCMExpect([mockUIApplication registerForRemoteNotifications]).andDo(^(NSInvocation *invocation) {
        // When the SDK calls register for notifications we send the new token
        [swrveMock deviceTokenUpdated:@"fake_token"];
    });

    // Intercept the event queue system to determine if the correct events are sent
    XCTestExpectation *eventWithDeviceTokenQueued = [self expectationWithDescription:@"Event with device token queued"];
    eventWithDeviceTokenQueued.assertForOverFulfill = NO;
    XCTestExpectation *eventWithPushAuthorizedQueued = [self expectationWithDescription:@"Event with push autorized status queued"];
    eventWithPushAuthorizedQueued.assertForOverFulfill = NO;
    [self listenToDeviceUpdateEvents:swrveMock withBlock:^(NSDictionary *attributes) {
        if ([[attributes objectForKey:@"swrve.ios_token"] isEqualToString:@"fake_token"]) {
            [eventWithDeviceTokenQueued fulfill];
        }
        if ([[attributes objectForKey:@"Swrve.permission.ios.push_notifications"] isEqualToString:@"authorized"]) {
            [eventWithPushAuthorizedQueued fulfill];
        }
    }];

    // Start the SDK
    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.pushEnabled = YES;
    config.autoCollectDeviceToken = NO; // Disable swizzling
    config.notificationCategories = customCategories;
    swrve = [swrve initWithAppID:123 apiKey:@"SomeAPIKey" config:config];
    // Mimic app being started
    [swrve appDidBecomeActive:nil];

    // We should see the permission status event with unknown queued
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];

    // Should have requested normal push permission (mock expect on UNUserNotificationCenter)
    // Should have sent an event informing of the status of the permission (mock expect on Swrve)
    OCMVerifyAll(currentMockCenter);
    OCMVerifyAll(swrveMock);
    OCMVerifyAll(mockUIApplication);

    // Verify that the token was saved to disk
    XCTAssertEqualObjects([SwrveLocalStorage deviceToken], @"fake_token");
    [currentMockCenter stopMocking];
}

// Test that when push is was enabled and a token was recieved:
// - The delegate is set
// - We set categories (because they are not empty)
// - We don't request push permission
// - We request a fresh token
- (void)testTokenPresentDoNotRequestPermissionAgain {
    NSSet *customCategories = [NSSet setWithObject:@"my_category"];
    // Assume the app already gave us a token
    [SwrveLocalStorage saveDeviceToken:@"fake_token"];

    id currentMockCenter = OCMClassMock([UNUserNotificationCenter class]);
    OCMStub([currentMockCenter currentNotificationCenter]).andReturn(currentMockCenter);
    
    OCMExpect([currentMockCenter setDelegate:OCMOCK_ANY]);
    OCMExpect([currentMockCenter setNotificationCategories:customCategories]);
    currentPushStatus = UNAuthorizationStatusAuthorized;
    [self mockNotificationCenterNotificationSettings:currentMockCenter];

    // Should not request push permission
    [self rejectNotificationCenterRequestAuth:currentMockCenter];
    [self rejectNotificationCenterRequestAuthProvisional:currentMockCenter];

    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
    id mockUIApplication = OCMPartialMock([UIApplication sharedApplication]);
    OCMExpect([mockUIApplication registerForRemoteNotifications]).andDo(^(NSInvocation *invocation) {
        // When the SDK ask for a fresh token we send an updated one
        [swrveMock deviceTokenUpdated:@"fake_token_updated"];
    });

    // Intercept the event queue system to determine if the correct events are sent
    XCTestExpectation *eventWithDeviceTokenQueued = [self expectationWithDescription:@"Event with device token queued"];
    eventWithDeviceTokenQueued.assertForOverFulfill = NO;
    [self listenToDeviceUpdateEvents:swrveMock withBlock:^(NSDictionary *attributes) {
        if ([[attributes objectForKey:@"swrve.ios_token"] isEqualToString:@"fake_token_updated"]) {
            [eventWithDeviceTokenQueued fulfill];
        }
    }];

    // Start the SDK
    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.pushEnabled = YES;
    config.autoCollectDeviceToken = NO; // Disable swizzling
    config.notificationCategories = customCategories;
    config.pushNotificationEvents = [[NSSet alloc] initWithArray:@[@"subscribe"]];
    swrve = [swrve initWithAppID:123 apiKey:@"SomeAPIKey" config:config];
    // Mimic app being started
    [swrve appDidBecomeActive:nil];

    // We should see the permission status event with unknown queued
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Expectation Error occured: %@", error);
        }
    }];

    // Should have requested normal push permission (mock expect on UNUserNotificationCenter)
    // Should have sent an event informing of the status of the permission (mock expect on Swrve)
    OCMVerifyAll(currentMockCenter);
    OCMVerifyAll(swrveMock);
    OCMVerifyAll(mockUIApplication);

    // Verify that the token was saved to disk
    XCTAssertEqualObjects([SwrveLocalStorage deviceToken], @"fake_token_updated");
    [currentMockCenter stopMocking];
}

// Test that when provisioanl push is enabled and set to be requested at start:
// - The delegate is set
// - An event with the new authorized status is queued
// - We set categories (because they are not empty)
// - We request provisional push permission
// - We request a fresh token
- (void)testProvisionalPushRegistration {
    if (@available(iOS 12.0, *)) {
        NSSet *customCategories = [NSSet setWithObject:@"my_category"];

        id currentMockCenter = OCMClassMock([UNUserNotificationCenter class]);
        OCMStub([currentMockCenter currentNotificationCenter]).andReturn(currentMockCenter);
        
        OCMExpect([currentMockCenter setDelegate:OCMOCK_ANY]);
        OCMExpect([currentMockCenter setNotificationCategories:customCategories]);
        currentPushStatus = UNAuthorizationStatusNotDetermined;
        [self mockNotificationCenterNotificationSettings:currentMockCenter];

        // Should request provisional push permission (and we mock a success)
        [self mockExpectRequestAuthorization:currentMockCenter withOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound + UNAuthorizationOptionBadge + UNAuthorizationOptionProvisional) andReturn:true withError:nil andPushStatus:UNAuthorizationStatusProvisional];

        Swrve *swrve = [Swrve alloc];
        id swrveMock = OCMPartialMock(swrve);
        id mockUIApplication = OCMPartialMock([UIApplication sharedApplication]);
        OCMExpect([mockUIApplication registerForRemoteNotifications]).andDo(^(NSInvocation *invocation) {
            // When the SDK calls register for notifications we send the new token
            [swrveMock deviceTokenUpdated:@"fake_token"];
        });

        // Intercept the event queue system to determine if the correct events are sent
        XCTestExpectation *eventWithDeviceTokenQueued = [self expectationWithDescription:@"Event with device token queued"];
        eventWithDeviceTokenQueued.assertForOverFulfill = NO;
        XCTestExpectation *eventWithPushProvisionalQueued = [self expectationWithDescription:@"Event with push provisional status queued"];
        eventWithPushProvisionalQueued.assertForOverFulfill = NO;
        [self listenToDeviceUpdateEvents:swrveMock withBlock:^(NSDictionary *attributes) {
            if ([[attributes objectForKey:@"swrve.ios_token"] isEqualToString:@"fake_token"]) {
                [eventWithDeviceTokenQueued fulfill];
            }
            if ([[attributes objectForKey:@"Swrve.permission.ios.push_notifications"] isEqualToString:@"provisional"]) {
                [eventWithPushProvisionalQueued fulfill];
            }
        }];

        // Start the SDK
        SwrveConfig *config = [[SwrveConfig alloc] init];
        config.pushEnabled = YES;
        config.autoCollectDeviceToken = NO; // Disable swizzling
        config.notificationCategories = customCategories;
        config.pushNotificationEvents = nil;
        config.provisionalPushNotificationEvents = [NSSet setWithObject:@"Swrve.session.start"];
        swrve = [swrve initWithAppID:123 apiKey:@"SomeAPIKey" config:config];
        // Mimic app being started
        [swrve appDidBecomeActive:nil];

        // We should see the permission status event with unknown queued
        [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
            if (error) {
                NSLog(@"Expectation Error occured: %@", error);
            }
        }];

        // Should have requested normal push permission (mock expect on UNUserNotificationCenter)
        // Should have sent an event informing of the status of the permission (mock expect on Swrve)
        OCMVerifyAll(currentMockCenter);
        OCMVerifyAll(swrveMock);
        OCMVerifyAll(mockUIApplication);

        // Verify that the token was saved to disk
        XCTAssertEqualObjects([SwrveLocalStorage deviceToken], @"fake_token");
        [currentMockCenter stopMocking];
    }
}

- (void)testDeeplinkDelegateCalled {
    //set deeplink delegate on config, confirm open url not called and delegate method called.

    id testDeeplinkDelegate =  OCMPartialMock([TestDeeplinkDelegate new]);
    NSURL *url = [NSURL URLWithString:@"https://google.com"];
    OCMExpect([testDeeplinkDelegate handleDeeplink:url]);
    
    id mockUIApplication = OCMPartialMock([UIApplication sharedApplication]);
    OCMReject([mockUIApplication openURL:url options:OCMOCK_ANY completionHandler:OCMOCK_ANY]);

    SwrveConfig *config = [SwrveConfig new];
    config.autoCollectDeviceToken = NO;
    config.deeplinkDelegate = testDeeplinkDelegate;
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
    [SwrveSDK addSharedInstance:swrveMock];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey" config:config];
#pragma clang diagnostic pop
    
    [swrveMock deeplinkReceived:url];
    OCMVerifyAll(testDeeplinkDelegate);
    OCMVerifyAll(mockUIApplication);
    [mockUIApplication stopMocking];
}

- (void)testDeeplinkDelegateNotCalled {
    //dont set deeplink delegate on config, confirm open url called

    id testDeeplinkDelegate =  OCMPartialMock([TestDeeplinkDelegate new]);
    NSURL *url = [NSURL URLWithString:@"https://google.com"];
    OCMReject([testDeeplinkDelegate handleDeeplink:url]);
    
    id mockUIApplication = OCMPartialMock([UIApplication sharedApplication]);
    OCMExpect([mockUIApplication openURL:url options:OCMOCK_ANY completionHandler:OCMOCK_ANY]);

    SwrveConfig *config = [SwrveConfig new];
    config.autoCollectDeviceToken = NO;
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
    [SwrveSDK addSharedInstance:swrveMock];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey" config:config];
#pragma clang diagnostic pop
    

    [swrveMock deeplinkReceived:url];
    OCMVerifyAll(testDeeplinkDelegate);
    OCMVerifyAll(mockUIApplication);
    [mockUIApplication stopMocking];
}

/* HELPER METHODS */

// Whenever the permission is asked, the 'currentPushStatus' value is returned
- (void) mockNotificationCenterNotificationSettings:(id)mock {
    OCMStub([mock getNotificationSettingsWithCompletionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invoke) {
        void (^callback)(UNNotificationSettings *_Nonnull settings);
        [invoke getArgument:&callback atIndex:2];

        id notificationSettingsMock = OCMClassMock([UNNotificationSettings class]);
        OCMStub([notificationSettingsMock authorizationStatus]).andReturn(currentPushStatus);
        callback(notificationSettingsMock);
    });
}

- (void) rejectNotificationCenterRequestAuth:(id)mock {
    UNAuthorizationOptions provisionalNotificationAuthOptions = (UNAuthorizationOptionAlert + UNAuthorizationOptionSound + UNAuthorizationOptionBadge);
    OCMReject([mock requestAuthorizationWithOptions:provisionalNotificationAuthOptions completionHandler:OCMOCK_ANY]);
}

- (void) rejectNotificationCenterRequestAuthProvisional:(id)mock {
    if (@available(iOS 12.0, *)) {
        UNAuthorizationOptions provisionalNotificationAuthOptions = (UNAuthorizationOptionAlert + UNAuthorizationOptionSound + UNAuthorizationOptionBadge + UNAuthorizationOptionProvisional);
        OCMReject([mock requestAuthorizationWithOptions:provisionalNotificationAuthOptions completionHandler:OCMOCK_ANY]);
    }
}

- (void) listenToDeviceUpdateEvents:(id)mock withBlock:(void (^)(NSDictionary*))attributesBlock {
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

- (void) mockExpectRequestAuthorization:(id)mock withOptions:(UNAuthorizationOptions)options andReturn:(BOOL)result withError:(NSError*)error andPushStatus:(UNAuthorizationStatus)status {
    OCMExpect([mock requestAuthorizationWithOptions:options completionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invoke) {
        void (^callback)(BOOL granted, NSError * _Nullable error);
        [invoke getArgument:&callback atIndex:3];

        // Update permission status
        currentPushStatus = status;
        callback(result, error);
    });
}

@end
