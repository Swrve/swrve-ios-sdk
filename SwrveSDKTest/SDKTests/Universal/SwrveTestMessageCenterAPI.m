#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <SwrveMessagePage.h>
#import <SwrveMessagePageViewController.h>
#import "SwrveTestHelper.h"

#import "SwrveMessage.h"
#import "SwrveMessageController.h"
#import "SwrveMessageViewController.h"
#import "SwrveAssetsManager.h"
#import "UISwrveButton.h"
#import "SwrveUtils.h"
#import "SwrveButton.h"
#import "SwrveCampaign.h"
#import "SwrveSDK.h"
#import "SwrvePrivateAccess.h"

@interface Swrve()
@property (atomic) SwrveRESTClient *restClient;
@property(atomic) SwrveMessageController *messaging;

- (void)initSwrveRestClient:(NSTimeInterval)timeOut urlSssionDelegate:(id <NSURLSessionDelegate>)urlSssionDelegate;
- (void)appDidBecomeActive:(NSNotification *)notification;
@end

@interface SwrveMessageController ()

- (id)initWithSwrve:(Swrve*)sdk;
- (void)writeToCampaignCache:(NSData*)campaignData;
- (void)updateCampaigns:(NSDictionary *)campaignDic withLoadingPreviousCampaignState:(BOOL) isLoadingPreviousCampaignState;
- (NSDate *)getNow;
@property (nonatomic, retain) SwrveAssetsManager *assetsManager;
@property (nonatomic, retain) UIWindow *inAppMessageWindow;
@property (nonatomic, retain) NSDate *initialisedTime;
@end

@interface SwrveTestMessageCenterAPI : XCTestCase

@end

@implementation SwrveTestMessageCenterAPI

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

+ (NSArray *)testJSONAssets {
    static NSArray *assets = nil;
    if (!assets) {
        assets = @[
                   @"8f984a803374d7c03c97dd122bce3ccf565bbdb5",
                   @"8721fd4e657980a5e12d498e73aed6e6a565dfca",
                   @"97c5df26c8e8fcff8dbda7e662d4272a6a94af7e",
                   ];
    }
    return assets;
}

- (id)swrveMock {
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
    
    // mock rest calls with success and empty data
    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
    id mockRestClient = OCMPartialMock(restClient);
    id mockResponse = OCMClassMock([NSHTTPURLResponse class]);
    OCMExpect([mockResponse statusCode]).andReturn(200);
    NSData *mockData = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
    OCMStub([mockRestClient sendHttpRequest:OCMOCK_ANY
                          completionHandler:([OCMArg invokeBlockWithArgs:mockResponse, mockData, [NSNull null], nil])]);
    
    OCMStub([swrveMock initSwrveRestClient:60 urlSssionDelegate:nil]).andDo(^(NSInvocation *invocation) {
        swrve.restClient = mockRestClient;
    });
    
     return swrveMock;
}

- (void)testMessageCenterWithOnlyNonMessageCenterCampaigns {
    [SwrveTestHelper createDummyAssets:[SwrveTestMessageCenterAPI testJSONAssets]];
    
    id swrveMock = [self swrveMock];
    
    // mock date that lies within the start and end time of the campaign in the test json file campaigns
    // we do this to pass: checkGlobalRules
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaigns" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockData options:0 error:nil];
    
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO];

    // No Message Center campaigns
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 0);
}

- (void)testIAMMessageCenter {
#if TARGET_OS_IOS
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];
#endif

    [SwrveTestHelper createDummyAssets:[SwrveTestMessageCenterAPI testJSONAssets]];

    id swrveMock = [self swrveMock];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop

    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsMessageCenter" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockData options:0 error:nil];

    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO];

    SwrveMessageController* controller = [swrveMock messaging];

    // No Message Center campaigns as they have both finished
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 0);

    // mock date that lies within the start and end time of the campaign in the test json file campaignsMessageCenter
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);

    // IAM, Embedded and Conversation support these orientations
#if TARGET_OS_IOS
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 3);
    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationLandscapeRight] count], 3);
    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationPortrait] count], 3);
#elif TARGET_OS_TV
    // should only get two now that the conversation is excluded from the message center response
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 2);
#endif
    SwrveCampaign *campaign = [[swrveMock messageCenterCampaigns] objectAtIndex:0];
    XCTAssertEqual(campaign.state.status,SWRVE_CAMPAIGN_STATUS_UNSEEN);
    XCTAssertEqualObjects(campaign.subject,@"IAM subject");
    XCTAssertEqual([campaign.priority intValue], 5);
    XCTAssertEqualObjects(campaign.name,@"Kindle");

    // Display in-app message
    [controller showMessageCenterCampaign:campaign];
    SwrveMessageViewController* viewController = [self messageViewControllerFrom:controller];
    [viewController viewDidAppear:NO];

    // Press dismiss button
    UISwrveButton* dismissButton = [UISwrveButton new];
    [viewController onButtonPressed:dismissButton pageId:[NSNumber numberWithInt:0]];

    XCTAssertEqual(campaign.state.impressions, 1);
    XCTAssertEqual(campaign.state.status, SWRVE_CAMPAIGN_STATUS_SEEN);

    // We can still get the IAM, even though the rules specify a limit of 1 impression
    SwrveCampaign *firstCampaign = [[swrveMock messageCenterCampaigns] objectAtIndex:0];

    XCTAssertEqual(firstCampaign.ID, campaign.ID);

    // Remove the campaign, we will never get it again
    [controller removeMessageCenterCampaign:campaign];

    XCTAssertFalse([[swrveMock messageCenterCampaigns] containsObject:campaign]);
    XCTAssertEqual(campaign.state.status, SWRVE_CAMPAIGN_STATUS_DELETED);

#if TARGET_OS_IOS
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];
#endif
}

- (void)testIAMMessageCenterProgrammaticallySeen {
#if TARGET_OS_IOS
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];
#endif
    
    [SwrveTestHelper createDummyAssets:[SwrveTestMessageCenterAPI testJSONAssets]];
   
    id swrveMock = [self swrveMock];
    // mock date that lies within the start and end time of the campaign in the test json file campaigns
    // we do this to pass: checkGlobalRules
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsMessageCenter" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockData options:0 error:nil];
    
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO];
    
    SwrveCampaign *campaign = [[swrveMock messageCenterCampaigns] objectAtIndex:0];
    XCTAssertEqual(campaign.state.status, SWRVE_CAMPAIGN_STATUS_UNSEEN);
    
    // Mark message as seen programmatically
    [swrveMock markMessageCenterCampaignAsSeen:campaign];
    XCTAssertEqual(campaign.state.status, SWRVE_CAMPAIGN_STATUS_SEEN);
    
#if TARGET_OS_IOS
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];
#endif
}

- (void)testPersonalizedIAMMessageCenter {
#if TARGET_OS_IOS
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];
#endif

    [SwrveTestHelper createDummyAssets:[SwrveTestMessageCenterAPI testJSONAssets]];
    NSDictionary *validPersonalization = @{@"test_cp": @"test_value",
            @"test_custom":@"urlprocessed",
            @"test_display": @"display"};

    id swrveMock = [self swrveMock];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop

    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsPersonalization" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockData options:0 error:nil];
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO];

    SwrveMessageController *controller = [swrveMock messaging];

    // No Message Center campaigns as they have both finished
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 0);

    // mock date that lies within the start and end time of the campaign in the test json file campaignsMessageCenter
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);

    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 0); // Should be 0 message centerCampaign because they all require personalization
    XCTAssertEqual([[swrveMock messageCenterCampaignsWithPersonalization:validPersonalization] count], 2); // Should be 2 message centerCampaign with correct personalization passed in

    // IAM and Conversation support these orientations
#if TARGET_OS_IOS
    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationLandscapeRight withPersonalization:validPersonalization] count], 2);
    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationPortrait withPersonalization:validPersonalization] count], 2);

    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationLandscapeRight withPersonalization:nil] count], 0);
    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationPortrait withPersonalization:nil] count], 0);
#endif

    SwrveCampaign *campaign = [[swrveMock messageCenterCampaignsWithPersonalization:validPersonalization] objectAtIndex:0];
    XCTAssertEqual(campaign.state.status,SWRVE_CAMPAIGN_STATUS_UNSEEN);
    XCTAssertEqualObjects(campaign.subject,@"Personalized Campaign");

    // Should be invalid due to missing personalization
    [controller showMessageCenterCampaign:campaign withPersonalization:nil];
    SwrveMessageViewController* messageViewController = [self messageViewControllerFrom:controller];
    SwrveMessagePageViewController *viewController = nil;
#if TARGET_OS_TV
    viewController = [messageViewController.childViewControllers firstObject];
#else
    viewController = [messageViewController.viewControllers firstObject];
#endif
    [viewController viewDidAppear:NO];
    [messageViewController viewDidAppear:NO];

    // No Impression should be registered nor state change
    XCTAssertEqual(campaign.state.impressions, 0);
    XCTAssertEqual(campaign.state.status, SWRVE_CAMPAIGN_STATUS_UNSEEN);

    NSDictionary *invalidPersonalization = @{@"invalid_key": @"test_value"};

    // Should not appear now in the message center APIs
    XCTAssertEqual([[swrveMock messageCenterCampaignsWithPersonalization:invalidPersonalization] count], 0);
#if TARGET_OS_IOS
    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationLandscapeRight withPersonalization:invalidPersonalization] count], 0);
    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationPortrait withPersonalization:invalidPersonalization] count], 0);
#endif

    // Should be invalid due to invalid personalization dictionary
    [controller showMessageCenterCampaign:campaign withPersonalization:invalidPersonalization];
    viewController = [self messageViewControllerFrom:controller];
    [viewController viewDidAppear:NO];

    // No Impression should be registered nor state change
    XCTAssertEqual(campaign.state.impressions, 0);
    XCTAssertEqual(campaign.state.status, SWRVE_CAMPAIGN_STATUS_UNSEEN);

    // Should appear now in the message center APIs
    XCTAssertEqual([[swrveMock messageCenterCampaignsWithPersonalization:validPersonalization] count], 2);
#if TARGET_OS_IOS
    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationLandscapeRight withPersonalization:validPersonalization] count], 2);
    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationPortrait withPersonalization:validPersonalization] count], 2);
#endif

    // Display in-app message
    [controller showMessageCenterCampaign:campaign withPersonalization:validPersonalization];
    messageViewController = [self messageViewControllerFrom:controller];
    [messageViewController viewDidAppear:NO];
#if TARGET_OS_TV
    viewController = [messageViewController.childViewControllers firstObject];
#else
    viewController = [messageViewController.viewControllers firstObject];
#endif
    [viewController viewDidAppear:NO];

    SwrveMessageFormat *format = [viewController messageFormat];
    SwrveMessagePage *page = [[format pages] objectForKey:[NSNumber numberWithInt:0]];
    NSArray *buttons = [page buttons];
    XCTAssertEqual([buttons count], 2);

    __block int clipboardActionCount = 0;
    __block NSString *clipboardAction;

    // set clipboard callback for later use
    [controller setClipboardButtonCallback:^(NSString* action) {
        clipboardActionCount++;
        clipboardAction = action;
    }];

    // access the UIViews in the subview of the SwrveMessageViewController
    NSArray *vcSubviews = [[[[viewController view] subviews] firstObject] subviews];
    NSMutableArray *uiButtons = [NSMutableArray new];

    // get all the buttons
    for (UIView *item in vcSubviews){
        if ([item isKindOfClass:[UISwrveButton class]]) {
            [uiButtons addObject:item];
        }
    }

    XCTAssertEqual([uiButtons count], 2);
    UISwrveButton *clipboardButton = nil;

    for (NSInteger i = 0; i < [buttons count]; i++) {
        SwrveButton *swrveButton = [buttons objectAtIndex:i];

        // verify that a UISwrveButton matching the tag has custom action
        if ([swrveButton actionType] == kSwrveActionCustom) {
            for (UISwrveButton *button in uiButtons){
                if ([button.accessibilityIdentifier isEqualToString:swrveButton.name]) {
                    XCTAssertEqualObjects(button.displayString, @"custom: display");
                    XCTAssertEqualObjects(button.actionString, @"urltest.com/urlprocessed");
                }
            }
        }

        // verify that a UISwrveButton matching the tag has clipboard action
        if ([swrveButton actionType] == kSwrveActionClipboard) {
            for (UISwrveButton *button in uiButtons){
                if ([button.accessibilityIdentifier isEqualToString:swrveButton.name]) {
                    XCTAssertEqualObjects(button.displayString, @"clipboard: display");
                    XCTAssertEqualObjects(button.actionString, @"test_value");
                    clipboardButton = button;
                }
            }
        }
    }

    // Press the saved clipboard button
    XCTAssertNotNil(clipboardButton, @"clipboard Button should not be nil at this point");
    [viewController onButtonPressed:clipboardButton];
    [self waitForWindowDismissed:controller];

    XCTAssertEqual(campaign.state.impressions, 1);
    XCTAssertEqual(campaign.state.status, SWRVE_CAMPAIGN_STATUS_SEEN);

    // Check clipboard callback was called with correct parameters
    XCTAssertEqual(clipboardActionCount, 1);
    XCTAssertEqualObjects(clipboardAction, @"test_value");

#if TARGET_OS_IOS /** exclude tvOS **/
    // verify (on iOS) that the value was copied to clipboard
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    XCTAssertEqualObjects(pasteboard.string, @"test_value");
#endif /**TARGET_OS_IOS **/

    // We can still get the IAM, even though the rules specify a limit of 1 impression
    SwrveCampaign *firstCampaign = [[swrveMock messageCenterCampaignsWithPersonalization:validPersonalization] objectAtIndex:0];

    XCTAssertEqual(firstCampaign.ID, campaign.ID);

    // Remove the campaign, we will never get it again
    [swrveMock removeMessageCenterCampaign:campaign];

    XCTAssertFalse([[swrveMock messageCenterCampaigns] containsObject:campaign]);
    XCTAssertEqual(campaign.state.status, SWRVE_CAMPAIGN_STATUS_DELETED);

#if TARGET_OS_IOS
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];
#endif
}

- (void)testEmbeddedMessageCenter {
#if TARGET_OS_IOS
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];
#endif
    
    [SwrveTestHelper createDummyAssets:[SwrveTestMessageCenterAPI testJSONAssets]];
    
    id swrveMock = [self swrveMock];
    
    SwrveConfig *config = [SwrveConfig new];
    SwrveEmbeddedMessageConfig *messageConfig = [SwrveEmbeddedMessageConfig new];
    
    [messageConfig setEmbeddedMessageCallback:^(SwrveEmbeddedMessage *message) {
        [[swrveMock messaging] embeddedMessageWasShownToUser:message];
    }];
    
    config.embeddedMessageConfig = messageConfig;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey" config:config];
#pragma clang diagnostic pop
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsMessageCenter" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockData options:0 error:nil];
    
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO];
    
    SwrveMessageController *controller = [swrveMock messaging];

    // No Message Center campaigns as they have both finished
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 0);
    
    // mock date that lies within the start and end time of the campaign in the test json file campaignsMessageCenter
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);
    
    // IAM, Embedded and Conversation support these orientations
#if TARGET_OS_IOS
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 3);
    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationLandscapeRight] count], 3);
    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationPortrait] count], 3);
#elif TARGET_OS_TV
    // should only get two now that the conversation is excluded from the message center response
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 2);
#endif
    NSArray<SwrveCampaign *> *campaigns = [swrveMock messageCenterCampaigns];
    SwrveEmbeddedCampaign *embeddedCampaign = nil;
    
    for (SwrveCampaign *candidate in campaigns) {
        if([candidate isKindOfClass:[SwrveEmbeddedCampaign class]]) {
            embeddedCampaign = (SwrveEmbeddedCampaign *) candidate;
        }
    }
    
    XCTAssertNotNil(embeddedCampaign);
    XCTAssertEqual(embeddedCampaign.state.status,SWRVE_CAMPAIGN_STATUS_UNSEEN);
    XCTAssertEqualObjects(embeddedCampaign.subject,@"Embedded subject");
    XCTAssertEqualObjects(embeddedCampaign.name,@"Embedded name");
    
    [controller showMessageCenterCampaign:embeddedCampaign];
    
    XCTAssertEqual(embeddedCampaign.state.status,SWRVE_CAMPAIGN_STATUS_SEEN);
    
    // Remove the campaign, we will never get it again
    [controller removeMessageCenterCampaign:embeddedCampaign];
    
    XCTAssertFalse([[swrveMock messageCenterCampaigns] containsObject:embeddedCampaign]);
    XCTAssertEqual(embeddedCampaign.state.status, SWRVE_CAMPAIGN_STATUS_DELETED);
    
#if TARGET_OS_IOS
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];
#endif
}

- (void)testEmbeddedWithPersonalizationMessageCenter {
#if TARGET_OS_IOS
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];
#endif
    
    [SwrveTestHelper createDummyAssets:[SwrveTestMessageCenterAPI testJSONAssets]];
    
    id swrveMock = [self swrveMock];
    __block NSString *resolvedMessageData = nil;
    
    SwrveConfig *config = [SwrveConfig new];
    SwrveEmbeddedMessageConfig *messageConfig = [SwrveEmbeddedMessageConfig new];
    
    [messageConfig setEmbeddedMessageCallbackWithPersonalization:^(SwrveEmbeddedMessage *message, NSDictionary *personalizationProperties) {
        resolvedMessageData = [[swrveMock messaging] personalizeEmbeddedMessageData:message withPersonalization:personalizationProperties];
        [[swrveMock messaging] embeddedMessageWasShownToUser:message];
    }];

    config.embeddedMessageConfig = messageConfig;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey" config:config];
#pragma clang diagnostic pop
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsEmbeddedPersonalizationMessageCenter" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockData options:0 error:nil];
    
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO];
    
    SwrveMessageController *controller = [swrveMock messaging];

    // No Message Center campaigns as they have both finished
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 0);
    
    // mock date that lies within the start and end time of the campaign in the test json file campaignsMessageCenter
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);
    
    NSDictionary *validPersonalization = @{@"test_cp": @"test_value",
                                           @"test_custom":@"urlprocessed",
                                           @"test_display": @"display"};
      
    // IAM, Embedded and Conversation support these orientations
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 1);
    NSArray<SwrveCampaign *> *campaigns = [swrveMock messageCenterCampaignsWithPersonalization:validPersonalization];
    SwrveEmbeddedCampaign *embeddedCampaign = nil;
    
    for (SwrveCampaign *candidate in campaigns) {
        if([candidate isKindOfClass:[SwrveEmbeddedCampaign class]]) {
            embeddedCampaign = (SwrveEmbeddedCampaign *) candidate;
        }
    }
    
    XCTAssertNotNil(embeddedCampaign);
    XCTAssertEqual(embeddedCampaign.state.status,SWRVE_CAMPAIGN_STATUS_UNSEEN);
    XCTAssertEqualObjects(embeddedCampaign.subject,@"Embedded Personalization");

    [controller showMessageCenterCampaign:embeddedCampaign withPersonalization:@{@"test_key": @"WORKING"}];
    XCTAssertEqualObjects(resolvedMessageData, @"PERSONALIZATION: WORKING");
    XCTAssertEqual(embeddedCampaign.state.status,SWRVE_CAMPAIGN_STATUS_SEEN);
    
    // Remove the campaign, we will never get it again
    [controller removeMessageCenterCampaign:embeddedCampaign];
    
    XCTAssertFalse([[swrveMock messageCenterCampaigns] containsObject:embeddedCampaign]);
    XCTAssertEqual(embeddedCampaign.state.status, SWRVE_CAMPAIGN_STATUS_DELETED);
    
#if TARGET_OS_IOS
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];
#endif
}

- (void)testPersonalizedImageMessageCenter {
#if TARGET_OS_IOS
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];
#endif
    
    NSDictionary *testPersonalization = @{@"test_key_with_fallback": @"asset1", @"test_key_no_fallback":@"asset2"};
    
    SwrveConfig *config = [[SwrveConfig alloc] init];
    SwrveInAppMessageConfig *inAppConfig = [SwrveInAppMessageConfig new];
    SwrveMessagePersonalizationCallback personalizationCallback = ^(NSDictionary* eventPayload) {
        return testPersonalization;
    };
    [inAppConfig setPersonalizationCallback:personalizationCallback];
    config.inAppMessageConfig = inAppConfig;

    [SwrveTestHelper removeAllAssets];

    NSString *asset1 = [SwrveUtils sha1:[@"https://fakeitem/asset1.png" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    NSString *asset2 = [SwrveUtils sha1:[@"https://fakeitem/asset2.gif" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    NSString *asset3 = [SwrveUtils sha1:[@"https://fakeitem/asset3.jpg" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];

    NSMutableArray *testAssets = [[SwrveTestMessageCenterAPI testJSONAssets] mutableCopy];
    [testAssets addObjectsFromArray:@[asset1, asset2, asset3]];
    [SwrveTestHelper createDummyAssets:testAssets];
    
    id swrveMock = [self swrveMock];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey" config:config];
#pragma clang diagnostic pop
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsMessageCenter" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockData options:0 error:nil];
    
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO];
    
    SwrveMessageController *controller = [swrveMock messaging];
    
    // No Message Center campaigns as they have both finished
    XCTAssertEqual([[swrveMock messageCenterCampaignsWithPersonalization:testPersonalization] count], 0);

    // mock date that lies within the start and end time of the campaign in the test json file campaignsMessageCenter
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);
    
#if TARGET_OS_IOS
    XCTAssertEqual([[swrveMock messageCenterCampaignsWithPersonalization:nil] count], 3); // should not display since there's no personalization
    XCTAssertEqual([[swrveMock messageCenterCampaignsWithPersonalization:testPersonalization] count], 4);
#elif TARGET_OS_TV
    XCTAssertEqual([[swrveMock messageCenterCampaignsWithPersonalization:nil] count], 2);
    XCTAssertEqual([[swrveMock messageCenterCampaignsWithPersonalization:testPersonalization] count], 3);
#endif
    
    NSArray<SwrveCampaign *> *campaigns = [swrveMock messageCenterCampaignsWithPersonalization:testPersonalization];
    SwrveCampaign *campaign = nil;
    for (SwrveCampaign *candidate in campaigns) {
        if([candidate.subject isEqual:@"Personalized Image subject"]){
            campaign = candidate;
        }
    }
    
    XCTAssertEqual(campaign.state.status,SWRVE_CAMPAIGN_STATUS_UNSEEN);
    
    // attempt the wrong personalization
    [controller showMessageCenterCampaign:campaign withPersonalization:@{@"wrong":@"id"}];
    
    // it should not show
    XCTAssertEqual(campaign.state.status,SWRVE_CAMPAIGN_STATUS_UNSEEN);

    // Display in-app message with the correct personalization
    [controller showMessageCenterCampaign:campaign withPersonalization:testPersonalization];
    SwrveMessageViewController* viewController = [self messageViewControllerFrom:controller];
    [viewController viewDidAppear:NO];

    XCTAssertEqual(campaign.state.impressions, 1);
    XCTAssertEqual(campaign.state.status, SWRVE_CAMPAIGN_STATUS_SEEN);

    // Remove the campaign
    [controller removeMessageCenterCampaign:campaign];
    
    XCTAssertFalse([[swrveMock messageCenterCampaignsWithPersonalization:testPersonalization] containsObject:campaign]);
    XCTAssertEqual(campaign.state.status, SWRVE_CAMPAIGN_STATUS_DELETED);
    
#if TARGET_OS_IOS
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];
#endif
}

- (void)testPersonalizedImageMessageCenterWithRealTimeUserProperties {
#if TARGET_OS_IOS
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];
#endif
    
    // set this to nothing
    NSDictionary *testPersonalization = @{@"test_key": @"Asset3"};
    SwrveConfig *config = [[SwrveConfig alloc] init];
    SwrveInAppMessageConfig *inAppConfig = [SwrveInAppMessageConfig new];
    SwrveMessagePersonalizationCallback personalizationCallback = ^(NSDictionary* eventPayload) {
        return testPersonalization;
    };
    [inAppConfig setPersonalizationCallback:personalizationCallback];
    config.inAppMessageConfig = inAppConfig;

    [SwrveTestHelper removeAllAssets];

    NSString *asset1 = [SwrveUtils sha1:[@"https://fakeitem/rtup_value1.png" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    NSString *asset2 = [SwrveUtils sha1:[@"https://fakeitem/rtup_value2.gif" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    NSString *asset3 = [SwrveUtils sha1:[@"https://fakeitem/Asset3.jpg" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];

    NSMutableArray *testAssets = [[SwrveTestMessageCenterAPI testJSONAssets] mutableCopy];
    [testAssets addObjectsFromArray:@[asset1, asset2, asset3]];
    [SwrveTestHelper createDummyAssets:testAssets];

    Swrve *swrveMock = [SwrveTestHelper initializeSwrveWithRealTimeUserPropertiesFile:@"realTimeUserProperties" andConfig:config];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsMessageCenter" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockData options:0 error:nil];
    
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO];
    
    SwrveMessageController *controller = [swrveMock messaging];

#if TARGET_OS_IOS
    XCTAssertEqual([[swrveMock messageCenterCampaignsWithPersonalization:testPersonalization] count], 5);
#elif TARGET_OS_TV
    XCTAssertEqual([[swrveMock messageCenterCampaignsWithPersonalization:testPersonalization] count], 4);
#endif
    
    NSArray<SwrveCampaign *> *campaigns = [swrveMock messageCenterCampaignsWithPersonalization:testPersonalization];
    SwrveCampaign *campaign = nil;
    for (SwrveCampaign *candidate in campaigns) {
        if([candidate.subject isEqual:@"Personalized RTUP Image subject"]){
            campaign = candidate;
        }
    }
    
    XCTAssertEqual(campaign.state.status,SWRVE_CAMPAIGN_STATUS_UNSEEN);
    
    // attempt the wrong personalization
    [controller showMessageCenterCampaign:campaign withPersonalization:@{@"wrong":@"id"}];
    
    // it should not show
    XCTAssertEqual(campaign.state.status,SWRVE_CAMPAIGN_STATUS_UNSEEN);

    // Display in-app message with the correct personalization
    [controller showMessageCenterCampaign:campaign withPersonalization:testPersonalization];
    SwrveMessageViewController* viewController = [self messageViewControllerFrom:controller];
    [viewController viewDidAppear:NO];

    XCTAssertEqual(campaign.state.impressions, 1);
    XCTAssertEqual(campaign.state.status, SWRVE_CAMPAIGN_STATUS_SEEN);

    // Remove the campaign
    [controller removeMessageCenterCampaign:campaign];
    
    XCTAssertFalse([[swrveMock messageCenterCampaignsWithPersonalization:testPersonalization] containsObject:campaign]);
    XCTAssertEqual(campaign.state.status, SWRVE_CAMPAIGN_STATUS_DELETED);
    
#if TARGET_OS_IOS
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];
#endif
}

- (void)testPersonalizedImageMessageCenterWithRealTimeUserPropertiesOnTheirOwn {
#if TARGET_OS_IOS
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];
#endif
    
    // set no Personalization Provider

    SwrveConfig *config = [[SwrveConfig alloc] init];
    [SwrveTestHelper removeAllAssets];

    NSString *asset1 = [SwrveUtils sha1:[@"https://fakeitem/rtup_value1.png" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    NSString *asset2 = [SwrveUtils sha1:[@"https://fakeitem/rtup_value2.gif" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];

    NSMutableArray *testAssets = [[SwrveTestMessageCenterAPI testJSONAssets] mutableCopy];
    [testAssets addObjectsFromArray:@[asset1, asset2]];
    [SwrveTestHelper createDummyAssets:testAssets];

    Swrve *swrveMock = [SwrveTestHelper initializeSwrveWithRealTimeUserPropertiesFile:@"realTimeUserProperties" andConfig:config];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsMessageCenter" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockData options:0 error:nil];
    
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO];
    
    SwrveMessageController *controller = [swrveMock messaging];

#if TARGET_OS_IOS
    //  include no personalization dictionary and we should still get 4
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 4);
    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationPortrait] count], 3);
#elif TARGET_OS_TV
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 3);
#endif
    
    NSArray<SwrveCampaign *> *campaigns = [swrveMock messageCenterCampaignsWithPersonalization:nil];
    SwrveCampaign *campaign = nil;
    for (SwrveCampaign *candidate in campaigns) {
        if([candidate.subject isEqual:@"RTUP Only IAM"]){
            campaign = candidate;
        }
    }
    
    XCTAssertEqual(campaign.state.status,SWRVE_CAMPAIGN_STATUS_UNSEEN);
    

    // Display in-app message with no personalization, should be resolved by injected RTUPs
    [controller showMessageCenterCampaign:campaign withPersonalization:nil];
    SwrveMessageViewController* viewController = [self messageViewControllerFrom:controller];
    [viewController viewDidAppear:NO];

    XCTAssertEqual(campaign.state.impressions, 1);
    XCTAssertEqual(campaign.state.status, SWRVE_CAMPAIGN_STATUS_SEEN);

    // Remove the campaign
    [controller removeMessageCenterCampaign:campaign];
    
    XCTAssertFalse([[swrveMock messageCenterCampaignsWithPersonalization:nil] containsObject:campaign]);
    XCTAssertEqual(campaign.state.status, SWRVE_CAMPAIGN_STATUS_DELETED);
    
#if TARGET_OS_IOS
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];
#endif
}


- (void)testInvalidCampaignsInMessageCenter {
#if TARGET_OS_IOS
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];
#endif
    [SwrveTestHelper removeAllAssets];

    NSString *asset1 = [SwrveUtils sha1:[@"https://fakeitem/asset1.png" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    NSString *asset2 = [SwrveUtils sha1:[@"https://fakeitem/asset2.gif" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    NSString *asset3 = [SwrveUtils sha1:[@"https://fakeitem/asset3.jpg" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];

    NSMutableArray *testAssets = [[SwrveTestMessageCenterAPI testJSONAssets] mutableCopy];
    [testAssets addObjectsFromArray:@[asset1, asset2, asset3]];
    [SwrveTestHelper createDummyAssets:testAssets];
    
    id swrveMock = [self swrveMock];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsMessageCenterInvalid" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockData options:0 error:nil];
    
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO];
    
    SwrveMessageController *controller = [swrveMock messaging];

    // mock date
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);
    
    // All campaigns are considered invalid because they're either missing an asset or won't personalize
#if TARGET_OS_IOS
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 0);
    XCTAssertEqual([[swrveMock messageCenterCampaignsWithPersonalization:nil] count], 0);
#elif TARGET_OS_TV
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 0);
    XCTAssertEqual([[swrveMock messageCenterCampaignsWithPersonalization:nil] count], 0);
#endif
    
}

- (void)testIAMMessageCenterDetails {
#if TARGET_OS_IOS
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];
#endif

    [SwrveTestHelper createDummyAssets:[SwrveTestMessageCenterAPI testJSONAssets]];

    id swrveMock = [self swrveMock];
    // mock date that lies within the start and end time of the campaign in the test json file campaigns
    // we do this to pass: checkGlobalRules
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop

    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsPersonalization" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockData options:0 error:nil];

    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO];

    // Now use valid, Expected by campaign personalization Dictionary
    NSDictionary *validPersonalization = @{@"test_cp": @"test_value",
            @"test_custom": @"urlprocessed",
            @"test_display": @"display"};
    //confirm message center details
    SwrveCampaign *campaign = [swrveMock messageCenterCampaignWithID:102 andPersonalization:validPersonalization];
    XCTAssertEqualObjects(campaign.messageCenterDetails.subject, @"some subject personalized test_value");
    XCTAssertEqualObjects(campaign.messageCenterDetails.description, @"some description personalized test_value");
    XCTAssertEqualObjects(campaign.messageCenterDetails.imageUrl, @"some url personalized urlprocessed");
    XCTAssertEqualObjects(campaign.messageCenterDetails.imageAccessibilityText, @"some alt text personalized test_value");
    XCTAssertEqualObjects(campaign.messageCenterDetails.imageSha, @"f6eb9596d473afcd13eb3d47d1347ea31a2f8ecb");

    //confirm campaign and message center details ok if some nil properties
    campaign = [swrveMock messageCenterCampaignWithID:103 andPersonalization:validPersonalization];
    XCTAssertEqualObjects(campaign.messageCenterDetails.subject, @"some subject personalized test_value");
    XCTAssertEqualObjects(campaign.messageCenterDetails.description, nil);
    XCTAssertEqualObjects(campaign.messageCenterDetails.imageUrl, nil);
    XCTAssertEqualObjects(campaign.messageCenterDetails.imageAccessibilityText, nil);
    XCTAssertEqualObjects(campaign.messageCenterDetails.imageSha, nil);

    campaign = [swrveMock messageCenterCampaignWithID:104 andPersonalization:validPersonalization];
    XCTAssertNil(campaign);
    NSMutableDictionary* validPersonalizationDetails = [NSMutableDictionary dictionaryWithDictionary:validPersonalization];
    [validPersonalizationDetails setObject:@"message_center_details_test" forKey:@"message_center_details_test"];
    campaign = [swrveMock messageCenterCampaignWithID:104 andPersonalization:validPersonalizationDetails]; // using the message center details personalization
    XCTAssertNotNil(campaign);

#if TARGET_OS_IOS
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];
#endif
}

- (void)testDownloadDate {
    [SwrveTestHelper createDummyAssets:[SwrveTestMessageCenterAPI testJSONAssets]];

    NSDate *today = [NSDate date];
    NSDate *yesterday = [today dateByAddingTimeInterval:-86400.0];

    // Mock the sdk so that the current date is yesterday.
    id swrveMock = [self swrveMock];
    OCMStub([swrveMock getNow]).andReturn(yesterday);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop

    // load up campaign json which contains only one campaign
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignDownloadDate1" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockData options:0 error:nil];
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:YES];

    // verify there's only 1 campaign and the download date is yesterday
    NSArray<SwrveCampaign *> *campaigns = [swrveMock messageCenterCampaigns];
    XCTAssertEqual([campaigns count], 1);
    SwrveCampaign *campaign = [swrveMock messageCenterCampaignWithID:102 andPersonalization:nil];
    NSDate *downloadDate = [campaign downloadDate];
    XCTAssertNotNil(downloadDate);
    XCTAssertEqual(downloadDate, yesterday);

    // Shutdown sdk and mock a new sdk instance so that the current date is today.
    [SwrveSDK resetSwrveSharedInstance];
    swrveMock = [self swrveMock];
    OCMStub([swrveMock getNow]).andReturn(today);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop

    // load up new campaign json which contains same campaign previously plus one new one
    filePath = [[NSBundle mainBundle] pathForResource:@"campaignDownloadDate2" ofType:@"json"];
    mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    jsonDict = [NSJSONSerialization JSONObjectWithData:mockData options:0 error:nil];
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:YES];

    // verify there's 2 campaigns now
    campaigns = [swrveMock messageCenterCampaigns];
    XCTAssertEqual([campaigns count], 2);

    // verify the download date for first one is yesterday
    campaign = [swrveMock messageCenterCampaignWithID:102 andPersonalization:nil];
    downloadDate = [campaign downloadDate];
    XCTAssertNotNil(downloadDate);
    XCTAssertEqualWithAccuracy([downloadDate timeIntervalSinceReferenceDate], [yesterday timeIntervalSinceReferenceDate], 1.0);

    // verify the download date for second one is today
    campaign = [swrveMock messageCenterCampaignWithID:103 andPersonalization:nil];
    downloadDate = [campaign downloadDate];
    XCTAssertNotNil(downloadDate);
    XCTAssertEqualWithAccuracy([downloadDate timeIntervalSinceReferenceDate], [today timeIntervalSinceReferenceDate], 1.0);

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

@end
