#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SwrveTestHelper.h"

@interface SwrveSDK()
+ (void)resetSwrveSharedInstance;
@end

@interface Swrve()
- (void)initSwrveRestClient:(NSTimeInterval)timeOut urlSssionDelegate:(id <NSURLSessionDelegate>)urlSssionDelegate;
- (void)appDidBecomeActive:(NSNotification *)notification;
@end

@interface SwrveMessageController ()

- (id)initWithSwrve:(Swrve*)sdk;
- (void)writeToCampaignCache:(NSData*)campaignData;
- (void)updateCampaigns:(NSDictionary *)campaignDic withLoadingPreviousCampaignState:(BOOL) isLoadingPreviousCampaignState notifyCampaignsUpdated:(BOOL)notifyCampaignsUpdated;
- (NSDate *)getNow;
@property (nonatomic, retain) SwrveAssetsManager *assetsManager;
@end

@interface SwrveThemedUIButton ()
@property(atomic) CGFloat renderScale;
@property(atomic, retain) SwrveCalibration *calibration;
@end

@interface SwrveMessageFocus ()

- (void)applyFocusOnSwrveButton:(UIView *)view gainFocus:(bool)gainFocus;

@end

@interface SwrveTestMessageCenterAPI : XCTestCase

@property NSDate *swrveNowDate;

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

+ (NSMutableArray *)testJSONButtonThemeAssets {
    NSMutableArray *assets = [NSMutableArray array];
    [assets addObject:@"1111111111111111111111111"];
    [assets addObject:@"535.1030.b60343e5f678c56d52e80b00e604104a73d256f2.ttf"];
    [assets addObject:@"9973b5003e299dab6394258c459e82b58a7a7633"];
    [assets addObject:@"73efb349f6e6ab7753bdfc1073d2035d607bbd40"];
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
    
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO notifyCampaignsUpdated:NO];

    // No Message Center campaigns
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 0);
}

- (void)testCampaignsUpdateDelegateFiresOnlyAfterAsyncAssetDownload {
#if TARGET_OS_IOS
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];
#endif

    // No createDummyAssets: the assets are missing, as on a fresh install.
    id swrveMock = [self swrveMock];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop

    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);

    // Hold the completion handler rather than letting the download run, so the notification can be
    // observed both before and after the assets land. This is the fresh-install path: the handler is
    // what the app depends on, and it arrives long after updateCampaigns has returned.
    __block void (^heldCompletion)(void) = nil;
    __block BOOL assetsLanded = NO;
    NSSet *noAssets = [NSSet set];
    NSSet *allAssets = [NSSet setWithArray:[SwrveTestMessageCenterAPI testJSONAssets]];

    id mockAssetsManager = OCMPartialMock([[swrveMock messaging] assetsManager]);
    OCMStub([mockAssetsManager downloadAssets:OCMOCK_ANY withCompletionHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained void (^handler)(void) = nil;
        [invocation getArgument:&handler atIndex:3];
        heldCompletion = [handler copy];
    });
    OCMStub([mockAssetsManager assetsOnDisk]).andDo(^(NSInvocation *invocation) {
        NSSet *result = assetsLanded ? allAssets : noAssets;
        [invocation setReturnValue:&result];
    });

    __block NSUInteger countSeenByDelegate = NSNotFound;
    id mockDelegate = OCMProtocolMock(@protocol(SwrveCampaignsUpdateDelegate));
    OCMStub([mockDelegate campaignsUpdated]).andDo(^(NSInvocation *invocation) {
        countSeenByDelegate = [[swrveMock messageCenterCampaigns] count];
    });
    [swrveMock campaignsUpdateListener:mockDelegate];

    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsMessageCenter" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockData options:0 error:nil];

    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO notifyCampaignsUpdated:YES];

    // Only the embedded campaign is listable: it has no assets to wait for, while the IAM one is gated on
    // assetsReady. Notifying now is the bug this feature exists to remove — the app would re-read and find
    // an incomplete Message Center with no further callback to tell it the rest had arrived.
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 1, @"only the asset-free embedded campaign should be listable yet");
    XCTAssertEqual(countSeenByDelegate, NSNotFound, @"the delegate must not be told before the assets land");
    XCTAssertNotNil(heldCompletion, @"downloadAssets should have been asked for the missing assets");

    // The assets arrive, then the handler runs — the order the SDK actually produces.
    assetsLanded = YES;
    heldCompletion();

    XCTAssertEqual(countSeenByDelegate, 2, @"the delegate must see both campaigns as listable once the assets land");
}

- (void)testCampaignsUpdateDelegateCanReadNewCampaigns {
#if TARGET_OS_IOS
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];
#endif

    // Assets already on disk, so downloadAssets has nothing to fetch and its completion handler —
    // which is where the delegate is invoked — runs synchronously inside updateCampaigns.
    [SwrveTestHelper createDummyAssets:[SwrveTestMessageCenterAPI testJSONAssets]];

    id swrveMock = [self swrveMock];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop

    // The campaigns in this fixture are only inside their window at this date.
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);

    // Read the getters from inside the callback. The contract promises the new campaigns are readable
    // by then, which only holds because self.campaigns is assigned before downloadAssets is called.
    __block NSUInteger countSeenByDelegate = NSNotFound;
    id mockDelegate = OCMProtocolMock(@protocol(SwrveCampaignsUpdateDelegate));
    OCMStub([mockDelegate campaignsUpdated]).andDo(^(NSInvocation *invocation) {
        countSeenByDelegate = [[swrveMock messageCenterCampaigns] count];
    });
    [swrveMock campaignsUpdateListener:mockDelegate];

    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsMessageCenter" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockData options:0 error:nil];

    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO notifyCampaignsUpdated:YES];

    // One assertion, deliberately: it fails as NSNotFound if the delegate was never called, and with the
    // wrong count if it was called before the campaigns were readable. The number of calls is not asserted —
    // downloadAssets fires its handler from each asset's own completion, so it coalesces only while requests
    // overlap, and this harness answers HTTP synchronously, giving one call per asset.
    XCTAssertEqual(countSeenByDelegate, 2, @"the delegate must be able to read the new campaigns when it is called");
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

    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO notifyCampaignsUpdated:NO];

    SwrveMessageController* controller = [swrveMock messaging];

    // No Message Center campaigns as they have both finished
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 0);

    // mock date that lies within the start and end time of the campaign in the test json file campaignsMessageCenter
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);

    // IAM, Embedded
#if TARGET_OS_IOS
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 2);
    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationLandscapeRight] count], 2);
    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationPortrait] count], 2);
#elif TARGET_OS_TV
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 2);
#endif
    SwrveCampaign *campaign = [[swrveMock messageCenterCampaigns] objectAtIndex:0];
    XCTAssertEqual(campaign.state.status, SwrveCampaignStatusUnseen);
    XCTAssertEqual([campaign.priority intValue], 5);
    XCTAssertEqualObjects(campaign.name,@"Kindle");

    // Display in-app message
    [controller showMessageCenterCampaign:campaign];
    SwrveMessageViewController* viewController = [self messageViewControllerFrom:controller];
    [viewController viewDidAppear:NO];

    // Press dismiss button
    SwrveUIButton* dismissButton = [SwrveUIButton new];
    [viewController onButtonPressed:dismissButton pageId:[NSNumber numberWithInt:0]];

    XCTAssertEqual(campaign.state.impressions, 1);
    XCTAssertEqual(campaign.state.status, SwrveCampaignStatusSeen);

    // We can still get the IAM, even though the rules specify a limit of 1 impression
    SwrveCampaign *firstCampaign = [[swrveMock messageCenterCampaigns] objectAtIndex:0];

    XCTAssertEqual(firstCampaign.ID, campaign.ID);

    // Remove the campaign, we will never get it again
    [controller removeMessageCenterCampaign:campaign];

    XCTAssertFalse([[swrveMock messageCenterCampaigns] containsObject:campaign]);
    XCTAssertEqual(campaign.state.status, SwrveCampaignStatusDeleted);

#if TARGET_OS_IOS
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];
#endif
}

- (void)testIAMMessageCenterIsActive {

    [SwrveTestHelper createDummyAssets:[SwrveTestMessageCenterAPI testJSONAssets]];
    id swrveMock = [self swrveMock];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop

    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsMessageCenter" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockData options:0 error:nil];
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO notifyCampaignsUpdated:NO];
    SwrveMessageController* controller = [swrveMock messaging];
    controller.analyticsSDK = swrveMock;
    
    // Campaign 102 has a start date of 2013-03-07T15:55:00Z and an end date of 2013-03-29T14:55:00Z
    // Test will get the campaign while campaign is active, then try show it under different date scenarios
    
    NSISO8601DateFormatter *iso8601Formatter = [[NSISO8601DateFormatter alloc] init];
    OCMStub([swrveMock getNow]).andDo(^(NSInvocation *invocation) {
        NSDate *retVal = self.swrveNowDate;
        NSLog(@"retVal %@", retVal);
        [invocation setReturnValue:&retVal];
    });
    
    // No Message Center campaign as it has not started yet
    self.swrveNowDate = [iso8601Formatter dateFromString:@"2013-03-06T12:00:00Z"];
    SwrveCampaign *campaign = [swrveMock messageCenterCampaignWithID:102 andPersonalization:nil];
    XCTAssertNil(campaign);
    
    // Get campaign during active period and try show it
    self.swrveNowDate = [iso8601Formatter dateFromString:@"2013-03-10T12:00:00Z"];
    campaign = [swrveMock messageCenterCampaignWithID:102 andPersonalization:nil];
    XCTAssertNotNil(campaign);
    XCTAssertTrue([swrveMock showMessageCenterCampaign:campaign]);

    // Using campaign which was previously retrieved, try show it after end date
    self.swrveNowDate = [iso8601Formatter dateFromString:@"2013-03-30T12:00:00Z"];
    XCTAssertFalse([swrveMock showMessageCenterCampaign:campaign]);

    // Using campaign which was previously retrieved, try show it during active period
    self.swrveNowDate = [iso8601Formatter dateFromString:@"2013-03-10T12:00:00Z"];
    XCTAssertTrue([swrveMock showMessageCenterCampaign:campaign]);
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
    
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO notifyCampaignsUpdated:NO];
    
    SwrveCampaign *campaign = [[swrveMock messageCenterCampaigns] objectAtIndex:0];
    XCTAssertEqual(campaign.state.status, SwrveCampaignStatusUnseen);
    
    // Mark message as seen programmatically
    [swrveMock markMessageCenterCampaignAsSeen:campaign];
    XCTAssertEqual(campaign.state.status, SwrveCampaignStatusSeen);
    
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
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO notifyCampaignsUpdated:NO];

    SwrveMessageController *controller = [swrveMock messaging];

    // No Message Center campaigns as they have both finished
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 0);

    // mock date that lies within the start and end time of the campaign in the test json file campaignsMessageCenter
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);

    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 0); // Should be 0 message centerCampaign because they all require personalization
    XCTAssertEqual([[swrveMock messageCenterCampaignsWithPersonalization:validPersonalization] count], 2); // Should be 2 message centerCampaign with correct personalization passed in

    // IAM support these orientations
#if TARGET_OS_IOS
    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationLandscapeRight withPersonalization:validPersonalization] count], 2);
    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationPortrait withPersonalization:validPersonalization] count], 2);

    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationLandscapeRight withPersonalization:nil] count], 0);
    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationPortrait withPersonalization:nil] count], 0);
#endif

    SwrveCampaign *campaign = [[swrveMock messageCenterCampaignsWithPersonalization:validPersonalization] objectAtIndex:0];
    XCTAssertEqual(campaign.state.status,SwrveCampaignStatusUnseen);

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
    XCTAssertEqual(campaign.state.status, SwrveCampaignStatusUnseen);

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
    XCTAssertEqual(campaign.state.status, SwrveCampaignStatusUnseen);

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

    // access the UIViews in the subview of the SwrveMessageViewController
    NSArray *vcSubviews = [[[[viewController view] subviews] firstObject] subviews];
    NSMutableArray *uiButtons = [NSMutableArray new];

    // get all the buttons
    for (UIView *item in vcSubviews){
        if ([item isKindOfClass:[SwrveUIButton class]]) {
            [uiButtons addObject:item];
        }
    }

    XCTAssertEqual([uiButtons count], 2);
    SwrveUIButton *clipboardButton = nil;

    for (NSInteger i = 0; i < [buttons count]; i++) {
        SwrveButton *swrveButton = [buttons objectAtIndex:i];

        // verify that a SwrveUIButton matching the tag has custom action
        if ([swrveButton actionType] == kSwrveActionCustom) {
            for (SwrveUIButton *button in uiButtons){
                if ([button.accessibilityIdentifier isEqualToString:swrveButton.name]) {
                    XCTAssertEqualObjects(button.displayString, @"custom: display");
                    XCTAssertEqualObjects(button.actionString, @"urltest.com/urlprocessed");
                }
            }
        }

        // verify that a SwrveUIButton matching the tag has clipboard action
        if ([swrveButton actionType] == kSwrveActionClipboard) {
            for (SwrveUIButton *button in uiButtons){
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
    [messageViewController onButtonPressed:clipboardButton pageId:[NSNumber numberWithInt:0]];
    [self waitForWindowDismissed:controller];

    XCTAssertEqual(campaign.state.impressions, 1);
    XCTAssertEqual(campaign.state.status, SwrveCampaignStatusSeen);

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
    XCTAssertEqual(campaign.state.status, SwrveCampaignStatusDeleted);

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
    
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO notifyCampaignsUpdated:NO];
    
    SwrveMessageController *controller = [swrveMock messaging];
    
    // No Message Center campaigns as they have both finished
    XCTAssertEqual([[swrveMock messageCenterCampaignsWithPersonalization:testPersonalization] count], 0);

    // mock date that lies within the start and end time of the campaign in the test json file campaignsMessageCenter
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);
    
#if TARGET_OS_IOS
    XCTAssertEqual([[swrveMock messageCenterCampaignsWithPersonalization:nil] count], 2); // should not display since there's no personalization
    XCTAssertEqual([[swrveMock messageCenterCampaignsWithPersonalization:testPersonalization] count], 3);
#elif TARGET_OS_TV
    XCTAssertEqual([[swrveMock messageCenterCampaignsWithPersonalization:nil] count], 2);
    XCTAssertEqual([[swrveMock messageCenterCampaignsWithPersonalization:testPersonalization] count], 3);
#endif
    
    NSArray<SwrveCampaign *> *campaigns = [swrveMock messageCenterCampaignsWithPersonalization:testPersonalization];
    SwrveCampaign *campaign = nil;
    for (SwrveCampaign *candidate in campaigns) {
        if(candidate.ID == 105 ){
            campaign = candidate;
        }
    }
    
    XCTAssertEqual(campaign.state.status,SwrveCampaignStatusUnseen);
    
    // attempt the wrong personalization
    [controller showMessageCenterCampaign:campaign withPersonalization:@{@"wrong":@"id"}];
    
    // it should not show
    XCTAssertEqual(campaign.state.status,SwrveCampaignStatusUnseen);

    // Display in-app message with the correct personalization
    [controller showMessageCenterCampaign:campaign withPersonalization:testPersonalization];
    SwrveMessageViewController* viewController = [self messageViewControllerFrom:controller];
    [viewController viewDidAppear:NO];

    XCTAssertEqual(campaign.state.impressions, 1);
    XCTAssertEqual(campaign.state.status, SwrveCampaignStatusSeen);

    // Remove the campaign
    [controller removeMessageCenterCampaign:campaign];
    
    XCTAssertFalse([[swrveMock messageCenterCampaignsWithPersonalization:testPersonalization] containsObject:campaign]);
    XCTAssertEqual(campaign.state.status, SwrveCampaignStatusDeleted);
    
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
    
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO notifyCampaignsUpdated:NO];
    
    SwrveMessageController *controller = [swrveMock messaging];

#if TARGET_OS_IOS
    XCTAssertEqual([[swrveMock messageCenterCampaignsWithPersonalization:testPersonalization] count], 5);
#elif TARGET_OS_TV
    XCTAssertEqual([[swrveMock messageCenterCampaignsWithPersonalization:testPersonalization] count], 5);
#endif
    
    NSArray<SwrveCampaign *> *campaigns = [swrveMock messageCenterCampaignsWithPersonalization:testPersonalization];
    SwrveCampaign *campaign = nil;
    for (SwrveCampaign *candidate in campaigns) {
        if(candidate.ID == 106){
            campaign = candidate;
        }
    }
    
    XCTAssertEqual(campaign.state.status,SwrveCampaignStatusUnseen);
    
    // attempt the wrong personalization
    [controller showMessageCenterCampaign:campaign withPersonalization:@{@"wrong":@"id"}];
    
    // it should not show
    XCTAssertEqual(campaign.state.status,SwrveCampaignStatusUnseen);

    // Display in-app message with the correct personalization
    [controller showMessageCenterCampaign:campaign withPersonalization:testPersonalization];
    SwrveMessageViewController* viewController = [self messageViewControllerFrom:controller];
    [viewController viewDidAppear:NO];

    XCTAssertEqual(campaign.state.impressions, 1);
    XCTAssertEqual(campaign.state.status, SwrveCampaignStatusSeen);

    // Remove the campaign
    [controller removeMessageCenterCampaign:campaign];
    
    XCTAssertFalse([[swrveMock messageCenterCampaignsWithPersonalization:testPersonalization] containsObject:campaign]);
    XCTAssertEqual(campaign.state.status, SwrveCampaignStatusDeleted);
    
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
    
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO notifyCampaignsUpdated:NO];
    
    SwrveMessageController *controller = [swrveMock messaging];

#if TARGET_OS_IOS
    //  include no personalization dictionary and we should still get 4
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 3);
    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationPortrait] count], 3);
#elif TARGET_OS_TV
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 3);
#endif
    
    NSArray<SwrveCampaign *> *campaigns = [swrveMock messageCenterCampaignsWithPersonalization:nil];
    SwrveCampaign *campaign = nil;
    for (SwrveCampaign *candidate in campaigns) {
        if(candidate.ID == 107){
            campaign = candidate;
        }
    }
    
    XCTAssertEqual(campaign.state.status,SwrveCampaignStatusUnseen);

    // Display in-app message with no personalization, should be resolved by injected RTUPs
    [controller showMessageCenterCampaign:campaign withPersonalization:nil];
    SwrveMessageViewController* viewController = [self messageViewControllerFrom:controller];
    [viewController viewDidAppear:NO];

    XCTAssertEqual(campaign.state.impressions, 1);
    XCTAssertEqual(campaign.state.status, SwrveCampaignStatusSeen);

    // Remove the campaign
    [controller removeMessageCenterCampaign:campaign];
    
    XCTAssertFalse([[swrveMock messageCenterCampaignsWithPersonalization:nil] containsObject:campaign]);
    XCTAssertEqual(campaign.state.status, SwrveCampaignStatusDeleted);
    
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
    
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO notifyCampaignsUpdated:NO];
    
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

    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO notifyCampaignsUpdated:NO];

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
    XCTAssertEqualObjects(campaign.messageCenterDetails.description, @"");
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

- (void)testIAMMessageCenterDetailsWithFreemarker {
#if TARGET_OS_IOS
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];
#endif

    [SwrveTestHelper createDummyAssets:[SwrveTestMessageCenterAPI testJSONAssets]];

    id swrveMock = [self swrveMock];
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600];
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop

    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsFreemarkerMessageCenter" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockData options:0 error:nil];
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO notifyCampaignsUpdated:NO];

    // FreeMarker conditional resolves correctly for gold tier
    NSDictionary *goldPersonalization = @{@"Recipient.tier": @"gold", @"Recipient.name": @"Alice"};
    SwrveCampaign *campaign = [swrveMock messageCenterCampaignWithID:105 andPersonalization:goldPersonalization];
    XCTAssertEqualObjects(campaign.messageCenterDetails.subject, @"Gold Member");
    XCTAssertEqualObjects(campaign.messageCenterDetails.description, @"Welcome, Alice");
    XCTAssertEqualObjects(campaign.messageCenterDetails.imageAccessibilityText, @"Gold banner");

    // FreeMarker conditional resolves correctly for non-gold tier
    NSDictionary *standardPersonalization = @{@"Recipient.tier": @"bronze", @"Recipient.name": @"Bob"};
    campaign = [swrveMock messageCenterCampaignWithID:105 andPersonalization:standardPersonalization];
    XCTAssertEqualObjects(campaign.messageCenterDetails.subject, @"Standard Member");
    XCTAssertEqualObjects(campaign.messageCenterDetails.description, @"Welcome, Bob");
    XCTAssertEqualObjects(campaign.messageCenterDetails.imageAccessibilityText, @"Standard banner");

    // Missing required FreeMarker property suppresses the campaign
    NSDictionary *missingProps = @{@"Recipient.name": @"Charlie"};
    campaign = [swrveMock messageCenterCampaignWithID:105 andPersonalization:missingProps];
    XCTAssertNil(campaign);

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
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:YES notifyCampaignsUpdated:NO];

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
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:YES notifyCampaignsUpdated:NO];

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

- (void)testThemedButton {
    [SwrveTestHelper createDummyAssets:[SwrveTestMessageCenterAPI testJSONButtonThemeAssets]];
    [SwrveTestHelper createDummyAssets:@[@"9973b5003e299dab6394258c459e82b58a7a7633", @"73efb349f6e6ab7753bdfc1073d2035d607bbd40"] withResourceName:@"swrve_logo" ofType:@"png"];

    id swrveMock = [self swrveMock];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop

    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaign_native_button_basics" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockData options:0 error:nil];
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO notifyCampaignsUpdated:NO];

    SwrveMessageController *controller = [swrveMock messaging];
    SwrveCampaign *campaign = [controller messageCenterCampaignWithID:625386 andPersonalization:nil];
    [controller showMessageCenterCampaign:campaign];
    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    XCTAssertNotNil(messageViewController);
    XCTAssertNotNil(messageViewController.message);
    XCTAssertEqualObjects(messageViewController.message.name, @"native buttons t1");

    SwrveMessagePageViewController *viewController = nil;
#if TARGET_OS_TV
    viewController = [messageViewController.childViewControllers firstObject];
#else
    viewController = [messageViewController.viewControllers firstObject];
#endif

    // access the UIViews in the subview of the SwrveMessageViewController
    NSArray *vcSubviews = [[[[viewController view] subviews] firstObject] subviews];
    XCTAssertEqual([vcSubviews count], 5);

    UIView *backgroundImage = [vcSubviews objectAtIndex:0];
    XCTAssertTrue([backgroundImage isKindOfClass:[UIImageView class]]);

    // 1st button
    [self assertThemedButton:vcSubviews index:1 text:@"Text Button" accessibilityLabel:@"Text Button"
                cornerRadius:0 font:@".SFUI-Regular" fontSize:21
                   textColor:@"#FF000000" textColorPressed:@"#FFFF0000"
                     bgColor:@"#FFFF0000" bgColorPressed:@"#ffffd700" bgColorFocused:nil
                 borderWidth:0 borderColor:nil borderColorPressed:nil borderColorFocused:nil
                  paddingTop:10 paddingLeft:20 paddingBottom:30 paddingRight:40
                   alignment:UIControlContentHorizontalAlignmentLeft];

    // 2nd button with custom accessibility text
    [self assertThemedButton:vcSubviews index:2 text:@"Text Button longer  text" accessibilityLabel:@"Custom accessibility text"
                cornerRadius:40 font:@".SFUI-Regular" fontSize:10
                   textColor:@"#FF000000" textColorPressed:@"#FFFF0000"
                     bgColor:@"#FFFF0000" bgColorPressed:@"#ffffd700" bgColorFocused:@"ffffff00"
                 borderWidth:4 borderColor:@"FF000000" borderColorPressed:@"FFFF0000" borderColorFocused:@"FF0040DD"
                  paddingTop:0 paddingLeft:0 paddingBottom:0 paddingRight:0
                   alignment:UIControlContentHorizontalAlignmentCenter];

    // 3rd button
    [self assertThemedButton:vcSubviews index:3 text:@"system 12" accessibilityLabel:@"system 12"
                cornerRadius:0 font:@".SFUI-Regular" fontSize:12
                   textColor:@"#FF000000" textColorPressed:@"#FFFF0000"
                     bgColor:nil bgColorPressed:nil bgColorFocused:nil
                 borderWidth:0 borderColor:nil borderColorPressed:nil borderColorFocused:nil
                  paddingTop:0 paddingLeft:0 paddingBottom:0 paddingRight:0
                   alignment:UIControlContentHorizontalAlignmentRight];

    // 4th button
    [self assertThemedButton:vcSubviews index:4 text:@"Comic 16" accessibilityLabel:@"Comic 16"
                cornerRadius:0 font:@".SFUI-Regular" fontSize:16
                   textColor:@"#FF000000" textColorPressed:@"#FFFF0000"
                     bgColor:@"#667fd8ff" bgColorPressed:@"#ffffd700" bgColorFocused:nil
                 borderWidth:0 borderColor:nil borderColorPressed:nil borderColorFocused:nil
                  paddingTop:0 paddingLeft:0 paddingBottom:0 paddingRight:0
                   alignment:UIControlContentHorizontalAlignmentCenter];
}

- (void)assertThemedButton:(NSArray *)vcSubviews index:(int)index text:(NSString *)text accessibilityLabel:(NSString *)accessibilityLabel
              cornerRadius:(int)cornerRadius font:(NSString *)fontName fontSize:(CGFloat)fontSize
                 textColor:(NSString *)textColor textColorPressed:(NSString *)textColorPressed
                   bgColor:(NSString *)bgColor bgColorPressed:(NSString *)bgColorPressed bgColorFocused:(NSString *)bgColorFocused
               borderWidth:(CGFloat)borderWidth borderColor:(NSString *)borderColor borderColorPressed:(NSString *)borderColorPressed borderColorFocused:(NSString *)borderColorFocused
                paddingTop:(CGFloat)top paddingLeft:(CGFloat)left paddingBottom:(CGFloat)bottom paddingRight:(CGFloat)right
                 alignment:(UIControlContentHorizontalAlignment)alignment {
    UIView *view1 = [vcSubviews objectAtIndex:index];
    XCTAssertTrue([view1 isKindOfClass:[SwrveThemedUIButton class]]);
    SwrveThemedUIButton *button = (SwrveThemedUIButton *) view1;
    XCTAssertEqualObjects(button.titleLabel.text, text);
    XCTAssertEqualObjects([button accessibilityLabel], accessibilityLabel);
    XCTAssertEqual(button.layer.cornerRadius, cornerRadius * button.renderScale);
    XCTAssertEqualObjects(button.titleLabel.font.fontName, fontName);
    UIFont *systemFont = [UIFont systemFontOfSize:fontSize];
    CGFloat scaledFontSize = [SwrveSDKUtils scaleFont:systemFont
                                           calibration:button.calibration
                                         swrveFontSize:fontSize
                                           renderScale:button.renderScale];
    XCTAssertEqual(button.titleLabel.font.pointSize, scaledFontSize);
    UIColor *titleUIColor = [SwrveUtils processHexColorValue:textColor];
    XCTAssertEqualObjects(button.titleLabel.textColor, titleUIColor);
    if (bgColor) {
        UIColor *bgUIColor = [SwrveUtils processHexColorValue:bgColor];
        XCTAssertEqualObjects(button.backgroundColor, bgUIColor);
    } else {
        XCTAssertNotNil([button backgroundImageForState:UIControlStateNormal]);
        XCTAssertNotNil([button backgroundImageForState:UIControlStateHighlighted]);
        XCTAssertNotNil([button backgroundImageForState:UIControlStateFocused]);
    }
    XCTAssertEqual(button.layer.borderWidth, borderWidth * button.renderScale);
    if (borderWidth > 0) {
        UIColor *borderUIColor = [SwrveUtils processHexColorValue:borderColor];
        XCTAssert(CGColorEqualToColor(button.layer.borderColor, [borderUIColor CGColor]));
    }
    XCTAssertEqual(button.contentEdgeInsets.top, (top + borderWidth) * button.renderScale);
    XCTAssertEqual(button.contentEdgeInsets.left, (left + borderWidth) * button.renderScale);
    XCTAssertEqual(button.contentEdgeInsets.bottom, (bottom + borderWidth) * button.renderScale);
    XCTAssertEqual(button.contentEdgeInsets.right, (right + borderWidth) * button.renderScale);

    // test focused state
    SwrveMessageFocus *messageFocus = [[SwrveMessageFocus alloc] initWithView:button]; // should be init with root view, but doens't matter here for test
    [messageFocus applyFocusOnSwrveButton:button gainFocus:true];
    if (bgColorFocused) {
        UIColor *focusedBgUIColor = [SwrveUtils processHexColorValue:bgColorFocused];
        XCTAssertEqualObjects(button.backgroundColor, focusedBgUIColor);
    }
    if (borderWidth > 0 && borderColorFocused) {
        UIColor *borderUIColor = [SwrveUtils processHexColorValue:borderColorFocused];
        XCTAssert(CGColorEqualToColor(button.layer.borderColor, [borderUIColor CGColor]));
    }

    // test pressed/highlighted state
    [button setHighlighted:true];

    UIColor *pressedTitleUIColor = [SwrveUtils processHexColorValue:textColorPressed];
    XCTAssertEqualObjects(button.titleLabel.textColor, pressedTitleUIColor);
    if (bgColorPressed) {
        UIColor *pressedBgUIColor = [SwrveUtils processHexColorValue:bgColorPressed];
        XCTAssertEqualObjects(button.backgroundColor, pressedBgUIColor);
    } else {
        XCTAssertEqualObjects(button.backgroundColor, UIColor.clearColor);
    }
    if (borderWidth > 0) {
        UIColor *borderUIColor = [SwrveUtils processHexColorValue:borderColorPressed];
        XCTAssert(CGColorEqualToColor(button.layer.borderColor, [borderUIColor CGColor]));
    }

    XCTAssertEqual(button.contentHorizontalAlignment, alignment);
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

- (void)testEmbeddedMessageCenterCampaigns {
    [SwrveTestHelper createDummyAssets:[SwrveTestMessageCenterAPI testJSONAssets]];
    
    id swrveMock = [self swrveMock];
    // mock date that lies within the start and end time of the campaign
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop
    
    // Load campaigns with embedded messages
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsMessageCenter" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockData options:0 error:nil];
    
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO notifyCampaignsUpdated:NO];
    
    NSArray *embeddedCampaigns = [swrveMock embeddedMessageCenterCampaigns:nil];
    XCTAssertNotNil(embeddedCampaigns);
    XCTAssertEqual(embeddedCampaigns.count, 1);
    
    NSDictionary *personalization = @{@"test_key": @"test_value"};
    embeddedCampaigns = [swrveMock embeddedMessageCenterCampaigns:personalization];
    XCTAssertTrue([embeddedCampaigns.firstObject isKindOfClass:[SwrveEmbeddedMessage class]]);
    SwrveEmbeddedMessage *embeddedMessage = embeddedCampaigns.firstObject;
    XCTAssertEqual(embeddedMessage.campaignID, 104);
    SwrveEmbeddedMessage *embeddedMessage2 = [embeddedCampaigns objectAtIndex:1];
    XCTAssertEqual(embeddedMessage2.campaignID, 108);
    
    XCTAssertEqualObjects(embeddedMessage.dataRaw, @"test string with personalization:${test_key}");
    XCTAssertEqualObjects(embeddedMessage.data, @"test string with personalization:test_value");
    NSString *personalizedData = [swrveMock personalizeEmbeddedMessageData: embeddedMessage withPersonalization:personalization];
    XCTAssertEqualObjects(personalizedData, @"test string with personalization:test_value");

    personalization = @{@"test_key": @"test_value_UPDATED"};
    embeddedCampaigns = [swrveMock embeddedMessageCenterCampaigns:personalization];
    XCTAssertTrue([embeddedCampaigns.firstObject isKindOfClass:[SwrveEmbeddedMessage class]]);
    embeddedMessage = embeddedCampaigns.firstObject;
    XCTAssertEqualObjects(embeddedMessage.dataRaw, @"test string with personalization:${test_key}"); // data raw never changes
    XCTAssertEqualObjects(embeddedMessage.data, @"test string with personalization:test_value_UPDATED"); // data changes with personalization
    
    // Mark a campaign as deleted and verify it's not returned
    [swrveMock removeMessageCenterCampaignWithID:embeddedMessage.campaignID];
    NSArray *updatedCampaigns = [swrveMock embeddedMessageCenterCampaigns:nil];
    XCTAssertEqual(updatedCampaigns.count, 1);
    embeddedMessage = updatedCampaigns.firstObject;
    XCTAssertEqual(embeddedMessage.campaignID, 108);
}

- (void)testEmbeddedMessageCenterCampaignsWithFreemarker {
    [SwrveTestHelper createDummyAssets:[SwrveTestMessageCenterAPI testJSONAssets]];

    id swrveMock = [self swrveMock];
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop

    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsFreemarkerMessageCenter" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockData options:0 error:nil];
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO notifyCampaignsUpdated:NO];

    // All 7 embedded campaigns — pass required properties so all campaigns resolve during the filter step
    NSArray *embeddedCampaigns = [swrveMock embeddedMessageCenterCampaigns:@{@"Recipient.tier": @"bronze", @"Recipient.first_name": @"test"}];
    XCTAssertEqual(embeddedCampaigns.count, 7);

    // Find each message by campaignID
    SwrveEmbeddedMessage *embeddedOther = nil;
    SwrveEmbeddedMessage *embeddedJson = nil;
    SwrveEmbeddedMessage *embeddedJsonDoubleQuote = nil;
    SwrveEmbeddedMessage *embeddedJsonNested = nil;
    SwrveEmbeddedMessage *embeddedJsonArray = nil;
    SwrveEmbeddedMessage *embeddedOtherStringLiteral = nil;
    SwrveEmbeddedMessage *embeddedJsonTopLevelArray = nil;
    for (SwrveEmbeddedMessage *msg in embeddedCampaigns) {
        if (msg.campaignID == 106) embeddedOther = msg;
        if (msg.campaignID == 107) embeddedJson = msg;
        if (msg.campaignID == 108) embeddedJsonDoubleQuote = msg;
        if (msg.campaignID == 109) embeddedJsonNested = msg;
        if (msg.campaignID == 110) embeddedJsonArray = msg;
        if (msg.campaignID == 111) embeddedOtherStringLiteral = msg;
        if (msg.campaignID == 112) embeddedJsonTopLevelArray = msg;
    }
    XCTAssertNotNil(embeddedOther);
    XCTAssertNotNil(embeddedJson);
    XCTAssertNotNil(embeddedJsonDoubleQuote);
    XCTAssertNotNil(embeddedJsonNested);
    XCTAssertNotNil(embeddedJsonArray);
    XCTAssertNotNil(embeddedOtherStringLiteral);
    XCTAssertNotNil(embeddedJsonTopLevelArray);

    NSDictionary *propsWithName = @{@"user_name": @"Alice"};

    // --- type: other ---
    // Property present — FreeMarker resolves to the value
    NSString *resolvedOther = [swrveMock personalizeEmbeddedMessageData:embeddedOther withPersonalization:propsWithName];
    XCTAssertEqualObjects(resolvedOther, @"Alice");

    // Property absent — FreeMarker <#else> branch resolves to "anonymous"
    NSString *resolvedOtherDefault = [swrveMock personalizeEmbeddedMessageData:embeddedOther withPersonalization:@{}];
    XCTAssertEqualObjects(resolvedOtherDefault, @"anonymous");

    // --- type: json (parse-first) ---
    // NSJSONSerialization produces compact JSON (no spaces), compare parsed values
    NSString *resolvedJson = [swrveMock personalizeEmbeddedMessageData:embeddedJson withPersonalization:propsWithName];
    NSDictionary *resolvedJsonDict = [NSJSONSerialization JSONObjectWithData:[resolvedJson dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    XCTAssertEqualObjects(resolvedJsonDict[@"name"], @"Alice");

    NSString *resolvedJsonDefault = [swrveMock personalizeEmbeddedMessageData:embeddedJson withPersonalization:@{}];
    NSDictionary *resolvedJsonDefaultDict = [NSJSONSerialization JSONObjectWithData:[resolvedJsonDefault dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    XCTAssertEqualObjects(resolvedJsonDefaultDict[@"name"], @"anonymous");

    // --- type: json with double-quoted string literal ---
    // Verifies parse-first correctly handles \"gold\" from server double-escaping
    NSDictionary *goldProps = @{@"Recipient.tier": @"gold"};
    NSString *resolvedGold = [swrveMock personalizeEmbeddedMessageData:embeddedJsonDoubleQuote withPersonalization:goldProps];
    NSDictionary *resolvedGoldDict = [NSJSONSerialization JSONObjectWithData:[resolvedGold dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    XCTAssertEqualObjects(resolvedGoldDict[@"tier_message"], @"Gold Member");

    NSDictionary *bronzeProps = @{@"Recipient.tier": @"bronze"};
    NSString *resolvedBronze = [swrveMock personalizeEmbeddedMessageData:embeddedJsonDoubleQuote withPersonalization:bronzeProps];
    NSDictionary *resolvedBronzeDict = [NSJSONSerialization JSONObjectWithData:[resolvedBronze dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    XCTAssertEqualObjects(resolvedBronzeDict[@"tier_message"], @"Standard Member");

    // --- type: json with nested object ---
    // Verifies parse-first recursively evaluates FreeMarker in nested JSON values
    NSDictionary *nestedProps = @{@"Recipient.first_name": @"Alice", @"Recipient.tier": @"gold"};
    NSString *resolvedNested = [swrveMock personalizeEmbeddedMessageData:embeddedJsonNested withPersonalization:nestedProps];
    NSDictionary *resolvedNestedDict = [NSJSONSerialization JSONObjectWithData:[resolvedNested dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    NSDictionary *userDict = resolvedNestedDict[@"user"];
    XCTAssertEqualObjects(userDict[@"name"], @"Alice");
    XCTAssertEqualObjects(userDict[@"tier"], @"gold");
    XCTAssertEqualObjects(resolvedNestedDict[@"message"], @"Hello Alice");

    // --- type: json with array ---
    // Verifies parse-first recursively evaluates FreeMarker in JSON array elements
    NSDictionary *arrayProps = @{@"Recipient.first_name": @"Alice", @"Recipient.tier": @"gold"};
    NSString *resolvedArray = [swrveMock personalizeEmbeddedMessageData:embeddedJsonArray withPersonalization:arrayProps];
    NSDictionary *resolvedArrayDict = [NSJSONSerialization JSONObjectWithData:[resolvedArray dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    NSArray *tagsArray = resolvedArrayDict[@"tags"];
    XCTAssertEqualObjects(tagsArray[0], @"Alice");
    XCTAssertEqualObjects(tagsArray[1], @"gold");

    // --- type: other with string literal double-quote comparison ---
    // Verifies other type passes raw FreeMarker to engine; == "gold" string literals work without escaping issues
    NSDictionary *otherGoldProps = @{@"Recipient.tier": @"gold"};
    NSString *resolvedOtherGold = [swrveMock personalizeEmbeddedMessageData:embeddedOtherStringLiteral withPersonalization:otherGoldProps];
    XCTAssertEqualObjects(resolvedOtherGold, @"Gold Member");

    NSDictionary *otherBronzeProps = @{@"Recipient.tier": @"bronze"};
    NSString *resolvedOtherBronze = [swrveMock personalizeEmbeddedMessageData:embeddedOtherStringLiteral withPersonalization:otherBronzeProps];
    XCTAssertEqualObjects(resolvedOtherBronze, @"Standard Member");

    // --- type: json with top-level array ---
    // Verifies NSJSONSerialization + applyFreemarkerToJSONValue: dispatch handles array root correctly
    NSDictionary *topLevelArrayProps = @{@"Recipient.first_name": @"Alice", @"Recipient.tier": @"gold"};
    NSString *resolvedTopLevelArray = [swrveMock personalizeEmbeddedMessageData:embeddedJsonTopLevelArray withPersonalization:topLevelArrayProps];
    NSArray *topLevelArray = [NSJSONSerialization JSONObjectWithData:[resolvedTopLevelArray dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    XCTAssertEqualObjects(topLevelArray[0], @"Alice");
    XCTAssertEqualObjects(topLevelArray[1], @"gold");
}

#if TARGET_OS_IOS
- (void)testInAppMessageCenterCampaigns {
    [SwrveTestHelper createDummyAssets:[SwrveTestMessageCenterAPI testJSONAssets]];
    
    id swrveMock = [self swrveMock];
    // mock date that lies within the start and end time of the campaign
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop
    
    // Load campaigns with in app campaigns
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsMessageCenter" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockData options:0 error:nil];
    
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO notifyCampaignsUpdated:NO];
    
    // Test without personalization
    NSArray *inAppCampaigns = [swrveMock inAppMessageCenterCampaignsWith:UIInterfaceOrientationPortrait withPersonalization:@{}];
    XCTAssertNotNil(inAppCampaigns);
    XCTAssertEqual(inAppCampaigns.count, 1);
    XCTAssertTrue([inAppCampaigns.firstObject isKindOfClass:[SwrveInAppCampaign class]]);
    SwrveInAppCampaign *inAppCampaign102 = inAppCampaigns.firstObject;
    XCTAssertEqual(inAppCampaign102.ID, 102);
    
    // Test with invalid personalization
    NSDictionary *invalidPersonalization = @{@"invalid_test_key": @"test_value"};
    NSArray *inAppCampaignsWithInvalidPersonalization = [swrveMock inAppMessageCenterCampaignsWith:UIInterfaceOrientationPortrait withPersonalization:invalidPersonalization];
    XCTAssertNotNil(inAppCampaignsWithInvalidPersonalization);
    XCTAssertEqual(inAppCampaignsWithInvalidPersonalization.count, 1);
    XCTAssertTrue([inAppCampaignsWithInvalidPersonalization.firstObject isKindOfClass:[SwrveInAppCampaign class]]);
    inAppCampaign102 = inAppCampaignsWithInvalidPersonalization.firstObject;
    XCTAssertEqual(inAppCampaign102.ID, 102);

    // Test with valid personalization
    NSDictionary *validPersonalization = @{@"test_cp": @"test_value"};
    NSArray *inAppCampaignsWithValidPersonalization = [swrveMock inAppMessageCenterCampaignsWith:UIInterfaceOrientationPortrait withPersonalization:validPersonalization];
    XCTAssertNotNil(inAppCampaignsWithValidPersonalization);
    XCTAssertEqual(inAppCampaignsWithValidPersonalization.count, 2);
    XCTAssertTrue([inAppCampaignsWithValidPersonalization.firstObject isKindOfClass:[SwrveInAppCampaign class]]);
    inAppCampaign102 = inAppCampaignsWithValidPersonalization.firstObject;
    XCTAssertEqual(inAppCampaign102.ID, 102);
    SwrveInAppCampaign *inAppCampaign109 = [inAppCampaignsWithValidPersonalization objectAtIndex:1];
    XCTAssertEqual(inAppCampaign109.ID, 109);

    // Mark a campaign as deleted and verify it's not returned
    [swrveMock removeMessageCenterCampaignWithID:102];
    inAppCampaigns = [swrveMock inAppMessageCenterCampaignsWith:UIInterfaceOrientationPortrait withPersonalization:validPersonalization];
    XCTAssertEqual(inAppCampaigns.count, 1);
    inAppCampaign109 = [inAppCampaigns objectAtIndex:0];
    XCTAssertEqual(inAppCampaign109.ID, 109);
}
#endif


- (void)testIAMMessageCenterWithOrientation {
    // use ios for portrait testing and tvOS for landscape testing
#if TARGET_OS_IOS
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];
#elif TARGET_OS_TV
    // tvOS is landscape
#endif

    [SwrveTestHelper createDummyAssets:[SwrveTestMessageCenterAPI testJSONAssets]];
    id swrveMock = [self swrveMock];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop

    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsMessageCenterOrientation" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockData options:0 error:nil];
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO notifyCampaignsUpdated:NO];

#if TARGET_OS_IOS
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 3);
    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationLandscapeRight] count], 2);
    XCTAssertEqual([[swrveMock messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationPortrait] count], 2);
#elif TARGET_OS_TV
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 3);
#endif
    
    // Get all campaigns (Both orientations)
    NSArray<SwrveCampaign *> *allCampaigns = [swrveMock messageCenterCampaigns];
    SwrveCampaign *campaign102Both = [allCampaigns objectAtIndex:0];
    XCTAssertEqual(campaign102Both.ID, 102);
    SwrveCampaign *campaign105Landscape = [allCampaigns objectAtIndex:1];
    XCTAssertEqual(campaign105Landscape.ID, 105);
    SwrveCampaign *campaign106Portrait = [allCampaigns objectAtIndex:2];
    XCTAssertEqual(campaign106Portrait.ID, 106);

    SwrveMessageController* controller = [swrveMock messaging];
    SwrveUIButton* dummyDismissButton = [SwrveUIButton new];
    
    // Show campaign 102 which supports both orientations. 
    [controller showMessageCenterCampaign:campaign102Both];
    SwrveMessageViewController* messageViewController = [self messageViewControllerFrom:controller];
    XCTAssertNotNil(messageViewController);
    [messageViewController onButtonPressed:dummyDismissButton pageId:[NSNumber numberWithInt:0]];
    [self waitForWindowDismissed:controller];

    // Try showing campaign 105 which only supports landscape orientation (so only tvOS will show it)
#if TARGET_OS_IOS
    [controller showMessageCenterCampaign:campaign105Landscape];
    messageViewController = [self messageViewControllerFrom:controller];
    XCTAssertNil(messageViewController);
#elif TARGET_OS_TV
    [controller showMessageCenterCampaign:campaign105Landscape];
    messageViewController = [self messageViewControllerFrom:controller];
    XCTAssertNotNil(messageViewController);
    [messageViewController onButtonPressed:dummyDismissButton pageId:[NSNumber numberWithInt:0]];
    [self waitForWindowDismissed:controller];
#endif

    // Try showing campaign 106 which only supports portrait orientation (so only iOS will show it)
#if TARGET_OS_IOS
    [controller showMessageCenterCampaign:campaign106Portrait];
    messageViewController = [self messageViewControllerFrom:controller];
    XCTAssertNotNil(messageViewController);
    [messageViewController onButtonPressed:dummyDismissButton pageId:[NSNumber numberWithInt:0]];
    [self waitForWindowDismissed:controller];
#elif TARGET_OS_TV
    [controller showMessageCenterCampaign:campaign106Portrait];
    messageViewController = [self messageViewControllerFrom:controller];
    XCTAssertNil(messageViewController);
#endif
}

@end
