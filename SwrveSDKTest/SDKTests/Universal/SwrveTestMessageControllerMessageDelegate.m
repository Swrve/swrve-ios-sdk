#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SwrveTestHelper.h"
#import "TestCapabilitiesDelegate.h"

#if TARGET_OS_IOS
#import "SwrvePermissions.h"
#endif //TARGET_OS_IOS

@interface TestDeeplinkDelegate2 :NSObject<SwrveDeeplinkDelegate>
@end

@implementation TestDeeplinkDelegate2
- (void)handleDeeplink:(NSURL *)nsurl {}
@end

@interface SwrveMigrationsManager ()
+ (void)markAsMigrated;
@end

@interface SwrveSDK (InternalAccess)
+ (void)addSharedInstance:(Swrve*)instance;
@end

@interface Swrve ()
@property (nonatomic) SwrveReceiptProvider *receiptProvider;
@property (nonatomic) SwrveMessageController *message;
- (NSDate *)getNow;
- (void)initSwrveRestClient:(NSTimeInterval)timeOut urlSssionDelegate:(id <NSURLSessionDelegate>)urlSssionDelegate;
- (int)sessionStart;
- (void)suspend:(BOOL)terminating;
- (void)appDidBecomeActive:(NSNotification *)notification;
@property (atomic) SwrveRESTClient *restClient;
@property (atomic) NSMutableArray *eventBuffer;
- (int)queueEvent:(NSString *)eventType data:(NSMutableDictionary *)eventData triggerCallback:(bool)triggerCallback;
- (void)reIdentifyUser;
@end

#if TARGET_OS_IOS
@interface SwrvePush (SwrvePushInternalAccess)
- (void)registerForPushNotifications:(BOOL)provisional providesAppNotificationSettings:(BOOL)providesAppNotificationSettings;
@end
#endif //TARGET_OS_IOS

@interface SwrveMessageController ()
- (void)showMessage:(SwrveMessage *)message queue:(bool)isQueued withPersonalization:(NSDictionary *)personalization;
- (void)showMessage:(SwrveMessage *)message withPersonalization:(NSDictionary *)personalization;
- (void)dismissMessageWindow;
- (void)updateCampaigns:(NSDictionary *)campaignJson withLoadingPreviousCampaignState:(BOOL) isLoadingPreviousCampaignState;
- (SwrveBaseMessage *)baseMessageForEvent:(NSString *)eventName withPayload:(NSDictionary *)payload;
- (void)showMessage:(SwrveMessage *)message;
- (void)messageWasShownToUser:(SwrveMessage *)message;
- (void)startSwrveGeoSDK;
- (bool)shouldStartSwrveGeoSDK;
@property (nonatomic, retain) UIWindow *inAppMessageWindow;
@property (nonatomic, retain) NSArray *campaigns;
@property (nonatomic) bool autoShowMessagesEnabled;
@property (nonatomic, retain) SwrveAssetsManager *assetsManager;
@property (nonatomic, retain) NSString *user;
@property (nonatomic, retain) NSString *apiKey;
@property (nonatomic, retain) NSMutableDictionary *campaignsState;
@property (nonatomic, retain) NSString *server;
@property (nonatomic, retain) NSString *language;
@property (nonatomic) SwrveInterfaceOrientation orientation;
@property (nonatomic, retain) NSDate *initialisedTime;
@property (nonatomic, retain) NSString *campaignsStateFilePath;
@property (nonatomic, retain) NSDate *showMessagesAfterLaunch;
@property (nonatomic, retain) NSDate *showMessagesAfterDelay;
@property(nonatomic, retain) NSMutableArray *iamQueue;
@property(nonatomic) bool pushEnabled;
@property(nonatomic) SwrveActionType inAppMessageActionType;
@property(nonatomic, retain) NSString *inAppMessageAction;
@end

@interface SwrveReceiptProvider ()
- (NSData *)readMainBundleAppStoreReceipt API_AVAILABLE(ios(12.0));
@end

@interface SwrveMessageViewController ()
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(SwrveMessagePageViewController *)viewController;
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(SwrveMessagePageViewController *)viewController;
- (CGSize)windowSize;
- (void)handleTap:(UITapGestureRecognizer *)tap;
@property(nonatomic) SwrveInAppStoryView *storyView;
@property(nonatomic) SwrveInAppStoryUIButton *storyDismissButton;
@end

@interface SwrveMessageUIView()
- (void)addAccessibilityText:(NSString *)accessibilityText backupText:(NSString *)backupText withPersonalization:(NSDictionary *)personalizationDict toView:(UIView *)view;
- (IBAction)onButtonPressed:(id)buttonView;
@end

@interface SwrveTestMessageControllerMessageDelegate : XCTestCase

@property NSDate *swrveNowDate;
+ (NSArray*)testJSONAssets;
@end

@implementation SwrveTestMessageControllerMessageDelegate

+ (NSArray *)testJSONAssets {
    static NSArray* assets = nil;
    if (!assets) {
        assets = @[
                   @"8f984a803374d7c03c97dd122bce3ccf565bbdb5",
                   @"8721fd4e657980a5e12d498e73aed6e6a565dfca",
                   @"97c5df26c8e8fcff8dbda7e662d4272a6a94af7e",
                   ];
    }
    return assets;
}

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
    [SwrveTestHelper createDummyAssets:[SwrveTestMessageControllerMessageDelegate testJSONAssets]];
    self.swrveNowDate = [NSDate dateWithTimeIntervalSince1970:1362873600];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

- (id)swrveMockWithTestJson:(NSString *)jsonFileName {
    return [self swrveMockWithTestJson:jsonFileName withConfig:[SwrveConfig new]];
}

- (id)swrveMockWithTestJson:(NSString *)jsonFileName withConfig:(SwrveConfig *)config {
    [SwrveMigrationsManager markAsMigrated];
    
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
    
    // mock date that lies within the start and end time of the campaign in the test json file
    // we do this to pass: checkGlobalRules
    OCMStub([swrveMock getNow]).andDo(^(NSInvocation *invocation) {
        NSDate *retVal = self.swrveNowDate;
        NSLog(@"retVal %@", retVal);
        [invocation setReturnValue:&retVal];
    });
    
    // mock rest calls with success and empty data
    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
    id mockRestClient = OCMPartialMock(restClient);
    id mockResponse = OCMClassMock([NSHTTPURLResponse class]);
    OCMExpect([mockResponse statusCode]).andReturn(200);
    NSData *mockResponseData = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
    OCMStub([mockRestClient sendHttpRequest:OCMOCK_ANY
                          completionHandler:([OCMArg invokeBlockWithArgs:mockResponse, mockResponseData, [NSNull null], nil])]);
    
    OCMStub([swrveMock initSwrveRestClient:60 urlSssionDelegate:nil]).andDo(^(NSInvocation *invocation) {
        swrve.restClient = mockRestClient;
    });
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"someAPIKey" config:config];
#pragma clang diagnostic pop
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:jsonFileName ofType:@"json"];
    NSData *mockJsonData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockJsonData options:0 error:nil];

    BOOL isLoadingPreviousCampaignState = ![[SwrveQA sharedInstance] resetDeviceState];
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:isLoadingPreviousCampaignState];
    
    return swrveMock;
}

- (void)testMessageCallbackImpressionAndClipboard {
    SwrveConfig *config = [[SwrveConfig alloc]init];
    SwrveInAppMessageConfig *inAppMessageConfig = OCMPartialMock([SwrveInAppMessageConfig new]);

    id mockMessageDelegate = OCMProtocolMock(@protocol(SwrveInAppMessageDelegate));
    OCMStub([inAppMessageConfig inAppMessageDelegate]).andReturn(mockMessageDelegate);
    config.inAppMessageConfig = inAppMessageConfig;
    
    [OCMExpect([mockMessageDelegate onAction:SwrveMessageActionImpression messageDetails:OCMOCK_ANY selectedButton:nil]) andDo:^(NSInvocation *invocation) {
  
        __unsafe_unretained SwrveMessageDetails *messageDetails;
        [invocation getArgument:&messageDetails atIndex:3];
        
        XCTAssertEqual(messageDetails.campaignId, 102);
        XCTAssertEqual(messageDetails.variantId, 165);
        XCTAssertEqualObjects(messageDetails.messageName, @"Kindle");
        XCTAssertEqual([messageDetails.buttons count], 5);
        
        __unsafe_unretained SwrveMessageButtonDetails *button;
        [invocation getArgument:&button atIndex:4];
        XCTAssertNil(button);
    }];
    
    [OCMExpect([mockMessageDelegate onAction:SwrveMessageActionClipboard messageDetails:OCMOCK_ANY selectedButton:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
        
        __unsafe_unretained SwrveMessageDetails *messageDetails;
        [invocation getArgument:&messageDetails atIndex:3];
        
        XCTAssertEqual(messageDetails.campaignId, 102);
        XCTAssertEqual(messageDetails.variantId, 165);
        XCTAssertEqualObjects(messageDetails.messageName, @"Kindle");
        XCTAssertEqual([messageDetails.buttons count], 5);
        
        __unsafe_unretained SwrveMessageButtonDetails *button;
        [invocation getArgument:&button atIndex:4];
        XCTAssertEqualObjects(button.buttonName, @"clipboard_action");
        XCTAssertEqualObjects(button.buttonText, @"hello"); // fallback text
        XCTAssertEqual(button.actionType, kSwrveActionClipboard);
        XCTAssertEqualObjects(button.actionString, @"some personalized value1");
    
    }];

    id swrveMock = [self swrveMockWithTestJson:@"campaigns" withConfig:config];
    
    SwrveMessageController *controller = [swrveMock messaging];
    
    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;
    
    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message withPersonalization: @{@"test_cp_action":@"some personalized value1", @"test_2":@"some personalized value2"}];
    
    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    SwrveMessagePageViewController *viewController = [self loadMessagePageViewController:messageViewController];
    [viewController viewDidAppear:NO];
    
    SwrveMessageUIView *messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    for (UIView *subview in messageUiView.subviews) {
        if ([subview isKindOfClass:[SwrveUIButton class]]) {
            SwrveUIButton *swrveUIButton = (SwrveUIButton *) subview;
            if ([swrveUIButton.buttonName isEqualToString:@"clipboard_action"]) {
                SwrveMessageUIView *swrveMessageUIView = (SwrveMessageUIView*) [swrveUIButton superview];
                [swrveMessageUIView onButtonPressed:swrveUIButton];
                [self waitForWindowDismissed:controller];
                break;
            }
        }
    };
    
    [self waitForInterval:1.0];
    OCMVerifyAll(mockMessageDelegate);
}

- (void)testMessageCallbackCustomOpenUrlCalled {
    
    SwrveConfig *config = OCMPartialMock([SwrveConfig new]);
    SwrveInAppMessageConfig *inAppMessageConfig = OCMPartialMock([SwrveInAppMessageConfig new]);

    //set SwrveInAppMessageDelegate
    id mockMessageDelegate = OCMProtocolMock(@protocol(SwrveInAppMessageDelegate));
    OCMStub([inAppMessageConfig inAppMessageDelegate]).andReturn(mockMessageDelegate);
    config.inAppMessageConfig = inAppMessageConfig;
    
    //Dont set SwrveDeeplinkDelegate

    //Confirm open url is called internally even when we set SwrveInAppMessageDelegate
    NSURL *url = [NSURL URLWithString:@"https://google.com"];
    id mockUIApplication = OCMPartialMock([UIApplication sharedApplication]);
    OCMExpect([mockUIApplication openURL:OCMOCK_ANY options:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
    
    id swrveMock = [self swrveMockWithTestJson:@"campaigns" withConfig:config];
    
    SwrveMessageController *controller = [swrveMock messaging];
    
    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message withPersonalization: @{@"test_1":@"some personalized value1", @"test_2":@"some personalized value2"}];
    
    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    SwrveMessagePageViewController *viewController = [self loadMessagePageViewController:messageViewController];
    [viewController viewDidAppear:NO];
    
    SwrveMessageUIView *messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    for (UIView *subview in messageUiView.subviews) {
        if ([subview isKindOfClass:[SwrveUIButton class]]) {
            SwrveUIButton *swrveUIButton = (SwrveUIButton *) subview;
            if ([swrveUIButton.buttonName isEqualToString:@"custom"]) {
                SwrveMessageUIView *swrveMessageUIView = (SwrveMessageUIView*) [swrveUIButton superview];
                [swrveMessageUIView onButtonPressed:swrveUIButton];
                [self waitForWindowDismissed:controller];
                break;
            }
        }
    };
    
    [self waitForInterval:1.0];
    OCMVerifyAll(mockUIApplication);
}

- (void)testMessageCallbackCustomOpenUrlNotCalled {
    
    SwrveConfig *config = OCMPartialMock([SwrveConfig new]);
    SwrveInAppMessageConfig *inAppMessageConfig = OCMPartialMock([SwrveInAppMessageConfig new]);

    //set SwrveInAppMessageDelegate
    id mockMessageDelegate = OCMProtocolMock(@protocol(SwrveInAppMessageDelegate));
    OCMStub([inAppMessageConfig inAppMessageDelegate]).andReturn(mockMessageDelegate);
    config.inAppMessageConfig = inAppMessageConfig;
    
    //set SwrveDeeplinkDelegate
    id mockDeeplinkDelegate = OCMProtocolMock(@protocol(SwrveDeeplinkDelegate));
    OCMStub([config deeplinkDelegate]).andReturn(mockDeeplinkDelegate);
    
    //Confirm open url not called as we have set SwrveDeeplinkDelegate
    NSURL *url = [NSURL URLWithString:@"https://google.com"];
    id mockUIApplication = OCMPartialMock([UIApplication sharedApplication]);
    OCMReject([mockUIApplication openURL:url options:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
    
    //Confirm we call handleDeeplink SwrveDeeplinkDelegate, from there its up to dev to implement openurl
    OCMExpect([mockDeeplinkDelegate handleDeeplink:url]);
       
    id swrveMock = [self swrveMockWithTestJson:@"campaigns" withConfig:config];
    
    SwrveMessageController *controller = [swrveMock messaging];
    
    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message withPersonalization: @{@"test_1":@"some personalized value1", @"test_2":@"some personalized value2"}];
    
    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    SwrveMessagePageViewController *viewController = [self loadMessagePageViewController:messageViewController];
    [viewController viewDidAppear:NO];
    
    SwrveMessageUIView *messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    for (UIView *subview in messageUiView.subviews) {
        if ([subview isKindOfClass:[SwrveUIButton class]]) {
            SwrveUIButton *swrveUIButton = (SwrveUIButton *) subview;
            if ([swrveUIButton.buttonName isEqualToString:@"custom"]) {
                SwrveMessageUIView *swrveMessageUIView = (SwrveMessageUIView*) [swrveUIButton superview];
                [swrveMessageUIView onButtonPressed:swrveUIButton];
                [self waitForWindowDismissed:controller];
                break;
            }
        }
    };
    OCMVerifyAll(mockUIApplication);
    OCMVerifyAll(mockDeeplinkDelegate);
}

- (void)testMessageCallbackImpressionAndCustom {
    SwrveConfig *config = OCMPartialMock([SwrveConfig new]);
    SwrveInAppMessageConfig *inAppMessageConfig = OCMPartialMock([SwrveInAppMessageConfig new]);

    id mockMessageDelegate = OCMProtocolMock(@protocol(SwrveInAppMessageDelegate));
    OCMStub([inAppMessageConfig inAppMessageDelegate]).andReturn(mockMessageDelegate);
    config.inAppMessageConfig = inAppMessageConfig;
    
    [OCMExpect([mockMessageDelegate onAction:SwrveMessageActionImpression messageDetails:OCMOCK_ANY selectedButton:nil]) andDo:^(NSInvocation *invocation) {
  
        __unsafe_unretained SwrveMessageDetails *messageDetails;
        [invocation getArgument:&messageDetails atIndex:3];
        
        XCTAssertEqual(messageDetails.campaignId, 102);
        XCTAssertEqual(messageDetails.variantId, 165);
        XCTAssertEqualObjects(messageDetails.messageName, @"Kindle");
        XCTAssertEqual([messageDetails.buttons count], 5);
        
        __unsafe_unretained SwrveMessageButtonDetails *button;
        [invocation getArgument:&button atIndex:4];
        XCTAssertNil(button);
    }];
    
    [OCMExpect([mockMessageDelegate onAction:SwrveMessageActionCustom messageDetails:OCMOCK_ANY selectedButton:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
        
        __unsafe_unretained SwrveMessageDetails *messageDetails;
        [invocation getArgument:&messageDetails atIndex:3];
        
        XCTAssertEqual(messageDetails.campaignId, 102);
        XCTAssertEqual(messageDetails.variantId, 165);
        XCTAssertEqualObjects(messageDetails.messageName, @"Kindle");
        XCTAssertEqual([messageDetails.buttons count], 5);
        
        __unsafe_unretained SwrveMessageButtonDetails *button;
        [invocation getArgument:&button atIndex:4];
        XCTAssertEqualObjects(button.buttonName, @"custom");
        XCTAssertNil(button.buttonText);
        XCTAssertEqual(button.actionType, kSwrveActionCustom);
        XCTAssertEqualObjects(button.actionString, @"https://google.com");
    }];

    id swrveMock = [self swrveMockWithTestJson:@"campaigns" withConfig:config];
    
    SwrveMessageController *controller = [swrveMock messaging];
    
    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;
    
    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message withPersonalization: @{@"test_1":@"some personalized value1", @"test_2":@"some personalized value2"}];
    
    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    SwrveMessagePageViewController *viewController = [self loadMessagePageViewController:messageViewController];
    [viewController viewDidAppear:NO];
    
    SwrveMessageUIView *messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    for (UIView *subview in messageUiView.subviews) {
        if ([subview isKindOfClass:[SwrveUIButton class]]) {
            SwrveUIButton *swrveUIButton = (SwrveUIButton *) subview;
            if ([swrveUIButton.buttonName isEqualToString:@"custom"]) {
                SwrveMessageUIView *swrveMessageUIView = (SwrveMessageUIView*) [swrveUIButton superview];
                [swrveMessageUIView onButtonPressed:swrveUIButton];
                [self waitForWindowDismissed:controller];
                break;
            }
        }
    };
    
    [self waitForInterval:1.0];
    OCMVerifyAll(mockMessageDelegate);
}

- (void)testMessageCallbackImpressionAndDismiss {
    SwrveConfig *config = [[SwrveConfig alloc]init];
    SwrveInAppMessageConfig *inAppMessageConfig = OCMPartialMock([SwrveInAppMessageConfig new]);

    id mockMessageDelegate = OCMProtocolMock(@protocol(SwrveInAppMessageDelegate));
    OCMStub([inAppMessageConfig inAppMessageDelegate]).andReturn(mockMessageDelegate);
    config.inAppMessageConfig = inAppMessageConfig;
    
    [OCMExpect([mockMessageDelegate onAction:SwrveMessageActionImpression messageDetails:OCMOCK_ANY selectedButton:nil]) andDo:^(NSInvocation *invocation) {
  
        __unsafe_unretained SwrveMessageDetails *messageDetails;
        [invocation getArgument:&messageDetails atIndex:3];
        
        XCTAssertEqual(messageDetails.campaignId, 102);
        XCTAssertEqual(messageDetails.variantId, 165);
        XCTAssertEqualObjects(messageDetails.messageName, @"Kindle");
        XCTAssertEqual([messageDetails.buttons count], 5);
        
        __unsafe_unretained SwrveMessageButtonDetails *button;
        [invocation getArgument:&button atIndex:4];
        XCTAssertNil(button);
    }];
    
    [OCMExpect([mockMessageDelegate onAction:SwrveMessageActionDismiss messageDetails:OCMOCK_ANY selectedButton:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
        
        __unsafe_unretained SwrveMessageDetails *messageDetails;
        [invocation getArgument:&messageDetails atIndex:3];
        
        XCTAssertEqual(messageDetails.campaignId, 102);
        XCTAssertEqual(messageDetails.variantId, 165);
        XCTAssertEqualObjects(messageDetails.messageName, @"Kindle");
        XCTAssertEqual([messageDetails.buttons count], 5);
        
        __unsafe_unretained SwrveMessageButtonDetails *button;
        [invocation getArgument:&button atIndex:4];
        XCTAssertEqualObjects(button.buttonName, @"close");
        XCTAssertNil(button.buttonText);
        XCTAssertEqual(button.actionType, kSwrveActionDismiss);
        XCTAssertEqualObjects(button.actionString, @"");
    }];
    
    id swrveMock = [self swrveMockWithTestJson:@"campaigns" withConfig:config];

    SwrveMessageController *controller = [swrveMock messaging];
    
    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;
    
    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message withPersonalization: @{@"test_1":@"some personalized value1", @"test_2":@"some personalized value2"}];
    
    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    SwrveMessagePageViewController *viewController = [self loadMessagePageViewController:messageViewController];
    [viewController viewDidAppear:NO];
    
    SwrveMessageUIView *messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    for (UIView *subview in messageUiView.subviews) {
        if ([subview isKindOfClass:[SwrveUIButton class]]) {
            SwrveUIButton *swrveUIButton = (SwrveUIButton *) subview;
            if ([swrveUIButton.buttonName isEqualToString:@"close"]) {
                SwrveMessageUIView *swrveMessageUIView = (SwrveMessageUIView*) [swrveUIButton superview];
                [swrveMessageUIView onButtonPressed:swrveUIButton];
                [self waitForWindowDismissed:controller];
                break;
            }
        }
    };
    [self waitForInterval:1.0];
    OCMVerifyAll(mockMessageDelegate);
}

- (void)testDeeplinkDelegateCalled {
    //set deeplink delegate on config, confirm open url not called and delegate method called.

    id testDeeplinkDelegate =  OCMPartialMock([TestDeeplinkDelegate2 new]);
    NSURL *url = [NSURL URLWithString:@"https://google.com"];
    OCMExpect([testDeeplinkDelegate handleDeeplink:url]);
    
    id mockUIApplication = OCMPartialMock([UIApplication sharedApplication]);
    OCMReject([mockUIApplication openURL:url options:OCMOCK_ANY completionHandler:OCMOCK_ANY]);

    SwrveConfig *config = [SwrveConfig new];
    config.deeplinkDelegate = testDeeplinkDelegate;
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
    [SwrveSDK addSharedInstance:swrveMock];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey" config:config];
#pragma clang diagnostic pop
    
    SwrveMessageController *controller = [swrveMock messaging];
    controller.inAppMessageWindow = [UIWindow new];
    controller.inAppMessageAction = @"https://google.com";
    controller.inAppMessageActionType = kSwrveActionCustom;
    
    [controller dismissMessageWindow];
    
    OCMVerifyAll(testDeeplinkDelegate);
    OCMVerifyAll(mockUIApplication);
    [mockUIApplication stopMocking];
}

- (void)testDeeplinkDelegateNotCalled {
    //dont set deeplink delegate on config, confirm open url called

    id testDeeplinkDelegate =  OCMPartialMock([TestDeeplinkDelegate2 new]);
    NSURL *url = [NSURL URLWithString:@"https://google.com"];
    OCMReject([testDeeplinkDelegate handleDeeplink:url]);
    
    id mockUIApplication = OCMPartialMock([UIApplication sharedApplication]);
    OCMExpect([mockUIApplication openURL:url options:OCMOCK_ANY completionHandler:OCMOCK_ANY]);

    SwrveConfig *config = [SwrveConfig new];
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
    [SwrveSDK addSharedInstance:swrveMock];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey" config:config];
#pragma clang diagnostic pop
    
    SwrveMessageController *controller = [swrveMock messaging];
    controller.inAppMessageWindow = [UIWindow new];
    controller.inAppMessageAction = @"https://google.com";
    controller.inAppMessageActionType = kSwrveActionCustom;
    
    [controller dismissMessageWindow];
    
    OCMVerifyAll(testDeeplinkDelegate);
    OCMVerifyAll(mockUIApplication);
    [mockUIApplication stopMocking];
}

- (void)waitForInterval:(NSTimeInterval)interval {
    NSDate *delay = [[NSDate date] dateByAddingTimeInterval:interval];
    XCTestExpectation *expectation = [self expectationWithDescription:@"WaitForInterval"];
    [SwrveTestHelper waitForBlock:0.01 conditionBlock:^BOOL() {
        return ([[NSDate date] compare:delay] == NSOrderedDescending);
    }                 expectation:expectation];
    [self waitForExpectationsWithTimeout:30.0 handler:nil];
}

- (void)waitForWindowDismissed:(SwrveMessageController *)controller {
    XCTestExpectation *expectation = [self expectationWithDescription:@"WindowDismissed"];
    [SwrveTestHelper waitForBlock:0.005 conditionBlock:^BOOL() {
        return controller.inAppMessageWindow == nil;
    }                 expectation:expectation];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (SwrveMessageViewController *)messageViewControllerFrom:(SwrveMessageController *)controller {
    SwrveMessageViewController *viewController = (SwrveMessageViewController *) [[controller inAppMessageWindow] rootViewController];
    return viewController;
}

- (SwrveMessageUIView *)swrveMessageUIViewFromController:(SwrveMessageViewController *)viewController {
    SwrveMessagePageViewController *messagePageViewController = [self loadMessagePageViewController:viewController];
    return [[[messagePageViewController view] subviews] firstObject];
}

- (SwrveMessagePageViewController*)loadMessagePageViewController:(SwrveMessageViewController*) messageViewController {
    SwrveMessagePageViewController *messagePageViewController = nil;
#if TARGET_OS_TV
    messagePageViewController = [messageViewController.childViewControllers firstObject];
#else
    messagePageViewController = [messageViewController.viewControllers firstObject];
#endif
    [messagePageViewController viewDidAppear:NO];
    [messagePageViewController viewWillAppear:NO];
    return messagePageViewController;
}

- (BOOL)pressSwrveUIButton:(UIView *)view name:(NSString *)buttonName {
    BOOL pressed = NO;
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[SwrveUIButton class]]) {
            SwrveUIButton *swrveUIButton = (SwrveUIButton *) subview;
            if ([swrveUIButton.displayString isEqualToString:buttonName]) {
                [swrveUIButton sendActionsForControlEvents:UIControlEventTouchUpInside];
                pressed = YES;
                break;
            }
        }
    };
    return pressed;
}

@end
