#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SwrveInAppCampaign.h"
#import "SwrveEmbeddedCampaign.h"
#import "SwrveConversation.h"
#import "UISwrveButton.h"
#import "SwrveButton.h"
#import "SwrveImage.h"
#import "SwrveQA.h"
#import "SwrveTestHelper.h"
#import "SwrveUtils.h"
#import "TestShowMessageDelegateWithViewController.h"
#import "SwrveAssetsManager.h"
#import "SwrveMessageController+Private.h"
#import "SwrveLocalStorage.h"
#import "SwrveMigrationsManager.h"
#import "TestCapabilitiesDelegate.h"
#import "SwrveSDK.h"
#if TARGET_OS_IOS
#import "SwrvePermissions.h"
#import "SwrvePush.h"
#endif //TARGET_OS_IOS

@interface TestDeeplinkDelegate2:NSObject<SwrveDeeplinkDelegate>
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
- (void)initSwrveRestClient:(NSTimeInterval)timeOut;
- (int)sessionStart;
- (void)suspend:(BOOL)terminating;
- (void)appDidBecomeActive:(NSNotification *)notification;
@property (atomic) SwrveRESTClient *restClient;
@property (atomic) NSMutableArray *eventBuffer;
#if TARGET_OS_IOS
@property(atomic, readonly) SwrvePush *push;
#endif //TARGET_OS_IOS
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
- (void)showMessage:(SwrveMessage *)message queue:(bool)isQueued;
- (void)showConversation:(SwrveConversation *)conversation queue:(bool)isQueued;
- (void)dismissMessageWindow;
- (void)updateCampaigns:(NSDictionary *)campaignJson withLoadingPreviousCampaignState:(BOOL) isLoadingPreviousCampaignState;
- (SwrveBaseMessage *)baseMessageForEvent:(NSString *)eventName withPayload:(NSDictionary *)payload;
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
@property (nonatomic, retain) SwrveMessageFormat* current_format;
@end

@interface TestShowMessageDelegateNoCustomFind : NSObject<SwrveMessageDelegate>
- (void)showMessage:(SwrveMessage*)message;
- (void)showConversation:(SwrveConversation *)conversation;
@property SwrveMessage *messageShown;
@property SwrveConversation* conversationShown;
@end

@implementation TestShowMessageDelegateNoCustomFind

- (id) init {
    if (self = [super init]) {
        [self setMessageShown:nil];
    }
    return self;
}

- (void)showMessage:(SwrveMessage*)message {
    [self setMessageShown:message];
    [message wasShownToUser];
}

- (void)showConversation:(SwrveConversation *)conversation {
    [self setConversationShown:conversation];
    [conversation wasShownToUser];
}

@end

@interface TestShowTriggeredPersonalizationDelegate : NSObject<SwrveMessageDelegate>

- (void)showMessage:(SwrveMessage *)message withPersonalization:(NSDictionary *)personalization;
    @property SwrveMessage *messageShown;
@end

@implementation TestShowTriggeredPersonalizationDelegate

- (id) init {
    if (self = [super init]) {
        [self setMessageShown:nil];
    }
    return self;
}

- (void)showMessage:(SwrveMessage *)message withPersonalization:(NSDictionary *)personalization {
    [self setMessageShown:message];
    [message wasShownToUser];
}

@end

@interface TestShowIAMMessageDelegatePersonalization : NSObject<SwrveMessageDelegate>
- (void)showMessage:(SwrveMessage *)message withPersonalization:(NSDictionary *)personalization;
@property SwrveMessage *messageShown;
@end

@implementation TestShowIAMMessageDelegatePersonalization

- (id) init {
    if (self = [super init]) {
        [self setMessageShown:nil];
    }
    return self;
}

- (void)showMessage:(SwrveMessage *)message withPersonalization:(NSDictionary *)personalization {
    [self setMessageShown:message];
    [message wasShownToUser];
}

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
    
    OCMStub([swrveMock initSwrveRestClient:60]).andDo(^(NSInvocation *invocation) {
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
    [controller showMessage:message2 queue:true];
    
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
    [controller showMessage:message1  queue:true];
    
    XCTAssertEqual([[controller conversationsMessageQueue] count], 0);
    
    [controller dismissMessageWindow];
    
    XCTAssertEqual([[controller conversationsMessageQueue] count], 0);
}

- (void)testStoryboardPackaging {
    SwrveConversationItemViewController *controller = [SwrveConversationItemViewController initFromStoryboard];
    XCTAssertNotNil(controller);
}

- (void)testJsonParser {
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

    XCTAssertNotNil([format buttons]);
    XCTAssertEqual([[format buttons] count], 5);

    SwrveButton* button1 = [[format buttons] firstObject];
    XCTAssertNotNil(button1);
    XCTAssertEqualObjects([button1 image],@"8721fd4e657980a5e12d498e73aed6e6a565dfca");
    XCTAssertEqualObjects([button1 actionString], @"https://itunes.apple.com/us/app/ascension-chronicle-godslayer/id441838733?mt=8");
    XCTAssertEqualObjects([button1 message], message);
    XCTAssertEqual([button1 center].x, -200);
    XCTAssertEqual([button1 center].y, 80);
    XCTAssertEqual((int)[button1 messageID], 165);
    XCTAssertEqual((int)[button1 appID], 150);
    XCTAssertEqual([button1 actionType], kSwrveActionInstall);

    SwrveButton* button2 = [[format buttons] objectAtIndex:1];
    XCTAssertNotNil(button2);
    XCTAssertEqualObjects([button2 image], @"8721fd4e657980a5e12d498e73aed6e6a565dfca");
    XCTAssertEqualObjects([button2 actionString], @"custom_action");
    XCTAssertEqualObjects([button2 message], message);
    XCTAssertEqual([button2 center].x, 0);
    XCTAssertEqual([button2 center].y, 80);
    XCTAssertEqual((int)[button2 messageID], 165);
    XCTAssertEqual((int)[button2 appID], 0);
    XCTAssertEqual([button2 actionType], kSwrveActionCustom);

    SwrveButton* button3 = [[format buttons] objectAtIndex:2];
    XCTAssertNotNil(button3);
    XCTAssertEqualObjects([button3 image], @"97c5df26c8e8fcff8dbda7e662d4272a6a94af7e");
    XCTAssertEqualObjects([button3 actionString], @"");
    XCTAssertEqualObjects([button3 message], message);
    XCTAssertEqual([button3 center].x,932);
    XCTAssertEqual([button3 center].y, 32);
    XCTAssertEqual((int)[button3 messageID], 165);
    XCTAssertEqual((int)[button3 appID], 0);
    XCTAssertEqual([button3 actionType], kSwrveActionDismiss);
    
    SwrveButton* button4 = [[format buttons] objectAtIndex:3];
    XCTAssertNotNil(button4);
    XCTAssertEqualObjects([button4 image], @"97c5df26c8e8fcff8dbda7e662d4272a6a94af7e");
    XCTAssertEqualObjects([button4 actionString], @"${test_cp|fallback=\"test\"}");
    XCTAssertEqualObjects([button4 message], message);
    XCTAssertEqual([button4 center].x,999);
    XCTAssertEqual([button4 center].y, 23);
    XCTAssertEqual((int)[button4 messageID], 165);
    XCTAssertEqual((int)[button4 appID], 0);
    XCTAssertEqual([button4 actionType], kSwrveActionClipboard);
    
    SwrveButton* button5 = [[format buttons] lastObject];
    XCTAssertNotNil(button5);
    XCTAssertEqualObjects([button5 image], @"8721fd4e657980a5e12d498e73aed6e6a565dfca");
    XCTAssertEqualObjects([button5 actionString], @"swrve.contacts");
    XCTAssertEqualObjects([button5 message], message);
    XCTAssertEqual([button1 center].x, -200);
    XCTAssertEqual([button1 center].y, 80);
    XCTAssertEqual((int)[button1 messageID], 165);
    XCTAssertEqual((int)[button1 appID], 150);
    XCTAssertEqual([button5 actionType], kSwrveActionCapability);

    XCTAssertNotNil([format images]);
    XCTAssertEqual([[format images] count], 1);

    SwrveImage* image = [[format images] firstObject];
    XCTAssertNotNil(image);
    XCTAssertEqualObjects([image file], @"8f984a803374d7c03c97dd122bce3ccf565bbdb5");
    XCTAssertEqual([image center].x, 0);
    XCTAssertEqual([image center].y, 0);
}

- (void)testShowMessageDelegate {
    SwrveConfig *config = [SwrveConfig new];
    TestShowMessageDelegateNoCustomFind* testDelegate = [[TestShowMessageDelegateNoCustomFind alloc] init];
    config.inAppMessageConfig.showMessageDelegate = testDelegate;
    
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
    
    [controller eventRaised:event];

    SwrveMessage *message = [testDelegate messageShown];
    XCTAssertNotNil(message);
    XCTAssertEqualObjects(message.name, @"TestMessageName");
}

- (void)testShowMessageDelegateNoCustomFindMessage {
    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    SwrveMessageController *controller = [swrveMock messaging];
    
    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;

    TestShowMessageDelegateNoCustomFind *testDelegate = [[TestShowMessageDelegateNoCustomFind alloc] init];
    [controller setShowMessageDelegate:testDelegate];

    NSDictionary* event = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"currency_given", @"type",
                           @"Gold", @"given_currency",
                           @20, @"given_amount",
                           nil];
    [controller eventRaised:event];

    SwrveMessage *message = [testDelegate messageShown];
    XCTAssertNotNil(message);
    XCTAssertEqualObjects(message.name,@"Kindle");
}

- (void)testShowMessageDelegatePersonalizationOnly {
    id swrveMock = [self swrveMockWithTestJson:@"campaignsPersonalization"];
    SwrveMessageController *controller = [swrveMock messaging];

    TestShowIAMMessageDelegatePersonalization* testDelegate = [[TestShowIAMMessageDelegatePersonalization alloc] init];
    controller.showMessageDelegate = testDelegate;
    
    // mock date that lies within the start and end time of the campaign in the test json file campaignsMessageCenter
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);
    
    SwrveCampaign *campaign = [[controller messageCenterCampaigns] objectAtIndex:0];
    
    [controller showMessageCenterCampaign:campaign withPersonalization: @{@"test_cp": @"test_value",
                                                                          @"test_custom":@"urlprocessed",
                                                                          @"test_display": @"display"}];

    SwrveMessage *message = [testDelegate messageShown];
    XCTAssertNotNil(message);
    XCTAssertEqualObjects(message.name,@"Kindle");
}

- (void)testShowMessageDelegatePersonalizationFallback {
    id swrveMock = [self swrveMockWithTestJson:@"campaignsPersonalization"];
    SwrveMessageController *controller = [swrveMock messaging];

    // the standard message delegate should be called if selector personalization arg is not available
    TestShowMessageDelegateNoCustomFind* testDelegate = [[TestShowMessageDelegateNoCustomFind alloc] init];
    controller.showMessageDelegate = testDelegate;
    
    // mock date that lies within the start and end time of the campaign in the test json file campaignsMessageCenter
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);
    
    SwrveCampaign *campaign = [[controller messageCenterCampaigns] objectAtIndex:0];
    
    [controller showMessageCenterCampaign:campaign withPersonalization: @{@"test_cp": @"test_value",
                                                                          @"test_custom":@"urlprocessed",
                                                                          @"test_display": @"display"}];

    SwrveMessage *message = [testDelegate messageShown];
    XCTAssertNotNil(message);
    XCTAssertEqualObjects(message.name,@"Kindle");
}

- (void)testShowMessageDelegatePersonalizationFromTrigger {
    
    id swrveMock = [self swrveMockWithTestJson:@"campaignsPersonalization"];
    SwrveMessageController *controller = [swrveMock messaging];
    
    TestShowTriggeredPersonalizationDelegate *testDelegate = [[TestShowTriggeredPersonalizationDelegate alloc] init];
    controller.showMessageDelegate = testDelegate;
    
    SwrveMessagePersonalizationCallback personalizationCallback = ^(NSDictionary* eventPayload) {
        return @{@"test_cp": @"test_value", @"test_custom":@"urlprocessed", @"test_display": @"display"};
    };
    
    [controller setPersonalizationCallback:personalizationCallback];
    
    NSDictionary* event =  @{@"type": @"event",
                             @"seqnum": @1111,
                             @"name": @"trigger_name",
                             @"payload": @{}};
    [controller eventRaised:event];

    SwrveMessage *message = [testDelegate messageShown];
    XCTAssertNotNil(message);
    XCTAssertEqualObjects(message.name,@"Kindle");
}

- (void)testShowMessageDelegateImagePersonalizationFromTrigger {
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

    TestShowTriggeredPersonalizationDelegate *testDelegate = [[TestShowTriggeredPersonalizationDelegate alloc] init];
    controller.showMessageDelegate = testDelegate;

    NSDictionary* event =  @{@"type": @"event",
                             @"seqnum": @1111,
                             @"name": @"trigger_name",
                             @"payload": @{}};
    [controller eventRaised:event];

    SwrveMessage *message = [testDelegate messageShown];
    XCTAssertNotNil(message);
    XCTAssertEqualObjects(message.name,@"Kindle");
}

- (void)testShowMessageDelegateImagePersonalizationFromTriggerMissingPersonalization {
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

    TestShowTriggeredPersonalizationDelegate *testDelegate = [[TestShowTriggeredPersonalizationDelegate alloc] init];
    controller.showMessageDelegate = testDelegate;

    NSDictionary* event =  @{@"type": @"event",
                             @"seqnum": @1111,
                             @"name": @"trigger_name",
                             @"payload": @{}};
    [controller eventRaised:event];

    SwrveMessage *message = [testDelegate messageShown];
    XCTAssertNil(message);
}

- (void)testShowMessageDelegateImagePersonalizationWithRealTimeUserPropertiesFromTrigger {
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

    TestShowTriggeredPersonalizationDelegate *testDelegate = [[TestShowTriggeredPersonalizationDelegate alloc] init];
    controller.showMessageDelegate = testDelegate;

    NSDictionary* event =  @{@"type": @"event",
                             @"seqnum": @1111,
                             @"name": @"trigger_name",
                             @"payload": @{}};
    [controller eventRaised:event];

    SwrveMessage *message = [testDelegate messageShown];
    XCTAssertNotNil(message);
    XCTAssertEqualObjects(message.name,@"Kindle");
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
    for (SwrveButton* button in [format buttons]) {
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
    TestShowMessageDelegateNoCustomFind *testDelegate = [[TestShowMessageDelegateNoCustomFind alloc] init];
    [controller setShowMessageDelegate:testDelegate];

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
    [testDelegate showMessage:message];

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
    [testDelegate showMessage:message];

    // Max impressions

    // This message should only be shown 3 times, it has been shown twice already
    self.swrveNowDate = [NSDate dateWithTimeInterval:60 sinceDate:self.swrveNowDate];

    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    [testDelegate showMessage:message];

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
    
    TestShowMessageDelegateNoCustomFind *testDelegate = [[TestShowMessageDelegateNoCustomFind alloc] init];
    [controller setShowMessageDelegate:testDelegate];

    // This message should only be shown 2 times
    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    [testDelegate showMessage:message];
    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    [testDelegate showMessage:message];
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
    
    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    // First message display
    self.swrveNowDate = [NSDate dateWithTimeInterval:130 sinceDate:self.swrveNowDate];
    
    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    [controller showMessage:message];

    SwrveMessageViewController *viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];

    self.swrveNowDate = [NSDate dateWithTimeInterval:130 sinceDate:self.swrveNowDate];
    
    // Press dismiss button
    UISwrveButton* dismissButton = [UISwrveButton new];
    [dismissButton setTag:2];
    [viewController onButtonPressed:dismissButton];

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
    TestShowMessageDelegateNoCustomFind *testDelegate = [[TestShowMessageDelegateNoCustomFind alloc] init];
    [controller setShowMessageDelegate:testDelegate];

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

    TestShowMessageDelegateNoCustomFind *testDelegate = [[TestShowMessageDelegateNoCustomFind alloc] init];
    [controller setShowMessageDelegate:testDelegate];

    // First Message Delay
    // App has start delay of 30 seconds, so no message should be returned
    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.user_purchase"];
    XCTAssertNil(message);

    OCMVerify([swrveQAMock campaignTriggered:@"Swrve.user_purchase" eventPayload:nil displayed:NO reason:@"{App throttle limit} Too soon after launch. Wait until 00:00:30 +0000" campaignInfo:nil]);
    
    // Go 40 seconds into future
    self.swrveNowDate = [NSDate dateWithTimeInterval:40 sinceDate:self.swrveNowDate];
    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.user_purchase"];
    XCTAssertNotNil(message);
    [testDelegate showMessage:message];

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
    [testDelegate showMessage:message];

    // Max impressions

    // Any message should only be shown 4 times, it has been shown twice already
    self.swrveNowDate = [NSDate dateWithTimeInterval:60 sinceDate:self.swrveNowDate];
    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.user_purchase"];
    XCTAssertNotNil(message);
    [testDelegate showMessage:message];

    self.swrveNowDate = [NSDate dateWithTimeInterval:60 sinceDate:self.swrveNowDate];
    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.user_purchase"];
    XCTAssertNotNil(message);
    [testDelegate showMessage:message];

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

    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];

    __block int customActionCount = 0;
    __block NSString *customAction;

    // Set custom callbacks
    [controller setCustomButtonCallback:^(NSString* action) {
        customActionCount++;
        customAction = action;
    }];

    NSArray* buttons = [[viewController current_format] buttons];
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
        if ([swrveButton actionType] == kSwrveActionCustom) {
            for (UISwrveButton *button in uiButtons){
                if ([button.accessibilityIdentifier isEqualToString:swrveButton.name]) {
                    // pretend to press it
                    [viewController onButtonPressed:button];
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

/**
 * Tests install button pressed
 */
- (void)testInstallButtonPressed {
    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    SwrveMessageController *controller = [swrveMock messaging];
    
    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;

    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];

    NSArray* buttons = [[viewController current_format] buttons];
    XCTAssertEqual([buttons count], 5);
    
    id mockUIApplication = OCMPartialMock([UIApplication sharedApplication]);
    OCMExpect([mockUIApplication openURL:OCMOCK_ANY options:OCMOCK_ANY completionHandler:OCMOCK_ANY]);

    // Pretend to press all buttons
    for (NSInteger i = 0; i < [buttons count]; i++) {
        SwrveButton* swrveButton = [buttons objectAtIndex:i];
        if ([swrveButton actionType] == kSwrveActionInstall) {
            UISwrveButton* button = [UISwrveButton new];
            [button setTag:i];
            [viewController onButtonPressed:button];
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
    
    OCMVerifyAll(mockUIApplication);
    
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

    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];
    __block NSString *campaignSubject = @"";
    __block NSString *buttonName = @"";

    __block int customActionCount = 0;
    __block int clipboardActionCount = 0;
    __block int dismissActionCount = 0;

    // Set custom callbacks
    [controller setCustomButtonCallback:^(NSString *action) {
        customActionCount++;
    }];

    [controller setDismissButtonCallback:^(NSString *campaignS, NSString *buttonN) {
        dismissActionCount++;
        campaignSubject = campaignS;
        buttonName = buttonN;
    }];
    
    [controller setClipboardButtonCallback:^(NSString *processedText) {
        clipboardActionCount++;
    }];

    NSArray *buttons = [[viewController current_format] buttons];
    XCTAssertEqual([buttons count],5);

    // Pretend to press all buttons
    for (NSInteger i = 0; i < [buttons count]; i++) {
        SwrveButton *swrveButton = [buttons objectAtIndex:i];
        if ([swrveButton actionType] == kSwrveActionDismiss) {
            UISwrveButton *button = [UISwrveButton new];
            [button setTag:i];
            [viewController onButtonPressed:button];
        }
    }

    // Ensure custom and install callbacks weren't invoked
    XCTAssertEqual(customActionCount, 0);
    XCTAssertEqual(dismissActionCount, 1);
    XCTAssertEqual(clipboardActionCount, 0);
    XCTAssertEqualObjects(buttonName, @"close");
    XCTAssertEqualObjects(campaignSubject, @"IAM subject");


    // Check no click events were sent
    int clickEventCount = 0;
    for (NSString *event in [swrveMock eventBuffer]) {
        if ([event rangeOfString:@"Swrve.Messages.Message-165.click"].location != NSNotFound) {
            clickEventCount++;
        }
    }
    XCTAssertEqual(clickEventCount, 0);
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

    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];

    __block int clipboardActionCount = 0;
    __block NSString *clipboardAction;

    // Set clipboard callbacks
    [controller setClipboardButtonCallback:^(NSString* action) {
        clipboardActionCount++;
        clipboardAction = action;
    }];

    NSArray* buttons = [[viewController current_format] buttons];
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
    
    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];
    
    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];

    NSArray* buttons = [[viewController current_format] buttons];
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
                }
            }
        }
    }

    // check capablity delegate called
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
    
    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];
    
    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;
    
    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"eventRequestablePush"];
    [controller showMessage:message];

    SwrveMessageViewController *viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];

    NSArray* buttons = [[viewController current_format] buttons];
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
    
    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];
    
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

    TestShowMessageDelegateNoCustomFind *testDelegate = [[TestShowMessageDelegateNoCustomFind alloc] init];
    [controller setShowMessageDelegate:testDelegate];

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    [testDelegate showMessage:message];

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
    [controller setShowMessageDelegate:testDelegate];

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

    TestShowMessageDelegateNoCustomFind *testDelegate = [[TestShowMessageDelegateNoCustomFind alloc] init];
    [controller setShowMessageDelegate:testDelegate];

    // Message ID 1 should be highest priority
    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    XCTAssertEqual([[message messageID] intValue], 1);
    [testDelegate showMessage:message];

    // Message ID 2 should be second highest priority
    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    XCTAssertEqual([[message messageID] intValue], 2);
    [testDelegate showMessage:message];

    //Max impressiong for message id 2 is set to 2, so it show should again.
    //Also Display order is random and round robin has been removed,
    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    XCTAssertEqual([[message messageID] intValue], 2);
    [testDelegate showMessage:message];

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

    TestShowMessageDelegateNoCustomFind *testDelegate = [[TestShowMessageDelegateNoCustomFind alloc] init];
    [controller setShowMessageDelegate:testDelegate];

    // Highest priority first (first in round robin)
    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    XCTAssertEqual([[message messageID] intValue], 2);
    [testDelegate showMessage:message];

    //
    message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    XCTAssertEqual([[message messageID] intValue], 2);
    [testDelegate showMessage:message];

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

    TestShowMessageDelegateNoCustomFind *testDelegate = [[TestShowMessageDelegateNoCustomFind alloc] init];
    [controller setShowMessageDelegate:testDelegate];

    // Highest priority conversation first
    SwrveConversation *conversation = [controller conversationForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(conversation);
    XCTAssertEqual([[conversation conversationID] intValue], 103);
    [testDelegate showConversation:conversation];

    // Second highest conversation
    conversation = [controller conversationForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(conversation);
    XCTAssertEqual([[conversation conversationID] intValue], 102);
    [testDelegate showConversation:conversation];

    // Lowest conversation (out of 3)
    conversation = [controller conversationForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(conversation);
    XCTAssertEqual([[conversation conversationID] intValue], 104);
    [testDelegate showConversation:conversation];

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

    TestShowMessageDelegateNoCustomFind *testDelegate = [[TestShowMessageDelegateNoCustomFind alloc] init];
    [controller setShowMessageDelegate:testDelegate];

    // Highest priority conversation first
    SwrveConversation *conversation = [controller conversationForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(conversation);
    XCTAssertEqual([[conversation conversationID] intValue], 103);
    [testDelegate showConversation:conversation];

    // Second highest conversation
    conversation = [controller conversationForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(conversation);
    XCTAssertEqual([[conversation conversationID] intValue], 104);
    [testDelegate showConversation:conversation];

    // Lowest conversation (out of 3)
    conversation = [controller conversationForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(conversation);
    XCTAssertEqual([[conversation conversationID] intValue], 102);
    [testDelegate showConversation:conversation];

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

    SwrveConversation *conversation = [controller conversationForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(conversation);

    OCMVerify([swrveQAMock conversationCampaignTriggered:@"Swrve.currency_given" eventPayload:nil displayed:YES campaignInfoDict:OCMOCK_ANY]);
}

#elif TARGET_OS_TV

/**
 * Check that conversation rejection logic for tvOS
 */
- (void)testConversationTvOS {
    id swrveMock = [self swrveMockWithTestJson:@"conversationCampaignsPriority"];
    SwrveMessageController *controller = [swrveMock messaging];

    TestShowMessageDelegateNoCustomFind *testDelegate = [[TestShowMessageDelegateNoCustomFind alloc] init];
    [controller setShowMessageDelegate:testDelegate];

    // try to retrieve a conversation
    SwrveConversation *conversation = [controller conversationForEvent:@"Swrve.currency_given"];
    XCTAssertNil(conversation, @"Conversations are not supported in tvOS should not be found and nil should be returned");
}

#endif /**TARGET_OS_TV */

/**
 * Ensure session start event can trigger a message
 */
- (void)testSessionStartTrigger {
    id swrveMock = [self swrveMockWithTestJson:@"campaignSessionStart"];
    SwrveMessageController *controller = [swrveMock messaging];

    TestShowMessageDelegateNoCustomFind *testDelegate = [[TestShowMessageDelegateNoCustomFind alloc] init];
    [controller setShowMessageDelegate:testDelegate];

    int success = [swrveMock sessionStart];
    XCTAssertEqual(success, SWRVE_SUCCESS);

    SwrveMessage *message = [testDelegate messageShown];
    XCTAssertNotNil(message);
    XCTAssertEqual([[message messageID] intValue], 165);
}

/**
 * Ensure only one message is shown at a time. If a second message is triggered it will be ignored
 * until the first message is dismissed
 */
- (void)testOneMessageAtATime {
    id swrveMock = [self swrveMockWithTestJson:@"campaignsMessagePriority"];
    SwrveMessageController *controller = [swrveMock messaging];

    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];

    OCMStub([swrveMock getNow]).andReturn([NSDate dateWithTimeInterval:40 sinceDate:[swrveMock getNow]]);

    // Ensure that if we try to display a second message without dismissing the first one this fails and the same message is still shown
    SwrveMessage *message2 = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message2];
    viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];

    XCTAssertEqualObjects([viewController message], message);

    // Press dismiss button
    UISwrveButton* dismissButton = [UISwrveButton new];
    [dismissButton setTag:0];
    [viewController onButtonPressed:dismissButton];

    // Ensure that new message is now shown correctly
    [controller showMessage:message2];
    viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];

    XCTAssertEqualObjects([viewController message], message2);

}

#if TARGET_OS_IOS /** The concept of orientation is not on tvOS **/
/**
 * When a message format supports both landscape and portrait we want to make sure that if the
 * device orientation is portrait the message displayed is the portrait one; and when we dismiss the message,
 * rotate the device and show the same message again it should show in landscape format
 */
- (void)testMessageAppearsWithCorrectFormat {
    XCUIDevice.sharedDevice.orientation = UIInterfaceOrientationPortrait;

    id swrveMock = [self swrveMockWithTestJson:@"campaignsBothOrientations"];
    SwrveMessageController *controller = [swrveMock messaging];
    
    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;

    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];

    XCTAssertNotNil([viewController message]);
    XCTAssertEqual([[[viewController message] messageID] intValue], 165);
    XCTAssertEqual([[viewController current_format] orientation], SWRVE_ORIENTATION_PORTRAIT);

    // Press dismiss button
    UISwrveButton *dismissButton = [UISwrveButton new];
    [dismissButton setTag:0];
    [viewController onButtonPressed:dismissButton];

    // Rotate device
    XCUIDevice.sharedDevice.orientation = UIInterfaceOrientationLandscapeRight;

    // Show same message again
    [controller showMessage:message];
    viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];

    // Ensure message is now shown in landscape format
    XCTAssertNotNil([viewController message]);
    XCTAssertEqual([[[viewController message] messageID] intValue], 165);

    // Change orientation back to original
    XCUIDevice.sharedDevice.orientation = UIInterfaceOrientationPortrait;
}

/**
 * When a message is shown that supports both landscape and portrait and the device is
 * rotated, the message should still be there after rotation but with the new orientation format
 */
- (void)testMessageReappearsWithDifferentFormat {
    XCUIDevice.sharedDevice.orientation = UIInterfaceOrientationPortrait;

    id swrveMock = [self swrveMockWithTestJson:@"campaignsBothOrientations"];
    SwrveMessageController *controller = [swrveMock messaging];

    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];

    XCTAssertNotNil([viewController message]);
    XCTAssertEqual([[[viewController message] messageID] intValue], 165);

    // Rotate device
    XCUIDevice.sharedDevice.orientation = UIInterfaceOrientationLandscapeRight;

    [viewController viewDidAppear:NO];

    // Ensure message is now shown in landscape format
    XCTAssertNotNil([viewController message]);
    XCTAssertEqual([[[viewController message] messageID] intValue], 165);

    // Change orientation back to original
    XCUIDevice.sharedDevice.orientation = UIInterfaceOrientationPortrait;
}

/**
 * When a message is shown that supports only portrait  and the device is
 * rotated, the message should still be there after rotation with the same format
 */
- (void)testMessageReappearsWithSameFormat {
    XCUIDevice.sharedDevice.orientation = UIInterfaceOrientationPortrait;

    id swrveMock = [self swrveMockWithTestJson:@"campaignsPortraitOnly"];
    SwrveMessageController *controller = [swrveMock messaging];

    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];

    XCTAssertNotNil([viewController message]);
    XCTAssertEqual([[[viewController message] messageID] intValue], 165);

    // Rotate device
    XCUIDevice.sharedDevice.orientation = UIInterfaceOrientationLandscapeRight;

    viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];

    // Ensure message is still shown with the same format
    XCTAssertNotNil([viewController message]);
    XCTAssertEqual([[[viewController message] messageID] intValue], 165);

    // Change orientation back to original
    XCUIDevice.sharedDevice.orientation = UIInterfaceOrientationPortrait;
}
#endif //TARGET_OS_IOS

/**
 * Test that setting custom action listener works
 */
- (void)testCustomActionListener {
    __block NSString *customActionResult = @"";

    SwrveCustomButtonPressedCallback customCallback = ^(NSString* action) {
        customActionResult = action;
    };
    
    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.inAppMessageConfig.customButtonCallback = customCallback;
    
    id swrveMock = [self swrveMockWithTestJson:@"campaigns" withConfig:config];
    [swrveMock messaging].customButtonCallback(@"CustomAction");

    XCTAssertEqualObjects(customActionResult, @"CustomAction");
}

/**
 * Test that setting dismiss action listener works
 */
- (void)testDismissActionListener {
    __block NSString *campaignName = @"";
    __block NSString *buttonName = @"";

    SwrveDismissButtonPressedCallback dismissCallback = ^(NSString *campaignN, NSString *buttonN) {
        campaignName = campaignN;
        buttonName = buttonN;
    };
    
    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.inAppMessageConfig.dismissButtonCallback = dismissCallback;

    id swrveMock = [self swrveMockWithTestJson:@"campaigns" withConfig:config];
    [swrveMock messaging].dismissButtonCallback(@"campaignName", @"btnClose");

    XCTAssertEqualObjects(campaignName, @"campaignName");
    XCTAssertEqualObjects(buttonName, @"btnClose");
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
        TestShowMessageDelegateNoCustomFind *testDelegate = [[TestShowMessageDelegateNoCustomFind alloc] init];
        [controller setShowMessageDelegate:testDelegate];

        XCTAssertEqual([[controller campaigns] count], 1);
        SwrveCampaign* campaign = [[controller campaigns] firstObject];

        XCTAssertEqual(campaign.ID, 102);
        XCTAssertEqual(campaign.state.impressions, impressionAmount);

        [swrveMock currencyGiven:@"USD" givenAmount:123.54];

        SwrveMessage *messageShown = [testDelegate messageShown];
        XCTAssertNotNil(messageShown);

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
    TestShowMessageDelegateNoCustomFind *testDelegate = [[TestShowMessageDelegateNoCustomFind alloc] init];
    [controller setShowMessageDelegate:testDelegate];

    XCTAssertEqual([[controller campaigns] count], 1);
    SwrveCampaign *campaign = [[controller campaigns] firstObject];

    XCTAssertEqual(campaign.ID, 102);
    XCTAssertEqual(campaign.state.impressions, impressionAmount);
    [swrveMock currencyGiven:@"USD" givenAmount:123.54];

    SwrveMessage *messageShown = [testDelegate messageShown];

    //should be nil since it's over the limit
    XCTAssertNil(messageShown);
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

    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];

    XCTAssertEqualObjects(viewController.view.backgroundColor, [UIColor redColor]);
}

/**
 * Test default colors from config
 */
- (void)testDefaultColors {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.inAppMessageConfig.backgroundColor = [UIColor redColor];
    
    id swrveMock = [self swrveMockWithTestJson:@"campaigns" withConfig:config];
    SwrveMessageController *controller = [swrveMock messaging];
    
    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;

    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];

    XCTAssertEqualObjects(viewController.inAppConfig.personalizationForegroundColor, [UIColor blackColor]);
    XCTAssertEqualObjects(viewController.inAppConfig.personalizationBackgroundColor, [UIColor clearColor]);
    XCTAssertEqualObjects(viewController.inAppConfig.personalizationFont, [UIFont systemFontOfSize:0]);
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

    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    // mock date that lies within the start and end time of the campaign in the test json file campaignsMessageCenter
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);
    
    SwrveCampaign *campaign = [[controller messageCenterCampaigns] objectAtIndex:0];
  
    [controller showMessageCenterCampaign:campaign withPersonalization: @{@"test_cp": @"test_value",
                                                                          @"test_custom":@"urlprocessed",
                                                                          @"test_display": @"display"}];

    SwrveMessageViewController *viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];

    XCTAssertEqualObjects(viewController.view.backgroundColor, [UIColor redColor]);
    XCTAssertEqualObjects(viewController.inAppConfig.personalizationForegroundColor, [UIColor blueColor]);
    XCTAssertEqualObjects(viewController.inAppConfig.personalizationBackgroundColor, [UIColor blackColor]);
    XCTAssertEqualObjects(viewController.inAppConfig.personalizationFont, [UIFont italicSystemFontOfSize:1]);
}

/**
 * Test configurable RRGGBB color from template
 */
- (void)testBackgroundColorFromTemplateRRGGBB {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.inAppMessageConfig.backgroundColor = [UIColor blueColor];

    id swrveMock = [self swrveMockWithTestJson:@"campaignsRRGGBB" withConfig:config];
    SwrveMessageController *controller = [swrveMock messaging];

    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];
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

    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];
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
    
    OCMStub([swrveMock initSwrveRestClient:60]).andDo(^(NSInvocation *invocation) {
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
    
    OCMStub([swrveMock initSwrveRestClient:60]).andDo(^(NSInvocation *invocation) {
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
    
    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

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
    
    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];
    
    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;

    SwrveMessage *message = (SwrveMessage *)[controller baseMessageForEvent:@"eventRequestable"];
    XCTAssertNotNil(message);
        
    OCMVerify([testCapabilitiesDelegateMock canRequestCapability:@"swrve.contacts"]);
}

-(void)testFilterMessageCapabilityNotRequestable {
    id swrveMock = [self swrveMockWithTestJson:@"iamCapabilites"];
    SwrveMessageController *controller = [swrveMock messaging];
    
    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];
    
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
    
    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];
    
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

@end
