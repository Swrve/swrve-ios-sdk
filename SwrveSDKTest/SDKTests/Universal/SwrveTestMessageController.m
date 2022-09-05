#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <SwrveMessagePage.h>
#import <SwrveMessageUIView.h>
#import "SwrveInAppCampaign.h"
#import "SwrveConversation.h"
#import "UISwrveButton.h"
#import "SwrveButton.h"
#import "SwrveImage.h"
#import "SwrveQA.h"
#import "SwrveTestHelper.h"
#import "SwrveUtils.h"
#import "SwrveAssetsManager.h"
#import "SwrveMessageController+Private.h"
#import "SwrveMigrationsManager.h"
#import "TestCapabilitiesDelegate.h"
#import "SwrveSDK.h"
#import "SwrveTextView.h"
#import "SwrveMessagePageViewController.h"
#import "SwrveCommon.h"
#import "SwrveMessageFocus.h"

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

@interface Swrve ()
@property(atomic) SwrveMessageController *messaging;
@property (nonatomic) SwrveReceiptProvider *receiptProvider;
- (NSDate *)getNow;
- (void)initSwrveRestClient:(NSTimeInterval)timeOut urlSssionDelegate:(id <NSURLSessionDelegate>)urlSssionDelegate;
- (int)sessionStart;
- (void)suspend:(BOOL)terminating;
- (void)appDidBecomeActive:(NSNotification *)notification;
@property (atomic) SwrveRESTClient *restClient;
@property (atomic) NSMutableArray *eventBuffer;
#if TARGET_OS_IOS
@property(atomic, readonly) SwrvePush *push;
#endif //TARGET_OS_IOS
- (int)queueEvent:(NSString *)eventType data:(NSMutableDictionary *)eventData triggerCallback:(bool)triggerCallback;

@end

#if TARGET_OS_IOS
@interface SwrvePush (SwrvePushInternalAccess)
- (void)registerForPushNotifications:(BOOL)provisional;
@end
#endif //TARGET_OS_IOS

@interface SwrveSDK (InternalAccess)
+ (void)addSharedInstance:(Swrve *)instance;
+ (void)resetSwrveSharedInstance;
@end

@interface SwrveMessageController ()
- (NSMutableDictionary *)capabilities:(SwrveMessage *)swrveMessage withCapabilityDelegate:(id<SwrveInAppCapabilitiesDelegate>)delegate;
- (void)showMessage:(SwrveMessage *)message queue:(bool)isQueued withPersonalization:(NSDictionary *)personalization;
- (void)showMessage:(SwrveMessage *)message withPersonalization:(NSDictionary *)personalization;
- (void)showConversation:(SwrveConversation *)conversation queue:(bool)isQueued;
- (void)dismissMessageWindow;
- (void)updateCampaigns:(NSDictionary *)campaignJson withLoadingPreviousCampaignState:(BOOL) isLoadingPreviousCampaignState;
- (SwrveBaseMessage *)baseMessageForEvent:(NSString *)eventName withPayload:(NSDictionary *)payload;
- (void)showMessage:(SwrveMessage *)message;
- (void)messageWasShownToUser:(SwrveMessage *)message;
- (SwrveConversation*)conversationForEvent:(NSString *) eventName withPayload:(NSDictionary *)payload;
@property (nonatomic, retain) UIWindow *inAppMessageWindow;
@property (nonatomic, retain) NSMutableDictionary *appStoreURLs;
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
@property(nonatomic, retain) NSMutableArray *conversationsMessageQueue;
@property(nonatomic) bool pushEnabled;
@property(nonatomic) SwrveActionType inAppMessageActionType;
@property(nonatomic, retain) NSString *inAppMessageAction;
@end

@interface SwrveReceiptProvider ()
- (NSData *)readMainBundleAppStoreReceipt API_AVAILABLE(ios(8.0));
@end

@interface SwrveMessageViewController ()
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(SwrveMessagePageViewController *)viewController;
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(SwrveMessagePageViewController *)viewController;
- (CGSize)windowSize;
@property(nonatomic, retain) SwrveMessageFocus *messageFocus;
@end

@interface SwrveMessage()
-(BOOL)assetsReady:(NSSet*)assets withPersonalization:(NSDictionary *)personalization;
@end

@interface SwrveMessageUIView()
- (void)addAccessibilityText:(NSString *)accessibilityText backupText:(NSString *)backupText withPersonalization:(NSDictionary *)personalizationDict toView:(UIView *)view;
@end

@interface TestingSwrveMessage : SwrveMessage
@end

@implementation TestingSwrveMessage

#if TARGET_OS_TV==0
- (BOOL)supportsOrientation:(UIInterfaceOrientation)orientation
{
    return YES;
}
#endif

@end

@interface SwrveTestMessageController : XCTestCase

@property NSDate *swrveNowDate;
+ (NSArray*)testJSONAssets;

@end

@implementation SwrveTestMessageController

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
    [SwrveTestHelper createDummyAssets:[SwrveTestMessageController testJSONAssets]];
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

- (void)testMulitpleConversationsAreNotQueued {
    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    SwrveMessageController *controller = [swrveMock messaging];
    
    SwrveMessage *message1 = (SwrveMessage *)[controller baseMessageForEvent:@"test1"];
    [controller showMessage:message1];
    
    SwrveMessage *message2 = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message2];
    
    XCTAssertEqual([[controller conversationsMessageQueue] count], 0);
}

- (void)testMulitpleConversationsQueued {
    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    SwrveMessageController *controller = [swrveMock messaging];
    
    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;
    
    SwrveMessage *message1 = (SwrveMessage *)[controller baseMessageForEvent:@"test1"];
    [controller showMessage:message1];
    
    SwrveMessage *message2 = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message2 queue:true withPersonalization:nil];
    
    SwrveMessage *message3 = (SwrveMessage *)[controller baseMessageForEvent:@"test1"];
    [controller showMessage:message3];
    
    XCTAssertEqual([[controller conversationsMessageQueue] count], 1);
    
    [controller dismissMessageWindow];

    XCTAssertEqual([[controller conversationsMessageQueue] count], 0);
}

- (void)testConversationNotQueuedWhenNothingElseShowing {
    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    SwrveMessageController *controller = [swrveMock messaging];
    
    SwrveMessage *message1 = (SwrveMessage *)[controller baseMessageForEvent:@"test1"];
    [controller showMessage:message1 queue:true withPersonalization:nil];
    
    XCTAssertEqual([[controller conversationsMessageQueue] count], 0);
    
    [controller dismissMessageWindow];
    
    XCTAssertEqual([[controller conversationsMessageQueue] count], 0);
}

- (void)testStoryboardPackaging {
    SwrveConversationItemViewController *controller = [SwrveConversationItemViewController initFromStoryboard];
    XCTAssertNotNil(controller);
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
    XCTAssertEqualObjects([[controller appStoreURLs] objectForKey:@"150"],@"https://itunes.apple.com/us/app/ascension-chronicle-godslayer/id441838733?mt=8");

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
    XCTAssertEqual(0,[[campaign.state showMsgsAfterDelay] timeIntervalSince1970]);

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
    XCTAssertEqual(format.firstPageId, 0);
    SwrveMessagePage *page = [[format pages] objectForKey:[NSNumber numberWithInt:0]];
    XCTAssertNotNil([page buttons]);
    XCTAssertEqual([[page buttons] count], 5);

    SwrveButton* button1 = [[page buttons] firstObject];
    XCTAssertNotNil(button1);
    XCTAssertEqualObjects([button1 image],@"8721fd4e657980a5e12d498e73aed6e6a565dfca");
    XCTAssertEqualObjects([button1 actionString], @"https://itunes.apple.com/us/app/ascension-chronicle-godslayer/id441838733?mt=8");
    XCTAssertEqual([button1 messageId], [message.messageID integerValue]);
    XCTAssertEqual([button1 center].x, -200);
    XCTAssertEqual([button1 center].y, 80);
    XCTAssertEqual((int)[button1 messageId], 165);
    XCTAssertEqual((int)[button1 appID], 150);
    XCTAssertEqual([button1 actionType], kSwrveActionInstall);

    SwrveButton* button2 = [[page buttons] objectAtIndex:1];
    XCTAssertNotNil(button2);
    XCTAssertEqualObjects([button2 image], @"8721fd4e657980a5e12d498e73aed6e6a565dfca");
    XCTAssertEqualObjects([button2 actionString], @"custom_action");
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
    XCTAssertEqualObjects([button4 actionString], @"${test_cp|fallback=\"test\"}");
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
    XCTAssertEqualObjects([[controller appStoreURLs] objectForKey:@"150"], @"https://www.someurl.com");

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
    XCTAssertEqual(0, [[campaign.state showMsgsAfterDelay] timeIntervalSince1970]);

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
    XCTAssertEqual(format.firstPageId, 123);
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

- (void)testShowMessage {
    SwrveConfig *config = [SwrveConfig new];
    id swrveMock = [self swrveMockWithTestJson:@"campaigns" withConfig:config];
    SwrveMessageController *controller = [swrveMock messaging];
    id controllerMock = OCMPartialMock(controller);
    [swrveMock setMessaging:controllerMock];

    NSDictionary* event = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"purchase", @"type",
                           @"item", @"toy",
                           nil];

    TestingSwrveMessage *mockMessage = [[TestingSwrveMessage alloc] init];
    mockMessage.name = @"TestMessageName";
    OCMStub([controllerMock baseMessageForEvent:@"Swrve.user_purchase" withPayload:OCMOCK_ANY]).andReturn(mockMessage);

    OCMExpect([controllerMock showMessage:mockMessage withPersonalization:[NSDictionary new]]);
    [controller eventRaised:event];

    OCMVerifyAll(controllerMock);
}

- (void)testShowMessageNoCustomFindMessage {
    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    SwrveMessageController *controller = [swrveMock messaging];
    id controllerMock = OCMPartialMock(controller);
    [swrveMock setMessaging:controllerMock];

    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;

    NSDictionary* event = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"currency_given", @"type",
                           @"Gold", @"given_currency",
                           @20, @"given_amount",
                           nil];

    __block SwrveMessage *swrveMessageTriggered = nil;
    id arg = [OCMArg checkWithBlock:^BOOL(SwrveMessage *swrveMessage){
        swrveMessageTriggered = swrveMessage;
        return swrveMessage;
    }];
    OCMStub([controllerMock showMessage:arg withPersonalization:[NSDictionary new]]);
    [controllerMock eventRaised:event];

    XCTAssertNotNil(swrveMessageTriggered);
    XCTAssertEqualObjects(swrveMessageTriggered.name, @"Kindle");

    OCMVerifyAll(controllerMock);
}

- (void)testShowMessagePersonalizationOnly {
    id swrveMock = [self swrveMockWithTestJson:@"campaignsPersonalization"];
    SwrveMessageController *controller = [swrveMock messaging];

    // mock date that lies within the start and end time of the campaign in the test json file campaignsMessageCenter
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);

    NSDictionary *validPersonalization = @{@"test_cp": @"test_value",
            @"test_custom":@"urlprocessed",
            @"test_display": @"display"};
    SwrveCampaign *campaign = [[controller messageCenterCampaignsWithPersonalization:validPersonalization] objectAtIndex:0];
    [controller showMessageCenterCampaign:campaign withPersonalization: validPersonalization];
    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    XCTAssertNotNil(messageViewController);
    XCTAssertNotNil(messageViewController.message);
    XCTAssertEqualObjects(messageViewController.message.name, @"Kindle");
}

- (void)testShowMessagePersonalizationFallback {
    id swrveMock = [self swrveMockWithTestJson:@"campaignsPersonalization"];
    SwrveMessageController *controller = [swrveMock messaging];

    // mock date that lies within the start and end time of the campaign in the test json file campaignsMessageCenter
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);

    NSDictionary *validPersonalization = @{@"test_cp": @"test_value",
            @"test_custom":@"urlprocessed",
            @"test_display": @"display"};
    SwrveCampaign *campaign = [[controller messageCenterCampaignsWithPersonalization:validPersonalization] objectAtIndex:0];
    [controller showMessageCenterCampaign:campaign withPersonalization:validPersonalization];

    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    XCTAssertNotNil(messageViewController);
    XCTAssertNotNil(messageViewController.message);
    XCTAssertEqualObjects(messageViewController.message.name, @"Kindle");
}

- (void)testShowMessagePersonalizationFromTrigger {

    id swrveMock = [self swrveMockWithTestJson:@"campaignsPersonalization"];
    SwrveMessageController *controller = [swrveMock messaging];
    SwrveMessagePersonalizationCallback personalizationCallback = ^(NSDictionary *eventPayload) {
        return @{@"test_cp": @"test_value", @"test_custom": @"urlprocessed", @"test_display": @"display"};
    };
    [controller setPersonalizationCallback:personalizationCallback];

    NSDictionary *event = @{@"type": @"event",
            @"seqnum": @1111,
            @"name": @"trigger_name",
            @"payload": @{}
    };
    [controller eventRaised:event];

    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    XCTAssertNotNil(messageViewController);
    XCTAssertNotNil(messageViewController.message);
    XCTAssertEqualObjects(messageViewController.message.name, @"Kindle");
}

- (void)testShowMessageImagePersonalizationFromTrigger {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    SwrveInAppMessageConfig *inAppConfig = [SwrveInAppMessageConfig new];
    SwrveMessagePersonalizationCallback personalizationCallback = ^(NSDictionary* eventPayload) {
        return @{@"test_key_with_fallback": @"asset1", @"test_key_no_fallback":@"asset2"};
    };
    [inAppConfig setPersonalizationCallback:personalizationCallback];
    config.inAppMessageConfig = inAppConfig;

    [SwrveTestHelper removeAllAssets];

    NSString *asset1 = [SwrveUtils sha1:[@"https://fakeitem/asset1.png" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    NSString *asset2 = [SwrveUtils sha1:[@"https://fakeitem/asset2.gif" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    NSString *asset3 = [SwrveUtils sha1:[@"https://fakeitem/asset3.jpg" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];

    [SwrveTestHelper createDummyAssets:@[asset1, asset2, asset3, @"1111111111111111111111111"]];

    id swrveMock = [self swrveMockWithTestJson:@"campaignsImagePersonalizationTriggered" withConfig:config];
    SwrveMessageController *controller = [swrveMock messaging];

    NSDictionary* event =  @{@"type": @"event",
                             @"seqnum": @1111,
                             @"name": @"trigger_name",
                             @"payload": @{}};
    [controller eventRaised:event];

    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    XCTAssertNotNil(messageViewController);
    XCTAssertNotNil(messageViewController.message);
    XCTAssertEqualObjects(messageViewController.message.name, @"Kindle");
}

- (void)testShowMessageImagePersonalizationFromTriggerMissingPersonalization {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    SwrveInAppMessageConfig *inAppConfig = [SwrveInAppMessageConfig new];
    SwrveMessagePersonalizationCallback personalizationCallback = ^(NSDictionary* eventPayload) {
        //deliberately take out 'test_key_no_fallback'
        return @{@"test_key_with_fallback": @"asset1"};
    };
    [inAppConfig setPersonalizationCallback:personalizationCallback];
    config.inAppMessageConfig = inAppConfig;

    [SwrveTestHelper removeAllAssets];

    NSString *asset1 = [SwrveUtils sha1:[@"https://fakeitem/asset1.png" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    NSString *asset2 = [SwrveUtils sha1:[@"https://fakeitem/asset2.gif" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    NSString *asset3 = [SwrveUtils sha1:[@"https://fakeitem/asset3.jpg" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];

    [SwrveTestHelper createDummyAssets:@[asset1, asset2, asset3, @"1111111111111111111111111"]];

    id swrveMock = [self swrveMockWithTestJson:@"campaignsImagePersonalizationTriggered" withConfig:config];
    SwrveMessageController *controller = [swrveMock messaging];

    NSDictionary* event =  @{@"type": @"event",
                             @"seqnum": @1111,
                             @"name": @"trigger_name",
                             @"payload": @{}};
    [controller eventRaised:event];

    XCTAssertNil([controller inAppMessageWindow]);
}

- (void)testShowMessageImagePersonalizationWithRealTimeUserPropertiesFromTrigger {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    SwrveInAppMessageConfig *inAppConfig = [SwrveInAppMessageConfig new];
    SwrveMessagePersonalizationCallback personalizationCallback = ^(NSDictionary* eventPayload) {
        return @{@"test_key_with_fallback": @"asset1", @"test_key_no_fallback":@"asset2"};
    };
    [inAppConfig setPersonalizationCallback:personalizationCallback];
    config.inAppMessageConfig = inAppConfig;

    [SwrveTestHelper removeAllAssets];

    NSString *asset1 = [SwrveUtils sha1:[@"https://fakeitem/asset1.png" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    NSString *asset2 = [SwrveUtils sha1:[@"https://fakeitem/asset2.gif" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    NSString *asset3 = [SwrveUtils sha1:[@"https://fakeitem/rtups_value1.jpg" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];

    [SwrveTestHelper createDummyAssets:@[asset1, asset2, asset3, @"1111111111111111111111111"]];
    
    Swrve *swrveMock = [SwrveTestHelper initializeSwrveWithRealTimeUserPropertiesFile:@"realTimeUserProperties" andConfig:config];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsImagePersonalizationTriggered" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockData options:0 error:nil];
    
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO];
    
    SwrveMessageController *controller = [swrveMock messaging];

    NSDictionary* event =  @{@"type": @"event",
                             @"seqnum": @1111,
                             @"name": @"trigger_name",
                             @"payload": @{}};
    [controller eventRaised:event];

    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    XCTAssertNotNil(messageViewController);
    XCTAssertNotNil(messageViewController.message);
    XCTAssertEqualObjects(messageViewController.message.name, @"Kindle");
}

- (void)testEmbeddedMessageCallback {
    
    __block SwrveEmbeddedMessage *embmessage = nil;
    
    SwrveConfig *config = [SwrveConfig new];
    SwrveEmbeddedMessageConfig *embeddedConfig = [SwrveEmbeddedMessageConfig new];
    [embeddedConfig setEmbeddedMessageCallback:^(SwrveEmbeddedMessage *message) {
        embmessage = message;
    }];
    
    config.embeddedMessageConfig = embeddedConfig;
    
    id swrveMock = [self swrveMockWithTestJson:@"campaignsEmbedded" withConfig:config];
    SwrveMessageController *controller = [swrveMock messaging];
    
    NSDictionary* event =  @{@"type": @"event",
                             @"seqnum": @1111,
                             @"name": @"trigger_embedded",
                             @"payload": @{}};
    
    [controller eventRaised:event];
    
    XCTAssertNotNil(embmessage);
    XCTAssertEqualObjects(embmessage.data, @"test string");
    XCTAssertEqual(embmessage.type, kSwrveEmbeddedDataTypeOther);
    NSArray<NSString *> *buttons = embmessage.buttons;
    
    XCTAssertEqualObjects(buttons[0], @"Button 1");
    XCTAssertEqualObjects(buttons[1], @"Button 2");
    XCTAssertEqualObjects(buttons[2], @"Button 3");
    
    // Raise a different event for a JSON type embedded Campaign
    
    event =  @{@"type": @"event",
                             @"seqnum": @1111,
                             @"name": @"embedded_payload",
               @"payload": @{@"test": @"value"}};
    
    [controller eventRaised:event];
    
    XCTAssertNotNil(embmessage);
    XCTAssertEqualObjects(embmessage.data, @"{\"test\": \"json_payload\"}");
    XCTAssertEqual(embmessage.type, kSwrveEmbeddedDataTypeJson);
    buttons = embmessage.buttons;
    
    XCTAssertEqualObjects(buttons[0], @"Button 1");
    XCTAssertEqualObjects(buttons[1], @"Button 2");
    XCTAssertEqualObjects(buttons[2], @"Button 3");
}

- (void)testEmbeddedPriority {
    id swrveMock = [self swrveMockWithTestJson:@"campaignsEmbedded"];
    SwrveCampaign *campaign = [swrveMock messageCenterCampaignWithID:11111 andPersonalization:nil];
    XCTAssertNotNil(campaign);
    XCTAssertEqual([campaign.priority intValue], 600);
}

- (void)testEmbeddedMessageWithPersonalizationCallback {
    
    __block SwrveEmbeddedMessage *embmessage = nil;
    __block NSDictionary *personalizationProps = nil;
    
    
    SwrveConfig *config = [SwrveConfig new];
    
    SwrveInAppMessageConfig *inAppConfig = [SwrveInAppMessageConfig new];
    inAppConfig.personalizationCallback = ^NSDictionary *(NSDictionary *eventPayload) {
        return @{@"testkey": @"WORKING"};
    };
    
    SwrveEmbeddedMessageConfig *embeddedConfig = [SwrveEmbeddedMessageConfig new];
    [embeddedConfig setEmbeddedMessageCallbackWithPersonalization:^(SwrveEmbeddedMessage *message, NSDictionary *personalizationProperties) {
        embmessage = message;
        personalizationProps = personalizationProperties;
        
    }];
    
    config.embeddedMessageConfig = embeddedConfig;
    config.inAppMessageConfig = inAppConfig;
    
    id swrveMock = [self swrveMockWithTestJson:@"campaignsEmbedded" withConfig:config];
    SwrveMessageController *controller = [swrveMock messaging];
    
    NSDictionary* event =  @{@"type": @"event",
                             @"seqnum": @1111,
                             @"name": @"trigger_embedded_personalization",
                             @"payload": @{}};
    
    [controller eventRaised:event];
    
    XCTAssertNotNil(embmessage);
    XCTAssertEqualObjects(embmessage.data, @"PERSONALIZATION: ${testkey}");
    XCTAssertNotNil(personalizationProps);
    XCTAssertEqualObjects(personalizationProps[@"testkey"], @"WORKING");
    XCTAssertEqual(embmessage.type, kSwrveEmbeddedDataTypeOther);
    NSArray<NSString *> *buttons = embmessage.buttons;
    
    XCTAssertEqualObjects(buttons[0], @"Button 1");
    XCTAssertEqualObjects(buttons[1], @"Button 2");
}

/**
 * Ensure QA trigger function gets called when QA user is set and message is requested
 */
- (void)testSwrveQAUserCalls {
    // Mock SwrveQA
    id swrveQAMock = OCMPartialMock([SwrveQA sharedInstance]);
    OCMStub([swrveQAMock isQALogging]).andReturn(YES);
    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];

    // set the expected expectedQACampaign.
    NSArray<SwrveQACampaignInfo*> *expectedQACampaign = @[
    [[SwrveQACampaignInfo alloc] initWithCampaignID:102 variantID:165 type:SWRVE_CAMPAIGN_IAM displayed:NO reason:@"There is no trigger in 102 that matches InvalidEvent with conditions (null)"],
    [[SwrveQACampaignInfo alloc] initWithCampaignID:101 variantID:165 type:SWRVE_CAMPAIGN_IAM displayed:NO reason:@"There is no trigger in 101 that matches InvalidEvent with conditions (null)"]];

    SwrveMessageController *controller = [swrveMock messaging];
    
    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);

    message = (SwrveMessage *)[controller baseMessageForEvent:@"InvalidEvent"];

    OCMVerify([swrveQAMock messageCampaignTriggered:@"InvalidEvent" eventPayload:nil displayed:NO campaignInfoDict:expectedQACampaign]);

    [swrveQAMock stopMocking];
}

/**
 * Check that correct app store URL is retrieved for install button
 */
- (void)testAppStoreURLForApp {
    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    SwrveMessageController *controller = [swrveMock messaging];
    
    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;

    NSDictionary *appStoreURLs = [controller appStoreURLs];
    XCTAssertEqual([appStoreURLs count], 1);
    XCTAssertNotNil([appStoreURLs objectForKey:@"150"]);
    XCTAssertNil([appStoreURLs objectForKey:@"250"]);

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    
#if TARGET_OS_IOS
     SwrveMessageFormat* format = [message bestFormatForOrientation:UIInterfaceOrientationPortrait];
#else
    SwrveMessageFormat* format = message.formats.firstObject;
#endif

    BOOL correct = NO;
    SwrveMessagePage *page = [[format pages] objectForKey:[NSNumber numberWithInt:0]];
    for (SwrveButton* button in [page buttons]) {
        if ([button actionType] == kSwrveActionInstall && [button appID] == 150) {
            correct = YES;
        }
    }
    XCTAssertTrue(correct);
}

/**
 * Test campaign throttle limits: delay after launch, delay between messages and max impressions
 */
- (void)testCampaignThrottleLimits {
    // Mock campaign and QA User.
    id swrveMock = [self swrveMockWithTestJson:@"campaignsDelay"];
    id swrveQAMock = OCMPartialMock([SwrveQA sharedInstance]);
    OCMStub([swrveQAMock isQALogging]).andReturn(YES);
    NSArray<SwrveQACampaignInfo*> *expectedQACampaign;

    SwrveMessageController *controller = [swrveMock messaging];
    // First Message Delay
    // Campaign has start delay of 60 seconds, so no message should be returned after 40 seconds
    self.swrveNowDate = [NSDate dateWithTimeInterval:40 sinceDate:self.swrveNowDate];

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNil(message);

    expectedQACampaign = @[
        [[SwrveQACampaignInfo alloc] initWithCampaignID:102 variantID:165 type:SWRVE_CAMPAIGN_IAM displayed:NO reason:@"{Campaign throttle limit} Too soon after launch. Wait until 00:01:00 +0000"],
        [[SwrveQACampaignInfo alloc] initWithCampaignID:103 variantID:166 type:SWRVE_CAMPAIGN_IAM displayed:NO reason:@"There is no trigger in 103 that matches Swrve.currency_given with conditions (null)"]];
    OCMVerify([swrveQAMock messageCampaignTriggered:@"Swrve.currency_given" eventPayload:nil displayed:NO campaignInfoDict:expectedQACampaign]);

    // Go another 30 seconds into future to get to start time + 70 seconds, message should appear now
    self.swrveNowDate = [NSDate dateWithTimeInterval:30 sinceDate:self.swrveNowDate];
    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    [controller messageWasShownToUser:message];

    // Delay between messages
    // Go 10 seconds into the future, no message should show because there need to be 30 seconds between messages
    self.swrveNowDate = [NSDate dateWithTimeInterval:10 sinceDate:self.swrveNowDate];

    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNil(message);

    expectedQACampaign = @[
        [[SwrveQACampaignInfo alloc] initWithCampaignID:102 variantID:165 type:SWRVE_CAMPAIGN_IAM displayed:NO reason:@"{Campaign throttle limit} Too soon after last message. Wait until 00:01:40 +0000"],
        [[SwrveQACampaignInfo alloc] initWithCampaignID:103 variantID:166 type:SWRVE_CAMPAIGN_IAM displayed:NO reason:@"There is no trigger in 103 that matches Swrve.currency_given with conditions (null)"]];
    OCMVerify([swrveQAMock messageCampaignTriggered:@"Swrve.currency_given" eventPayload:nil displayed:NO campaignInfoDict:expectedQACampaign]);

    // Another 25 seconds and a message should be shown again
    self.swrveNowDate = [NSDate dateWithTimeInterval:25 sinceDate:self.swrveNowDate];

    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    [controller messageWasShownToUser:message];

    // Max impressions

    // This message should only be shown 3 times, it has been shown twice already
    self.swrveNowDate = [NSDate dateWithTimeInterval:60 sinceDate:self.swrveNowDate];

    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    [controller messageWasShownToUser:message];

    self.swrveNowDate = [NSDate dateWithTimeInterval:60 sinceDate:self.swrveNowDate];

    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNil(message);

    expectedQACampaign = @[
        [[SwrveQACampaignInfo alloc] initWithCampaignID:102 variantID:165 type:SWRVE_CAMPAIGN_IAM displayed:NO reason:@"{Campaign throttle limit} Campaign 102 has been shown 3 times already"],
        [[SwrveQACampaignInfo alloc] initWithCampaignID:103 variantID:166 type:SWRVE_CAMPAIGN_IAM displayed:NO reason:@"There is no trigger in 103 that matches Swrve.currency_given with conditions (null)"]];
    OCMVerify([swrveQAMock messageCampaignTriggered:@"Swrve.currency_given" eventPayload:nil displayed:NO campaignInfoDict:expectedQACampaign]);

    [swrveQAMock stopMocking];
}

/**
 * Test campaign state is saved
 */
- (void)testImpressionsStateSaved {
    id swrveMock = [self swrveMockWithTestJson:@"campaignsImpressions"];
    SwrveMessageController *controller = [swrveMock messaging];

    // This message should only be shown 2 times
    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    [controller messageWasShownToUser:message];
    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    [controller messageWasShownToUser:message];
    // Cannot show the message anymore
    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNil(message);
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsNone" ofType:@"json"];
    NSData *mockJsonData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockJsonData options:0 error:nil];

    // Fake campaigns gone and come back
    [controller updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO];
    XCTAssertEqual([[controller campaigns] count], 0);
    
    [[swrveMock messaging] saveCampaignsState];

    // Fake campaigns are available again
    filePath = [[NSBundle mainBundle] pathForResource:@"campaignsImpressions" ofType:@"json"];
    mockJsonData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    jsonDict = [NSJSONSerialization JSONObjectWithData:mockJsonData options:0 error:nil];

    [controller updateCampaigns:jsonDict withLoadingPreviousCampaignState:YES];
    XCTAssertEqual([[controller campaigns] count], 1);
    
    // Impressions rule still in place
    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNil(message);
}

/**
 * Ensure delay is also calculated after message dismissal
 */
- (void)testMessageIntervalCalculatedAfterDismissal {
    id swrveMock = [self swrveMockWithTestJson:@"campaignsDelay"];
    SwrveMessageController *controller = [swrveMock messaging];

    // First message display
    self.swrveNowDate = [NSDate dateWithTimeInterval:130 sinceDate:self.swrveNowDate];

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    [controller showMessage:message];

    SwrveMessageViewController *viewController = [self messageViewControllerFrom:controller];
    [viewController viewDidAppear:NO];

    self.swrveNowDate = [NSDate dateWithTimeInterval:130 sinceDate:self.swrveNowDate];

    // Press dismiss button
    UISwrveButton* dismissButton = [UISwrveButton new];
    [dismissButton setTag:2];
    [viewController onButtonPressed:dismissButton pageId:[NSNumber numberWithInt:0]];
    [self waitForWindowDismissed:controller];

    // No message should be shown as the message has just been dismissed
    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNil(message);

    // Another 35 seconds and a message should be shown again
    self.swrveNowDate = [NSDate dateWithTimeInterval:35 sinceDate:self.swrveNowDate];

    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
}

/**
 * When a campaign is loaded it should be initialised with the start time of the app, not with
 * the time the campaign was downloaded to ensure that the throttle limits count from start of session.
 */
- (void)testCampaignThrottleLimitsOnReset {
    // Mock SwrveQA
    id swrveQAMock = OCMPartialMock([SwrveQA sharedInstance]);
    OCMStub([swrveQAMock isQALogging]).andReturn(YES);
    id swrveMock = [self swrveMockWithTestJson:@"campaignsDelay"];

    NSArray<SwrveQACampaignInfo*> *expectedQACampaign = @[
    [[SwrveQACampaignInfo alloc] initWithCampaignID:102 variantID:165 type:SWRVE_CAMPAIGN_IAM displayed:NO reason:@"{Campaign throttle limit} Too soon after launch. Wait until 00:01:00 +0000"],
    [[SwrveQACampaignInfo alloc] initWithCampaignID:103 variantID:166 type:SWRVE_CAMPAIGN_IAM displayed:NO reason:@"There is no trigger in 103 that matches Swrve.currency_given with conditions (null)"]];

    SwrveMessageController *controller = [swrveMock messaging];

    // Campaign has start delay of 60 seconds - so if we go 40 seconds into the future and reload the
    // campaigns it shouldn't show yet
    self.swrveNowDate = [NSDate dateWithTimeInterval:40 sinceDate:self.swrveNowDate];

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNil(message);

    OCMVerify([swrveQAMock messageCampaignTriggered:@"Swrve.currency_given" eventPayload:nil displayed:NO campaignInfoDict:expectedQACampaign]);

    // If we then go another 30 seconds into the future it should show
    // (if throttle limit is reset at campaign load it would only show after 40 + 60 seconds)
    self.swrveNowDate = [NSDate dateWithTimeInterval:30 sinceDate:self.swrveNowDate];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsDelay" ofType:@"json"];
    NSData *mockJsonData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockJsonData options:0 error:nil];
    [controller updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO];
    
    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);

    [swrveQAMock stopMocking];
}

/**
 * Test app throttle limits: delay after launch, delay between messages and max impressions
 */
- (void)testAppThrottleLimits {
    id swrveQAMock = OCMPartialMock([SwrveQA sharedInstance]);
    OCMStub([swrveQAMock isQALogging]).andReturn(YES);
    id swrveMock = [self swrveMockWithTestJson:@"campaignsDelay"];
    SwrveMessageController *controller = [swrveMock messaging];

    // First Message Delay
    // App has start delay of 30 seconds, so no message should be returned
    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.user_purchase"];
    XCTAssertNil(message);

    OCMVerify([swrveQAMock campaignTriggered:@"Swrve.user_purchase" eventPayload:nil displayed:NO reason:@"{App throttle limit} Too soon after launch. Wait until 00:00:30 +0000" campaignInfo:nil]);
    
    // Go 40 seconds into future
    self.swrveNowDate = [NSDate dateWithTimeInterval:40 sinceDate:self.swrveNowDate];
    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.user_purchase"];
    XCTAssertNotNil(message);
    [controller messageWasShownToUser:message];

    // Delay between messages
    // Go 5 seconds into the future, no message should show because there need to be 10 seconds between messages
    self.swrveNowDate = [NSDate dateWithTimeInterval:5 sinceDate:self.swrveNowDate];
    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.user_purchase"];
    XCTAssertNil(message);

    OCMVerify([swrveQAMock campaignTriggered:@"Swrve.user_purchase" eventPayload:nil displayed:NO reason:@"{App throttle limit} Too soon after last iam. Wait until 00:00:50 +0000" campaignInfo:nil]);

    // Another 15 seconds and a message should be shown again
    self.swrveNowDate = [NSDate dateWithTimeInterval:15 sinceDate:self.swrveNowDate];
    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.user_purchase"];
    XCTAssertNotNil(message);
    [controller messageWasShownToUser:message];

    // Max impressions

    // Any message should only be shown 4 times, it has been shown twice already
    self.swrveNowDate = [NSDate dateWithTimeInterval:60 sinceDate:self.swrveNowDate];
    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.user_purchase"];
    XCTAssertNotNil(message);
    [controller messageWasShownToUser:message];

    self.swrveNowDate = [NSDate dateWithTimeInterval:60 sinceDate:self.swrveNowDate];
    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.user_purchase"];
    XCTAssertNotNil(message);
    [controller messageWasShownToUser:message];

    self.swrveNowDate = [NSDate dateWithTimeInterval:60 sinceDate:self.swrveNowDate];
    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.user_purchase"];
    XCTAssertNil(message);

    OCMVerify([swrveQAMock campaignTriggered:@"Swrve.user_purchase" eventPayload:nil displayed:NO reason:@"{App Throttle limit} Too many iam s shown" campaignInfo:nil]);

    [swrveQAMock stopMocking];
}

- (void)testGetMessageForNonExistingTrigger {
    id swrveMock = [self swrveMockWithTestJson:@"campaignsDelay"];
    SwrveMessageController *controller = [swrveMock messaging];

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"InvalidTrigger"];
    XCTAssertNil(message);
}

- (void)testGetMessageWithEmptyCampaigns {

    id swrveQAMock = OCMPartialMock([SwrveQA sharedInstance]);
    OCMStub([swrveQAMock isQALogging]).andReturn(YES);

    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    SwrveMessageController *controller = [swrveMock messaging];

    NSData *emptyJson = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:emptyJson options:0 error:nil];
    
    [controller updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO];

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNil(message);

    OCMVerify([swrveQAMock campaignTriggered:@"Swrve.currency_given" eventPayload:nil displayed:NO reason:@"No iams available" campaignInfo:nil]);
    [swrveQAMock stopMocking];
}

/**
 * Test that a campaign with a start date in the future is not displayed
 * Ensure that it is displayed when we move time to after the start date
 * Test that it stops displaying when we move time past the campaign end date
 */
- (void)testCampaignsStartEndDates {
    // Mock SwrveQA
    id swrveQAMock = OCMPartialMock([SwrveQA sharedInstance]);
    OCMStub([swrveQAMock isQALogging]).andReturn(YES);
    NSArray<SwrveQACampaignInfo*> *expectedQACampaign = nil;

    id swrveMock = [self swrveMockWithTestJson:@"campaignsFuture"];
    SwrveMessageController *controller = [swrveMock messaging];

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNil(message);

    expectedQACampaign = @[
    [[SwrveQACampaignInfo alloc] initWithCampaignID:105 variantID:170 type:SWRVE_CAMPAIGN_IAM displayed:NO reason:@"Campaign 105 has not started yet"]];
    OCMVerify([swrveQAMock messageCampaignTriggered:@"Swrve.currency_given" eventPayload:nil displayed:NO campaignInfoDict:expectedQACampaign]);

    // 25 hours into the future the campaign should be available
    self.swrveNowDate = [NSDate dateWithTimeInterval:60*60*25 sinceDate:self.swrveNowDate];

    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);

    // The campaign is only live for 24 hours, so another 24 hours into the future it should no longer be available
    self.swrveNowDate = [NSDate dateWithTimeInterval:60*60*24 sinceDate:self.swrveNowDate];

    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNil(message);

    expectedQACampaign = @[
    [[SwrveQACampaignInfo alloc] initWithCampaignID:105 variantID:170 type:SWRVE_CAMPAIGN_IAM displayed:NO reason:@"Campaign 105 has finished"]];
    OCMVerify([swrveQAMock messageCampaignTriggered:@"Swrve.currency_given" eventPayload:nil displayed:NO campaignInfoDict:expectedQACampaign]);

    [swrveQAMock stopMocking];
}

/**
 * Test actions when custom button pressed
 * - custom button callback called with correct action
 * - click event sent
 */
- (void)testCustomButtonPressed {
    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    SwrveMessageController *controller = [swrveMock messaging];

    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    SwrveMessagePageViewController *pageViewController = [self loadMessagePageViewController:messageViewController];

    __block int customActionCount = 0;
    __block NSString *customAction;

    // Set custom callbacks
    [controller setCustomButtonCallback:^(NSString* action, NSString* name) {
        customActionCount++;
        customAction = action;
    }];

    SwrveMessageFormat *format = [pageViewController messageFormat];
    SwrveMessagePage *page = [[format pages] objectForKey:[NSNumber numberWithInt:0]];
    NSArray *buttons = [page buttons];
    XCTAssertEqual([buttons count], 5);

    // access the UIViews in the subview of the SwrveMessageViewController
    NSArray *vcSubviews = [[[[pageViewController view] subviews] firstObject] subviews];
    NSMutableArray *uiButtons = [NSMutableArray new];

    // get all the buttons
    for (UIView *item in vcSubviews){
        if ([item isKindOfClass:[UISwrveButton class]]) {
            [uiButtons addObject:item];
        }
    }

    XCTAssertEqual([uiButtons count], 5);

    for (NSInteger i = 0; i < [buttons count]; i++) {
        SwrveButton *swrveButton = [buttons objectAtIndex:i];

        // verify that a UISwrveButton matching the accessibility id
        if ([swrveButton actionType] == kSwrveActionCustom) {
            for (UISwrveButton *button in uiButtons){
                if ([button.accessibilityIdentifier isEqualToString:swrveButton.name]) {
                    // pretend to press it
                    [pageViewController onButtonPressed:button];
                    [self waitForWindowDismissed:controller];
                }
            }
        }
    }

    // Check custom callback was called with correct parameters
    XCTAssertEqual(customActionCount, 1);
    XCTAssertNotNil(message);
    XCTAssertEqualObjects(customAction, @"custom_action");

    // Check if correct event was sent to Swrve for this button
    int clickEventCount = 0;
    for (NSString *event in [swrveMock eventBuffer]) {
        if ([event rangeOfString:@"Swrve.Messages.Message-165.click"].location != NSNotFound) {
            clickEventCount++;
            // Assert that the event contains the name of the button in the payload
            XCTAssertTrue([event rangeOfString:@"{\"name\":\"custom\",\"embedded\":\"false\"}"].location != NSNotFound);
        }
    }
    XCTAssertEqual(clickEventCount, 1);
}

- (void)testDismissButtonPressedWithPages {
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

    // go straight to last page which has a dismiss button
    SwrveMessageUIView *messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    XCTAssertTrue([self pressUISwrveButton:messageUiView name:@"Page5"]);
    pageViewController = [self loadMessagePageViewController:messageViewController];
    XCTAssertEqual([[messageViewController currentPageId] integerValue], 5);

    NSMutableDictionary *eventData = [NSMutableDictionary new];
    [eventData setValue:@"iam" forKey:@"campaignType"];
    [eventData setValue:@"dismiss" forKey:@"actionType"];
    [eventData setValue:[NSNumber numberWithLong:89355] forKey:@"id"];
    [eventData setValue:[NSNumber numberWithLong:5] forKey:@"contextId"];
    NSMutableDictionary *eventPayload = [NSMutableDictionary new];
    [eventPayload setValue:@"page 5" forKey:@"pageName"];
    [eventPayload setValue:@"Button 5 page 5 dismiss" forKey:@"buttonName"];
    [eventPayload setValue:[NSNumber numberWithLong:501] forKey:@"buttonId"];
    [eventData setValue:eventPayload forKey:@"payload"];
    OCMExpect([swrveMock queueEvent:@"generic_campaign_event" data:eventData triggerCallback:false]);

    // press the dismiss button
    messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    XCTAssertTrue([self pressUISwrveButton:messageUiView name:@"Dismiss"]);

    OCMVerifyAll(swrveMock);
}

- (void)testCustomButtonPressedWithPages {
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

    NSMutableDictionary *payload = [self messageClickPayloadEvent:1 pageName:@"page 1" buttonId:102];
    OCMExpect([swrveMock eventInternal:@"Swrve.Messages.Message-89355.click" payload:payload triggerCallback:false]);
    SwrveMessageUIView *messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    [self pressUISwrveButton:messageUiView name:@"custom"];

    OCMVerifyAll(swrveMock);
}

- (NSMutableDictionary *)messageClickPayloadEvent:(long)pageId pageName:(NSString *)pageName buttonId:(long)buttonId {
    NSMutableDictionary *eventData = [NSMutableDictionary new];
    [eventData setValue:@"false" forKey:@"embedded"];
    [eventData setValue:[NSNumber numberWithLong:pageId] forKey:@"contextId"];
    [eventData setValue:@"custom" forKey:@"name"];
    [eventData setValue:[NSNumber numberWithLong:buttonId] forKey:@"buttonId"];
    [eventData setValue:pageName forKey:@"pageName"];
    return eventData;
}

/**
 * Tests install button pressed
 */
- (void)testInstallButtonPressed {
    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    SwrveMessageController *controller = [swrveMock messaging];

    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    SwrveMessagePageViewController *pageViewController = [self loadMessagePageViewController:messageViewController];

    SwrveMessageFormat *format =[pageViewController messageFormat];
    SwrveMessagePage *page = [[format pages] objectForKey:[NSNumber numberWithInt:0]];
    NSArray *buttons = [page buttons];
    XCTAssertEqual([buttons count], 5);

    id mockUIApplication = OCMPartialMock([UIApplication sharedApplication]);
    OCMExpect([mockUIApplication openURL:OCMOCK_ANY options:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
    OCMStub([mockUIApplication openURL:OCMOCK_ANY options:OCMOCK_ANY completionHandler:OCMOCK_ANY]);

    // Pretend to press install buttons
    for (NSInteger i = 0; i < [buttons count]; i++) {
        SwrveButton* swrveButton = [buttons objectAtIndex:i];
        if ([swrveButton actionType] == kSwrveActionInstall) {
            UISwrveButton* button = [UISwrveButton new];
            [button setTag:i];
            [pageViewController onButtonPressed:button];
        }
    }

    // Ensure install callback was called, with correct parameters
    XCTAssertNotNil(message);

    // Check if correct event was sent to Swrve for this button
    int clickEventCount = 0;
    for (NSString* event in [swrveMock eventBuffer]) {
        if ([event rangeOfString:@"Swrve.Messages.Message-165.click"].location != NSNotFound) {
            clickEventCount++;
        }
    }
    XCTAssertEqual(clickEventCount, 1);

    OCMVerifyAllWithDelay(mockUIApplication, 5);

    [mockUIApplication stopMocking];
}

/**
 * Test dismiss button presses
 * - custom button callback called with correct action
 * - install button callback called with correct appStoreURL
 * - click events sent on custom and install buttons
 */
- (void)testDismissButtonPressed {
    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    SwrveMessageController *controller = [swrveMock messaging];

    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    SwrveMessagePageViewController *viewController = [self loadMessagePageViewController:messageViewController];
    [viewController viewDidAppear:NO];
    __block NSString *campaignSubject = @"";
    __block NSString *campaignName = @"";
    __block NSString *buttonName = @"";

    __block int customActionCount = 0;
    __block int clipboardActionCount = 0;
    __block int dismissActionCount = 0;

    // Set custom callbacks
    [controller setCustomButtonCallback:^(NSString *action, NSString *name) {
        customActionCount++;
    }];

    [controller setDismissButtonCallback:^(NSString *campaignS, NSString *buttonN, NSString *campaignN) {
        dismissActionCount++;
        campaignSubject = campaignS;
        campaignName = campaignN;
        buttonName = buttonN;
    }];

    [controller setClipboardButtonCallback:^(NSString *processedText) {
        clipboardActionCount++;
    }];

    SwrveMessageFormat *format =[viewController messageFormat];
    SwrveMessagePage *page = [[format pages] objectForKey:[NSNumber numberWithInt:0]];
    NSArray *buttons = [page buttons];
    XCTAssertEqual([buttons count],5);

    // Pretend to press all buttons
    for (NSInteger i = 0; i < [buttons count]; i++) {
        SwrveButton *swrveButton = [buttons objectAtIndex:i];
        if ([swrveButton actionType] == kSwrveActionDismiss) {
            UISwrveButton *button = [UISwrveButton new];
            [button setTag:i];
            [viewController onButtonPressed:button];
            [self waitForWindowDismissed:controller];
        }
    }

    // Ensure custom and install callbacks weren't invoked
    XCTAssertEqual(customActionCount, 0);
    XCTAssertEqual(dismissActionCount, 1);
    XCTAssertEqual(clipboardActionCount, 0);
    XCTAssertEqualObjects(buttonName, @"close");
    XCTAssertEqualObjects(campaignSubject, @"IAM subject");
    XCTAssertEqualObjects(campaignName, @"Kindle");

    // Check no click events were sent
    int clickEventCount = 0;
    for (NSString *event in [swrveMock eventBuffer]) {
        if ([event rangeOfString:@"Swrve.Messages.Message-165.click"].location != NSNotFound) {
            clickEventCount++;
        }
    }
    XCTAssertEqual(clickEventCount, 0);
}

- (void)testPagingViaButtons {

    __block BOOL *dismissed = NO;
    SwrveDismissButtonPressedCallback dismissCallback = ^(NSString *campaignS, NSString *buttonN, NSString *campaignN) {
        dismissed = YES;
    };
    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.inAppMessageConfig.dismissButtonCallback = dismissCallback;

    NSArray *assets = @[@"6c871366c876fdb495d96eff3d2905f9d4594c62"];
    [SwrveTestHelper createDummyAssets:assets];
    id swrveMock = [self swrveMockWithTestJson:@"campaigns_multipage" withConfig:config];
    XCTAssertEqual([[swrveMock messageCenterCampaigns] count], 1);

    SwrveMessageController *controller = [swrveMock messaging];
    SwrveCampaign *campaign = [[swrveMock messageCenterCampaigns] objectAtIndex:0];
    [controller showMessageCenterCampaign:campaign];
    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    [messageViewController viewDidAppear:NO];
    SwrveMessagePageViewController *pageViewController = [self loadMessagePageViewController:messageViewController];

    XCTAssertEqual([[messageViewController currentPageId] integerValue], 1);
    SwrveMessageUIView *messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    [self pressUISwrveButton:messageUiView name:@"Next"];
    [self loadMessagePageViewController:messageViewController];

    XCTAssertEqual([[messageViewController currentPageId] integerValue], 2);
    messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    [self pressUISwrveButton:messageUiView name:@"Next"];
    [self loadMessagePageViewController:messageViewController];

    XCTAssertEqual([[messageViewController currentPageId] integerValue], 3);
    messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    [self pressUISwrveButton:messageUiView name:@"Next"];
    [self loadMessagePageViewController:messageViewController];

    XCTAssertEqual([[messageViewController currentPageId] integerValue], 4);
    messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    [self pressUISwrveButton:messageUiView name:@"Next"];
    [self loadMessagePageViewController:messageViewController];

    XCTAssertEqual([[messageViewController currentPageId] integerValue], 5);
    messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    [self pressUISwrveButton:messageUiView name:@"Previous"];
    [self loadMessagePageViewController:messageViewController];

    XCTAssertEqual([[messageViewController currentPageId] integerValue], 4);
    messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    [self pressUISwrveButton:messageUiView name:@"Page2"];
    [self loadMessagePageViewController:messageViewController];

    XCTAssertEqual([[messageViewController currentPageId] integerValue], 2);
    messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    [self pressUISwrveButton:messageUiView name:@"Previous"];
    [self loadMessagePageViewController:messageViewController];

    XCTAssertEqual([[messageViewController currentPageId] integerValue], 1);
    messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    [self pressUISwrveButton:messageUiView name:@"Page5"];
    [self loadMessagePageViewController:messageViewController];

    XCTAssertEqual([[messageViewController currentPageId] integerValue], 5);
    XCTAssertFalse(dismissed);
    messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    [self pressUISwrveButton:messageUiView name:@"Dismiss"];
    [self loadMessagePageViewController:messageViewController];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Dismiss button should be called"];
    [SwrveTestHelper waitForBlock:0.5 conditionBlock:^BOOL() {
        return dismissed;
    }                 expectation:expectation];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    XCTAssertTrue(dismissed);
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
    NSMutableDictionary *eventDataNextNavPage1 = [self pageNavEventData:1 pageName:@"page 1" toPageId:2 buttonId:101];
    OCMExpect([swrveMock queueEvent:@"generic_campaign_event" data:eventDataNextNavPage1 triggerCallback:false]);
    SwrveMessageUIView *messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    XCTAssertTrue([self pressUISwrveButton:messageUiView name:@"Next"]);
    [self loadMessagePageViewController:messageViewController];
    XCTAssertEqual([[messageViewController currentPageId] integerValue], 2);
    OCMVerifyAll(swrveMock);

    NSMutableDictionary *eventDataPage3 = [self pageViewEventData:3 pageName:@"page 3"];
    OCMExpect([swrveMock queueEvent:@"generic_campaign_event" data:eventDataPage3 triggerCallback:false]);
    NSMutableDictionary *eventDataNextNavPage2 = [self pageNavEventData:2 pageName:@"page 2" toPageId:3 buttonId:201];
    OCMExpect([swrveMock queueEvent:@"generic_campaign_event" data:eventDataNextNavPage2 triggerCallback:false]);
    messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    XCTAssertTrue([self pressUISwrveButton:messageUiView name:@"Next"]);
    [self loadMessagePageViewController:messageViewController];
    XCTAssertEqual([[messageViewController currentPageId] integerValue], 3);
    OCMVerifyAll(swrveMock);

    // pressing the previous button (to go back to page 2) should not send another eventDataPage2 event, so use OCMReject
    OCMReject([swrveMock queueEvent:@"generic_campaign_event" data:eventDataPage2 triggerCallback:false]);
    NSMutableDictionary *eventDataPreviousNavPage3 = [self pageNavEventData:3 pageName:@"page 3" toPageId:2 buttonId:300];
    OCMExpect([swrveMock queueEvent:@"generic_campaign_event" data:eventDataPreviousNavPage3 triggerCallback:false]);
    messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    XCTAssertTrue([self pressUISwrveButton:messageUiView name:@"Previous"]);
    [self loadMessagePageViewController:messageViewController];
    XCTAssertEqual([[messageViewController currentPageId] integerValue], 2);
    OCMVerifyAll(swrveMock);

    // pressing the next button AGAIN (to go back to page 3) should not send another eventDataPage3/eventDataNextNavPage2 event, so use OCMReject
    OCMReject([swrveMock queueEvent:@"generic_campaign_event" data:eventDataPage3 triggerCallback:false]);
    OCMReject([swrveMock queueEvent:@"generic_campaign_event" data:eventDataNextNavPage2 triggerCallback:false]);
    messageUiView = [self swrveMessageUIViewFromController:messageViewController];
    XCTAssertTrue([self pressUISwrveButton:messageUiView name:@"Next"]);
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
    [eventData setValue:eventPayload forKey:@"payload"];
    return eventData;
}

- (NSMutableDictionary*)pageNavEventData:(long)pageId pageName:(NSString *)pageName toPageId:(long)toPageId buttonId:(long)buttonId {
    NSMutableDictionary *eventData = [NSMutableDictionary new];
    [eventData setValue:@"iam" forKey:@"campaignType"];
    [eventData setValue:@"navigation" forKey:@"actionType"];
    [eventData setValue:[NSNumber numberWithLong:89355] forKey:@"id"];
    [eventData setValue:[NSNumber numberWithLong:pageId] forKey:@"contextId"];
    NSMutableDictionary *eventPayload = [NSMutableDictionary new];
    [eventPayload setValue:pageName forKey:@"pageName"];
    [eventPayload setValue:[NSNumber numberWithLong:toPageId] forKey:@"to"];
    [eventPayload setValue:[NSNumber numberWithLong:buttonId] forKey:@"buttonId"];
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
    [self pressUISwrveButton:messageUiView name:@"Next"];

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

- (BOOL)pressUISwrveButton:(UIView *)view name:(NSString *)buttonName {
    BOOL pressed = NO;
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UISwrveButton class]]) {
            UISwrveButton *uiSwrveButton = (UISwrveButton *) subview;
            if ([uiSwrveButton.displayString isEqualToString:buttonName]) {
                [uiSwrveButton sendActionsForControlEvents:UIControlEventTouchUpInside];
                pressed = YES;
                break;
            }
        }
    };
    return pressed;
}

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

/**
 * Test actions when clipboard button pressed
 * - clipboard button callback called with correct action
 * - click event sent
 */
- (void)testClipboardButtonPressed {
    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    SwrveMessageController *controller = [swrveMock messaging];

    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    SwrveMessagePageViewController *viewController = [self loadMessagePageViewController:messageViewController];
    [viewController viewDidAppear:NO];

    __block int clipboardActionCount = 0;
    __block NSString *clipboardAction;

    // Set clipboard callbacks
    [controller setClipboardButtonCallback:^(NSString* action) {
        clipboardActionCount++;
        clipboardAction = action;
    }];

    SwrveMessageFormat *format = [viewController messageFormat];
    SwrveMessagePage *page = [[format pages] objectForKey:[NSNumber numberWithInt:0]];
    NSArray *buttons = [page buttons];
    XCTAssertEqual([buttons count], 5);

    // access the UIViews in the subview of the SwrveMessageViewController
    NSArray *vcSubviews = [[[[viewController view] subviews] firstObject] subviews];
    NSMutableArray *uiButtons = [NSMutableArray new];

    // get all the buttons
    for (UIView *item in vcSubviews){
        if ([item isKindOfClass:[UISwrveButton class]]) {
            [uiButtons addObject:item];
        }
    }

    XCTAssertEqual([uiButtons count], 5);

    for (NSInteger i = 0; i < [buttons count]; i++) {
        SwrveButton *swrveButton = [buttons objectAtIndex:i];

        // verify that a UISwrveButton matching the accessibility id
        if ([swrveButton actionType] == kSwrveActionClipboard) {
            for (UISwrveButton *button in uiButtons){
                if ([button.accessibilityIdentifier isEqualToString:swrveButton.name]) {
                    // pretend to press it
                    [viewController onButtonPressed:button];
                    [self waitForWindowDismissed:controller];
                }
            }
        }
    }

    // Check clipboard callback was called with correct parameters
    XCTAssertEqual(clipboardActionCount, 1);
    XCTAssertNotNil(message);
    XCTAssertEqualObjects(clipboardAction, @"test");

#if TARGET_OS_IOS /** exclude tvOS **/
        // verify (on iOS) that the value was copied to clipboard
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        XCTAssertEqualObjects(pasteboard.string, @"test");
#endif /**TARGET_OS_IOS **/

    // Check if correct event was sent to Swrve for this button
    int clickEventCount = 0;
    for (NSString *event in [swrveMock eventBuffer]) {
        if ([event rangeOfString:@"Swrve.Messages.Message-165.click"].location != NSNotFound) {
            clickEventCount++;
            // Assert that the event contains the name of the button in the payload
            XCTAssertTrue([event rangeOfString:@"{\"name\":\"clipboard_action\",\"embedded\":\"false\"}"].location != NSNotFound);
        }
    }
    XCTAssertEqual(clickEventCount, 1);
}

/**
 * Test actions when capability button pressed
 * - delegate called
 * - click event sent
 */
- (void)testCapabilityButtonPressed {
    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    SwrveMessageController *controller = [swrveMock messaging];

    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    SwrveMessagePageViewController *viewController = [self loadMessagePageViewController:messageViewController];
    [viewController viewDidAppear:NO];

    SwrveMessageFormat *format =[viewController messageFormat];
    SwrveMessagePage *page = [[format pages] objectForKey:[NSNumber numberWithInt:0]];
    NSArray *buttons = [page buttons];
    XCTAssertEqual([buttons count], 5);

    // access the UIViews in the subview of the SwrveMessageViewController
    NSArray *vcSubviews = [[[[viewController view] subviews] firstObject] subviews];
    NSMutableArray *uiButtons = [NSMutableArray new];

    // get all the buttons
    for (UIView *item in vcSubviews){
        if ([item isKindOfClass:[UISwrveButton class]]) {
            [uiButtons addObject:item];
        }
    }

    XCTAssertEqual([uiButtons count], 5);

    for (NSInteger i = 0; i < [buttons count]; i++) {
        SwrveButton *swrveButton = [buttons objectAtIndex:i];
        // verify that a UISwrveButton matching the accessibility id
        if ([swrveButton actionType] == kSwrveActionCapability) {
            for (UISwrveButton *button in uiButtons){
                if ([button.accessibilityIdentifier isEqualToString:swrveButton.name]) {
                    // pretend to press it
                    [viewController onButtonPressed:button];
                    [self waitForWindowDismissed:controller];
                }
            }
        }
    }

    // check capability delegate called
    OCMVerify([testCapabilitiesDelegateMock requestCapability:@"swrve.contacts" completionHandler:OCMOCK_ANY]);

    int clickEventCount = 0;
    for (NSString* event in [swrveMock eventBuffer]) {
        if ([event rangeOfString:@"Swrve.Messages.Message-165.click"].location != NSNotFound) {
            clickEventCount++;
        }
    }
    XCTAssertEqual(clickEventCount, 1);
}

/**
 * Test actions when capability button pressed for push  (special case)
 * - delegate not called
 * - click event sent
 */

#if TARGET_OS_IOS
- (void)testCapabilityButtonPressedForPush {
    id swrveMock = [self swrveMockWithTestJson:@"iamCapabilites"];
    SwrveMessageController *controller = [swrveMock messaging];
    controller.pushEnabled = true;

    id swrvePushMock = OCMPartialMock([SwrvePush alloc]);
    OCMStub([swrveMock push]).andReturn(swrvePushMock);

    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"eventRequestablePush"];
    [controller showMessage:message];

    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    SwrveMessagePageViewController *viewController = [messageViewController.viewControllers firstObject];
    [viewController viewDidAppear:NO];

    SwrveMessageFormat *format =[viewController messageFormat];
    SwrveMessagePage *page = [[format pages] objectForKey:[NSNumber numberWithInt:0]];
    NSArray *buttons = [page buttons];
    XCTAssertEqual([buttons count], 1);

    // access the UIViews in the subview of the SwrveMessageViewController
    NSArray *vcSubviews = [[[[viewController view] subviews] firstObject] subviews];
    NSMutableArray *uiButtons = [NSMutableArray new];

    // get all the buttons
    for (UIView *item in vcSubviews){
        if ([item isKindOfClass:[UISwrveButton class]]) {
            [uiButtons addObject:item];
        }
    }

    XCTAssertEqual([uiButtons count], 1);

    id swrvePermissions = OCMClassMock([SwrvePermissions class]);
    OCMStub([swrvePermissions requestPushNotifications:OCMOCK_ANY provisional:OCMOCK_ANY]).andDo(nil);

    // check capablity delegate not called
    OCMReject([testCapabilitiesDelegateMock requestCapability:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
    OCMExpect([swrvePushMock registerForPushNotifications:FALSE]).andDo(nil);

    for (NSInteger i = 0; i < [buttons count]; i++) {
        SwrveButton *swrveButton = [buttons objectAtIndex:i];
        // verify that a UISwrveButton matching the accessibility id
        if ([swrveButton actionType] == kSwrveActionCapability) {
            for (UISwrveButton *button in uiButtons){
                if ([button.accessibilityIdentifier isEqualToString:swrveButton.name]) {
                    // pretend to press it
                    [viewController onButtonPressed:button];
                    [self waitForWindowDismissed:controller];
                }
            }
        }
    }

    OCMVerifyAll(swrvePushMock);

    int clickEventCount = 0;
    for (NSString* event in [swrveMock eventBuffer]) {
        if ([event rangeOfString:@"Swrve.Messages.Message-165.click"].location != NSNotFound) {
            clickEventCount++;
        }
    }
    XCTAssertEqual(clickEventCount, 1);
}

- (void)testCapabilityFilterForPush {
    id swrveMock = [self swrveMockWithTestJson:@"iamCapabilites"];
    SwrveMessageController *controller = [swrveMock messaging];
    controller.pushEnabled = true;

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"eventRequestablePush"];
    XCTAssertNotNil(message);
    
    id permissionMock = OCMClassMock([SwrvePermissions class]);
    OCMStub([permissionMock didWeAskForPushPermissionsAlready]).andReturn(true);
    
    message = (SwrveMessage *)[controller baseMessageForEvent:@"eventRequestablePush"];
    XCTAssertNil(message);
}

- (void)testFilterCampaignFromMessageCenter {
    id swrveMock = [self swrveMockWithTestJson:@"iamCapabilites"];
    SwrveMessageController *controller = [swrveMock messaging];
    controller.pushEnabled = true;

    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;

    //Check campaign has been filtered out of messageCenterCampaigns
    NSArray *messageCenterCampaigns = [controller messageCenterCampaigns];
    XCTAssertEqual([messageCenterCampaigns count], 2);
    XCTAssertEqual([[controller campaigns] count], 3);
    
    OCMVerify([testCapabilitiesDelegateMock canRequestCapability:@"swrve.contacts"]);
    OCMVerify([testCapabilitiesDelegateMock canRequestCapability:@"swrve.photo"]);
}

#endif //TARGET_OS_IOS

- (void)testEmbeddedImpressionAndEngagement {
    
    __block SwrveEmbeddedMessage *embmessage = nil;
    __block id swrveMock = nil;
    
    SwrveConfig *config = [SwrveConfig new];
    
    // add this to test that an embedded campaign doesn't trigger a capability check
    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    config.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;
    
    SwrveEmbeddedMessageConfig *embeddedConfig = [SwrveEmbeddedMessageConfig new];
    [embeddedConfig setEmbeddedMessageCallback:^(SwrveEmbeddedMessage *message) {
        embmessage = message;
        [[swrveMock messaging] embeddedMessageWasShownToUser:message];
        [[swrveMock messaging] embeddedButtonWasPressed:message buttonName:message.buttons[0]];
    }];
    
    config.embeddedMessageConfig = embeddedConfig;
    
    swrveMock = [self swrveMockWithTestJson:@"campaignsEmbedded" withConfig:config];
    SwrveMessageController *controller = [swrveMock messaging];
    
    NSDictionary* event =  @{@"type": @"event",
                             @"seqnum": @1111,
                             @"name": @"trigger_embedded",
                             @"payload": @{}};
    
    [controller eventRaised:event];
    
    XCTAssertNotNil(embmessage);
    XCTAssertEqualObjects(embmessage.data, @"test string");
    XCTAssertEqual(embmessage.type, kSwrveEmbeddedDataTypeOther);
    NSArray<NSString *> *buttons = embmessage.buttons;
    
    XCTAssertEqualObjects(buttons[0], @"Button 1");
    XCTAssertEqualObjects(buttons[1], @"Button 2");
    XCTAssertEqualObjects(buttons[2], @"Button 3");

    // Check if correct events have sent to Swrve from these calls in the callback
    int clickEventCount = 0;
    for (NSString* event in [swrveMock eventBuffer]) {
        
        if ([event rangeOfString:@"Swrve.Messages.Message-20.impression"].location != NSNotFound) {
            clickEventCount++;

            // Assert that the event contains the embedded bool in the payload
            XCTAssertTrue([event rangeOfString:@"{\"embedded\":\"true\"}"].location != NSNotFound);
        }
        
        if ([event rangeOfString:@"Swrve.Messages.Message-20.click"].location != NSNotFound) {
            clickEventCount++;
            
            // Assert that the event contains the button and embedded bool in the payload
            XCTAssertTrue([event rangeOfString:@"{\"name\":\"Button 1\",\"embedded\":\"true\"}"].location != NSNotFound);
        }
    }
    XCTAssertEqual(clickEventCount, 2);
}

/**
 * When a QA user has resetDevice set to YES the max impression count shouldn't apply
 */
- (void)testQAResetDevice {
    id swrveMock = [self swrveMockWithTestJson:@"campaignsQAReset"];
    SwrveMessageController *controller = [swrveMock messaging];

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    [controller messageWasShownToUser:message];

    // QA user follows rules since the first campaign reload (thus impressions prevent from showing it)
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsQAReset" ofType:@"json"];
    NSData *mockJsonData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockJsonData options:0 error:nil];

    [SwrveQA updateQAUser: [jsonDict objectForKey:@"qa"] andSessionToken:@"whatEverSessionToken"];
    BOOL isLoadingCampaign = [[SwrveQA sharedInstance] resetDeviceState];
    [controller updateCampaigns: jsonDict withLoadingPreviousCampaignState:isLoadingCampaign];

    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNil(message);

    // An SDK reset will cause the rules to reset
    swrveMock = [self swrveMockWithTestJson:@"campaignsQAReset"];
    controller = [swrveMock messaging];
    [controller messageWasShownToUser:message];

    // Message shows because rules have been reset
    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
}

/**
 * Check message priority is taken into account
 */
- (void)testMessagePriority {
    id swrveMock = [self swrveMockWithTestJson:@"campaignsMessagePriority"];
    SwrveMessageController *controller = [swrveMock messaging];

    // Message ID 1 should be highest priority
    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    XCTAssertEqual([[message messageID] intValue], 1);
    [controller messageWasShownToUser:message];

    // Message ID 2 should be second highest priority
    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    XCTAssertEqual([[message messageID] intValue], 2);
    [controller messageWasShownToUser:message];

    //Max impressiong for message id 2 is set to 2, so it show should again.
    //Also Display order is random and round robin has been removed,
    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    XCTAssertEqual([[message messageID] intValue], 2);
    [controller messageWasShownToUser:message];

    //Should now move to message id 4
    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    XCTAssertEqual([[message messageID] intValue], 4);
}

- (void)testMessagePriorityReverse {
    // https://swrvedev.jira.com/browse/SWRVE-10432
    // We were not clearing the bucket of candidate messages, ever...
    id swrveMock = [self swrveMockWithTestJson:@"campaignsMessagePriorityReverse"];
    SwrveMessageController *controller = [swrveMock messaging];

    // Highest priority first (first in round robin)
    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    XCTAssertEqual([[message messageID] intValue], 2);
    [controller messageWasShownToUser:message];

    //
    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    XCTAssertEqual([[message messageID] intValue], 2);
    [controller messageWasShownToUser:message];

    // Lowest priority (first message in JSON)
    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    XCTAssertEqual([[message messageID] intValue], 1);
}

- (void)testMessagePriority_FavourEmbedded {
    id swrveMock = [self swrveMockWithTestJson:@"campaignsEmbeddedMessagePriority"];
    SwrveMessageController *controller = [swrveMock messaging];

    // Message ID 4 should be highest priority and should be embedded
    SwrveBaseMessage *message = [controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    XCTAssertEqual([[message messageID] intValue], 4);
    XCTAssertTrue([message isKindOfClass:[SwrveEmbeddedMessage class]]);
    
    // Now go over embedded message's message rules
    [controller embeddedMessageWasShownToUser:(SwrveEmbeddedMessage *)message];
    message = [controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    XCTAssertEqual([[message messageID] intValue], 1);
    XCTAssertTrue([message isKindOfClass:[SwrveMessage class]]);
}

#if TARGET_OS_IOS /** exclude tvOS **/
/**
 * Check conversation priority is taken into account
 */
- (void)testConversationPriority {
    id swrveMock = [self swrveMockWithTestJson:@"conversationCampaignsPriority"];
    SwrveMessageController *controller = [swrveMock messaging];

    // Highest priority conversation first
    SwrveConversation *conversation = [controller conversationForEvent:@"Swrve.currency_given" withPayload:nil];
    XCTAssertNotNil(conversation);
    XCTAssertEqual([[conversation conversationID] intValue], 103);
    [conversation wasShownToUser];

    // Second highest conversation
    conversation = [controller conversationForEvent:@"Swrve.currency_given" withPayload:nil];
    XCTAssertNotNil(conversation);
    XCTAssertEqual([[conversation conversationID] intValue], 102);
    [conversation wasShownToUser];

    // Lowest conversation (out of 3)
    conversation = [controller conversationForEvent:@"Swrve.currency_given" withPayload:nil];
    XCTAssertNotNil(conversation);
    XCTAssertEqual([[conversation conversationID] intValue], 104);
    [conversation wasShownToUser];

    // Highest IAM
    SwrveBaseMessage *message = [controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    XCTAssertTrue([message isKindOfClass:[SwrveMessage class]]);
    SwrveMessage *testMessage = (SwrveMessage *)message;
    XCTAssertEqual([[testMessage messageID] intValue], 1);
}

- (void)testConversationPriorityReverse {
    // https://swrvedev.jira.com/browse/SWRVE-10432
    // We were not clearing the bucket of candidate messages, ever...
    // Check that this does not happen with conversations either.
    id swrveMock = [self swrveMockWithTestJson:@"conversationCampaignsPriorityReverse"];
    SwrveMessageController *controller = [swrveMock messaging];

    // Highest priority conversation first
    SwrveConversation *conversation = [controller conversationForEvent:@"Swrve.currency_given" withPayload:nil];
    XCTAssertNotNil(conversation);
    XCTAssertEqual([[conversation conversationID] intValue], 103);
    [conversation wasShownToUser];

    // Second highest conversation
    conversation = [controller conversationForEvent:@"Swrve.currency_given" withPayload:nil];
    XCTAssertNotNil(conversation);
    XCTAssertEqual([[conversation conversationID] intValue], 104);
    [conversation wasShownToUser];

    // Lowest conversation (out of 3)
    conversation = [controller conversationForEvent:@"Swrve.currency_given" withPayload:nil];
    XCTAssertNotNil(conversation);
    XCTAssertEqual([[conversation conversationID] intValue], 102);
    [conversation wasShownToUser];

    // Highest IAM
    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(conversation);
    XCTAssertEqual([[message messageID] intValue], 1);
}

// Conversation is just supported by iOS.
- (void)testConversationForEventTriggerAsQAUser {
    id swrveMock = [self swrveMockWithTestJson:@"conversationCampaignsPriority"];
    SwrveMessageController *controller = [swrveMock messaging];
    // define as QAUser
    id swrveQAMock = OCMPartialMock([SwrveQA sharedInstance]);
    [swrveQAMock updateQAUser:@{@"logging": @YES, @"reset_device_state": @YES } andSessionToken:@"aSessinToken"];

    SwrveConversation *conversation = [controller conversationForEvent:@"Swrve.currency_given" withPayload:nil];
    XCTAssertNotNil(conversation);

    OCMVerify([swrveQAMock conversationCampaignTriggered:@"Swrve.currency_given" eventPayload:nil displayed:YES campaignInfoDict:OCMOCK_ANY]);
}

#endif /**TARGET_OS_TV */

/**
 * Ensure session start event can trigger a message
 */
- (void)testSessionStartTrigger {
    id swrveMock = [self swrveMockWithTestJson:@"campaignSessionStart"];
    SwrveMessageController *controller = [swrveMock messaging];
    int success = [swrveMock sessionStart];
    XCTAssertEqual(success, SWRVE_SUCCESS);
    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    XCTAssertNotNil(messageViewController);
    XCTAssertNotNil(messageViewController.message);
    XCTAssertEqual([[messageViewController.message messageID] intValue], 165);
}

/**
 * Ensure only one message is shown at a time. If a second message is triggered it will be ignored
 * until the first message is dismissed
 */
- (void)testOneMessageAtATime {
    id swrveMock = [self swrveMockWithTestJson:@"campaignsMessagePriority"];
    SwrveMessageController *controller = [swrveMock messaging];

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *viewController = [self messageViewControllerFrom:controller];
    [viewController viewDidAppear:NO];

    OCMStub([swrveMock getNow]).andReturn([NSDate dateWithTimeInterval:40 sinceDate:[swrveMock getNow]]);

    // Ensure that if we try to display a second message without dismissing the first one this fails and the same message is still shown
    SwrveMessage *message2 = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message2];
    viewController = [self messageViewControllerFrom:controller];

    XCTAssertEqualObjects([viewController message], message);

    // Press dismiss button
    UISwrveButton* dismissButton = [UISwrveButton new];
    [dismissButton setTag:0];
    [viewController onButtonPressed:dismissButton pageId:[NSNumber numberWithInt:0]];
    [self waitForWindowDismissed:controller];

    // Ensure that new message is now shown correctly
    [controller showMessage:message2];
    viewController = [self messageViewControllerFrom:controller];

    XCTAssertEqualObjects([viewController message], message2);
}

#if TARGET_OS_IOS /** The concept of orientation is not on tvOS **/
/**
 * When a message format supports both landscape and portrait we want to make sure that if the
 * device orientation is portrait the message displayed is the portrait one; and when we dismiss the message,
 * rotate the device and show the same message again it should show in landscape format
 */
- (void)testMessageAppearsWithCorrectFormat {
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];

    id swrveMock = [self swrveMockWithTestJson:@"campaignsBothOrientations"];
    SwrveMessageController *controller = [swrveMock messaging];

    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    SwrveMessagePageViewController *viewController = [messageViewController.viewControllers firstObject];
    [viewController viewDidAppear:NO];

    XCTAssertEqual([[messageViewController currentMessageFormat] orientation], SWRVE_ORIENTATION_PORTRAIT);

    // Press dismiss button
    UISwrveButton *dismissButton = [UISwrveButton new];
    [dismissButton setTag:0];
    [viewController onButtonPressed:dismissButton];
    [self waitForWindowDismissed:controller];

    // Rotate device
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationLandscapeRight];

    // Show same message again
    [controller showMessage:message];

    // Ensure message is now shown in landscape format
    XCTAssertEqual([[messageViewController currentMessageFormat] orientation], SWRVE_ORIENTATION_LANDSCAPE);

    // Change orientation back to original
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];
}

/**
 * When a message is shown that supports both landscape and portrait and the device is
 * rotated, the message should still be there after rotation but with the new orientation format
 */
- (void)testMessageReappearsWithDifferentFormat {
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];

    id swrveMock = [self swrveMockWithTestJson:@"campaignsBothOrientations"];
    SwrveMessageController *controller = [swrveMock messaging];

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *viewController = [self messageViewControllerFrom:controller];
    [viewController viewDidAppear:NO];

    XCTAssertNotNil([viewController message]);
    XCTAssertEqual([[[viewController message] messageID] intValue], 165);

    // Rotate device
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationLandscapeRight];

    [viewController viewDidAppear:NO];

    // Ensure message is now shown in landscape format
    XCTAssertNotNil([viewController message]);
    XCTAssertEqual([[[viewController message] messageID] intValue], 165);

    // Change orientation back to original
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];
}

/**
 * When a message is shown that supports only portrait  and the device is
 * rotated, the message should still be there after rotation with the same format
 */
- (void)testMessageReappearsWithSameFormat {
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];

    id swrveMock = [self swrveMockWithTestJson:@"campaignsPortraitOnly"];
    SwrveMessageController *controller = [swrveMock messaging];

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *viewController = [self messageViewControllerFrom:controller];
    [viewController viewDidAppear:NO];

    XCTAssertNotNil([viewController message]);
    XCTAssertEqual([[[viewController message] messageID] intValue], 165);

    // Rotate device
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationLandscapeRight];

    viewController = (SwrveMessageViewController*)[[controller inAppMessageWindow] rootViewController];

    // Ensure message is still shown with the same format
    XCTAssertNotNil([viewController message]);
    XCTAssertEqual([[[viewController message] messageID] intValue], 165);

    // Change orientation back to original
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];
}
#endif //TARGET_OS_IOS

/**
 * Test that setting custom action listener works
 */
- (void)testCustomActionListener {
    __block NSString *customActionResult = @"";
    __block NSString *campaignNameResult = @"";

    SwrveCustomButtonPressedCallback customCallback = ^(NSString* action, NSString *campaignName) {
        customActionResult = action;
        campaignNameResult = campaignName;
    };
    
    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.inAppMessageConfig.customButtonCallback = customCallback;
    
    id swrveMock = [self swrveMockWithTestJson:@"campaigns" withConfig:config];
    [swrveMock messaging].customButtonCallback(@"CustomAction", @"CampaignName");

    XCTAssertEqualObjects(customActionResult, @"CustomAction");
    XCTAssertEqualObjects(campaignNameResult, @"CampaignName");
}

/**
 * Test that setting dismiss action listener works
 */
- (void)testDismissActionListener {
    __block NSString *campaignSubject = @"";
    __block NSString *buttonName = @"";
    __block NSString *campaignName = @"";

    SwrveDismissButtonPressedCallback dismissCallback = ^(NSString *campaignS, NSString *buttonN, NSString *campaignN) {
        campaignSubject = campaignS;
        buttonName = buttonN;
        campaignName = campaignN;
    };
    
    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.inAppMessageConfig.dismissButtonCallback = dismissCallback;

    id swrveMock = [self swrveMockWithTestJson:@"campaigns" withConfig:config];
    [swrveMock messaging].dismissButtonCallback(@"campaignSubject", @"btnClose", @"campaignName");

    XCTAssertEqualObjects(campaignSubject, @"campaignSubject");
    XCTAssertEqualObjects(buttonName, @"btnClose");
    XCTAssertEqualObjects(campaignName, @"campaignName");
}

/**
 * Test that setting personalized text button action listener works
 */
- (void)testClipboardButtonActionListener {
    __block NSString *clipboardButtonProcessedTextResult = @"";
    SwrveClipboardButtonPressedCallback clipboardButtonPressedCallback = ^(NSString* processedText) {
        clipboardButtonProcessedTextResult = processedText;
    };
    
    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.inAppMessageConfig.clipboardButtonCallback = clipboardButtonPressedCallback;
    
    id swrveMock = [self swrveMockWithTestJson:@"campaigns" withConfig:config];
    [swrveMock messaging].clipboardButtonCallback(@"ProcessedText");

    XCTAssertEqualObjects(clipboardButtonProcessedTextResult, @"ProcessedText");
}


/**
 * Test that setting message personalization listener works
 */
- (void)testMessagePersonalizationListener {
    __block NSDictionary* messagePersonalizationResult = nil;
    SwrveMessagePersonalizationCallback personalizationCallback = ^(NSDictionary* eventPayload) {
        messagePersonalizationResult = eventPayload;
        return messagePersonalizationResult;
    };
    
    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.inAppMessageConfig.personalizationCallback = personalizationCallback;
    
    id swrveMock = [self swrveMockWithTestJson:@"campaigns" withConfig:config];
    NSDictionary *result = [swrveMock messaging].personalizationCallback(@{@"test": @"passed"});
    
    XCTAssertEqualObjects([result objectForKey:@"test"], @"passed");
}

/**
 * Check that a campaign which should be triggered at session start gets displayed
 */
// KEV to fix
//- (void)testAutomaticDisplayAtSessionStart {
//    SwrveConfig *config = [[SwrveConfig alloc] init];
//    id swrveMock = [self swrveMockWithTestJson:@"campaignsAutoshow" withConfig:config];
//
//    SwrveMessageController *controller = [swrveMock messaging];
//
//    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
//    [testDelegate setController:controller];
//    [controller setShowMessageDelegate:testDelegate];
//
//    XCTestExpectation* messageShownExpectation = [self expectationWithDescription:@"Message shown"];
//    testDelegate.messageShownExpectation = messageShownExpectation;
//    [swrveMock appDidBecomeActive:nil];
//
//
//
//
//    [controller dismissMessageWindow];
//
//
//    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
//        if (error) {
//            XCTFail(@"No message shown");
//        }
//    }];
//
//    XCTAssertNotNil([testDelegate messageShown]);
//    XCTAssertEqual([[[testDelegate messageShown] messageID] intValue], 165);
//
//    [swrveMock suspend:YES];
//    [swrveMock shutdown];
//    [swrveMock stopMocking];
//    swrveMock = [self swrveMockWithTestJson:@"campaignsAutoshow" withConfig:config];
//
//    controller = [swrveMock messaging];
//
//    testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
//    [testDelegate setController:controller];
//    [controller setShowMessageDelegate:testDelegate];
//
//    [swrveMock appDidBecomeActive:nil];
//
//    // Ensure that the Campaign State is still present and operational
//    SwrveCampaign *campaign = [[controller campaigns] firstObject];
//    XCTAssertEqual(campaign.ID, 102);
//    XCTAssertEqual(campaign.state.next, 0);
//    XCTAssertEqual(campaign.state.impressions, 1);
//
//    [controller dismissMessageWindow];
//
//    // Ensure that there was no message the second time around
//    XCTAssertNil([testDelegate messageShown]);
//}

/**
 * Check that max delay for auto show messages can be configured
 */
- (void)testAutomaticDisplayAtSessionStartMaxDelay {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];

    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    XCTAssertTrue([[swrveMock messaging] autoShowMessagesEnabled]);

    // Default delay is 5 seconds
    XCTAssertEqual([[swrveMock config] autoShowMessagesMaxDelay], 5000);

    // Set a custom delay low here for speed of testing
    [swrveMock shutdown];
    [config setAutoShowMessagesMaxDelay:2000];
    
    swrveMock = [self swrveMockWithTestJson:@"campaigns" withConfig:config];
    [swrveMock appDidBecomeActive:nil];
    XCTAssertTrue([[swrveMock messaging] autoShowMessagesEnabled]);
    XCTAssertEqual([[swrveMock config] autoShowMessagesMaxDelay], 2000);

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    XCTAssertTrue([[swrveMock messaging] autoShowMessagesEnabled]);

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
    XCTAssertFalse([[swrveMock messaging] autoShowMessagesEnabled]);
}

- (void)testCampaignStatesCannotGoOverLimit {
    int impressionAmount = 0;
    NSMutableArray *allEventsBuffer = [NSMutableArray new];
    
    //max impressions rule set to 5
    while(impressionAmount < 5) {
        id swrveMock = [self swrveMockWithTestJson:@"campaignSingle"];
        SwrveMessageController *controller = [swrveMock messaging];

        XCTAssertEqual([[controller campaigns] count], 1);
        SwrveCampaign* campaign = [[controller campaigns] firstObject];

        XCTAssertEqual(campaign.ID, 102);
        XCTAssertEqual(campaign.state.impressions, impressionAmount);

        [swrveMock currencyGiven:@"USD" givenAmount:123.54];

        SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
        XCTAssertNotNil(messageViewController);
        SwrveMessage *messageShown = messageViewController.message;
        XCTAssertNotNil(messageShown);
        [messageViewController viewDidAppear:NO];

        // Make sure first message is shown, and impressions have been updated
        SwrveCampaign* campaignShown = [messageShown campaign];
        XCTAssertEqual(campaignShown.ID, 102);

        //increment the impressionAmount everytime we've shown the message
        impressionAmount++;

        XCTAssertEqual(campaignShown.state.impressions, impressionAmount);

        // Fake that there were no campaigns before saving (can cause bugs if states are not saved properly)
        [swrveMock messaging].campaigns = [NSMutableArray new];

        [allEventsBuffer addObjectsFromArray:[swrveMock eventBuffer]];

        // Restart, and check campaign settings haven't been reset
        [swrveMock suspend:YES];
        [swrveMock shutdown];

        swrveMock = [self swrveMockWithTestJson:@"campaignSingle"];
        controller = [swrveMock messaging];
    
        XCTAssertEqual([[controller campaigns] count], 1);
        campaign = [[controller campaigns] firstObject];

        XCTAssertEqual(campaign.ID, 102);
        XCTAssertEqual(campaign.state.impressions,impressionAmount);

        [allEventsBuffer addObjectsFromArray:[swrveMock eventBuffer]];

        [swrveMock suspend:YES];
        [swrveMock shutdown];
    }

    id swrveMock = [self swrveMockWithTestJson:@"campaignSingle"];
    SwrveMessageController *controller = [swrveMock messaging];

    XCTAssertEqual([[controller campaigns] count], 1);
    SwrveCampaign *campaign = [[controller campaigns] firstObject];

    XCTAssertEqual(campaign.ID, 102);
    XCTAssertEqual(campaign.state.impressions, impressionAmount);
    [swrveMock currencyGiven:@"USD" givenAmount:123.54];

    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    XCTAssertNil(messageViewController);

    [swrveMock eventBuffer];

    [allEventsBuffer addObjectsFromArray:[swrveMock eventBuffer]];
    NSLog(@"I HAZ A BUFFA");
}

/**
 * Test configurable color from config
 */
- (void)testDefaultBackgroundColor {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    SwrveInAppMessageConfig *inAppConfig = [SwrveInAppMessageConfig new];
    inAppConfig.personalizationFont = [UIFont fontWithName:@"Papyrus" size:1];
    inAppConfig.personalizationBackgroundColor = [UIColor blackColor];
    inAppConfig.personalizationForegroundColor = [UIColor blueColor];
    inAppConfig.backgroundColor = [UIColor redColor];
    config.inAppMessageConfig = inAppConfig;

    id swrveMock = [self swrveMockWithTestJson:@"campaigns" withConfig:config];
    SwrveMessageController *controller = [swrveMock messaging];
    
    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *viewController = [self messageViewControllerFrom:controller];
    [viewController viewDidAppear:NO];

    XCTAssertEqualObjects(viewController.view.backgroundColor, [UIColor redColor]);
}

/**
 * Test default colors from config
 */
 // TODO come back to this test - seems a bit strange?!
- (void)testDefaultColors {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.inAppMessageConfig.backgroundColor = [UIColor redColor];

    id swrveMock = [self swrveMockWithTestJson:@"campaigns" withConfig:config];
    SwrveMessageController *controller = [swrveMock messaging];

    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *viewController = [self messageViewControllerFrom:controller];
    [viewController viewDidAppear:NO];

    XCTAssertEqualObjects(viewController.messageController.inAppMessageConfig.personalizationForegroundColor, [UIColor blackColor]);
    XCTAssertEqualObjects(viewController.messageController.inAppMessageConfig.personalizationBackgroundColor, [UIColor clearColor]);
    XCTAssertEqualObjects(viewController.messageController.inAppMessageConfig.personalizationFont, [UIFont systemFontOfSize:0]);
}

/**
 * Test configurable personalization colors from config
 */
- (void)testPersonalizationConfig {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    SwrveInAppMessageConfig *inAppConfig = [SwrveInAppMessageConfig new];
    inAppConfig.backgroundColor = [UIColor redColor];
    inAppConfig.personalizationFont = [UIFont italicSystemFontOfSize:1];
    inAppConfig.personalizationBackgroundColor = [UIColor blackColor];
    inAppConfig.personalizationForegroundColor = [UIColor blueColor];
    config.inAppMessageConfig = inAppConfig;

    id swrveMock = [self swrveMockWithTestJson:@"campaignsPersonalization" withConfig:config];
    SwrveMessageController *controller = [swrveMock messaging];

    // mock date that lies within the start and end time of the campaign in the test json file campaignsMessageCenter
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);

    NSDictionary *validPersonalization = @{@"test_cp": @"test_value",
            @"test_custom":@"urlprocessed",
            @"test_display": @"display"};
    SwrveCampaign *campaign = [[controller messageCenterCampaignsWithPersonalization:validPersonalization] objectAtIndex:0];
    [controller showMessageCenterCampaign:campaign withPersonalization: validPersonalization];
    SwrveMessageViewController *viewController = [self messageViewControllerFrom:controller];
    [viewController viewDidAppear:NO];

    XCTAssertEqualObjects(viewController.view.backgroundColor, [UIColor redColor]);
    XCTAssertEqualObjects(viewController.messageController.inAppMessageConfig.personalizationForegroundColor, [UIColor blueColor]);
    XCTAssertEqualObjects(viewController.messageController.inAppMessageConfig.personalizationBackgroundColor, [UIColor blackColor]);
    XCTAssertEqualObjects(viewController.messageController.inAppMessageConfig.personalizationFont, [UIFont italicSystemFontOfSize:1]);
}

/**
 * Test configurable RRGGBB color from template
 */
- (void)testBackgroundColorFromTemplateRRGGBB {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.inAppMessageConfig.backgroundColor = [UIColor blueColor];

    id swrveMock = [self swrveMockWithTestJson:@"campaignsRRGGBB" withConfig:config];
    SwrveMessageController *controller = [swrveMock messaging];

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *viewController = [self messageViewControllerFrom:controller];
    [viewController viewDidAppear:NO];

    XCTAssertEqualObjects(viewController.view.backgroundColor, [UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:1.0f]);
}

/**
 * Test configurable AARRGGBB color from template
 */
- (void)testBackgroundColorFromTemplateAARRGGBB {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.inAppMessageConfig.backgroundColor = [UIColor blueColor];

    id swrveMock = [self swrveMockWithTestJson:@"campaignsAARRGGBB" withConfig:config];
    SwrveMessageController *controller = [swrveMock messaging];

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *viewController = [self messageViewControllerFrom:controller];
    [viewController viewDidAppear:NO];

    NSLog(@"color: %@",viewController.view.backgroundColor);
    XCTAssertEqualObjects(viewController.view.backgroundColor, [UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:0.0f]);
}

/**
 * Test that messages can be displayed if all assets were downloaded beforehand
 */
- (void)testMessageDisplaysWithAllAssets {
    id swrveMock = [self swrveMockWithTestJson:@"campaignsAARRGGBB"];
    [swrveMock currencyGiven:@"gold" givenAmount:2];

    // Assets ready, should display message
    UIWindow *window = [swrveMock messaging].inAppMessageWindow;
    XCTAssertNotNil(window);
}

/**
 * Test that message does not display if assets haven't been downloaded yet, and are put in the queue
 */
- (void)testMessageDoesNotDisplayWithoutAssets {
    [SwrveTestHelper removeAssets:[SwrveTestMessageController testJSONAssets]];
    
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
    
    // disable callback on restclient so assetsCurrentlyDownloading is not cleared.
    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
    id mockRestClient = OCMPartialMock(restClient);
    OCMStub([mockRestClient sendHttpRequest:OCMOCK_ANY
                          completionHandler:OCMOCK_ANY]).andDo(nil);
    
    OCMStub([swrveMock initSwrveRestClient:60 urlSssionDelegate:nil]).andDo(^(NSInvocation *invocation) {
        swrve.restClient = mockRestClient;
    });
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"someAPIKey"];
#pragma clang diagnostic pop
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsAARRGGBB" ofType:@"json"];
    NSData *mockJsonData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockJsonData options:0 error:nil];
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO];

    [swrveMock currencyGiven:@"gold" givenAmount:2];
    
    // Assets were not ready, should not display message
    UIWindow* window = [swrveMock messaging].inAppMessageWindow;
    XCTAssertNil(window);

    SwrveAssetsManager *assetsManager = [[swrveMock messaging] assetsManager];
    XCTAssertTrue([[assetsManager valueForKey:@"assetsCurrentlyDownloading"] count] > 0);
}

/**
 * Test that assets are requeued on app resume
 */
//KEV fix
- (void)testAssetsAreRequeuedOnAppResume {
    [SwrveTestHelper removeAssets:[SwrveTestMessageController testJSONAssets]];
    
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
    
    // disable callback on restclient so assetsCurrentlyDownloading is not cleared.
    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
    id mockRestClient = OCMPartialMock(restClient);
    OCMStub([mockRestClient sendHttpRequest:OCMOCK_ANY
                          completionHandler:OCMOCK_ANY]).andDo(nil);
    
    OCMStub([swrveMock initSwrveRestClient:60 urlSssionDelegate:nil]).andDo(^(NSInvocation *invocation) {
        swrve.restClient = mockRestClient;
    });
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"someAPIKey"];
#pragma clang diagnostic pop
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsAARRGGBB" ofType:@"json"];
    NSData *mockJsonData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockJsonData options:0 error:nil];
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:NO];

    SwrveMessageController *controller = [swrveMock messaging];
    [swrveMock currencyGiven:@"gold" givenAmount:2];

    // Assets were not ready, should not display message
    UIWindow* window = controller.inAppMessageWindow;
    XCTAssertNil(window);
    XCTAssertEqual([[[controller assetsManager] valueForKey:@"assetsCurrentlyDownloading"] count], 3);

    // Artificially remove assets from the currently downloading assets
    [[[controller assetsManager] valueForKey:@"assetsCurrentlyDownloading"] removeAllObjects];

    // Emulate an app resume and the presence of one asset
    [SwrveTestHelper createDummyAssets:@[@"97c5df26c8e8fcff8dbda7e662d4272a6a94af7e"]];
    [controller appDidBecomeActive];

    [swrveMock currencyGiven:@"gold" givenAmount:2];
    window = controller.inAppMessageWindow;
    XCTAssertNil(window);
    XCTAssertEqual([[[controller assetsManager] valueForKey:@"assetsCurrentlyDownloading"] count], 2);
}

- (void)testMessageReturned {
    id swrveMock = [self swrveMockWithTestJson:@"campaignsDelay"];
    SwrveMessageController *controller = [swrveMock messaging];
    
    self.swrveNowDate = [NSDate dateWithTimeInterval:130 sinceDate:self.swrveNowDate];
    
    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);

    NSArray *eventsBuffer = [swrveMock eventBuffer];
    XCTAssertEqual([eventsBuffer count], 0);
}

#pragma mark - event trigger checks

- (void)testCustomerEventsTriggersMessages {
    SKPayment *dummyPayment =  OCMClassMock([SKPayment class]);
    OCMStub([dummyPayment productIdentifier]).andReturn(@"my_product_id");
    OCMStub([dummyPayment quantity]).andReturn(@8);

    SKPaymentTransaction *dummyTransaction =  OCMClassMock([SKPaymentTransaction class]);
    OCMStub([dummyTransaction payment]).andReturn(dummyPayment);
    OCMStub([dummyTransaction transactionState]).andReturn(SKPaymentTransactionStatePurchased);

    NSDecimalNumber* price = [[NSDecimalNumber alloc] initWithDouble:9.99];
    SKProduct *dummyProduct = OCMClassMock([SKProduct class]);
    OCMStub([dummyProduct price]).andReturn(price);
    
    NSDictionary *localeComponents = [NSDictionary dictionaryWithObject:@"EUR" forKey:NSLocaleCurrencyCode];
    NSString *localeIdentifier = [NSLocale localeIdentifierFromComponents:localeComponents];
    NSLocale *localeForDefaultCurrency = [[NSLocale alloc] initWithLocaleIdentifier:localeIdentifier];
    OCMStub([dummyProduct priceLocale]).andReturn(localeForDefaultCurrency);
    
    id swrveMock = [self swrveMockWithTestJson:@"campaignsDelay"];
    
    id receiptProviderPartialMock = OCMPartialMock([swrveMock receiptProvider]);
    OCMStub([receiptProviderPartialMock readMainBundleAppStoreReceipt]).andReturn([@"fake_receipt" dataUsingEncoding:NSUTF8StringEncoding]);
    OCMStub([swrveMock receiptProvider]).andReturn(receiptProviderPartialMock);

    // Check these events could trigger IAM/Conversations
    OCMExpect([swrveMock eventInternal:@"custom_event" payload:nil triggerCallback:true]);
    OCMExpect([swrveMock queueEvent:@"purchase" data:OCMOCK_ANY triggerCallback:true]);
    OCMExpect([swrveMock queueEvent:@"iap" data:OCMOCK_ANY triggerCallback:true]);
    OCMExpect([swrveMock queueEvent:@"iap" data:OCMOCK_ANY triggerCallback:true]);
    OCMExpect([swrveMock queueEvent:@"currency_given" data:OCMOCK_ANY triggerCallback:true]);

    [swrveMock event:@"custom_event"];
    [swrveMock purchaseItem:@"item" currency:@"euro" cost:1 quantity:2];
    [swrveMock iap:dummyTransaction product:dummyProduct];
    [swrveMock unvalidatedIap:nil localCost:20 localCurrency:@"gems" productId:@"id" productIdQuantity:1];
    [swrveMock currencyGiven:@"gold" givenAmount:20];

    OCMVerifyAll(swrveMock);
    [swrveMock stopMocking];
}

- (void)testMessageForEventTriggerAsQAUser {
    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    SwrveMessageController *controller = [swrveMock messaging];
    
    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;
    
    // define as QAUser
    id swrveQAMock = OCMPartialMock([SwrveQA sharedInstance]);
    [swrveQAMock updateQAUser:@{@"logging": @YES, @"reset_device_state": @YES} andSessionToken:@"aSessinToken"];

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);

    OCMVerify([swrveQAMock messageCampaignTriggered:@"Swrve.currency_given" eventPayload:nil displayed:YES campaignInfoDict:OCMOCK_ANY]);
}

-(void)testFilterMessageCapabilityRequestable {
    id swrveMock = [self swrveMockWithTestJson:@"iamCapabilites"];
    SwrveMessageController *controller = [swrveMock messaging];

    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"eventRequestable"];
    XCTAssertNotNil(message);
        
    OCMVerify([testCapabilitiesDelegateMock canRequestCapability:@"swrve.contacts"]);
}

-(void)testFilterMessageCapabilityNotRequestable {
    id swrveMock = [self swrveMockWithTestJson:@"iamCapabilites"];
    SwrveMessageController *controller = [swrveMock messaging];
    
    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"eventNotRequestable"];
    XCTAssertNil(message);
    
    OCMVerify([testCapabilitiesDelegateMock canRequestCapability:@"swrve.contacts"]);
    OCMVerify([testCapabilitiesDelegateMock canRequestCapability:@"swrve.photo"]);
}

- (void)testFilterCampaignFromMessageCenterNoCapabilityDelegateSet {
    id swrveMock = [self swrveMockWithTestJson:@"iamCapabilites"];
    SwrveMessageController *controller = [swrveMock messaging];

    //Check campaign has been filtered out of messageCenterCampaigns
    NSArray *messageCenterCampaigns = [controller messageCenterCampaigns];
    XCTAssertEqual([messageCenterCampaigns count], 0);
    XCTAssertEqual([[controller campaigns] count], 3);
}

- (void)testRetrievePersonalizationProperties {
    SwrveConfig *config = [SwrveConfig new];
    config.inAppMessageConfig.personalizationCallback = ^NSDictionary *(NSDictionary *eventPayload) {
        return @{@"key1": @"value1", @"user.test2": @"changed_value"}; //user.test2 value should be overriding the rtup
    };
    
    Swrve *swrveMock = [SwrveTestHelper initializeSwrveWithRealTimeUserPropertiesFile:@"realTimeUserProperties" andConfig:config];
    SwrveMessageController *controller = [swrveMock messaging];

    NSDictionary *expectedDictionary = @{@"user.test1": @"rtup_value1", @"user.test2": @"changed_value", @"key1": @"value1"};
    NSDictionary *resultDictionary = [controller retrievePersonalizationProperties:nil];
    
    XCTAssertEqualObjects(expectedDictionary, resultDictionary);
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

/**
 * Test message window dismissed when stop tracking is called.
 */
- (void)testMessageWindowDismissedWhenStopCalled {
    id swrveMock = [self swrveMockWithTestJson:@"campaignsAARRGGBB"];
    [swrveMock currencyGiven:@"gold" givenAmount:2];

    // Assets ready, should display message
    UIWindow *window = [swrveMock messaging].inAppMessageWindow;
    XCTAssertNotNil(window);
    
    [swrveMock stopTracking];
    
    window = [swrveMock messaging].inAppMessageWindow;
    XCTAssertNil(window);
}

- (void)testMutliLineFormatTextview {
    // No scrolling so no accesability and normal system font applied
    SwrveMessageViewController *messageViewController = [[SwrveMessageViewController alloc] init];
    NSDictionary *format = @{
        @"images" : @[
                @{
                @"w" : @{
                    @"type": @"number",
                    @"value": @846
                },
                @"h": @{
                    @"type": @"number",
                    @"value": @1335
                },
                @"multiline_text": @{
                    @"value": @"This is the expected text",
                    @"h_align": @"CENTER",
                    @"font_size": @18,
                    @"scrollable": @0
                }
                }
            ],
        @"buttons": @[],
        @"name": @"[0.467005076142132]all - portrait",
        @"orientation": @"portrait",
        @"language": @"*",
        @"scaled_by": @0.467005076142132,
        @"scaled_from": @"all - portrait",
        @"scale": @1,
        @"size": @{
            @"w": @{
                @"type": @"number",
                @"value": @828
            },
            @"h": @{
                @"type": @"number",
                @"value": @1472
            }
        }
    };

    SwrveMessageFormat *messageFormat = [[SwrveMessageFormat alloc]initFromJson:format campaignId:0 messageId:0 appStoreURLs:nil];
    // dont use calibration for this test
    messageFormat.calibration = [[SwrveCalibration alloc]initWithDictionary:@{
        @"width" : @0,
        @"height" : @0,
        @"base_font_size" : @0,
        @"text" : @""

    }];
    SwrveInAppMessageConfig *config = [SwrveInAppMessageConfig new];
    config.personalizationFont = [UIFont systemFontOfSize:18];
    config.personalizationForegroundColor = [UIColor redColor];
    config.personalizationBackgroundColor = [UIColor yellowColor];

    SwrveMessageUIView *view = [[SwrveMessageUIView alloc] initWithMessageFormat:messageFormat
                                                                          pageId:[NSNumber numberWithInt:0]
                                                                      parentSize:CGSizeMake(1000, 2000)
                                                                      controller:nil
                                                                 personalization:nil
                                                                     inAppConfig:config];

    NSString *expectedText = @"This is the expected text";
    NSString *text = nil;
    
    bool expectedScrollable = false;
    bool scrollable = false;
    
    NSTextAlignment expectedAlignment = NSTextAlignmentCenter;
    NSTextAlignment alignment = NSTextAlignmentLeft;
    
    UIFont *expectedFont = [UIFont systemFontOfSize:18];
    UIFont *font = [UIFont systemFontOfSize:12];
    
    UIColor *expectedForegroundColor = [UIColor redColor];
    UIColor *foregroundColor = [UIColor blackColor];
    
    UIColor *expectedBackgroundColor = [UIColor yellowColor];
    UIColor *backgroundColor = [UIColor blackColor];
    
    for (UIView *item in view.subviews){
          if ([item isKindOfClass:[SwrveTextView class]]) {
              SwrveTextView * tv = (SwrveTextView *)item;
              text = tv.text;
              scrollable = tv.isScrollEnabled;
              alignment = tv.textAlignment;
              font = tv.font;
              foregroundColor = tv.textColor;
              backgroundColor = tv.backgroundColor;
          }
    };
       
    XCTAssertEqualObjects(expectedText, text);
    XCTAssertEqual(expectedScrollable, scrollable);
    XCTAssertEqual(expectedAlignment, alignment);
    XCTAssertEqual([expectedFont pointSize], [font pointSize]);
    XCTAssertEqualObjects(expectedFont, font);
    XCTAssertEqualObjects(expectedForegroundColor, foregroundColor);
    XCTAssertEqualObjects(expectedBackgroundColor, backgroundColor);
}

- (void)testMutliLineFormatTextviewAccessabilityFont {
    // Use scrolling so accesability font applied
    SwrveMessageViewController *messageViewController = [[SwrveMessageViewController alloc] init];
    NSDictionary *format = @{
        @"images" : @[
                @{
                @"w" : @{
                    @"type": @"number",
                    @"value": @846
                },
                @"h": @{
                    @"type": @"number",
                    @"value": @1335
                },
                @"multiline_text": @{
                    @"value": @"This is the expected text",
                    @"h_align": @"CENTER",
                    @"font_size": @18,
                    @"scrollable": @1
                }
                }
            ],
        @"buttons": @[],
        @"name": @"[0.467005076142132]all - portrait",
        @"orientation": @"portrait",
        @"language": @"*",
        @"scaled_by": @0.467005076142132,
        @"scaled_from": @"all - portrait",
        @"scale": @1,
        @"size": @{
            @"w": @{
                @"type": @"number",
                @"value": @828
            },
            @"h": @{
                @"type": @"number",
                @"value": @1472
            }
        }
    };

    SwrveMessageFormat *messageFormat = [[SwrveMessageFormat alloc]initFromJson:format campaignId:0 messageId:0 appStoreURLs:nil];
    // dont use calibration for this test
    messageFormat.calibration = [[SwrveCalibration alloc]initWithDictionary:@{
        @"width" : @0,
        @"height" : @0,
        @"base_font_size" : @0,
        @"text" : @""

    }];
    SwrveInAppMessageConfig *config = [SwrveInAppMessageConfig new];
    config.personalizationFont = [UIFont systemFontOfSize:18];
    config.personalizationForegroundColor = [UIColor redColor];
    config.personalizationBackgroundColor = [UIColor yellowColor];

    SwrveMessageUIView *view = [[SwrveMessageUIView alloc] initWithMessageFormat:messageFormat
                                                                          pageId:[NSNumber numberWithInt:0]
                                                                      parentSize:CGSizeMake(1000, 2000)
                                                                      controller:nil
                                                                 personalization:nil
                                                                     inAppConfig:config];

    NSString *expectedText = @"This is the expected text";
    NSString *text = nil;
    
    bool expectedScrollable = false;
#if TARGET_OS_IOS
    expectedScrollable = true;
#endif
    bool scrollable = false;
    
    NSTextAlignment expectedAlignment = NSTextAlignmentCenter;
    NSTextAlignment alignment = NSTextAlignmentLeft;
    
    UIFont *expectedFont = nil;
    if (@available(iOS 11.0,tvOS 11.0, *)) {
#if TARGET_OS_IOS
        UIFontMetrics *metircs = [UIFontMetrics metricsForTextStyle:UIFontTextStyleBody];
        expectedFont = [metircs scaledFontForFont:[UIFont systemFontOfSize:18]];
#else
        expectedFont = [UIFont systemFontOfSize:18];
#endif

    } else {
        expectedFont = [UIFont systemFontOfSize:18];
    }
   

    UIFont *font = [UIFont systemFontOfSize:12];
    
    UIColor *expectedForegroundColor = [UIColor redColor];
    UIColor *foregroundColor = [UIColor blackColor];
    
    UIColor *expectedBackgroundColor = [UIColor yellowColor];
    UIColor *backgroundColor = [UIColor blackColor];
    
    for (UIView *item in view.subviews){
          if ([item isKindOfClass:[SwrveTextView class]]) {
              SwrveTextView * tv = (SwrveTextView *)item;
              text = tv.text;
              scrollable = tv.isScrollEnabled;
              alignment = tv.textAlignment;
              font = tv.font;
              foregroundColor = tv.textColor;
              backgroundColor = tv.backgroundColor;
          }
    };
       
    XCTAssertEqualObjects(expectedText, text);
    XCTAssertEqual(expectedScrollable, scrollable);
    XCTAssertEqual(expectedAlignment, alignment);
    XCTAssertEqual([expectedFont pointSize], [font pointSize]);
    XCTAssertEqualObjects(expectedFont, font);
    XCTAssertEqualObjects(expectedForegroundColor, foregroundColor);
    XCTAssertEqualObjects(expectedBackgroundColor, backgroundColor);
}

- (void)testMutliLineCalibration {
    float sample_scaled_by = 0.467005076142132;
    float sample_calibratedHeight = 5000 * sample_scaled_by;
    float sample_calibratedWidth = 500 * sample_scaled_by;
    float sample_json_size = 18;
    float sample_base_size = 20;
    NSString *sample_calibratedtext = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    float sample_multilineSize_Height = 800;
    float sample_multilineSize_Width = 1500;
    
    float expected_scaled_point_size = 41;
    
    SwrveMessageViewController *messageViewController = [[SwrveMessageViewController alloc] init];
    NSDictionary *format = @{
        @"calibration" : @{
            @"width" : [NSNumber numberWithFloat:sample_calibratedHeight],
            @"height" : [NSNumber numberWithFloat:sample_calibratedWidth],
            @"base_font_size" : [NSNumber numberWithFloat:sample_base_size],
            @"text" : sample_calibratedtext

        },
        @"images" : @[
                @{
                @"w" : @{
                    @"type": @"number",
                    @"value": [NSNumber numberWithFloat:sample_multilineSize_Width]
                },
                @"h": @{
                    @"type": @"number",
                    @"value" : [NSNumber numberWithFloat:sample_multilineSize_Height]
                },
                @"multiline_text": @{
                    @"value": @"This is the expected text",
                    @"h_align": @"CENTER",
                    @"font_size": [NSNumber numberWithFloat:sample_json_size],
                    @"scrollable": @1
                }
                }
            ],
        @"buttons": @[],
        @"name": @"[0.467005076142132]all - portrait",
        @"orientation": @"portrait",
        @"language": @"*",
        @"scaled_from": @"all - portrait",
        @"scaled_by": @1,
        @"scale": @1,
        @"size": @{
            @"w": @{
                @"type": @"number",
                @"value": [NSNumber numberWithFloat:sample_multilineSize_Width]
            },
            @"h": @{
                @"type": @"number",
                @"value": [NSNumber numberWithFloat:sample_multilineSize_Height]
            }
        }
    };

    SwrveMessageFormat *messageFormat = [[SwrveMessageFormat alloc]initFromJson:format campaignId:0 messageId:0 appStoreURLs:nil];
    SwrveInAppMessageConfig *config = [SwrveInAppMessageConfig new];
    config.personalizationFont = [UIFont systemFontOfSize:18];
    config.personalizationForegroundColor = [UIColor redColor];
    config.personalizationBackgroundColor = [UIColor yellowColor];

    SwrveMessageUIView *view = [[SwrveMessageUIView alloc] initWithMessageFormat:messageFormat
                                                                          pageId:[NSNumber numberWithInt:0]
                                                                      parentSize:CGSizeMake(1000, 2000)
                                                                      controller:nil
                                                                 personalization:nil
                                                                     inAppConfig:config];
    
    UIFont *expectedFont = [UIFont systemFontOfSize:expected_scaled_point_size];
    UIFont *font = [UIFont systemFontOfSize:12];
    
    for (UIView *item in view.subviews){
          if ([item isKindOfClass:[SwrveTextView class]]) {
              SwrveTextView * tv = (SwrveTextView *)item;
              font = tv.font;
          }
    };
       
    XCTAssertEqualWithAccuracy([expectedFont pointSize], [font pointSize], 0.5);
}

- (void)testMultiLineAssetSystemFontDownload {
    NSDictionary *messageDictStripped =
@{
     @"template": @{
         @"formats": @[
             @{
             @"images": @[
                 @{
                     @"multiline_text": @{
                         @"font_file": @"_system_font_",
                     }
                 },
                 @{
                     @"multiline_text": @{
                         @"font_file": @"SomeNativeFont",
                     }
                 }
             ]
         }]
     }
};
    
    SwrveMessage *message = [[SwrveMessage alloc] initWithDictionary:messageDictStripped forCampaign:nil forController:nil];

    NSSet *assets = [NSSet setWithArray:@[]];
    XCTAssertFalse([message assetsReady:assets withPersonalization:nil]); // missing SomeNativeFont
    
    assets = [NSSet setWithArray:@[@"_system_font_"]];
    XCTAssertFalse([message assetsReady:assets withPersonalization:nil]); // missing SomeNativeFont
    
    assets = [NSSet setWithArray:@[@"SomeNativeFont"]];
    XCTAssertTrue([message assetsReady:assets withPersonalization:nil]); // _system_font_ not needed
    
    assets = [NSSet setWithArray:@[@"_system_font_", @"SomeNativeFont"]];
    XCTAssertTrue([message assetsReady:assets withPersonalization:nil]);
}

- (void)testAccessibilityText {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsAccess" ofType:@"json"];
    NSData *mockJsonData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockJsonData options:0 error:nil];
    
    SwrveMessage *message = [[SwrveMessage alloc] initWithDictionary:jsonDict forCampaign:nil forController:nil];
    SwrveMessageFormat *messageFormat = message.formats[0];
    
    SwrveMessageUIView *view = [[SwrveMessageUIView alloc] initWithMessageFormat:messageFormat
                                                                          pageId:[NSNumber numberWithInt:0]
                                                                      parentSize:CGSizeMake(1000, 2000)
                                                                      controller:nil
                                                                 personalization:@{@"test_1": @"TEST123",
                                                                                   @"user": @"Jose"}
                                                                     inAppConfig:[SwrveInAppMessageConfig new]];

    UIView *background = view.subviews[0];
    XCTAssertEqualObjects(@"Decorative Purple Background personalized", background.accessibilityLabel);
    XCTAssertTrue(background.isAccessibilityElement);
    
    // for UITextview, VO will automaticaelly read out the text so no need to set accessibilityLabel
    UIView *swrveTextView1 = view.subviews[1];
    XCTAssertEqualObjects(nil, swrveTextView1.accessibilityLabel);
    XCTAssertTrue(swrveTextView1.isAccessibilityElement);
    
    UIView *swrveTextView2 = view.subviews[2];
    XCTAssertEqualObjects(nil, swrveTextView2.accessibilityLabel);
    XCTAssertTrue(swrveTextView2.isAccessibilityElement);
    
    UIView *swrveTextImageView = view.subviews[3];
    XCTAssertEqualObjects(@"Copy code to clipboard 01234566789", swrveTextImageView.accessibilityLabel);
    XCTAssertTrue(swrveTextImageView.isAccessibilityElement);
    
    UIView *swrveTextButtonView = view.subviews[4];
    XCTAssertEqualObjects(@"Dismiss Message Jose", swrveTextButtonView.accessibilityLabel);
    XCTAssertTrue(swrveTextImageView.isAccessibilityElement);
    
    UIView *swrveTextImageView2 = view.subviews[5];
    XCTAssertEqualObjects(@"Launch google", swrveTextImageView2.accessibilityLabel);
    XCTAssertTrue(swrveTextImageView2.isAccessibilityElement);
    
    UIView *swrveTextImageView3 = view.subviews[6];
    XCTAssertEqualObjects(@"Text TEST123", swrveTextImageView3.accessibilityLabel);
    XCTAssertTrue(swrveTextImageView3.isAccessibilityElement);
}

- (void)testAddAccessibilityTextTraits {
    SwrveMessageUIView *view = [SwrveMessageUIView new];
    UIImageView *imageView = [UIImageView new];
    [view addAccessibilityText:nil backupText:nil withPersonalization:nil toView:imageView];
    XCTAssertFalse(imageView.isAccessibilityElement);
    XCTAssertNil(imageView.accessibilityLabel);
    XCTAssertEqualObjects(@"Image", imageView.accessibilityHint);
    XCTAssertEqual(UIAccessibilityTraitNone, imageView.accessibilityTraits);

    [view addAccessibilityText:@"some text" backupText:nil withPersonalization:nil toView:imageView];
    XCTAssertTrue(imageView.isAccessibilityElement);
    XCTAssertEqualObjects(@"some text", imageView.accessibilityLabel);
    XCTAssertEqualObjects(@"Image", imageView.accessibilityHint);
    XCTAssertEqual(UIAccessibilityTraitNone, imageView.accessibilityTraits);

    UISwrveButton *buttonView = [UISwrveButton new];
    [view addAccessibilityText:nil backupText:nil withPersonalization:nil toView:buttonView];
    XCTAssertTrue(buttonView.isAccessibilityElement);
    XCTAssertNil(buttonView.accessibilityLabel);
    XCTAssertEqualObjects(@"Button", buttonView.accessibilityHint);
    XCTAssertEqual(UIAccessibilityTraitNone, buttonView.accessibilityTraits);
    
    [view addAccessibilityText:@"some text" backupText:nil withPersonalization:nil toView:buttonView];
    XCTAssertTrue(buttonView.isAccessibilityElement);
    XCTAssertEqualObjects(@"some text", buttonView.accessibilityLabel);
    XCTAssertEqualObjects(@"Button", buttonView.accessibilityHint);
    XCTAssertEqual(UIAccessibilityTraitNone, buttonView.accessibilityTraits);
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
