#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SwrveTestHelper.h"

#import "SwrveConversationStyler.h"
#import "TestShowMessageDelegateWithViewController.h"
#import "SwrveAssetsManager.h"
#import "SwrveMessageController+Private.h"
#import "SwrveCampaign.h"
#import "UISwrveButton.h"
#import "SwrveUtils.h"
#import "SwrveButton.h"
#import "SwrveConversationCampaign.h"

@interface Swrve()
@property (atomic) SwrveRESTClient *restClient;
@property(atomic) SwrveMessageController *messaging;

- (void)initSwrveRestClient:(NSTimeInterval)timeOut urlSssionDelegate:(id <NSURLSessionDelegate>)urlSssionDelegate;
- (void)appDidBecomeActive:(NSNotification *)notification;
@end

@interface SwrveMessageViewController ()
@property (nonatomic, retain) SwrveMessageFormat* current_format;
@end

@interface SwrveMessageController ()

- (id)initWithSwrve:(Swrve*)sdk;
- (void)writeToCampaignCache:(NSData*)campaignData;
- (void)updateCampaigns:(NSDictionary *)campaignDic withLoadingPreviousCampaignState:(BOOL) isLoadingPreviousCampaignState;
- (NSDate *)getNow;
@property (nonatomic, retain) SwrveAssetsManager *assetsManager;

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
    
    TestShowMessageDelegateWithViewController* testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

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

    // Display in-app message
    [controller showMessageCenterCampaign:campaign];
    SwrveMessageViewController* viewController = (SwrveMessageViewController*)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];

    // Press dismiss button
    UISwrveButton* dismissButton = [UISwrveButton new];
    [viewController onButtonPressed:dismissButton];

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
    
    // Mark message as seen programatically
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
    
    TestShowMessageDelegateWithViewController* testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    // No Message Center campaigns as they have both finished
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 0);
    
    // mock date that lies within the start and end time of the campaign in the test json file campaignsMessageCenter
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);
    
    // Should be only 1 message centerCampaign
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 1);
    XCTAssertEqual([[swrveMock messageCenterCampaignsWithPersonalization:nil] count], 0);
    
    // IAM and Conversation support these orientations
#if TARGET_OS_IOS
    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationLandscapeRight] count], 1);
    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationPortrait] count], 1);
    
    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationLandscapeRight withPersonalization:nil] count], 0);
    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationPortrait withPersonalization:nil] count], 0);
#endif
    
    SwrveCampaign *campaign = [[swrveMock messageCenterCampaigns] objectAtIndex:0];
    XCTAssertEqual(campaign.state.status,SWRVE_CAMPAIGN_STATUS_UNSEEN);
    XCTAssertEqualObjects(campaign.subject,@"Personalized Campaign");
    
    SwrveMessageViewController *viewController = nil;
    
    // Should be invalid due to missing personalization
    [controller showMessageCenterCampaign:campaign withPersonalization:nil];
    viewController = (SwrveMessageViewController*)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];
    
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
    viewController = (SwrveMessageViewController*)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];
    
    // No Impression should be registered nor state change
    XCTAssertEqual(campaign.state.impressions, 0);
    XCTAssertEqual(campaign.state.status, SWRVE_CAMPAIGN_STATUS_UNSEEN);
    
    // Now use valid, Expected by campaign personalization Dictionary
    NSDictionary *validPersonalization = @{@"test_cp": @"test_value",
                                           @"test_custom":@"urlprocessed",
                                           @"test_display": @"display"};
    

    // Should appear now in the message center APIs
    XCTAssertEqual([[swrveMock messageCenterCampaignsWithPersonalization:validPersonalization] count], 1);
#if TARGET_OS_IOS
    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationLandscapeRight withPersonalization:validPersonalization] count], 1);
    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationPortrait withPersonalization:validPersonalization] count], 1);
#endif
    
    // Display in-app message
    [controller showMessageCenterCampaign:campaign withPersonalization:validPersonalization];
    viewController = (SwrveMessageViewController*)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];

    NSArray *buttons = [[viewController current_format] buttons];
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
    SwrveCampaign *firstCampaign = [[swrveMock messageCenterCampaigns] objectAtIndex:0];
    
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
    
    TestShowMessageDelegateWithViewController* testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

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
    
    for (SwrveCampaign *canditate in campaigns) {
        if([canditate isKindOfClass:[SwrveEmbeddedCampaign class]]) {
            embeddedCampaign = (SwrveEmbeddedCampaign *) canditate;
        }
    }
    
    XCTAssertNotNil(embeddedCampaign);
    XCTAssertEqual(embeddedCampaign.state.status,SWRVE_CAMPAIGN_STATUS_UNSEEN);
    XCTAssertEqualObjects(embeddedCampaign.subject,@"Embedded subject");
    
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
    
    TestShowMessageDelegateWithViewController* testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    // No Message Center campaigns as they have both finished
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 0);
    
    // mock date that lies within the start and end time of the campaign in the test json file campaignsMessageCenter
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);
    
    // IAM, Embedded and Conversation support these orientations
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 1);
    NSArray<SwrveCampaign *> *campaigns = [swrveMock messageCenterCampaigns];
    SwrveEmbeddedCampaign *embeddedCampaign = nil;
    
    for (SwrveCampaign *canditate in campaigns) {
        if([canditate isKindOfClass:[SwrveEmbeddedCampaign class]]) {
            embeddedCampaign = (SwrveEmbeddedCampaign *) canditate;
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
    
    TestShowMessageDelegateWithViewController* testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

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
    for (SwrveCampaign *canditate in campaigns) {
        if([canditate.subject isEqual:@"Personalized Image subject"]){
            campaign = canditate;
        }
    }
    
    XCTAssertEqual(campaign.state.status,SWRVE_CAMPAIGN_STATUS_UNSEEN);
    
    // attempt the wrong personalization
    [controller showMessageCenterCampaign:campaign withPersonalization:@{@"wrong":@"id"}];
    
    // it should not show
    XCTAssertEqual(campaign.state.status,SWRVE_CAMPAIGN_STATUS_UNSEEN);

    // Display in-app message with the correct personalization
    [controller showMessageCenterCampaign:campaign withPersonalization:testPersonalization];
    SwrveMessageViewController* viewController = (SwrveMessageViewController*)[testDelegate viewControllerUsed];
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
    
    TestShowMessageDelegateWithViewController* testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];
    
#if TARGET_OS_IOS
    XCTAssertEqual([[swrveMock messageCenterCampaignsWithPersonalization:testPersonalization] count], 5);
#elif TARGET_OS_TV
    XCTAssertEqual([[swrveMock messageCenterCampaignsWithPersonalization:testPersonalization] count], 4);
#endif
    
    NSArray<SwrveCampaign *> *campaigns = [swrveMock messageCenterCampaignsWithPersonalization:testPersonalization];
    SwrveCampaign *campaign = nil;
    for (SwrveCampaign *canditate in campaigns) {
        if([canditate.subject isEqual:@"Personalized RTUP Image subject"]){
            campaign = canditate;
        }
    }
    
    XCTAssertEqual(campaign.state.status,SWRVE_CAMPAIGN_STATUS_UNSEEN);
    
    // attempt the wrong personalization
    [controller showMessageCenterCampaign:campaign withPersonalization:@{@"wrong":@"id"}];
    
    // it should not show
    XCTAssertEqual(campaign.state.status,SWRVE_CAMPAIGN_STATUS_UNSEEN);

    // Display in-app message with the correct personalization
    [controller showMessageCenterCampaign:campaign withPersonalization:testPersonalization];
    SwrveMessageViewController* viewController = (SwrveMessageViewController*)[testDelegate viewControllerUsed];
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
    
    TestShowMessageDelegateWithViewController* testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];
    
#if TARGET_OS_IOS
    //  include no personalization dictionary and we should still get 4
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 4);
    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationPortrait] count], 3);
#elif TARGET_OS_TV
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 3);
#endif
    
    NSArray<SwrveCampaign *> *campaigns = [swrveMock messageCenterCampaignsWithPersonalization:nil];
    SwrveCampaign *campaign = nil;
    for (SwrveCampaign *canditate in campaigns) {
        if([canditate.subject isEqual:@"RTUP Only IAM"]){
            campaign = canditate;
        }
    }
    
    XCTAssertEqual(campaign.state.status,SWRVE_CAMPAIGN_STATUS_UNSEEN);
    

    // Display in-app message with no personalization, should be resolved by injected RTUPs
    [controller showMessageCenterCampaign:campaign withPersonalization:nil];
    SwrveMessageViewController* viewController = (SwrveMessageViewController*)[testDelegate viewControllerUsed];
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
    
    TestShowMessageDelegateWithViewController* testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

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



@end
