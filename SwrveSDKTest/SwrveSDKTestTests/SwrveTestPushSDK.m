#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "Swrve.h"
#import "SwrveTestHelper.h"
#import "SwrveLocalStorage.h"
#import "SwrveMockNSURLProtocol.h"
#import "SwrvePermissions.h"



// Internal access to hidden Swrve methods for test only
@interface Swrve (InternalAccess)

- (void) appDidBecomeActive:(NSNotification*)notification;
- (int)queueEvent:(NSString *)eventType data:(NSMutableDictionary *)eventData triggerCallback:(bool)triggerCallback;

@end

@interface SwrveTestPushSDK : XCTestCase

@end

// Note: This test cannot be run in parallel due to its use of static variables (currentMockCenter, currentPushStatus)
@implementation SwrveTestPushSDK

   static id currentMockCenter;
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

// This test temporarily replaces [UNUserNotificationCenter currentNotificationCenter] with this implementation to return a controllable mock
+ (UNUserNotificationCenter *)currentNotificationCenter {
    return currentMockCenter;
}

// Test that when push is disabled no requests are done to request the push authorization
- (void)testStartWithNoPush {
    IMP originalCurrentCenterImp = [self replaceCurrentNotificationCenter];
    currentMockCenter = OCMClassMock([UNUserNotificationCenter class]);
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
    
    // Test cleanup
    [self restoreCurrentNotificationCenter:originalCurrentCenterImp];
    [currentMockCenter stopMocking];
    [mockUIApplication stopMocking];
}

// Test that when push is enabled and configured to trigger on a certain event:
// - The delegate is set
// - An event with the current status is queued
// - We don't set categories (because they are empty)
// - We don't request push permission
// - We don't request a fresh token
- (void)testStartWithPushButNoTriggeredByEvent {
    IMP originalCurrentCenterImp = [self replaceCurrentNotificationCenter];
    currentMockCenter = OCMClassMock([UNUserNotificationCenter class]);
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
    
    // Test cleanup
    [self restoreCurrentNotificationCenter:originalCurrentCenterImp];
    [currentMockCenter stopMocking];
    [swrveMock stopMocking];
    [mockUIApplication stopMocking];
}

// Test that when push is enabled and set to be requested at start:
// - The delegate is set
// - An event with the new authorized status is queued
// - We set categories (because they are not empty)
// - We request push permission
// - We request a fresh token
- (void)testPushRegistration {
    NSSet *customCategories = [NSSet setWithObject:@"my_category"];
    
    IMP originalCurrentCenterImp = [self replaceCurrentNotificationCenter];
    currentMockCenter = OCMClassMock([UNUserNotificationCenter class]);
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
    
    // Test cleanup
    [self restoreCurrentNotificationCenter:originalCurrentCenterImp];
    [currentMockCenter stopMocking];
    [swrveMock stopMocking];
    [mockUIApplication stopMocking];
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
    
    IMP originalCurrentCenterImp = [self replaceCurrentNotificationCenter];
    currentMockCenter = OCMClassMock([UNUserNotificationCenter class]);
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
    
    // Test cleanup
    [self restoreCurrentNotificationCenter:originalCurrentCenterImp];
    [currentMockCenter stopMocking];
    [swrveMock stopMocking];
    [mockUIApplication stopMocking];
}

/* HELPER METHODS */

// Replace the [UNUserNotificationCenter currentNotificationCenter] method to return a mock using a method in this class and return the
// original method implementation to be able to restore it at the end of the test
- (IMP) replaceCurrentNotificationCenter {
    Class notificationCenterClass = [UNUserNotificationCenter class];
    SEL currentCenterSelector = @selector(currentNotificationCenter);
    Method originalMethod = class_getClassMethod(notificationCenterClass, currentCenterSelector);
    IMP newImplementation = [[self class] methodForSelector:currentCenterSelector];
    
    return method_setImplementation(originalMethod, newImplementation);
}

- (void) restoreCurrentNotificationCenter:(IMP)originalCurrentCenterImp {
    Class notificationCenterClass = [UNUserNotificationCenter class];
    SEL currentCenterSelector = @selector(currentNotificationCenter);
    Method originalMethod = class_getClassMethod(notificationCenterClass, currentCenterSelector);
    
    method_setImplementation(originalMethod, originalCurrentCenterImp);
}

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
