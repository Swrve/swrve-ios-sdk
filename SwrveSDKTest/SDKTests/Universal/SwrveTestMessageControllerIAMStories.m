#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SwrveTestHelper.h"
#import "TestCapabilitiesDelegate.h"

#if TARGET_OS_IOS
#import "SwrvePermissions.h"
#endif //TARGET_OS_IOS


@interface Swrve ()
@property (nonatomic) SwrveReceiptProvider *receiptProvider;
@property (nonatomic) SwrveMessageController *message;
- (NSDate *)getNow;
- (void)initSwrveRestClient:(NSTimeInterval)timeOut urlSssionDelegate:(id <NSURLSessionDelegate>)urlSssionDelegate;
- (int)sessionStart;
- (void)suspend:(BOOL)terminating;
- (void)appDidBecomeActive:(NSNotification *)notification;
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
- (void)updateCampaigns:(NSDictionary *)campaignJson withLoadingPreviousCampaignState:(BOOL) isLoadingPreviousCampaignState notifyCampaignsUpdated:(BOOL)notifyCampaignsUpdated;
- (SwrveBaseMessage *)baseMessageForEvent:(NSString *)eventName withPayload:(NSDictionary *)payload;
- (void)showMessage:(SwrveMessage *)message;
- (void)messageWasShownToUser:(SwrveMessage *)message;
- (void)startSwrveGeoSDK;
- (bool)shouldStartSwrveGeoSDK;
@property (nonatomic) bool autoShowMessagesEnabled;
@property (nonatomic, retain) SwrveAssetsManager *assetsManager;
@property (nonatomic, retain) NSString *user;
@property (nonatomic, retain) NSString *apiKey;
@property (nonatomic, retain) NSMutableDictionary *campaignsState;
@property (nonatomic, retain) NSString *server;
@property (nonatomic, retain) NSString *language;
@property (nonatomic) SwrveInterfaceOrientation orientation;
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

@interface SwrveTestMessageControllerIAMStories : XCTestCase

@property NSDate *swrveNowDate;
+ (NSArray*)testJSONAssets;
@end

@implementation SwrveTestMessageControllerIAMStories

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
    [SwrveTestHelper createDummyAssets:[SwrveTestMessageControllerIAMStories testJSONAssets]];
    self.swrveNowDate = [NSDate dateWithTimeIntervalSince1970:1362873600];
    
    [UIView setAnimationsEnabled: NO];
    [CATransaction setDisableActions: NO];

}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    
    [UIView setAnimationsEnabled: YES];
    [CATransaction setDisableActions: YES];
    
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
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:isLoadingPreviousCampaignState notifyCampaignsUpdated:NO];
    
    return swrveMock;
}

- (void)testJsonParserStorySettings {
    [SwrveLocalStorage saveSwrveUserId:@"someUserID"];
    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];
    [config setContentServer:@"someContentServer"];
    [config setOrientation:SWRVE_ORIENTATION_BOTH];
    id swrveMock = [self swrveMockWithTestJson:@"campaigns" withConfig:config];
    SwrveMessageController *controller = [swrveMock messaging];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"in_app_story_campaign" ofType:@"json"];
    NSData *mockJsonData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockJsonData options:0 error:nil];
    [controller updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO notifyCampaignsUpdated:NO];
    XCTAssertEqual([[controller campaigns] count], 1);

    SwrveInAppCampaign *campaign = [[controller campaigns] firstObject];
    SwrveMessage *message = campaign.message;
    XCTAssertNotNil(message);
    SwrveMessageFormat* format = [[message formats] firstObject];
    XCTAssertNotNil(format);

    SwrveStorySettings *storySettings = [format storySettings];
    XCTAssertNotNil(storySettings);
    XCTAssertEqual(7500, [[storySettings pageDuration] intValue]);
    XCTAssertEqual(kSwrveStoryLastPageProgressionDismiss, [storySettings lastPageProgression]);
    XCTAssertEqual(1, [[storySettings topPadding] intValue]);
    XCTAssertEqual(2, [[storySettings leftPadding] intValue]);
    XCTAssertEqual(4, [[storySettings rightPadding] intValue]);
    XCTAssertEqualObjects(@"#fffffffa", [storySettings barColor]);
    XCTAssertEqualObjects(@"#fffffffb", [storySettings barBgColor]);
    XCTAssertEqual(10, [[storySettings barHeight] intValue]);
    XCTAssertEqual(6, [[storySettings segmentGap] intValue]);
    
    XCTAssertTrue([storySettings gesturesEnabled]);
    
    SwrveStoryDismissButton *dismissButton = [storySettings dismissButton];
    XCTAssertNotNil(dismissButton);
    XCTAssertEqual(12345, [[dismissButton buttonId] intValue]);
    XCTAssertEqualObjects(@"Dismiss?", [dismissButton name]);
    XCTAssertEqualObjects(@"#fffffffc", [dismissButton color]);
    XCTAssertEqualObjects(@"#fffffffd", [dismissButton pressedColor]);
    XCTAssertEqualObjects(@"#fffffffe", [dismissButton focusedColor]);
    XCTAssertEqual(15, [[dismissButton size] intValue]);
    XCTAssertEqual(11, [[dismissButton marginTop] intValue]);
    XCTAssertEqualObjects(@"Dismiss", [dismissButton accessibilityText]);
}

- (void)testInAppStoryDifferentDataJSON {
    SwrveStorySettings *storySettings1 = [self dummyStorySettings:@"loop" hasGestures:NO gesturesEnabled:YES hasDismissButton:YES];
    XCTAssertEqual(kSwrveStoryLastPageProgressionLoop, [storySettings1 lastPageProgression]);
    XCTAssertTrue([storySettings1 gesturesEnabled]);
    XCTAssertNotNil([storySettings1 dismissButton]);

    SwrveStorySettings *storySettings2 = [self dummyStorySettings:@"stop" hasGestures:YES gesturesEnabled:NO hasDismissButton:NO];
    XCTAssertEqual(kSwrveStoryLastPageProgressionStop, [storySettings2 lastPageProgression]);
    XCTAssertFalse([storySettings2 gesturesEnabled]);
    XCTAssertNil([storySettings2 dismissButton]);

    SwrveStorySettings *storySettings3 = [self dummyStorySettings:@"dismiss" hasGestures:YES gesturesEnabled:YES hasDismissButton:NO];
    XCTAssertEqual(kSwrveStoryLastPageProgressionDismiss, [storySettings3 lastPageProgression]);
    XCTAssertEqual(12345, [[storySettings3 lastPageDismissId] intValue]);
    XCTAssertEqualObjects(@"Auto dismiss?", [storySettings3 lastPageDismissName]);
    XCTAssertTrue([storySettings3 gesturesEnabled]);
    XCTAssertNil([storySettings3 dismissButton]);
}

- (SwrveStorySettings *)dummyStorySettings:(NSString *)lastPageProgression
                           hasGestures:(BOOL)hasGestures
                        gesturesEnabled:(BOOL)gestureEnabled
                      hasDismissButton:(BOOL)hasDismissButton {
    NSString *json = [NSString stringWithFormat:@"{\n"
                      "\"page_duration\": 7500,\n"
                      "\"last_page_progression\": \"%@\",\n", lastPageProgression];

    if ([lastPageProgression isEqualToString:@"dismiss"]) {
        json = [json stringByAppendingString:@"\"last_page_dismiss_id\" : 12345,\n"];
        json = [json stringByAppendingString:@"\"last_page_dismiss_name\" : \"Auto dismiss?\",\n"];
    }

    if (hasGestures) {
        json = [json stringByAppendingFormat:@"\"gestures_enabled\": %@,\n", gestureEnabled ? @"true" : @"false"];
    }

    json = [json stringByAppendingString:
            @"\"padding\": "
                "{\n\"top\": 1,\n\"left\": 2,\n\"bottom\": 3,\n\"right\": 4\n},\n"
            "\"progress_bar\": "
                "{\n\"bar_color\": \"#ffffffff\",\n"
                "\"bg_color\": \"#ffffffff\",\n"
                "\"w\": -1,\n"
                "\"h\": 10,\n"
                "\"segment_gap\": 6\n"
            "}\n"];

    if (hasDismissButton) {
        json = [json stringByAppendingString:@""
                ",\n"
                "\"dismiss_button\": {\n"
                    "\"id\": 12345,\n"
                    "\"name\": \"Dismiss?\",\n"
                    "\"color\": \"#ffffffff\",\n"
                    "\"pressed_color\": \"#ffffffff\",\n"
                    "\"focused_color\": \"#ffffffff\",\n"
                    "\"size\": 7,\n"
                    "\"margin_top\": 8,\n"
                    "\"accessibility_text\": \"Dismiss\""
                "\n}"
            "}"];
    } else {
        json = [json stringByAppendingString:@"}"];
    }

    NSError *error;
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if (error) {
        NSLog(@"Error creating JSON object: %@", error);
        return nil;
    }

    SwrveStorySettings *settings = [[SwrveStorySettings alloc] initWithDictionary:jsonObject];
    return settings;
}

- (void)testInAppStoryDismissButton {
    NSArray *assets = @[@"6c871366c876fdb495d96eff3d2905f9d4594c62"];
    [SwrveTestHelper createDummyAssets:assets];
    id swrveMock = [self swrveMockWithTestJson:@"campaigns_in_app_story_single_page"];
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 1);

    SwrveMessageController *controller = [swrveMock messaging];
    SwrveCampaign *campaign = [[swrveMock messageCenterCampaigns] objectAtIndex:0];
    [controller showMessageCenterCampaign:campaign];

    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    [self waitForStoryProgression:messageViewController toPageId:1]; // wait for the story to progress to the last page
    XCTAssertEqual([messageViewController.storyView currentIndex], 0);

    // Setup expectation for generic_campaign_event dismiss event
    NSMutableDictionary *eventData = [NSMutableDictionary new];
    [eventData setValue:[NSNumber numberWithLong:654665] forKey:@"id"];
    [eventData setValue:@"dismiss" forKey:@"actionType"];
    [eventData setValue:[NSNumber numberWithLong:1] forKey:@"contextId"];
    [eventData setValue:@"iam" forKey:@"campaignType"];
    NSMutableDictionary *eventPayload = [NSMutableDictionary new];
    [eventPayload setValue:@"Page 1" forKey:@"pageName"];
    [eventPayload setValue:@"Dismiss?" forKey:@"buttonName"];
    [eventPayload setValue:[NSNumber numberWithLong:12345] forKey:@"buttonId"];
#if TARGET_OS_TV
    [eventPayload setValue:@"tv" forKey:@"deviceType"];
    [eventPayload setValue:@"tvos" forKey:@"platform"];
#else
    [eventPayload setValue:@"mobile" forKey:@"deviceType"];
    [eventPayload setValue:@"ios" forKey:@"platform"];
#endif
    [eventData setValue:eventPayload forKey:@"payload"];
    OCMExpect([swrveMock queueEvent:@"generic_campaign_event" data:eventData triggerCallback:false]);

    XCTAssertNotNil(messageViewController.storyDismissButton);
    XCTAssertEqualObjects(messageViewController.storyDismissButton.accessibilityLabel, @"Dismiss");
    XCTAssertEqualObjects(messageViewController.storyDismissButton.accessibilityHint, @"Button");
    XCTAssertEqual(messageViewController.storyDismissButton.currentImage.renderingMode, UIImageRenderingModeAlwaysTemplate); // default image uses svg

    // press the dismiss button
    [messageViewController.storyDismissButton sendActionsForControlEvents:UIControlEventTouchUpInside];

    [self waitForWindowDismissed:controller];
    OCMVerifyAllWithDelay(swrveMock, 1);
}


- (void)testInAppStoryWithCustomDismissButtonImage {
    NSArray *assets = @[@"6c871366c876fdb495d96eff3d2905f9d4594c62"];
    [SwrveTestHelper createDummyAssets:assets];

    SwrveConfig *config = [[SwrveConfig alloc] init];
    SwrveInAppMessageConfig *inAppConfig = [SwrveInAppMessageConfig new];
    if (@available(iOS 13.0, *)) {
        inAppConfig.storyDismissButton = [UIImage systemImageNamed:@"info.circle.fill"];
    }
    if (@available(iOS 13.0, *)) {
        inAppConfig.storyDismissButtonHighlighted = [UIImage systemImageNamed:@"info.circle.fill"];
    }    
    config.inAppMessageConfig = inAppConfig;
    id swrveMock = [self swrveMockWithTestJson:@"campaigns_in_app_story_single_page" withConfig:config];
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 1);

    SwrveMessageController *controller = [swrveMock messaging];
    SwrveInAppCampaign *campaign = (SwrveInAppCampaign*)[[swrveMock messageCenterCampaigns] objectAtIndex:0];
    [controller showMessageCenterCampaign:campaign];

    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    [self waitForStoryProgression:messageViewController toPageId:1]; // wait for the story to progress to the last page
    XCTAssertEqual([messageViewController.storyView currentIndex], 0);

    XCTAssertNotNil(messageViewController.storyDismissButton);

    // check the dismiss button image is set correctly
    UIImage *dismissButtonImage = [messageViewController.storyDismissButton imageForState:UIControlStateNormal];
    UIImage *dismissButtonImagePressed = [messageViewController.storyDismissButton imageForState:UIControlStateHighlighted];
    XCTAssertNotNil(dismissButtonImage);
    XCTAssertNotNil(dismissButtonImagePressed);
    XCTAssertEqual(dismissButtonImage.renderingMode, UIImageRenderingModeAutomatic);
    XCTAssertEqual(dismissButtonImagePressed.renderingMode, UIImageRenderingModeAutomatic);
}
 
- (void)testInAppStoryLastPageStop {
    NSArray *assets = @[@"6c871366c876fdb495d96eff3d2905f9d4594c62"];
    [SwrveTestHelper createDummyAssets:assets];
    id swrveMock = [self swrveMockWithTestJson:@"campaigns_in_app_story"];
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 1);

    SwrveMessageController *controller = [swrveMock messaging];
    SwrveCampaign *campaign = [[swrveMock messageCenterCampaigns] objectAtIndex:0];
    [controller showMessageCenterCampaign:campaign];

    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    [self waitForStoryProgression:messageViewController toPageId:5]; // wait until progression to last page
    XCTAssertEqual([messageViewController.storyView currentIndex], 4);

    // Press button on page 5 which should go to page 3 but the page progression should continue
    SwrveMessageUIView *messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    [self pressSwrveUIButton:messageUiView name:@"Back to page 3"];
    [self waitForStoryProgression:messageViewController toPageId:3];
    
    [self waitForStoryProgression:messageViewController toPageId:5];
    XCTAssertEqual([messageViewController.storyView currentIndex], 4); // wait until progression to last page
}

- (void)testInAppStoryLastPageDismiss {
    NSArray *assets = @[@"6c871366c876fdb495d96eff3d2905f9d4594c62"];
    [SwrveTestHelper createDummyAssets:assets];
    id swrveMock = [self swrveMockWithTestJson:@"campaigns_in_app_story_dismiss"];
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 1);

    NSMutableDictionary *eventData = [NSMutableDictionary new];
    [eventData setValue:[NSNumber numberWithLong:654665] forKey:@"id"];
    [eventData setValue:@"dismiss" forKey:@"actionType"];
    [eventData setValue:[NSNumber numberWithLong:2] forKey:@"contextId"];
    [eventData setValue:@"iam" forKey:@"campaignType"];
    NSMutableDictionary *eventPayload = [NSMutableDictionary new];
    [eventPayload setValue:@"Page 2" forKey:@"pageName"];
    [eventPayload setValue:@"Auto dismiss?" forKey:@"buttonName"];
    [eventPayload setValue:[NSNumber numberWithLong:111111] forKey:@"buttonId"];
#if TARGET_OS_TV
    [eventPayload setValue:@"tv" forKey:@"deviceType"];
    [eventPayload setValue:@"tvos" forKey:@"platform"];
#else
    [eventPayload setValue:@"mobile" forKey:@"deviceType"];
    [eventPayload setValue:@"ios" forKey:@"platform"];
#endif
    [eventData setValue:eventPayload forKey:@"payload"];
    OCMExpect([swrveMock queueEvent:@"generic_campaign_event" data:eventData triggerCallback:false]);

    SwrveMessageController *controller = [swrveMock messaging];
    SwrveInAppCampaign *campaign = (SwrveInAppCampaign*)[[swrveMock messageCenterCampaigns] objectAtIndex:0];
    [controller showMessageCenterCampaign:campaign];

    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    [self waitForStoryProgression:messageViewController toPageId:2]; // wait for the story to progress to the last page
    XCTAssertEqual([messageViewController.storyView currentIndex], 1);

    [self waitForWindowDismissed:controller]; // wait for the iam to be dismissed

    OCMVerifyAllWithDelay(swrveMock, 1);
}

//TODO fix this
//- (void)testInAppStoryLastPageLoop {
//    NSArray *assets = @[@"6c871366c876fdb495d96eff3d2905f9d4594c62"];
//    [SwrveTestHelper createDummyAssets:assets];
//    id swrveMock = [self swrveMockWithTestJson:@"campaigns_in_app_story_loop"];
//    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 1);
//
//    SwrveMessageController *controller = [swrveMock messaging];
//    SwrveInAppCampaign *campaign = (SwrveInAppCampaign*)[[swrveMock messageCenterCampaigns] objectAtIndex:0];
//    [controller showMessageCenterCampaign:campaign];
//
//    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
//    [self waitForStoryProgression:messageViewController toPageId:2]; // wait for the story to progress to the last page
//    XCTAssertEqual([messageViewController.storyView currentIndex], 1);
//
//    // after last page reached, wait for the story to loop back to start and continue progression
//    [self waitForStoryProgression:messageViewController toPageId:1];
//    XCTAssertEqual([messageViewController.storyView currentIndex], 0);
//    [self waitForStoryProgression:messageViewController toPageId:2];
//    XCTAssertEqual([messageViewController.storyView currentIndex], 1);
//}

- (void)testInAppStoryGesturesEnabled {
    NSArray *assets = @[@"6c871366c876fdb495d96eff3d2905f9d4594c62"];
    [SwrveTestHelper createDummyAssets:assets];
    id swrveMock = [self swrveMockWithTestJson:@"campaigns_in_app_story"];
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 1);

    SwrveMessageController *controller = [swrveMock messaging];
    SwrveCampaign *campaign = [[swrveMock messageCenterCampaigns] objectAtIndex:0];
    [controller showMessageCenterCampaign:campaign];

    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    UITapGestureRecognizer *tapGestureRecognizer = nil;
    for (UIGestureRecognizer *gestureRecognizer in messageViewController.view.gestureRecognizers) {
        if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
            tapGestureRecognizer = (UITapGestureRecognizer *) gestureRecognizer;
            break;
        }
    }
#if TARGET_OS_TV
    XCTAssertNil(tapGestureRecognizer, @"Tap gesture recognizer should be nil in tvOS");
#else
    XCTAssertNotNil(tapGestureRecognizer, @"Tap gesture recognizer should not be nil");
    XCTAssertEqual(tapGestureRecognizer.numberOfTapsRequired, 1, @"Number of taps should be 1");
#endif
}

- (void)testInAppStoryGesturesDisabled {
    NSArray *assets = @[@"6c871366c876fdb495d96eff3d2905f9d4594c62"];
    [SwrveTestHelper createDummyAssets:assets];
    id swrveMock = [self swrveMockWithTestJson:@"campaigns_in_app_story"];
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 1);

    SwrveMessageController *controller = [swrveMock messaging];
    SwrveInAppCampaign *campaign = (SwrveInAppCampaign*)[[swrveMock messageCenterCampaigns] objectAtIndex:0];
    SwrveMessageFormat *format = campaign.message.formats[0];
    format.storySettings.gesturesEnabled = NO; // change gesturesEnabled to NO
    [controller showMessageCenterCampaign:campaign];

    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    UITapGestureRecognizer *tapGestureRecognizer = nil;
    for (UIGestureRecognizer *gestureRecognizer in messageViewController.view.gestureRecognizers) {
        if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
            tapGestureRecognizer = (UITapGestureRecognizer *) gestureRecognizer;
            break;
        }
    }
    XCTAssertNil(tapGestureRecognizer, @"Tap gesture recognizer should be nil because gesturesEnabled is NO");
}

- (void)testInAppStoryHandleTap {
    NSArray *assets = @[@"6c871366c876fdb495d96eff3d2905f9d4594c62"];
    [SwrveTestHelper createDummyAssets:assets];
    id swrveMock = [self swrveMockWithTestJson:@"campaigns_in_app_story"];
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 1);

    SwrveMessageController *controller = [swrveMock messaging];
    SwrveInAppCampaign *campaign = (SwrveInAppCampaign *) [[swrveMock messageCenterCampaigns] objectAtIndex:0];
    SwrveMessageFormat *format = campaign.message.formats[0];
    format.storySettings.pageDuration = [NSNumber numberWithInt:INT_MAX]; // change page duration to max so that the story does not progress automatically
    [controller showMessageCenterCampaign:campaign];
    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];

    id mockLeftTap = OCMPartialMock([[UITapGestureRecognizer alloc] init]);
    CGPoint leftTapLocation = CGPointMake(CGRectGetWidth(messageViewController.view.bounds) * 0.25, CGRectGetHeight(messageViewController.view.bounds) / 2.0);
    OCMStub([mockLeftTap locationInView:OCMOCK_ANY]).andReturn(leftTapLocation);

    id mockRightTap = OCMPartialMock([[UITapGestureRecognizer alloc] init]);
    CGPoint rightTapLocation = CGPointMake(CGRectGetWidth(messageViewController.view.bounds) * 0.75, CGRectGetHeight(messageViewController.view.bounds) / 2.0);
    OCMStub([mockRightTap locationInView:OCMOCK_ANY]).andReturn(rightTapLocation);

    // start page 1
    [self waitForStoryProgression:messageViewController toPageId:1];
    XCTAssertEqual([messageViewController.storyView currentIndex], 0);

    // tap left should remain on page 1
    [messageViewController handleTap:mockLeftTap];
    [self waitForStoryProgression:messageViewController toPageId:1];
    XCTAssertEqual([messageViewController.storyView currentIndex], 0);

    // tap right to page 2
    [messageViewController handleTap:mockRightTap];
    [self waitForStoryProgression:messageViewController toPageId:2];
    XCTAssertEqual([messageViewController.storyView currentIndex], 1);

    // tap left to page 1
    [messageViewController handleTap:mockLeftTap];
    [self waitForStoryProgression:messageViewController toPageId:1];
    XCTAssertEqual([messageViewController.storyView currentIndex], 0);

    OCMVerify([mockLeftTap locationInView:messageViewController.view]);
    OCMVerify([mockRightTap locationInView:messageViewController.view]);
}

- (void)testIAMPageElementOrder_iam_z_index {
    NSArray *assets = @[@"asset1"];
    [SwrveTestHelper createDummyAssets:assets];
    id swrveMock = [self swrveMockWithTestJson:@"campaigns_iam_z_index_tests"];
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 2);

    SwrveMessageController *controller = [swrveMock messaging];
    SwrveInAppCampaign *campaign = (SwrveInAppCampaign *) [swrveMock messageCenterCampaignWithID:1 andPersonalization:nil]; // campign id 1
    XCTAssertNotNil(campaign);
    [controller showMessageCenterCampaign:campaign];
    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    SwrveMessageUIView *messageUiView = [self swrveMessageUIViewFromController:messageViewController];

    // test that the order of page elements is the same as defined by the iam_z_index in the json
    XCTAssertTrue([messageUiView.subviews[0] isKindOfClass:[SwrveUIButton class]], @"Expected SwrveButtonView");
    XCTAssertTrue([messageUiView.subviews[1] isKindOfClass:[SwrveThemedUIButton class]], @"Expected SwrveThemedUIButton");
    XCTAssertTrue([messageUiView.subviews[2] isKindOfClass:[SwrveUITextView class]], @"Expected SwrveUITextView");
    XCTAssertTrue([messageUiView.subviews[3] isKindOfClass:[UIImageView class]], @"Expected UIImageView");
}

- (void)testIAMPageElementOrder_json_array {
    NSArray *assets = @[@"asset1"];
    [SwrveTestHelper createDummyAssets:assets];
    id swrveMock = [self swrveMockWithTestJson:@"campaigns_iam_z_index_tests"];
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 2);

    SwrveMessageController *controller = [swrveMock messaging];
    SwrveInAppCampaign *campaign = (SwrveInAppCampaign *) [swrveMock messageCenterCampaignWithID:2 andPersonalization:nil]; // campign id 2
    XCTAssertNotNil(campaign);
    [controller showMessageCenterCampaign:campaign];
    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    SwrveMessageUIView *messageUiView = [self swrveMessageUIViewFromController:messageViewController];

    // test that the order of page elements is the same as the order in the json array
    XCTAssertTrue([messageUiView.subviews[0] isKindOfClass:[SwrveUITextView class]], @"Expected SwrveUITextView");
    XCTAssertTrue([messageUiView.subviews[1] isKindOfClass:[UIImageView class]], @"Expected UIImageView");
    XCTAssertTrue([messageUiView.subviews[2] isKindOfClass:[SwrveUIButton class]], @"Expected SwrveUIButton");
    XCTAssertTrue([messageUiView.subviews[3] isKindOfClass:[SwrveThemedUIButton class]], @"Expected SwrveThemedUIButton");
    
}

- (void)waitForStoryProgression:(SwrveMessageViewController *)messageViewController toPageId:(int)pageId {
    NSString *expectationDescription = [NSString stringWithFormat:@"CurrentPageId should be %d", pageId];
    XCTestExpectation *expectation = [self expectationWithDescription:expectationDescription];
    [SwrveTestHelper waitForBlock:0.05 conditionBlock:^BOOL() {
        return [[messageViewController currentPageId] integerValue] == pageId;
    }                 expectation:expectation];
    [self waitForExpectationsWithTimeout:40.0 handler:nil];
}

- (void)waitForWindowDismissed:(SwrveMessageController *)controller {
    XCTestExpectation *expectation = [self expectationWithDescription:@"WindowDismissed"];
    [SwrveTestHelper waitForBlock:0.005 conditionBlock:^BOOL() {
        return controller.inAppMessageWindow == nil;
    }                 expectation:expectation];
    [self waitForExpectationsWithTimeout:6.0 handler:nil];
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
