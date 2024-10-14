#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SwrveTestHelper.h"
#import "TestCapabilitiesDelegate.h"

#if TARGET_OS_IOS
#import "SwrvePermissions.h"
#endif //TARGET_OS_IOS

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

@interface SwrveTestMessageControllerIAMPages : XCTestCase

@property NSDate *swrveNowDate;
+ (NSArray*)testJSONAssets;
@end

@implementation SwrveTestMessageControllerIAMPages

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
    [SwrveTestHelper createDummyAssets:[SwrveTestMessageControllerIAMPages testJSONAssets]];
    self.swrveNowDate = [NSDate dateWithTimeIntervalSince1970:1362873600];
    [UIView setAnimationsEnabled: NO];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [UIView setAnimationsEnabled: YES];

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

- (void)testJsonParserNoPages {
    [SwrveLocalStorage saveSwrveUserId:@"someUserID"];
    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];
    [config setContentServer:@"someContentServer"];
    [config setOrientation:SWRVE_ORIENTATION_BOTH];
    id swrveMock = [self swrveMockWithTestJson:@"campaigns" withConfig:config];
    SwrveMessageController *controller = [swrveMock messaging];

    XCTAssertNotNil(controller);

    // Ensure calling updateCampaigns with nil doesn't change the current campaigns
    NSArray *currentCampaigns = [controller campaigns];
    [[swrveMock messaging] updateCampaigns:nil withLoadingPreviousCampaignState:NO];
    if ([controller campaigns] != nil) {
        XCTAssertEqualObjects([controller campaigns], currentCampaigns);
    }

    NSData *emptyJson = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:emptyJson options:0 error:nil];
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO];

    XCTAssertEqual([[controller campaigns] count], 0);
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaigns" ofType:@"json"];
    NSData *mockJsonData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    jsonDict = [NSJSONSerialization JSONObjectWithData:mockJsonData options:0 error:nil];

    [controller updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO];
    XCTAssertEqual([[controller campaigns] count], 2);

    NSTimeInterval nowTime = [[swrveMock getNow] timeIntervalSince1970];

    XCTAssertEqualObjects([controller user], @"someUserID");
    XCTAssertEqualObjects([[[swrveMock messaging] assetsManager] cdnImages], @"https://fake_cdn_root");
    XCTAssertEqualObjects([controller apiKey], @"someAPIKey");
    XCTAssertEqualObjects([controller server], @"someContentServer");
    XCTAssertEqualObjects([[controller assetsManager] cacheFolder], [SwrveTestHelper campaignCacheDirectory]);
    XCTAssertEqualObjects([controller language], [config language]);
    XCTAssertEqual([controller orientation], [config orientation]);
    NSString *campaignsStatePath = [SwrveLocalStorage campaignsStateFilePathForUserId:[controller user]];
    XCTAssertEqualObjects([controller campaignsStateFilePath], campaignsStatePath);

    XCTAssertEqual(nowTime, ([[controller initialisedTime] timeIntervalSince1970]));
    XCTAssertEqual(nowTime, ([[controller showMessagesAfterLaunch] timeIntervalSince1970]));
    XCTAssertEqual(0, ([[controller showMessagesAfterDelay] timeIntervalSince1970]));

    SwrveInAppCampaign *campaign = [[controller campaigns] firstObject];
    XCTAssertNotNil(campaign);

    XCTAssertEqual([campaign ID], 102);
    XCTAssertEqual([campaign maxImpressions], 20);
    XCTAssertEqual(campaign.state.impressions, 0);
    XCTAssertEqual([campaign minDelayBetweenMsgs], 30);

    XCTAssertEqual(nowTime, [[campaign showMsgsAfterLaunch] timeIntervalSince1970]);
    XCTAssertEqual(nowTime ,[[campaign.state showMsgsAfterDelay] timeIntervalSince1970]);

    SwrveMessage *message = campaign.message;
    XCTAssertNotNil(message);

    XCTAssertEqualObjects([message campaign], campaign);
    XCTAssertEqual([[message messageID] integerValue], 165);
    XCTAssertEqualObjects([message name], @"Kindle");
    XCTAssertEqual([[message priority] integerValue], 9999);

    XCTAssertNotNil([message formats]);
    XCTAssertEqual([[message formats] count],1);
    SwrveMessageFormat* format = [[message formats] firstObject];
    XCTAssertNotNil(format);

    XCTAssertEqualObjects([format name], @"Kindle (English (US))");
    XCTAssertEqualObjects([format language], @"en-US");
    XCTAssertEqual([format scale], 1.0);
    XCTAssertEqual([format size].height, 240.0);
    XCTAssertEqual([format size].width, 320.0);

    XCTAssertNotNil([format pages]);
    XCTAssertEqual([format.pagesOrdered[0] intValue], 0);
    SwrveMessagePage *page = [[format pages] objectForKey:[NSNumber numberWithInt:0]];
    XCTAssertNotNil([page buttons]);
    XCTAssertEqual([[page buttons] count], 5);

    SwrveButton* button1 = [[page buttons] firstObject];
    XCTAssertNotNil(button1);
    XCTAssertEqualObjects([button1 image],@"8721fd4e657980a5e12d498e73aed6e6a565dfca");
    XCTAssertEqual([button1 messageId], [message.messageID integerValue]);
    XCTAssertEqual([button1 center].x, -200);
    XCTAssertEqual([button1 center].y, 80);
    XCTAssertEqual((int)[button1 messageId], 165);
    XCTAssertEqual((int)[button1 appID], 150);
    XCTAssertEqual([button1 actionType], kSwrveActionInstall);
    
    NSArray *expectedEvents = @[
    @{
        @"name": @"Test Event 1",
        @"payload": @[
            @{
                @"key": @"key1",
                @"value": @"some value personalized:${test_1}"
            },
            @{
                @"key": @"key2",
                @"value": @"some value personalized:${test_2}"
            }
        ]

    },
    @{
        @"name": @"Test Event 2",
        @"payload": @[
        @{
            @"key": @"key1",
            @"value": @"some value personalized:${test_1}"
        }]
    }
    ];
    
    XCTAssertEqualObjects(expectedEvents, [button1 events]);
    
    NSArray *expectedUserUpdates = @[
        @{
          @"key": @"key1",
          @"value": @"some value personalized:${test_1}"
                
        }
    ];
    
    XCTAssertEqualObjects(expectedUserUpdates, [button1 userUpdates]);

    SwrveButton* button2 = [[page buttons] objectAtIndex:1];
    XCTAssertNotNil(button2);
    XCTAssertEqualObjects([button2 image], @"8721fd4e657980a5e12d498e73aed6e6a565dfca");
    XCTAssertEqualObjects([button2 actionString], @"https://google.com");
    XCTAssertEqual([button2 messageId], [message.messageID integerValue]);
    XCTAssertEqual([button2 center].x, 0);
    XCTAssertEqual([button2 center].y, 80);
    XCTAssertEqual((int)[button2 messageId], 165);
    XCTAssertEqual((int)[button2 appID], 0);
    XCTAssertEqual([button2 actionType], kSwrveActionCustom);

    SwrveButton* button3 = [[page buttons] objectAtIndex:2];
    XCTAssertNotNil(button3);
    XCTAssertEqualObjects([button3 image], @"97c5df26c8e8fcff8dbda7e662d4272a6a94af7e");
    XCTAssertEqualObjects([button3 actionString], @"");
    XCTAssertEqual([button3 messageId], [message.messageID integerValue]);
    XCTAssertEqual([button3 center].x,932);
    XCTAssertEqual([button3 center].y, 32);
    XCTAssertEqual((int)[button3 messageId], 165);
    XCTAssertEqual((int)[button3 appID], 0);
    XCTAssertEqual([button3 actionType], kSwrveActionDismiss);
    
    SwrveButton* button4 = [[page buttons] objectAtIndex:3];
    XCTAssertNotNil(button4);
    XCTAssertEqualObjects([button4 image], @"97c5df26c8e8fcff8dbda7e662d4272a6a94af7e");
    XCTAssertEqualObjects([button4 actionString], @"${test_cp_action|fallback=\"test\"}");
    XCTAssertEqual([button4 messageId], [message.messageID integerValue]);
    XCTAssertEqual([button4 center].x,999);
    XCTAssertEqual([button4 center].y, 23);
    XCTAssertEqual((int)[button4 messageId], 165);
    XCTAssertEqual((int)[button4 appID], 0);
    XCTAssertEqual([button4 actionType], kSwrveActionClipboard);
    
    SwrveButton* button5 = [[page buttons] lastObject];
    XCTAssertNotNil(button5);
    XCTAssertEqualObjects([button5 image], @"8721fd4e657980a5e12d498e73aed6e6a565dfca");
    XCTAssertEqualObjects([button5 actionString], @"swrve.contacts");
    XCTAssertEqual([button5 messageId], [message.messageID integerValue]);
    XCTAssertEqual([button1 center].x, -200);
    XCTAssertEqual([button1 center].y, 80);
    XCTAssertEqual((int)[button1 messageId], 165);
    XCTAssertEqual((int)[button1 appID], 150);
    XCTAssertEqual([button5 actionType], kSwrveActionCapability);

    XCTAssertNotNil([page images]);
    XCTAssertEqual([[page images] count], 1);

    SwrveImage* image = [[page images] firstObject];
    XCTAssertNotNil(image);
    XCTAssertEqualObjects([image file], @"8f984a803374d7c03c97dd122bce3ccf565bbdb5");
    XCTAssertEqual([image center].x, 0);
    XCTAssertEqual([image center].y, 0);
}

- (void)testJsonParserWithPages {
    [SwrveLocalStorage saveSwrveUserId:@"someUserID"];
    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];
    [config setContentServer:@"someContentServer"];
    [config setOrientation:SWRVE_ORIENTATION_BOTH];
    id swrveMock = [self swrveMockWithTestJson:@"campaigns" withConfig:config];
    SwrveMessageController *controller = [swrveMock messaging];

    XCTAssertNotNil(controller);

    // Ensure calling updateCampaigns with nil doesn't change the current campaigns
    NSArray *currentCampaigns = [controller campaigns];
    [[swrveMock messaging] updateCampaigns:nil withLoadingPreviousCampaignState:NO];
    if ([controller campaigns] != nil) {
        XCTAssertEqualObjects([controller campaigns], currentCampaigns);
    }

    NSData *emptyJson = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:emptyJson options:0 error:nil];
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO];

    XCTAssertEqual([[controller campaigns] count], 0);

    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"multipage_campaign_swipe" ofType:@"json"];
    NSData *mockJsonData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    jsonDict = [NSJSONSerialization JSONObjectWithData:mockJsonData options:0 error:nil];

    [controller updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO];
    XCTAssertEqual([[controller campaigns] count], 1);

    NSTimeInterval nowTime = [[swrveMock getNow] timeIntervalSince1970];

    XCTAssertEqualObjects([controller user], @"someUserID");
    XCTAssertEqualObjects([[[swrveMock messaging] assetsManager] cdnImages], @"http://www.someurl.com/");
    XCTAssertEqualObjects([controller apiKey], @"someAPIKey");
    XCTAssertEqualObjects([controller server], @"someContentServer");
    XCTAssertEqualObjects([[controller assetsManager] cacheFolder], [SwrveTestHelper campaignCacheDirectory]);
    XCTAssertEqualObjects([controller language], [config language]);
    XCTAssertEqual([controller orientation], [config orientation]);
    NSString *campaignsStatePath = [SwrveLocalStorage campaignsStateFilePathForUserId:[controller user]];
    XCTAssertEqualObjects([controller campaignsStateFilePath], campaignsStatePath);
    
    XCTAssertEqual(nowTime, ([[controller initialisedTime] timeIntervalSince1970]));
    XCTAssertEqual(nowTime, ([[controller showMessagesAfterLaunch] timeIntervalSince1970]));
    XCTAssertEqual(0, ([[controller showMessagesAfterDelay] timeIntervalSince1970]));

    SwrveInAppCampaign *campaign = [[controller campaigns] firstObject];
    XCTAssertNotNil(campaign);

    XCTAssertEqual([campaign ID], 102);
    XCTAssertEqual([campaign maxImpressions], 5);
    XCTAssertEqual(campaign.state.impressions, 0);
    XCTAssertEqual([campaign minDelayBetweenMsgs], 0);

    XCTAssertEqual(nowTime, [[campaign showMsgsAfterLaunch] timeIntervalSince1970]);
    XCTAssertEqual(nowTime, [[campaign.state showMsgsAfterDelay] timeIntervalSince1970]);

    SwrveMessage *message = campaign.message;
    XCTAssertNotNil(message);

    XCTAssertEqualObjects([message campaign], campaign);
    XCTAssertEqual([[message messageID] integerValue], 165);
    XCTAssertEqualObjects([message name], @"campaign name");
    XCTAssertEqual([[message priority] integerValue], 9999);

    XCTAssertNotNil([message formats]);
    XCTAssertEqual([[message formats] count], 1);
    SwrveMessageFormat *format = [[message formats] firstObject];
    XCTAssertNotNil(format);

    XCTAssertEqualObjects([format name], @"my multipage campaign");
    XCTAssertEqualObjects([format language], @"en-US");
    XCTAssertEqual([format scale], 1.0);
    XCTAssertEqual([format size].height, 240.0);
    XCTAssertEqual([format size].width, 320.0);

    XCTAssertNotNil([format pages]);
    XCTAssertEqual([format.pagesOrdered[0] intValue], 123);
    SwrveMessagePage *page123 = [[format pages] objectForKey:[NSNumber numberWithInt:123]];
    XCTAssertNotNil([page123 buttons]);
    XCTAssertEqual([[page123 buttons] count], 2);

    SwrveButton *button123_1 = [[page123 buttons] firstObject];
    XCTAssertNotNil(button123_1);
    XCTAssertEqualObjects([button123_1 image], @"asset2");
    XCTAssertEqualObjects([button123_1 actionString], @"456");
    XCTAssertEqual([button123_1 messageId], [message.messageID integerValue]);
    XCTAssertEqual([button123_1 center].x, -200);
    XCTAssertEqual([button123_1 center].y, 80);
    XCTAssertEqual((int) [button123_1 messageId], 165);
    XCTAssertEqual((int) [button123_1 appID], 2);
    XCTAssertEqual([button123_1 actionType], kSwrveActionPageLink);
    
    NSArray *expectedEvents = @[
    @{
        @"name": @"Test Event 1",
        @"payload": @[
            @{
                @"key": @"key1",
                @"value": @"some value personalized:${test_1}"
            },
            @{
                @"key": @"key2",
                @"value": @"some value personalized:${test_2}"
            }
        ]

    },
    @{
        @"name": @"Test Event 2",
        @"payload": @[
        @{
            @"key": @"key1",
            @"value": @"some value personalized: ${test_1}"
        }]
    }
    ];
    
    XCTAssertEqualObjects(expectedEvents, [button123_1 events]);
    
    NSArray *expectedUserUpdates = @[
        @{
          @"key": @"key1",
          @"value": @"some value personalized:${test_1}"
                
        }
    ];
    
    XCTAssertEqualObjects(expectedUserUpdates, [button123_1 userUpdates]);

    SwrveButton *button123_2 = [[page123 buttons] objectAtIndex:1];
    XCTAssertNotNil(button123_2);
    XCTAssertEqualObjects([button123_2 image], @"asset5");
    XCTAssertEqualObjects([button123_2 actionString], @"");
    XCTAssertEqual([button123_2 messageId], [message.messageID integerValue]);
    XCTAssertEqual([button123_2 center].x, 932);
    XCTAssertEqual([button123_2 center].y, 32);
    XCTAssertEqual((int) [button123_2 messageId], 165);
    XCTAssertEqual((int) [button123_2 appID], 0);
    XCTAssertEqual([button123_2 actionType], kSwrveActionDismiss);

    XCTAssertNotNil([page123 images]);
    XCTAssertEqual([[page123 images] count], 1);

    SwrveImage *image123 = [[page123 images] firstObject];
    XCTAssertNotNil(image123);
    XCTAssertEqualObjects([image123 file], @"asset1");
    XCTAssertEqual([image123 center].x, 0);
    XCTAssertEqual([image123 center].y, 0);

    SwrveMessagePage *page456 = [[format pages] objectForKey:[NSNumber numberWithInt:456]];
    XCTAssertNotNil([page456 buttons]);
    XCTAssertEqual([[page456 buttons] count], 2);

    SwrveButton *button456_1 = [[page456 buttons] firstObject];
    XCTAssertNotNil(button456_1);
    XCTAssertEqualObjects([button456_1 image], @"asset4");
    XCTAssertEqualObjects([button456_1 actionString], @"123");
    XCTAssertEqual([button456_1 messageId], [message.messageID integerValue]);
    XCTAssertEqual([button456_1 center].x, -200);
    XCTAssertEqual([button456_1 center].y, 80);
    XCTAssertEqual((int) [button456_1 messageId], 165);
    XCTAssertEqual((int) [button456_1 appID], 2);
    XCTAssertEqual([button456_1 actionType], kSwrveActionPageLink);

    SwrveButton *button456_2 = [[page456 buttons] objectAtIndex:1];
    XCTAssertNotNil(button456_2);
    XCTAssertEqualObjects([button456_2 image], @"asset5");
    XCTAssertEqualObjects([button456_2 actionString], @"");
    XCTAssertEqual([button456_2 messageId], [message.messageID integerValue]);
    XCTAssertEqual([button456_2 center].x, 932);
    XCTAssertEqual([button456_2 center].y, 32);
    XCTAssertEqual((int) [button456_2 messageId], 165);
    XCTAssertEqual((int) [button456_2 appID], 0);
    XCTAssertEqual([button456_2 actionType], kSwrveActionDismiss);

    XCTAssertNotNil([page456 images]);
    XCTAssertEqual([[page456 images] count], 1);

    SwrveImage *image456 = [[page456 images] firstObject];
    XCTAssertNotNil(image456);
    XCTAssertEqualObjects([image456 file], @"asset3");
    XCTAssertEqual([image456 center].x, 0);
    XCTAssertEqual([image456 center].y, 0);
}

- (void)testPagingViaButtons {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    
    SwrveInAppMessageConfig *inAppMessageConfig = OCMPartialMock([SwrveInAppMessageConfig new]);

    id mockMessageDelegate = OCMProtocolMock(@protocol(SwrveInAppMessageDelegate));
    OCMStub([inAppMessageConfig inAppMessageDelegate]).andReturn(mockMessageDelegate);
    config.inAppMessageConfig = inAppMessageConfig;
    
    __block BOOL dismissed = NO;
    [OCMExpect([mockMessageDelegate onAction:SwrveMessageActionDismiss messageDetails:OCMOCK_ANY selectedButton:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
        dismissed = YES;
        __unsafe_unretained SwrveMessageButtonDetails *button;
        [invocation getArgument:&button atIndex:4];
        XCTAssertEqual(button.actionType, kSwrveActionDismiss);
        XCTAssertEqualObjects(button.actionString, @"");
    }];
    
    NSArray *assets = @[@"6c871366c876fdb495d96eff3d2905f9d4594c62"];
    [SwrveTestHelper createDummyAssets:assets];
    id swrveMock = [self swrveMockWithTestJson:@"campaigns_multipage" withConfig:config];
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 1);

    SwrveMessageController *controller = [swrveMock messaging];
    SwrveCampaign *campaign = [[swrveMock messageCenterCampaigns] objectAtIndex:0];
    [controller showMessageCenterCampaign:campaign withPersonalization:@{@"test_1":@"some personalized value1", @"test_2":@"some personalized value2"}];
  
    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    [messageViewController viewDidAppear:NO];
    [self loadMessagePageViewController:messageViewController];

    XCTAssertEqual([[messageViewController currentPageId] integerValue], 1);
    SwrveMessageUIView *messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    
    id dic1 = [OCMArg checkWithBlock:^BOOL(NSDictionary *dic)  {
        XCTAssertEqualObjects([dic objectForKey:@"name"], @"Test Event PageLink");
        NSDictionary *payload = [dic objectForKey:@"payload"];
        XCTAssertEqualObjects([payload objectForKey:@"key1"], @"some value personalized:some personalized value1");
        XCTAssertEqualObjects([payload objectForKey:@"key2"], @"some value personalized:some personalized value2");
        return true;
    }];
    OCMExpect([swrveMock queueEvent:@"event" data:dic1 triggerCallback:true]);
    [self pressSwrveUIButton:messageUiView name:@"Next"];
    [self loadMessagePageViewController:messageViewController];
    OCMVerifyAll(swrveMock);

    XCTAssertEqual([[messageViewController currentPageId] integerValue], 2);
    messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    [self pressSwrveUIButton:messageUiView name:@"Next"];
    [self loadMessagePageViewController:messageViewController];

    XCTAssertEqual([[messageViewController currentPageId] integerValue], 3);
    messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    [self pressSwrveUIButton:messageUiView name:@"Next"];
    [self loadMessagePageViewController:messageViewController];

    XCTAssertEqual([[messageViewController currentPageId] integerValue], 4);
    messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    [self pressSwrveUIButton:messageUiView name:@"Next"];
    [self loadMessagePageViewController:messageViewController];

    XCTAssertEqual([[messageViewController currentPageId] integerValue], 5);
    messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    [self pressSwrveUIButton:messageUiView name:@"Previous"];
    [self loadMessagePageViewController:messageViewController];

    XCTAssertEqual([[messageViewController currentPageId] integerValue], 4);
    messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    [self pressSwrveUIButton:messageUiView name:@"Page2"];
    [self loadMessagePageViewController:messageViewController];

    XCTAssertEqual([[messageViewController currentPageId] integerValue], 2);
    messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    [self pressSwrveUIButton:messageUiView name:@"Previous"];
    [self loadMessagePageViewController:messageViewController];

    XCTAssertEqual([[messageViewController currentPageId] integerValue], 1);
    messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    [self pressSwrveUIButton:messageUiView name:@"Page5"];
    [self loadMessagePageViewController:messageViewController];

    XCTAssertEqual([[messageViewController currentPageId] integerValue], 5);
    XCTAssertFalse(dismissed);
    messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    [self verifyDataCapturedFromButtonClick:swrveMock];
    [self pressSwrveUIButton:messageUiView name:@"Dismiss"];
    [self loadMessagePageViewController:messageViewController];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Dismiss button should be called"];
    [SwrveTestHelper waitForBlock:0.05 conditionBlock:^BOOL() {
        return dismissed;
    }                 expectation:expectation];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    XCTAssertTrue(dismissed);
    OCMVerifyAll(swrveMock);
}

- (void)testMultiPageEventsOnlyOnceWithNavigationViaButtons {
    NSArray *assets = @[@"6c871366c876fdb495d96eff3d2905f9d4594c62"];
    [SwrveTestHelper createDummyAssets:assets];
    id swrveMock = [self swrveMockWithTestJson:@"campaigns_multipage"];
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 1);

    NSMutableDictionary *eventDataPage1 = [self pageViewEventData:1 pageName:@"page 1"];
    OCMExpect([swrveMock queueEvent:@"generic_campaign_event" data:eventDataPage1 triggerCallback:false]);
    SwrveMessageController *controller = [swrveMock messaging];
    SwrveCampaign *campaign = [[swrveMock messageCenterCampaigns] objectAtIndex:0];
    [controller showMessageCenterCampaign:campaign];
    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    [messageViewController viewDidAppear:NO];
    [self loadMessagePageViewController:messageViewController];
    XCTAssertEqual([[messageViewController currentPageId] integerValue], 1);
    OCMVerifyAll(swrveMock);

    NSMutableDictionary *eventDataPage2 = [self pageViewEventData:2 pageName:@"page 2"];
    OCMExpect([swrveMock queueEvent:@"generic_campaign_event" data:eventDataPage2 triggerCallback:false]);
    NSMutableDictionary *eventDataNextNavPage1 = [self pageNavEventData:1 pageName:@"page 1" toPageId:2 buttonId:101 buttonName:@"Button next page 1"];
    OCMExpect([swrveMock queueEvent:@"generic_campaign_event" data:eventDataNextNavPage1 triggerCallback:false]);
    SwrveMessageUIView *messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    XCTAssertTrue([self pressSwrveUIButton:messageUiView name:@"Next"]);
    [self loadMessagePageViewController:messageViewController];
    XCTAssertEqual([[messageViewController currentPageId] integerValue], 2);
    OCMVerifyAll(swrveMock);

    NSMutableDictionary *eventDataPage3 = [self pageViewEventData:3 pageName:@"page 3"];
    OCMExpect([swrveMock queueEvent:@"generic_campaign_event" data:eventDataPage3 triggerCallback:false]);
    NSMutableDictionary *eventDataNextNavPage2 = [self pageNavEventData:2 pageName:@"page 2" toPageId:3 buttonId:201 buttonName:@"Button 3 - page 2 next"];
    OCMExpect([swrveMock queueEvent:@"generic_campaign_event" data:eventDataNextNavPage2 triggerCallback:false]);
    messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    XCTAssertTrue([self pressSwrveUIButton:messageUiView name:@"Next"]);
    [self loadMessagePageViewController:messageViewController];
    XCTAssertEqual([[messageViewController currentPageId] integerValue], 3);
    OCMVerifyAll(swrveMock);
    // pressing the previous button (to go back to page 2) should not send another eventDataPage2 event, so use OCMReject
    OCMReject([swrveMock queueEvent:@"generic_campaign_event" data:eventDataPage2 triggerCallback:false]);
    NSMutableDictionary *eventDataPreviousNavPage3 = [self pageNavEventData:3 pageName:@"page 3" toPageId:2 buttonId:300 buttonName:@"Button 4 page 3 previous"];
    OCMExpect([swrveMock queueEvent:@"generic_campaign_event" data:eventDataPreviousNavPage3 triggerCallback:false]);
    messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    XCTAssertTrue([self pressSwrveUIButton:messageUiView name:@"Previous"]);
    [self loadMessagePageViewController:messageViewController];
    XCTAssertEqual([[messageViewController currentPageId] integerValue], 2);
    OCMVerifyAll(swrveMock);

    // pressing the next button AGAIN (to go back to page 3) should not send another eventDataPage3/eventDataNextNavPage2 event, so use OCMReject
    OCMReject([swrveMock queueEvent:@"generic_campaign_event" data:eventDataPage3 triggerCallback:false]);
    OCMReject([swrveMock queueEvent:@"generic_campaign_event" data:eventDataNextNavPage2 triggerCallback:false]);
    messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    XCTAssertTrue([self pressSwrveUIButton:messageUiView name:@"Next"]);
    [self loadMessagePageViewController:messageViewController];
    XCTAssertEqual([[messageViewController currentPageId] integerValue], 3);
    OCMVerifyAll(swrveMock);
}

- (NSMutableDictionary *)pageViewEventData:(long)pageId pageName:(NSString *)pageName {
    NSMutableDictionary *eventData = [NSMutableDictionary new];
    [eventData setValue:@"iam" forKey:@"campaignType"];
    [eventData setValue:@"page_view" forKey:@"actionType"];
    [eventData setValue:[NSNumber numberWithLong:89355] forKey:@"id"];
    [eventData setValue:[NSNumber numberWithLong:pageId] forKey:@"contextId"];
    NSMutableDictionary *eventPayload = [NSMutableDictionary new];
    [eventPayload setValue:pageName forKey:@"pageName"];
#if TARGET_OS_TV
    [eventPayload setValue:@"tv" forKey:@"deviceType"];
    [eventPayload setValue:@"tvos" forKey:@"platform"];
#else
    [eventPayload setValue:@"mobile" forKey:@"deviceType"];
    [eventPayload setValue:@"ios" forKey:@"platform"];
#endif
    [eventData setValue:eventPayload forKey:@"payload"];
    return eventData;
}

- (NSMutableDictionary*)pageNavEventData:(long)pageId pageName:(NSString *)pageName toPageId:(long)toPageId buttonId:(long)buttonId buttonName:(NSString *)buttonName {
    NSMutableDictionary *eventData = [NSMutableDictionary new];
    [eventData setValue:@"iam" forKey:@"campaignType"];
    [eventData setValue:@"navigation" forKey:@"actionType"];
    [eventData setValue:[NSNumber numberWithLong:89355] forKey:@"id"];
    [eventData setValue:[NSNumber numberWithLong:pageId] forKey:@"contextId"];
    NSMutableDictionary *eventPayload = [NSMutableDictionary new];
    [eventPayload setValue:pageName forKey:@"pageName"];
    [eventPayload setValue:[NSNumber numberWithLong:toPageId] forKey:@"to"];
    [eventPayload setValue:[NSNumber numberWithLong:buttonId] forKey:@"buttonId"];
    [eventPayload setValue:buttonName forKey:@"buttonName"];
#if TARGET_OS_TV
    [eventPayload setValue:@"tv" forKey:@"deviceType"];
    [eventPayload setValue:@"tvos" forKey:@"platform"];
#else
    [eventPayload setValue:@"mobile" forKey:@"deviceType"];
    [eventPayload setValue:@"ios" forKey:@"platform"];
#endif
    [eventData setValue:eventPayload forKey:@"payload"];
    return eventData;
}

#if TARGET_OS_IOS /** exclude tvOS **/
// test behaviour (on iOS) with rotation. Tv does not rotate.
- (void)testPagingAndRotationWithNavViaButtons {
    NSArray *assets = @[@"6c871366c876fdb495d96eff3d2905f9d4594c62"];
    [SwrveTestHelper createDummyAssets:assets];
    id swrveMock = [self swrveMockWithTestJson:@"campaigns_multipage_orientations"];
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 1);

    SwrveMessageController *controller = [swrveMock messaging];
    SwrveCampaign *campaign = [[swrveMock messageCenterCampaigns] objectAtIndex:0];
    [controller showMessageCenterCampaign:campaign];
    SwrveMessageViewController *viewController = [self messageViewControllerFrom:controller];
    [viewController viewDidAppear:NO];

    XCTAssertEqual([[viewController currentPageId] integerValue], 1);
    SwrveMessageUIView *messageUiView = [self swrveMessageUIViewFromController:viewController];
    [self pressSwrveUIButton:messageUiView name:@"Next"];

    XCTAssertEqual([[viewController currentPageId] integerValue], 2);
    NSString *formatName = [[viewController currentMessageFormat] name];
    XCTAssertEqualObjects(formatName, @"FormatName-Portrait");
    XCTAssertEqualObjects([controller apiKey], @"someAPIKey");

    // Simulate rotating the device by calling viewWillTransitionToSize
    CGSize sizeOriginal = [viewController windowSize];
    CGSize sizeNew = CGSizeMake(sizeOriginal.height, sizeOriginal.width); // swap the width/height around to make a new CGSize
    [viewController viewWillTransitionToSize:sizeNew withTransitionCoordinator:nil];

    XCTAssertEqual([[viewController currentPageId] integerValue], 2); // same page
    formatName = [[viewController currentMessageFormat] name];
    XCTAssertEqualObjects(formatName, @"FormatName-Landscape"); // different format name
}
#endif /**TARGET_OS_IOS **/


// swipe supported on iOS only. Not supported on tvOS.
#if TARGET_OS_IOS

- (void)testPagingViaSwipeForward {
    NSArray *assets = @[@"6c871366c876fdb495d96eff3d2905f9d4594c62"];
    [SwrveTestHelper createDummyAssets:assets];
    id swrveMock = [self swrveMockWithTestJson:@"campaigns_multipage"];
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 1);

    SwrveMessageController *controller = [swrveMock messaging];
    SwrveCampaign *campaign = [[swrveMock messageCenterCampaigns] objectAtIndex:0];
    [controller showMessageCenterCampaign:campaign];
    SwrveMessageViewController *viewController = [self messageViewControllerFrom:controller];
    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    [viewController viewDidAppear:NO];

    SwrveMessagePageViewController *pageViewController = [self loadMessagePageViewController:viewController];
    XCTAssertEqual([[viewController currentPageId] integerValue], 1);
    XCTAssertEqual([[pageViewController pageId] integerValue], 1);

    // simulate swiping forward
    pageViewController = [viewController pageViewController:viewController viewControllerAfterViewController:pageViewController];
    [pageViewController viewDidAppear:NO];
    XCTAssertEqual([[viewController currentPageId] integerValue], 2);
    XCTAssertEqual([[pageViewController pageId] integerValue], 2);

    pageViewController = [viewController pageViewController:viewController viewControllerAfterViewController:pageViewController];
    [pageViewController viewDidAppear:NO];
    XCTAssertEqual([[viewController currentPageId] integerValue], 3);
    XCTAssertEqual([[pageViewController pageId] integerValue], 3);

    pageViewController = [viewController pageViewController:viewController viewControllerAfterViewController:pageViewController];
    [pageViewController viewDidAppear:NO];
    XCTAssertEqual([[viewController currentPageId] integerValue], 4);
    XCTAssertEqual([[pageViewController pageId] integerValue], 4);

    pageViewController = [viewController pageViewController:viewController viewControllerAfterViewController:pageViewController];
    [pageViewController viewDidAppear:NO];
    XCTAssertEqual([[viewController currentPageId] integerValue], 5);
    XCTAssertEqual([[pageViewController pageId] integerValue], 5);

    pageViewController = [viewController pageViewController:viewController viewControllerAfterViewController:pageViewController];
    [pageViewController viewDidAppear:NO];
    XCTAssertEqual([[viewController currentPageId] integerValue], 5); // page remains at 5 because there's no more
    XCTAssertNil(pageViewController);
}

- (void)testPagingViaSwipeBackward {
    NSArray *assets = @[@"6c871366c876fdb495d96eff3d2905f9d4594c62"];
    [SwrveTestHelper createDummyAssets:assets];
    id swrveMock = [self swrveMockWithTestJson:@"campaigns_multipage"];
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 1);

    SwrveMessageController *controller = [swrveMock messaging];
    SwrveCampaign *campaign = [[swrveMock messageCenterCampaigns] objectAtIndex:0];
    [controller showMessageCenterCampaign:campaign];
    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    [messageViewController viewDidAppear:NO];
    SwrveMessagePageViewController *pageViewController = [self loadMessagePageViewController:messageViewController];

    XCTAssertEqual([[messageViewController currentPageId] integerValue], 1);

    // jump to page 5 and simulate swiping backwards
    [messageViewController showPage:[NSNumber numberWithInt:5]];

    pageViewController = [self loadMessagePageViewController:messageViewController];
    XCTAssertEqual([[messageViewController currentPageId] integerValue], 5);
    XCTAssertEqual([[pageViewController pageId] integerValue], 5);

    pageViewController = [messageViewController pageViewController:messageViewController viewControllerBeforeViewController:pageViewController];
    [pageViewController viewDidAppear:NO];
    XCTAssertEqual([[messageViewController currentPageId] integerValue], 4);
    XCTAssertEqual([[pageViewController pageId] integerValue], 4);

    pageViewController = [messageViewController pageViewController:messageViewController viewControllerBeforeViewController:pageViewController];
    [pageViewController viewDidAppear:NO];
    XCTAssertEqual([[messageViewController currentPageId] integerValue], 3);
    XCTAssertEqual([[pageViewController pageId] integerValue], 3);

    pageViewController = [messageViewController pageViewController:messageViewController viewControllerBeforeViewController:pageViewController];
    [pageViewController viewDidAppear:NO];
    XCTAssertEqual([[messageViewController currentPageId] integerValue], 2);
    XCTAssertEqual([[pageViewController pageId] integerValue], 2);

    pageViewController = [messageViewController pageViewController:messageViewController viewControllerBeforeViewController:pageViewController];
    [pageViewController viewDidAppear:NO];
    XCTAssertEqual([[messageViewController currentPageId] integerValue], 1);
    XCTAssertEqual([[pageViewController pageId] integerValue], 1);

    pageViewController = [messageViewController pageViewController:messageViewController viewControllerBeforeViewController:pageViewController];
    [pageViewController viewDidAppear:NO];
    XCTAssertEqual([[messageViewController currentPageId] integerValue], 1); // page remains at 1 because there's no more
    XCTAssertNil(pageViewController);
}

- (void)testMultiPageEventsOnlyOnceWithNavigationViaSwipe {

    NSArray *assets = @[@"6c871366c876fdb495d96eff3d2905f9d4594c62"];
    [SwrveTestHelper createDummyAssets:assets];
    id swrveMock = [self swrveMockWithTestJson:@"campaigns_multipage"];
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 1);

    NSMutableDictionary *eventDataPage1 = [self pageViewEventData:1 pageName:@"page 1"];
    OCMExpect([swrveMock queueEvent:@"generic_campaign_event" data:eventDataPage1 triggerCallback:false]);
    SwrveMessageController *controller = [swrveMock messaging];
    SwrveCampaign *campaign = [[swrveMock messageCenterCampaigns] objectAtIndex:0];
    [controller showMessageCenterCampaign:campaign];
    [self waitForInterval:1.0];
    OCMVerifyAll(swrveMock);

    SwrveMessageViewController *viewController = [self messageViewControllerFrom:controller];
    XCTAssertEqual([[viewController currentPageId] integerValue], 1);

    // simulate swiping forward

    NSMutableDictionary *eventDataPage2 = [self pageViewEventData:2 pageName:@"page 2"];
    OCMExpect([swrveMock queueEvent:@"generic_campaign_event" data:eventDataPage2 triggerCallback:false]);
    SwrveMessagePageViewController *pageViewController = [self loadMessagePageViewController:viewController];
    pageViewController = [viewController pageViewController:viewController viewControllerAfterViewController:pageViewController];
    [pageViewController viewDidAppear:NO];
    XCTAssertEqual([[viewController currentPageId] integerValue], 2);
    OCMVerifyAll(swrveMock);

    NSMutableDictionary *eventDataPage3 = [self pageViewEventData:3 pageName:@"page 3"];
    OCMExpect([swrveMock queueEvent:@"generic_campaign_event" data:eventDataPage3 triggerCallback:false]);
    pageViewController = [viewController pageViewController:viewController viewControllerAfterViewController:pageViewController];
    [pageViewController viewDidAppear:NO];
    XCTAssertEqual([[viewController currentPageId] integerValue], 3);
    OCMVerifyAll(swrveMock);

    NSMutableDictionary *eventDataPage4 = [self pageViewEventData:4 pageName:@"page 4"];
    OCMExpect([swrveMock queueEvent:@"generic_campaign_event" data:eventDataPage4 triggerCallback:false]);
    pageViewController = [viewController pageViewController:viewController viewControllerAfterViewController:pageViewController];
    [pageViewController viewDidAppear:NO];
    XCTAssertEqual([[viewController currentPageId] integerValue], 4);
    OCMVerifyAll(swrveMock);

    // simulate swiping backward to go back to page 3 but should not send another eventDataPage3 event, so use OCMReject
    OCMReject([swrveMock queueEvent:@"generic_campaign_event" data:eventDataPage3 triggerCallback:false]);
    pageViewController = [viewController pageViewController:viewController viewControllerBeforeViewController:pageViewController];
    [pageViewController viewDidAppear:NO];
    XCTAssertEqual([[viewController currentPageId] integerValue], 3);
    OCMVerifyAll(swrveMock);
}

#endif

- (void)testPagingWithOldCampaigns {
    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    SwrveMessageController *controller = [swrveMock messaging];
    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];
    SwrveMessageViewController *viewController = [self messageViewControllerFrom:controller];
    [viewController viewDidAppear:NO];

    SwrveMessagePageViewController *pageViewController = [self loadMessagePageViewController:viewController];
    XCTAssertEqual([[viewController currentPageId] integerValue], 0);
    XCTAssertEqual([[pageViewController pageId] integerValue], 0);

    // simulate swiping forward
    SwrveMessagePageViewController *pageViewControllerAfter = [viewController pageViewController:viewController viewControllerAfterViewController:pageViewController];
    XCTAssertEqual([[viewController currentPageId] integerValue], 0); // page remains at 0 because there's only one page
    XCTAssertNil(pageViewControllerAfter);

    // simulate swiping backward
    SwrveMessagePageViewController *pageViewControllerBefore = [viewController pageViewController:viewController viewControllerBeforeViewController:pageViewController];
    XCTAssertEqual([[viewController currentPageId] integerValue], 0); // page remains at 0 because there's only one page
    XCTAssertNil(pageViewControllerBefore);
}

- (void)verifyDataCapturedFromButtonClick:(id)swrveMock {
    id dic1 = [OCMArg checkWithBlock:^BOOL(NSDictionary *dic)  {
        XCTAssertEqualObjects([dic objectForKey:@"name"], @"Test Event 1");
        NSDictionary *payload = [dic objectForKey:@"payload"];
        XCTAssertEqualObjects([payload objectForKey:@"key1"], @"some value personalized:some personalized value1");
        XCTAssertEqualObjects([payload objectForKey:@"key2"], @"some value personalized:some personalized value2");
        return true;
    }];
    OCMExpect([swrveMock queueEvent:@"event" data:dic1 triggerCallback:true]);

    id dic2 = [OCMArg checkWithBlock:^BOOL(NSDictionary *dic)  {
        XCTAssertEqualObjects([dic objectForKey:@"name"], @"Test Event 2");
        NSDictionary *payload = [dic objectForKey:@"payload"];
        XCTAssertEqualObjects([payload objectForKey:@"key1"], @"some value personalized:some personalized value1");
        return true;
    }];
    OCMExpect([swrveMock queueEvent:@"event" data:dic2 triggerCallback:true]);

    id dic3 = [OCMArg checkWithBlock:^BOOL(NSDictionary *dic)  {
        XCTAssertEqualObjects([dic objectForKey:@"key1"], @"some value personalized:some personalized value1");
        return true;
    }];
    OCMExpect([swrveMock userUpdate:dic3]);
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
