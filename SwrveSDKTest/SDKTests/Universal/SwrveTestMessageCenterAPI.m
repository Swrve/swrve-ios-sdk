#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SwrveTestHelper.h"

#import "SwrveConversationStyler.h"
#import "TestShowMessageDelegateWithViewController.h"
#import "SwrveAssetsManager.h"
#import "SwrveMessageController+Private.h"
#import "SwrveCampaign.h"
#import "UISwrveButton.h"
#import "SwrveButton.h"
#import "SwrveConversationCampaign.h"

@interface Swrve()

@property (atomic) SwrveRESTClient *restClient;
- (void)initSwrveRestClient:(NSTimeInterval)timeOut;
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
    
    OCMStub([swrveMock initSwrveRestClient:60]).andDo(^(NSInvocation *invocation) {
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

    SwrveMessageController *controller = [swrveMock messaging];
    // No Message Center campaigns
    XCTAssertEqual([[controller messageCenterCampaigns] count], 0);
}

- (void)testIAMMessageCenter {
#if TARGET_OS_IOS
    XCUIDevice.sharedDevice.orientation = UIInterfaceOrientationPortrait;
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
    XCTAssertEqual([[controller messageCenterCampaigns] count], 0);
    
    // mock date that lies within the start and end time of the campaign in the test json file campaignsMessageCenter
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);

    // IAM and Conversation support these orientations
#if TARGET_OS_IOS
    XCTAssertEqual([[controller messageCenterCampaigns] count], 2);
    XCTAssertEqual([[controller messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationLandscapeRight] count], 2);
    XCTAssertEqual([[controller messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationPortrait] count], 2);
#elif TARGET_OS_TV
    // should only get one now that the conversation is excluded from the message center response
    XCTAssertEqual([[controller messageCenterCampaigns] count], 1);
#endif
    SwrveCampaign *campaign = [[controller messageCenterCampaigns] objectAtIndex:0];
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
    SwrveCampaign *firstCampaign = [[controller messageCenterCampaigns] objectAtIndex:0];
    
    XCTAssertEqual(firstCampaign.ID, campaign.ID);
 
    // Remove the campaign, we will never get it again
    [controller removeMessageCenterCampaign:campaign];
    
    XCTAssertFalse([[controller messageCenterCampaigns] containsObject:campaign]);
    XCTAssertEqual(campaign.state.status, SWRVE_CAMPAIGN_STATUS_DELETED);
}

- (void)testIAMMessageCenterProgrammaticallySeen {
#if TARGET_OS_IOS
    XCUIDevice.sharedDevice.orientation = UIInterfaceOrientationPortrait;
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
    
    SwrveMessageController *controller = [swrveMock messaging];
    
    SwrveCampaign *campaign = [[controller messageCenterCampaigns] objectAtIndex:0];
    XCTAssertEqual(campaign.state.status, SWRVE_CAMPAIGN_STATUS_UNSEEN);
    
    // Mark message as seen programatically
    [controller markMessageCenterCampaignAsSeen:campaign];
    XCTAssertEqual(campaign.state.status, SWRVE_CAMPAIGN_STATUS_SEEN);
}

- (void)testPersonalisedIAMMessageCenter {
#if TARGET_OS_IOS
    XCUIDevice.sharedDevice.orientation = UIInterfaceOrientationPortrait;
#endif
    
    [SwrveTestHelper createDummyAssets:[SwrveTestMessageCenterAPI testJSONAssets]];
   
    id swrveMock = [self swrveMock];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsPersonalisation" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockData options:0 error:nil];
    
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO];
    
    SwrveMessageController *controller = [swrveMock messaging];
    
    TestShowMessageDelegateWithViewController* testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    // No Message Center campaigns as they have both finished
    XCTAssertEqual([[controller messageCenterCampaigns] count], 0);
    
    // mock date that lies within the start and end time of the campaign in the test json file campaignsMessageCenter
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);
    
    // Should be only 1 message centerCampaign
    XCTAssertEqual([[controller messageCenterCampaigns] count], 1);
    XCTAssertEqual([[controller messageCenterCampaignsWithPersonalisation:nil] count], 0);
    
    // IAM and Conversation support these orientations
#if TARGET_OS_IOS
    XCTAssertEqual([[controller messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationLandscapeRight] count], 1);
    XCTAssertEqual([[controller messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationPortrait] count], 1);
    
    XCTAssertEqual([[controller messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationLandscapeRight withPersonalisation:nil] count], 0);
    XCTAssertEqual([[controller messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationPortrait withPersonalisation:nil] count], 0);
#endif
    
    SwrveCampaign *campaign = [[controller messageCenterCampaigns] objectAtIndex:0];
    XCTAssertEqual(campaign.state.status,SWRVE_CAMPAIGN_STATUS_UNSEEN);
    XCTAssertEqualObjects(campaign.subject,@"Personalised Campaign");
    
    SwrveMessageViewController *viewController = nil;
    
    // Should be invalid due to missing personalisation
    [controller showMessageCenterCampaign:campaign withPersonalisation:nil];
    viewController = (SwrveMessageViewController*)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];
    
    // No Impression should be registered nor state change
    XCTAssertEqual(campaign.state.impressions, 0);
    XCTAssertEqual(campaign.state.status, SWRVE_CAMPAIGN_STATUS_UNSEEN);
    
    NSDictionary *invalidPersonalisation = @{@"invalid_key": @"test_value"};
    
    // Should not appear now in the message center APIs
    XCTAssertEqual([[controller messageCenterCampaignsWithPersonalisation:invalidPersonalisation] count], 0);
#if TARGET_OS_IOS
    XCTAssertEqual([[controller messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationLandscapeRight withPersonalisation:invalidPersonalisation] count], 0);
    XCTAssertEqual([[controller messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationPortrait withPersonalisation:invalidPersonalisation] count], 0);
#endif
    
    // Should be invalid due to invalid personalisation dictionary
    [controller showMessageCenterCampaign:campaign withPersonalisation:invalidPersonalisation];
    viewController = (SwrveMessageViewController*)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];
    
    // No Impression should be registered nor state change
    XCTAssertEqual(campaign.state.impressions, 0);
    XCTAssertEqual(campaign.state.status, SWRVE_CAMPAIGN_STATUS_UNSEEN);
    
    // Now use valid, Expected by campaign personalisation Dictionary
    NSDictionary *validPersonalisation = @{@"test_cp": @"test_value",
                                           @"test_custom":@"urlprocessed",
                                           @"test_display": @"display"};
    

    // Should appear now in the message center APIs
    XCTAssertEqual([[controller messageCenterCampaignsWithPersonalisation:validPersonalisation] count], 1);
#if TARGET_OS_IOS
    XCTAssertEqual([[controller messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationLandscapeRight withPersonalisation:validPersonalisation] count], 1);
    XCTAssertEqual([[controller messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationPortrait withPersonalisation:validPersonalisation] count], 1);
#endif
    
    // Display in-app message
    [controller showMessageCenterCampaign:campaign withPersonalisation:validPersonalisation];
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
    SwrveCampaign *firstCampaign = [[controller messageCenterCampaigns] objectAtIndex:0];
    
    XCTAssertEqual(firstCampaign.ID, campaign.ID);

    // Remove the campaign, we will never get it again
    [controller removeMessageCenterCampaign:campaign];
    
    XCTAssertFalse([[controller messageCenterCampaigns] containsObject:campaign]);
    XCTAssertEqual(campaign.state.status, SWRVE_CAMPAIGN_STATUS_DELETED);
}

#if TARGET_OS_IOS /** Conversations are not supported on tvOS **/
- (void)testConversationMessageCenter {

    XCUIDevice.sharedDevice.orientation = UIInterfaceOrientationLandscapeRight;
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
    
    SwrveMessageController *controller = [swrveMock messaging];

    // No Message Center campaigns as they have both finished
    XCTAssertEqual([[controller messageCenterCampaigns] count], 0);

    // mock date that lies within the start and end time of the campaign in the test json file campaignsMessageCenter
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);

    XCTAssertEqual([[controller messageCenterCampaigns] count], 2);

    SwrveConversationCampaign *campaign = [[controller messageCenterCampaigns] objectAtIndex:1];
    XCTAssertEqual(campaign.state.status,SWRVE_CAMPAIGN_STATUS_UNSEEN);
    XCTAssertEqualObjects(campaign.subject,@"Conversation subject");

    // Display in-app message
    [controller showMessageCenterCampaign:campaign];
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    XCTAssertNotNil(controller.swrveConversationItemViewController);

    //ensure that the corner radius was changed by the campaign JSON
    XCTAssertEqual(controller.swrveConversationItemViewController.view.layer.cornerRadius,22.5);
    
    UIColor *lbUIColor = [SwrveConversationStyler convertToUIColor:@"#FFFF0000"];
    XCTAssertTrue(CGColorEqualToColor(controller.swrveConversationItemViewController.view.superview.backgroundColor.CGColor, lbUIColor.CGColor));
    
    // Dismiss the conversation
    [controller.swrveConversationItemViewController cancelButtonTapped:nil];
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];

    XCTAssertEqual(campaign.state.impressions,1);
    XCTAssertEqual(campaign.state.status,SWRVE_CAMPAIGN_STATUS_SEEN);

    // We don't get the conversation because the assets suddently dissapeared
    SwrveAssetsManager *assetsManager = [swrveMock messaging].assetsManager;
    NSMutableSet* assetsOnDisk = [assetsManager valueForKey:@"assetsOnDiskSet"];
    NSArray* previousAssets = [assetsOnDisk allObjects];
    [assetsOnDisk removeAllObjects];
    XCTAssertEqual([[controller messageCenterCampaigns] count], 0);

    [assetsOnDisk addObjectsFromArray:previousAssets];

    // We can still get the Conversation, even though the rules specify a limit of 1 impression
    SwrveCampaign* firstCampaign = [[controller messageCenterCampaigns] objectAtIndex:1];
    XCTAssertEqual(firstCampaign.ID, campaign.ID);

    // ensure dateStart is present
    XCTAssertNotNil(firstCampaign.dateStart);

    NSDateFormatter *dformat = [[NSDateFormatter alloc] init];
    [dformat setDateFormat:@"MMMM dd, yyyy (EEEE) HH:mm:ss z Z"];

    // set the timeZone to UTC so it passes regardless of Simulator time
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dformat setTimeZone:timeZone];

    XCTAssertEqualObjects([dformat stringFromDate:firstCampaign.dateStart],@"March 07, 2013 (Thursday) 15:55:00 GMT +0000");

    // Remove the campaign, we will never get it again
    [controller removeMessageCenterCampaign:campaign];

    XCTAssertFalse([[controller messageCenterCampaigns] containsObject:campaign]);
    XCTAssertEqual(campaign.state.status,SWRVE_CAMPAIGN_STATUS_DELETED);
    // Reset to default UIInterfaceOrientationPortrait orientation
    XCUIDevice.sharedDevice.orientation = UIInterfaceOrientationPortrait;
}
#endif

@end
