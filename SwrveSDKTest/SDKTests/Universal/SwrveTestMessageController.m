#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SwrveInAppCampaign.h"
#import "SwrveConversation.h"
#import "UISwrveButton.h"
#import "SwrveButton.h"
#import "SwrveImage.h"
#import "SwrveQAUser.h"
#import "SwrveTestHelper.h"
#import "TestShowMessageDelegateWithViewController.h"
#import "SwrveAssetsManager.h"
#import "SwrveMessageController+Private.h"
#import "SwrveLocalStorage.h"
#import "SwrveMigrationsManager.h"

@interface SwrveMigrationsManager ()
+ (void)markAsMigrated;
@end

@interface Swrve ()
@property (nonatomic) SwrveReceiptProvider *receiptProvider;
- (NSDate *)getNow;
- (void)initSwrveRestClient:(NSTimeInterval)timeOut;
- (int)sessionStart;
- (void)suspend:(BOOL)terminating;
- (void)appDidBecomeActive:(NSNotification *)notification;
@property (atomic) SwrveRESTClient *restClient;
@property (atomic) NSMutableArray *eventBuffer;

@end

@interface SwrveMessageController ()
- (void)showMessage:(SwrveMessage *)message queue:(bool)isQueued;
- (void)showConversation:(SwrveConversation *)conversation queue:(bool)isQueued;
- (void)dismissMessageWindow;
- (void)updateCampaigns:(NSDictionary *)campaignJson;
@property (nonatomic, retain) UIWindow *inAppMessageWindow;
@property (nonatomic) SwrveQAUser *qaUser;
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

@interface TestShowTriggeredPersonalisationDelegate : NSObject<SwrveMessageDelegate>

- (void)showMessage:(SwrveMessage *)message withPersonalisation:(NSDictionary *)personalisation;
    @property SwrveMessage *messageShown;
@end

@implementation TestShowTriggeredPersonalisationDelegate

- (id) init {
    if (self = [super init]) {
        [self setMessageShown:nil];
    }
    return self;
}

- (void)showMessage:(SwrveMessage *)message withPersonalisation:(NSDictionary *)personalisation {
    [self setMessageShown:message];
    [message wasShownToUser];
}

@end

@interface TestShowIAMMessageDelegatePersonalisation : NSObject<SwrveMessageDelegate>
- (void)showMessage:(SwrveMessage *)message withPersonalisation:(NSDictionary *)personalisation;
@property SwrveMessage *messageShown;
@end

@implementation TestShowIAMMessageDelegatePersonalisation

- (id) init {
    if (self = [super init]) {
        [self setMessageShown:nil];
    }
    return self;
}

- (void)showMessage:(SwrveMessage *)message withPersonalisation:(NSDictionary *)personalisation {
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


@interface TestShowMessageDelegate : TestShowMessageDelegateNoCustomFind
- (SwrveMessage*)messageForEvent:(NSString *) eventName withPayload:(NSDictionary *)payload;
@end


@implementation TestShowMessageDelegate

- (SwrveMessage*)messageForEvent:(NSString *) eventName withPayload:(NSDictionary *)payload {

    TestingSwrveMessage *mockMessage = [[TestingSwrveMessage alloc] init];
    mockMessage.name = @"TestMessageName";
    return mockMessage;
}

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
    
    [[swrveMock messaging] updateCampaigns:jsonDict];
    
    return swrveMock;
}

- (void)testMulitpleConversationsAreNotQueued {
    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    SwrveMessageController *controller = [swrveMock messaging];
    
    SwrveMessage *message1 = [controller messageForEvent:@"test1"];
    [controller showMessage:message1];
    
    SwrveMessage *message2 = [controller messageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message2];
    
    XCTAssertEqual([[controller conversationsMessageQueue] count], 0);
}

- (void)testMulitpleConversationsQueued {
    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    SwrveMessageController *controller = [swrveMock messaging];
    
    SwrveMessage *message1 = [controller messageForEvent:@"test1"];
    [controller showMessage:message1];
    
    SwrveMessage *message2 = [controller messageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message2 queue:true];
    
    SwrveMessage *message3 = [controller messageForEvent:@"test1"];
    [controller showMessage:message3];
    
    XCTAssertEqual([[controller conversationsMessageQueue] count], 1);
    
    [controller dismissMessageWindow];

    XCTAssertEqual([[controller conversationsMessageQueue] count], 0);
}

- (void)testConversationNotQueuedWhenNothingElseShowing {
    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    SwrveMessageController *controller = [swrveMock messaging];
    
    SwrveMessage *message1 = [controller messageForEvent:@"test1"];
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
    [controller updateCampaigns:nil];
    if ([controller campaigns] != nil) {
        XCTAssertEqualObjects([controller campaigns], currentCampaigns);
    }

    NSData *emptyJson = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:emptyJson options:0 error:nil];
    [controller updateCampaigns:jsonDict];

    XCTAssertEqual([[controller campaigns] count], 0);
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaigns" ofType:@"json"];
    NSData *mockJsonData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    jsonDict = [NSJSONSerialization JSONObjectWithData:mockJsonData options:0 error:nil];

    [controller updateCampaigns:jsonDict];
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

    XCTAssertEqual(campaign.state.next, 0);
    XCTAssertEqual([campaign ID], 102);
    XCTAssertEqual([campaign maxImpressions], 20);
    XCTAssertEqual(campaign.state.impressions, 0);
    XCTAssertEqual([campaign minDelayBetweenMsgs], 30);

    XCTAssertEqual(nowTime, [[campaign showMsgsAfterLaunch] timeIntervalSince1970]);
    XCTAssertEqual(0,[[campaign.state showMsgsAfterDelay] timeIntervalSince1970]);

    XCTAssertNotNil([campaign messages]);
    XCTAssertEqual([[campaign messages] count], 1);

    SwrveMessage *message = [[campaign messages] firstObject];
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
    XCTAssertEqual([[format buttons] count], 4);

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
    
    SwrveButton* button4 = [[format buttons] lastObject];
    XCTAssertNotNil(button4);
    XCTAssertEqualObjects([button4 image], @"97c5df26c8e8fcff8dbda7e662d4272a6a94af7e");
    XCTAssertEqualObjects([button4 actionString], @"${test_cp|fallback=\"test\"}");
    XCTAssertEqualObjects([button4 message], message);
    XCTAssertEqual([button4 center].x,999);
    XCTAssertEqual([button4 center].y, 23);
    XCTAssertEqual((int)[button4 messageID], 165);
    XCTAssertEqual((int)[button4 appID], 0);
    XCTAssertEqual([button4 actionType], kSwrveActionClipboard);

    XCTAssertNotNil([format images]);
    XCTAssertEqual([[format images] count], 1);

    SwrveImage* image = [[format images] firstObject];
    XCTAssertNotNil(image);
    XCTAssertEqualObjects([image file], @"8f984a803374d7c03c97dd122bce3ccf565bbdb5");
    XCTAssertEqual([image center].x, 0);
    XCTAssertEqual([image center].y, 0);
}

- (void)testShowMessageDelegate {
    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    SwrveMessageController *controller = [swrveMock messaging];

    TestShowMessageDelegate* testDelegate = [[TestShowMessageDelegate alloc] init];
    controller.showMessageDelegate = testDelegate;

    NSDictionary* event = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"purchase", @"type",
                           @"item", @"toy",
                           nil];
    [controller eventRaised:event];

    SwrveMessage *message = [testDelegate messageShown];
    XCTAssertNotNil(message);
    XCTAssertEqualObjects(message.name,@"TestMessageName");
}

- (void)testShowMessageDelegateNoCustomFindMessage {
    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    SwrveMessageController *controller = [swrveMock messaging];

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

- (void)testShowMessageDelegatePersonalisationOnly {
    id swrveMock = [self swrveMockWithTestJson:@"campaignsPersonalisation"];
    SwrveMessageController *controller = [swrveMock messaging];

    TestShowIAMMessageDelegatePersonalisation* testDelegate = [[TestShowIAMMessageDelegatePersonalisation alloc] init];
    controller.showMessageDelegate = testDelegate;
    
    // mock date that lies within the start and end time of the campaign in the test json file campaignsMessageCenter
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);
    
    SwrveCampaign *campaign = [[controller messageCenterCampaigns] objectAtIndex:0];
    
    [controller showMessageCenterCampaign:campaign withPersonalisation: @{@"test_cp": @"test_value",
                                                                          @"test_custom":@"urlprocessed",
                                                                          @"test_display": @"display"}];

    SwrveMessage *message = [testDelegate messageShown];
    XCTAssertNotNil(message);
    XCTAssertEqualObjects(message.name,@"Kindle");
}

- (void)testShowMessageDelegatePersonalisationFallback {
    id swrveMock = [self swrveMockWithTestJson:@"campaignsPersonalisation"];
    SwrveMessageController *controller = [swrveMock messaging];

    // the standard message delegate should be called if selector personalisation arg is not available
    TestShowMessageDelegate* testDelegate = [[TestShowMessageDelegate alloc] init];
    controller.showMessageDelegate = testDelegate;
    
    // mock date that lies within the start and end time of the campaign in the test json file campaignsMessageCenter
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);
    
    SwrveCampaign *campaign = [[controller messageCenterCampaigns] objectAtIndex:0];
    
    [controller showMessageCenterCampaign:campaign withPersonalisation: @{@"test_cp": @"test_value",
                                                                          @"test_custom":@"urlprocessed",
                                                                          @"test_display": @"display"}];

    SwrveMessage *message = [testDelegate messageShown];
    XCTAssertNotNil(message);
    XCTAssertEqualObjects(message.name,@"Kindle");
}

- (void)testShowMessageDelegatePersonalisationFromTrigger {
    
    id swrveMock = [self swrveMockWithTestJson:@"campaignsPersonalisation"];
    SwrveMessageController *controller = [swrveMock messaging];
    
    TestShowTriggeredPersonalisationDelegate *testDelegate = [[TestShowTriggeredPersonalisationDelegate alloc] init];
    controller.showMessageDelegate = testDelegate;
    
    SwrveMessagePersonalisationCallback personalisationCallback = ^(NSDictionary* eventPayload) {
        return @{@"test_cp": @"test_value", @"test_custom":@"urlprocessed", @"test_display": @"display"};
    };
    
    [controller setPersonalisationCallback:personalisationCallback];
    
    NSDictionary* event =  @{@"type": @"event",
                             @"seqnum": @1111,
                             @"name": @"trigger_name",
                             @"payload": @{}};
    [controller eventRaised:event];

    SwrveMessage *message = [testDelegate messageShown];
    XCTAssertNotNil(message);
    XCTAssertEqualObjects(message.name,@"Kindle");
}

/**
 * Ensure QA trigger function gets called when QA user is set and message is requested
 */
- (void)testSwrveQAUserCalls {
    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    SwrveMessageController *controller = [swrveMock messaging];
    
    id mockSwrveQAUser = OCMClassMock([SwrveQAUser class]);
    [controller setQaUser:mockSwrveQAUser];
    
    SwrveMessage *message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    
    message = [controller messageForEvent:@"InvalidEvent"];
    
    OCMVerify(([mockSwrveQAUser trigger:@"InvalidEvent"
                            withMessage:message
                             withReason:@{@"102":@"There is no trigger in 102 that matches InvalidEvent with conditions (null)",
                                          @"101":@"There is no trigger in 101 that matches InvalidEvent with conditions (null)"
                                          }
                           withMessages:@{}]));
}

/**
 * Check that correct app store URL is retrieved for install button
 */
- (void)testAppStoreURLForApp {
    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    SwrveMessageController *controller = [swrveMock messaging];

    NSDictionary *appStoreURLs = [controller appStoreURLs];
    XCTAssertEqual([appStoreURLs count], 1);
    XCTAssertNotNil([appStoreURLs objectForKey:@"150"]);
    XCTAssertNil([appStoreURLs objectForKey:@"250"]);

    SwrveMessage *message = [controller messageForEvent:@"Swrve.currency_given"];
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
    id swrveMock = [self swrveMockWithTestJson:@"campaignsDelay"];
    SwrveMessageController *controller = [swrveMock messaging];

    TestShowMessageDelegateNoCustomFind *testDelegate = [[TestShowMessageDelegateNoCustomFind alloc] init];
    [controller setShowMessageDelegate:testDelegate];

    // First Message Delay
    // Campaign has start delay of 60 seconds, so no message should be returned after 40 seconds
    self.swrveNowDate = [NSDate dateWithTimeInterval:40 sinceDate:self.swrveNowDate];
    id mockSwrveQAUser = OCMClassMock([SwrveQAUser class]);
    [controller setQaUser:mockSwrveQAUser];

    SwrveMessage *message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNil(message);
    OCMVerify(([mockSwrveQAUser  trigger:@"Swrve.currency_given"
                                withMessage:message
                                 withReason:@{@"102":@"{Campaign throttle limit} Too soon after launch. Wait until 00:01:00 +0000",
                                              @"103":@"There is no trigger in 103 that matches Swrve.currency_given with conditions (null)"
                                              }
                               withMessages:@{}]));

    // Go another 30 seconds into future to get to start time + 70 seconds, message should appear now
    self.swrveNowDate = [NSDate dateWithTimeInterval:30 sinceDate:self.swrveNowDate];
    message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    [testDelegate showMessage:message];

    // Delay between messages

    // Go 10 seconds into the future, no message should show because there need to be 30 seconds between messages
    self.swrveNowDate = [NSDate dateWithTimeInterval:10 sinceDate:self.swrveNowDate];

    message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNil(message);

    OCMVerify(([mockSwrveQAUser trigger:@"Swrve.currency_given"
                            withMessage:message
                             withReason:@{@"102":@"{Campaign throttle limit} Too soon after last message. Wait until 00:01:40 +0000",
                                          @"103":@"There is no trigger in 103 that matches Swrve.currency_given with conditions (null)"
                                              }
                            withMessages:@{}]));

    // Another 25 seconds and a message should be shown again
    self.swrveNowDate = [NSDate dateWithTimeInterval:25 sinceDate:self.swrveNowDate];

    message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    [testDelegate showMessage:message];

    // Max impressions

    // This message should only be shown 3 times, it has been shown twice already
    self.swrveNowDate = [NSDate dateWithTimeInterval:60 sinceDate:self.swrveNowDate];

    message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    [testDelegate showMessage:message];

    self.swrveNowDate = [NSDate dateWithTimeInterval:60 sinceDate:self.swrveNowDate];

    message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNil(message);
    
    OCMVerify(([mockSwrveQAUser trigger:@"Swrve.currency_given"
                            withMessage:OCMOCK_ANY
                             withReason:@{@"102":@"{Campaign throttle limit} Campaign 102 has been shown 3 times already",
                                          @"103":@"There is no trigger in 103 that matches Swrve.currency_given with conditions (null)"
                                              }
                          withMessages:@{}]));
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
    SwrveMessage *message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    [testDelegate showMessage:message];
    message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    [testDelegate showMessage:message];
    // Cannot show the message anymore
    message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNil(message);
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsNone" ofType:@"json"];
    NSData *mockJsonData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockJsonData options:0 error:nil];

    // Fake campaigns gone and come back
    [controller updateCampaigns:jsonDict];
    XCTAssertEqual([[controller campaigns] count], 0);
    
    [[swrveMock messaging] saveCampaignsState];

    // Fake campaigns are available again
    filePath = [[NSBundle mainBundle] pathForResource:@"campaignsImpressions" ofType:@"json"];
    mockJsonData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    jsonDict = [NSJSONSerialization JSONObjectWithData:mockJsonData options:0 error:nil];

    [controller updateCampaigns:jsonDict];
    XCTAssertEqual([[controller campaigns] count], 1);
    
    // Impressions rule still in place
    message = [controller messageForEvent:@"Swrve.currency_given"];
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
    
    SwrveMessage *message = [controller messageForEvent:@"Swrve.currency_given"];
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
    message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNil(message);
    
    // Another 35 seconds and a message should be shown again
    self.swrveNowDate = [NSDate dateWithTimeInterval:35 sinceDate:self.swrveNowDate];
    
    message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
}

/**
 * When a campaign is loaded it should be initialised with the start time of the app, not with
 * the time the campaign was downloaded to ensure that the throttle limits count from start of session.
 */
- (void)testCampaignThrottleLimitsOnReset {
    id swrveMock = [self swrveMockWithTestJson:@"campaignsDelay"];
    SwrveMessageController *controller = [swrveMock messaging];

    TestShowMessageDelegateNoCustomFind *testDelegate = [[TestShowMessageDelegateNoCustomFind alloc] init];
    [controller setShowMessageDelegate:testDelegate];

    // Campaign has start delay of 60 seconds - so if we go 40 seconds into the future and reload the
    // campaigns it shouldn't show yet
    self.swrveNowDate = [NSDate dateWithTimeInterval:40 sinceDate:self.swrveNowDate];
    id mockSwrveQAUser = OCMClassMock([SwrveQAUser class]);
    [controller setQaUser:mockSwrveQAUser];
    
    SwrveMessage *message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNil(message);
    OCMVerify(([mockSwrveQAUser  trigger:@"Swrve.currency_given"
                             withMessage:message
                              withReason:@{@"102":@"{Campaign throttle limit} Too soon after launch. Wait until 00:01:00 +0000",
                                           @"103":@"There is no trigger in 103 that matches Swrve.currency_given with conditions (null)"
                                           }
                            withMessages:@{}]));

    // If we then go another 30 seconds into the future it should show
    // (if throttle limit is reset at campaign load it would only show after 40 + 60 seconds)
    self.swrveNowDate = [NSDate dateWithTimeInterval:30 sinceDate:self.swrveNowDate];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsDelay" ofType:@"json"];
    NSData *mockJsonData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockJsonData options:0 error:nil];
    [controller updateCampaigns:jsonDict];
    
    message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
}

/**
 * Test app throttle limits: delay after launch, delay between messages and max impressions
 */
- (void)testAppThrottleLimits {
    id swrveMock = [self swrveMockWithTestJson:@"campaignsDelay"];
    SwrveMessageController *controller = [swrveMock messaging];

    TestShowMessageDelegateNoCustomFind *testDelegate = [[TestShowMessageDelegateNoCustomFind alloc] init];
    [controller setShowMessageDelegate:testDelegate];

    id mockSwrveQAUser = OCMClassMock([SwrveQAUser class]);
    [controller setQaUser:mockSwrveQAUser];
    
    // First Message Delay
    // App has start delay of 30 seconds, so no message should be returned
    SwrveMessage *message = [controller messageForEvent:@"Swrve.user_purchase"];
    XCTAssertNil(message);
    OCMVerify([mockSwrveQAUser triggerFailure:@"Swrve.user_purchase"
                                   withReason:@"{App throttle limit} Too soon after launch. Wait until 00:00:30 +0000"]);
    
    // Go 40 seconds into future
    self.swrveNowDate = [NSDate dateWithTimeInterval:40 sinceDate:self.swrveNowDate];
    message = [controller messageForEvent:@"Swrve.user_purchase"];
    XCTAssertNotNil(message);
    [testDelegate showMessage:message];

    // Delay between messages
    // Go 5 seconds into the future, no message should show because there need to be 10 seconds between messages
    self.swrveNowDate = [NSDate dateWithTimeInterval:5 sinceDate:self.swrveNowDate];
    message = [controller messageForEvent:@"Swrve.user_purchase"];
    XCTAssertNil(message);
    OCMVerify([mockSwrveQAUser triggerFailure:@"Swrve.user_purchase"
                                   withReason:@"{App throttle limit} Too soon after last message. Wait until 00:00:50 +0000"]);
               
    // Another 15 seconds and a message should be shown again
    self.swrveNowDate = [NSDate dateWithTimeInterval:15 sinceDate:self.swrveNowDate];
    [controller setQaUser:mockSwrveQAUser];
    message = [controller messageForEvent:@"Swrve.user_purchase"];
    XCTAssertNotNil(message);
    [testDelegate showMessage:message];

    // Max impressions

    // Any message should only be shown 4 times, it has been shown twice already
    self.swrveNowDate = [NSDate dateWithTimeInterval:60 sinceDate:self.swrveNowDate];
    message = [controller messageForEvent:@"Swrve.user_purchase"];
    XCTAssertNotNil(message);
    [testDelegate showMessage:message];

    self.swrveNowDate = [NSDate dateWithTimeInterval:60 sinceDate:self.swrveNowDate];
    message = [controller messageForEvent:@"Swrve.user_purchase"];
    XCTAssertNotNil(message);
    [testDelegate showMessage:message];

    self.swrveNowDate = [NSDate dateWithTimeInterval:60 sinceDate:self.swrveNowDate];
    [controller setQaUser:mockSwrveQAUser];
    message = [controller messageForEvent:@"Swrve.user_purchase"];
    XCTAssertNil(message);
    OCMVerify([mockSwrveQAUser triggerFailure:@"Swrve.user_purchase"
                                   withReason:@"{App throttle limit} Too many messages shown"]);
}

- (void)testGetMessageForNonExistingTrigger {
    id swrveMock = [self swrveMockWithTestJson:@"campaignsDelay"];
    SwrveMessageController *controller = [swrveMock messaging];

    SwrveMessage *message = [controller messageForEvent:@"InvalidTrigger"];
    XCTAssertNil(message);
}

- (void)testGetMessageWithEmptyCampaigns {
    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    SwrveMessageController *controller = [swrveMock messaging];
    
    id mockSwrveQAUser = OCMClassMock([SwrveQAUser class]);
    [controller setQaUser:mockSwrveQAUser];

    NSData *emptyJson = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:emptyJson options:0 error:nil];
    
    [controller updateCampaigns:jsonDict];

    SwrveMessage *message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNil(message);
    
    OCMVerify([mockSwrveQAUser triggerFailure:@"Swrve.currency_given"
                                   withReason:@"No campaigns available"]);
}

/**
 * Test that a campaign with a start date in the future is not displayed
 * Ensure that it is displayed when we move time to after the start date
 * Test that it stops displaying when we move time past the campaign end date
 */
- (void)testCampaignsStartEndDates {
    id swrveMock = [self swrveMockWithTestJson:@"campaignsFuture"];
    SwrveMessageController *controller = [swrveMock messaging];

    // Campaign has start date in future so should not be shown
    id mockSwrveQAUser = OCMClassMock([SwrveQAUser class]);
    [controller setQaUser:mockSwrveQAUser];
    
    SwrveMessage *message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNil(message);
    
    OCMVerify(([mockSwrveQAUser trigger:@"Swrve.currency_given"
                            withMessage:message
                             withReason:@{@"105":@"Campaign 105 has not started yet"}
                           withMessages:@{}]));

    // 25 hours into the future the campaign should be available
    self.swrveNowDate = [NSDate dateWithTimeInterval:60*60*25 sinceDate:self.swrveNowDate];

    message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);

    // The campaign is only live for 24 hours, so another 24 hours into the future it should no longer be available
    self.swrveNowDate = [NSDate dateWithTimeInterval:60*60*24 sinceDate:self.swrveNowDate];

    message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNil(message);
    
    OCMVerify(([mockSwrveQAUser trigger:@"Swrve.currency_given"
                            withMessage:message
                             withReason:@{@"105":@"Campaign 105 has finished"}
                           withMessages:@{}]));
}

/**
 * Ensure messages are shown sequentially when order is set to round robin
 */
- (void)testRoundRobin {
    id swrveMock = [self swrveMockWithTestJson:@"campaignRoundRobin"];
    SwrveMessageController *controller = [swrveMock messaging];
    
    TestShowMessageDelegateNoCustomFind *testDelegate = [[TestShowMessageDelegateNoCustomFind alloc] init];
    [controller setShowMessageDelegate:testDelegate];

    // Campaign has start date in future so should not be shown
    for (int i = 1; i < 6; i++) {
        SwrveMessage *message = [controller messageForEvent:@"Swrve.currency_given"];
        XCTAssertNotNil(message);
        XCTAssertEqual([[message messageID] intValue], i);
        [testDelegate showMessage:message];
    }
}

/**
 * When messages are supposed to be shown in random order, ensure they're not shown sequentially
 */
- (void)testRandom {
    id swrveMock = [self swrveMockWithTestJson:@"campaignsRandom"];
    SwrveMessageController *controller = [swrveMock messaging];
    
    TestShowMessageDelegateNoCustomFind *testDelegate = [[TestShowMessageDelegateNoCustomFind alloc] init];
    [controller setShowMessageDelegate:testDelegate];

    int hits = 0;

    for (int i = 0; i < 60; i++) {
        SwrveMessage *message = [controller messageForEvent:@"Swrve.currency_given"];
        XCTAssertNotNil(message);
        [testDelegate showMessage:message];

        if ([[message messageID] intValue] == (i % 6) + 1) {
            hits++;
        }
    }

    XCTAssertNotEqual(hits, 60);
}

/**
 * Test actions when custom button pressed
 * - custom button callback called with correct action
 * - click event sent
 */
- (void)testCustomButtonPressed {
    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    SwrveMessageController *controller = [swrveMock messaging];

    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    SwrveMessage *message = [controller messageForEvent:@"Swrve.currency_given"];
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
    XCTAssertEqual([buttons count], 4);
    
    // access the UIViews in the subview of the SwrveMessageViewController
    NSArray *vcSubviews = [[[[viewController view] subviews] firstObject] subviews];
    NSMutableArray *uiButtons = [NSMutableArray new];
    
    // get all the buttons
    for (UIView *item in vcSubviews){
        if ([item isKindOfClass:[UISwrveButton class]]) {
            [uiButtons addObject:item];
        }
    }
    
    XCTAssertEqual([uiButtons count], 4);

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
            XCTAssertTrue([event rangeOfString:@"{\"name\":\"custom\"}"].location != NSNotFound);
        }
    }
    XCTAssertEqual(clickEventCount, 1);
}

/**
 * Tests install button pressed
 * - install button callback called with correct appStoreURL
 */
- (void)testInstallButtonPressed {
    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    SwrveMessageController *controller = [swrveMock messaging];

    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    SwrveMessage *message = [controller messageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];

    __block int installActionCount = 0;
    __block NSString* installURL;

    [controller setInstallButtonCallback:^(NSString* appStoreUrl) {
        installActionCount++;
        installURL = appStoreUrl;
        return NO;
    }];

    NSArray* buttons = [[viewController current_format] buttons];
    XCTAssertEqual([buttons count], 4);

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
    XCTAssertEqual(installActionCount, 1);
    XCTAssertNotNil(message);
    XCTAssertEqualObjects(installURL, @"https://itunes.apple.com/us/app/ascension-chronicle-godslayer/id441838733?mt=8");

    // Check if correct event was sent to Swrve for this button
    int clickEventCount = 0;
    for (NSString* event in [swrveMock eventBuffer]) {
        if ([event rangeOfString:@"Swrve.Messages.Message-165.click"].location != NSNotFound) {
            clickEventCount++;
        }
    }
    XCTAssertEqual(clickEventCount, 1);
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

    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    SwrveMessage *message = [controller messageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];
    __block NSString *campaignSubject = @"";
    __block NSString *buttonName = @"";

    __block int customActionCount = 0;
    __block int installActionCount = 0;
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

    [controller setInstallButtonCallback:^(NSString *appStoreUrl) {
        installActionCount++;
        return NO;
    }];
    
    [controller setClipboardButtonCallback:^(NSString *processedText) {
        clipboardActionCount++;
    }];

    NSArray *buttons = [[viewController current_format] buttons];
    XCTAssertEqual([buttons count],4);

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
    XCTAssertEqual(installActionCount, 0);
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

    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    SwrveMessage *message = [controller messageForEvent:@"Swrve.currency_given"];
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
    XCTAssertEqual([buttons count], 4);

    // access the UIViews in the subview of the SwrveMessageViewController
    NSArray *vcSubviews = [[[[viewController view] subviews] firstObject] subviews];
    NSMutableArray *uiButtons = [NSMutableArray new];

    // get all the buttons
    for (UIView *item in vcSubviews){
        if ([item isKindOfClass:[UISwrveButton class]]) {
            [uiButtons addObject:item];
        }
    }

    XCTAssertEqual([uiButtons count], 4);

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
            XCTAssertTrue([event rangeOfString:@"{\"name\":\"clipboard_action\"}"].location != NSNotFound);
        }
    }
    XCTAssertEqual(clickEventCount, 1);
}

/**
 * When a QA user has resetDevice set to YES the max impression count shouldn't apply
 */
- (void)testQAResetDevice {
    id swrveMock = [self swrveMockWithTestJson:@"campaignsQAReset"];
    SwrveMessageController *controller = [swrveMock messaging];

    TestShowMessageDelegateNoCustomFind *testDelegate = [[TestShowMessageDelegateNoCustomFind alloc] init];
    [controller setShowMessageDelegate:testDelegate];

    SwrveMessage *message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    [testDelegate showMessage:message];

    // QA user follows rules since the first campaign reload (thus impressions prevent from showing it)
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsQAReset" ofType:@"json"];
    NSData *mockJsonData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockJsonData options:0 error:nil];
    
    [controller updateCampaigns:jsonDict];
    
    message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNil(message);

    // An SDK reset will cause the rules to reset
    swrveMock = [self swrveMockWithTestJson:@"campaignsQAReset"];
    controller = [swrveMock messaging];
    [controller setShowMessageDelegate:testDelegate];

    // Message shows because rules have been reset
    message = [controller messageForEvent:@"Swrve.currency_given"];
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
    SwrveMessage *message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    XCTAssertEqual([[message messageID] intValue], 1);
    [testDelegate showMessage:message];

    // Message ID 2 should be second highest priority
    message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    XCTAssertEqual([[message messageID] intValue], 2);
    [testDelegate showMessage:message];

    // It should then go to round robin between 2 and 3
    message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    XCTAssertEqual([[message messageID] intValue], 3);
    [testDelegate showMessage:message];

    message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    XCTAssertEqual([[message messageID] intValue], 2);
}

- (void)testMessagePriorityReverse {
    // https://swrvedev.jira.com/browse/SWRVE-10432
    // We were not clearing the bucket of candidate messages, ever...
    id swrveMock = [self swrveMockWithTestJson:@"campaignsMessagePriorityReverse"];
    SwrveMessageController *controller = [swrveMock messaging];

    TestShowMessageDelegateNoCustomFind *testDelegate = [[TestShowMessageDelegateNoCustomFind alloc] init];
    [controller setShowMessageDelegate:testDelegate];

    // Highest priority first (first in round robin)
    SwrveMessage *message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    XCTAssertEqual([[message messageID] intValue], 2);
    [testDelegate showMessage:message];

    // Round robin later
    message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    XCTAssertEqual([[message messageID] intValue], 3);
    [testDelegate showMessage:message];

    // Lowest priority (first message in JSON)
    message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    XCTAssertEqual([[message messageID] intValue], 1);
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
    SwrveMessage *message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);
    XCTAssertEqual([[message messageID] intValue], 1);
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
    SwrveMessage *message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(conversation);
    XCTAssertEqual([[message messageID] intValue], 1);
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

    SwrveMessage *message = [controller messageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];

    OCMStub([swrveMock getNow]).andReturn([NSDate dateWithTimeInterval:40 sinceDate:[swrveMock getNow]]);

    // Ensure that if we try to display a second message without dismissing the first one this fails and the same message is still shown
    SwrveMessage *message2 = [controller messageForEvent:@"Swrve.currency_given"];
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
    [self changeOrientation:UIInterfaceOrientationPortrait];

    id swrveMock = [self swrveMockWithTestJson:@"campaignsBothOrientations"];
    SwrveMessageController *controller = [swrveMock messaging];

    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    SwrveMessage *message = [controller messageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];

    XCTAssertNotNil([viewController message]);
    XCTAssertEqual([[[viewController message] messageID] intValue], 165);
    XCTAssertEqual([[viewController current_format] orientation], SWRVE_ORIENTATION_PORTRAIT);

    // Press dismiss button
    UISwrveButton* dismissButton = [UISwrveButton new];
    [dismissButton setTag:0];
    [viewController onButtonPressed:dismissButton];

    // Rotate device
    [self changeOrientation:UIInterfaceOrientationLandscapeRight];

    // Show same message again
    [controller showMessage:message];
    viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];

    // Ensure message is now shown in landscape format
    XCTAssertNotNil([viewController message]);
    XCTAssertEqual([[[viewController message] messageID] intValue], 165);

    // Change orientation back to original
    [self changeOrientation:UIInterfaceOrientationPortrait];
}

/**
 * When a message is shown that supports both landscape and portrait and the device is
 * rotated, the message should still be there after rotation but with the new orientation format
 */
- (void)testMessageReappearsWithDifferentFormat {
    [self changeOrientation:UIInterfaceOrientationPortrait];

    id swrveMock = [self swrveMockWithTestJson:@"campaignsBothOrientations"];
    SwrveMessageController *controller = [swrveMock messaging];

    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    SwrveMessage *message = [controller messageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];

    XCTAssertNotNil([viewController message]);
    XCTAssertEqual([[[viewController message] messageID] intValue], 165);

    // Rotate device
    [self changeOrientation:UIInterfaceOrientationLandscapeRight];

    [viewController viewDidAppear:NO];

    // Ensure message is now shown in landscape format
    XCTAssertNotNil([viewController message]);
    XCTAssertEqual([[[viewController message] messageID] intValue], 165);

    // Change orientation back to original
    [self changeOrientation:UIInterfaceOrientationPortrait];
}

/**
 * When a message is shown that supports only portrait  and the device is
 * rotated, the message should still be there after rotation with the same format
 */
- (void)testMessageReappearsWithSameFormat {
    [self changeOrientation:UIInterfaceOrientationPortrait];

    id swrveMock = [self swrveMockWithTestJson:@"campaignsPortraitOnly"];
    SwrveMessageController *controller = [swrveMock messaging];

    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    SwrveMessage *message = [controller messageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];

    XCTAssertNotNil([viewController message]);
    XCTAssertEqual([[[viewController message] messageID] intValue], 165);

    // Rotate device
    [self changeOrientation:UIInterfaceOrientationLandscapeRight];
    viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];

    // Ensure message is still shown with the same format
    XCTAssertNotNil([viewController message]);
    XCTAssertEqual([[[viewController message] messageID] intValue], 165);

    // Change orientation back to original
    [self changeOrientation:UIInterfaceOrientationPortrait];
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
    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    [[swrveMock messaging] setCustomButtonCallback:customCallback];
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

    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    [[swrveMock messaging] setDismissButtonCallback:dismissCallback];
    [swrveMock messaging].dismissButtonCallback(@"campaignName", @"btnClose");

    XCTAssertEqualObjects(campaignName, @"campaignName");
    XCTAssertEqualObjects(buttonName, @"btnClose");
}

/**
 * Test that setting install action listener works
 */
- (void)testInstallActionListener {
    __block NSString* installActionResult = @"";

    SwrveInstallButtonPressedCallback installCallback = ^(NSString* action) {
        installActionResult = action;
        return NO;
    };
     id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    [[swrveMock messaging] setInstallButtonCallback:installCallback];
    [swrveMock messaging].installButtonCallback(@"InstallAction");

    XCTAssertEqualObjects(installActionResult, @"InstallAction");
}

/**
 * Test that setting personalised text button action listener works
 */
- (void)testClipboardButtonActionListener {
    __block NSString *clipboardButtonProcessedTextResult = @"";

    SwrveClipboardButtonPressedCallback clipboardButtonPressedCallback = ^(NSString* processedText) {
        clipboardButtonProcessedTextResult = processedText;
    };
    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    [[swrveMock messaging] setClipboardButtonCallback:clipboardButtonPressedCallback];
    [swrveMock messaging].clipboardButtonCallback(@"ProcessedText");

    XCTAssertEqualObjects(clipboardButtonProcessedTextResult, @"ProcessedText");
}


/**
 * Test that setting message personalisation listener works
 */
- (void)testMessagePersonalisationListener {
    __block NSDictionary* messagePersonalisationResult = nil;

    SwrveMessagePersonalisationCallback personalisationCallback = ^(NSDictionary* eventPayload) {
        messagePersonalisationResult = eventPayload;
        return messagePersonalisationResult;
    };
    
    id swrveMock = [self swrveMockWithTestJson:@"campaigns"];
    [[swrveMock messaging] setPersonalisationCallback:personalisationCallback];
    NSDictionary *result = [swrveMock messaging].personalisationCallback(@{@"test": @"passed"});
    
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
    [swrveMock stopMocking];
    
    swrveMock = [self swrveMockWithTestJson:@"campaigns" withConfig:config];
    [swrveMock appDidBecomeActive:nil];
    XCTAssertTrue([[swrveMock messaging] autoShowMessagesEnabled]);
    XCTAssertEqual([[swrveMock config] autoShowMessagesMaxDelay], 2000);

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    XCTAssertTrue([[swrveMock messaging] autoShowMessagesEnabled]);

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
    XCTAssertFalse([[swrveMock messaging] autoShowMessagesEnabled]);
}

/**
 * Ensure campaign settings are loaded correctly when a campaign is updated
 */
- (void)testCampaignStates {
    id swrveMock = [self swrveMockWithTestJson:@"campaignRoundRobin"];
    SwrveMessageController *controller = [swrveMock messaging];
    
    TestShowMessageDelegateNoCustomFind *testDelegate = [[TestShowMessageDelegateNoCustomFind alloc] init];
    [controller setShowMessageDelegate:testDelegate];

    XCTAssertEqual([[controller campaigns] count], 1);
    SwrveCampaign* campaign = [[controller campaigns] firstObject];

    XCTAssertEqual(campaign.ID, 102);
    XCTAssertEqual(campaign.state.next, 0);
    XCTAssertEqual(campaign.state.impressions, 0);

   [swrveMock currencyGiven:@"USD" givenAmount:123.54];

    SwrveMessage *messageShown = [testDelegate messageShown];
    XCTAssertNotNil(messageShown);
    XCTAssertEqual([[messageShown messageID] intValue], 1);

    // Make sure first message is shown, and that next and impressions have been updated
    SwrveCampaign* campaignShown = [messageShown campaign];
    XCTAssertEqual(campaignShown.ID, 102);
    XCTAssertEqual(campaignShown.state.next, 1);
    XCTAssertEqual(campaignShown.state.impressions, 1);

    // Fake that there were no campaigns before saving (can cause bugs if states are not saved properly)
    [swrveMock messaging].campaigns = [[NSMutableArray alloc] init];

    // Restart, and check campaign settings haven't been reset
    [swrveMock suspend:YES];
    [swrveMock shutdown];
    swrveMock = [self swrveMockWithTestJson:@"campaignRoundRobin"];
    controller = [swrveMock messaging];
    testDelegate = [[TestShowMessageDelegateNoCustomFind alloc] init];
    [controller setShowMessageDelegate:testDelegate];

    XCTAssertEqual([[controller campaigns] count], 1);
    campaign = [[controller campaigns] firstObject];

    XCTAssertEqual(campaign.ID, 102);
    XCTAssertEqual(campaign.state.next, 1);
    XCTAssertEqual(campaign.state.impressions, 1);

    // Try a second event and ensure that the impression is incremented
    [swrveMock currencyGiven:@"USD" givenAmount:50.0];
    messageShown = [testDelegate messageShown];
    XCTAssertNotNil(messageShown);
    XCTAssertEqual([[messageShown messageID] intValue], 2);

    // Make sure first message is shown, and that next and impressions have been updated
    campaignShown = [messageShown campaign];
    XCTAssertEqual(campaignShown.ID, 102);
    XCTAssertEqual(campaignShown.state.impressions, 2);
}


- (void)testCampaignStatesCannotGoOverLimit {
    int impressionAmount = 0;
    NSMutableArray *allEventsBuffer = [[NSMutableArray alloc] init];
    
    //max impressions rule set to 5
    while(impressionAmount < 5) {
        id swrveMock = [self swrveMockWithTestJson:@"campaignRoundRobin"];
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

        // Make sure first message is shown, and that next and impressions have been updated
        SwrveCampaign* campaignShown = [messageShown campaign];
        XCTAssertEqual(campaignShown.ID, 102);

        //increment the impressionAmount everytime we've shown the message
        impressionAmount++;

        XCTAssertEqual(campaignShown.state.impressions, impressionAmount);

        // Fake that there were no campaigns before saving (can cause bugs if states are not saved properly)
        [swrveMock messaging].campaigns = [[NSMutableArray alloc] init];

        [allEventsBuffer addObjectsFromArray:[swrveMock eventBuffer]];

        // Restart, and check campaign settings haven't been reset
        [swrveMock suspend:YES];
        [swrveMock shutdown];

        swrveMock = [self swrveMockWithTestJson:@"campaignRoundRobin"];
        controller = [swrveMock messaging];
    
        XCTAssertEqual([[controller campaigns] count], 1);
        campaign = [[controller campaigns] firstObject];

        XCTAssertEqual(campaign.ID, 102);
        XCTAssertEqual(campaign.state.impressions,impressionAmount);

        [allEventsBuffer addObjectsFromArray:[swrveMock eventBuffer]];

        [swrveMock suspend:YES];
        [swrveMock shutdown];
    }

    id swrveMock = [self swrveMockWithTestJson:@"campaignRoundRobin"];
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
 * Ensure QA user values are set when the server has the 'qa' key
 */
- (void)testQAUserLoaded {
    id swrveMock = [self swrveMockWithTestJson:@"campaignsQAUser"];
    XCTAssertNotNil([swrveMock messaging].qaUser);
    XCTAssertTrue([swrveMock messaging].qaUser.resetDevice);
}

/**
 * Test configurable color from config
 */
- (void)testDefaultBackgroundColor {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.inAppMessageBackgroundColor = [UIColor redColor];
    
    SwrveInAppMessageConfig *inAppConfig = [SwrveInAppMessageConfig new];
    inAppConfig.personalisationFont = [UIFont fontWithName:@"Papyrus" size:1];
    inAppConfig.personalisationBackgroundColor = [UIColor blackColor];
    inAppConfig.personalisationForegroundColor = [UIColor blueColor];
    config.inAppMessageConfig = inAppConfig;

    id swrveMock = [self swrveMockWithTestJson:@"campaigns" withConfig:config];
    SwrveMessageController *controller = [swrveMock messaging];

    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    SwrveMessage *message = [controller messageForEvent:@"Swrve.currency_given"];
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
    config.inAppMessageBackgroundColor = [UIColor redColor];
    
    id swrveMock = [self swrveMockWithTestJson:@"campaigns" withConfig:config];
    SwrveMessageController *controller = [swrveMock messaging];

    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    SwrveMessage *message = [controller messageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message];

    SwrveMessageViewController *viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];

    XCTAssertEqualObjects(viewController.inAppConfig.personalisationForegroundColor, [UIColor blackColor]);
    XCTAssertEqualObjects(viewController.inAppConfig.personalisationBackgroundColor, [UIColor clearColor]);
    XCTAssertEqualObjects(viewController.inAppConfig.personalisationFont, [UIFont systemFontOfSize:0]);
}

/**
 * Test configurable personalisation colors from config
 */
- (void)testPersonalisationConfig {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.inAppMessageBackgroundColor = [UIColor redColor];
    
    SwrveInAppMessageConfig *inAppConfig = [SwrveInAppMessageConfig new];
    inAppConfig.backgroundColor = [UIColor redColor];
    inAppConfig.personalisationFont = [UIFont italicSystemFontOfSize:1];
    inAppConfig.personalisationBackgroundColor = [UIColor blackColor];
    inAppConfig.personalisationForegroundColor = [UIColor blueColor];
    config.inAppMessageConfig = inAppConfig;
    
    id swrveMock = [self swrveMockWithTestJson:@"campaignsPersonalisation" withConfig:config];
    SwrveMessageController *controller = [swrveMock messaging];

    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    // mock date that lies within the start and end time of the campaign in the test json file campaignsMessageCenter
    NSDate *mockInitDate = [NSDate dateWithTimeIntervalSince1970:1362873600]; // March 10, 2013
    OCMStub([swrveMock getNow]).andReturn(mockInitDate);
    
    SwrveCampaign *campaign = [[controller messageCenterCampaigns] objectAtIndex:0];
  
    [controller showMessageCenterCampaign:campaign withPersonalisation: @{@"test_cp": @"test_value",
                                                                          @"test_custom":@"urlprocessed",
                                                                          @"test_display": @"display"}];

    SwrveMessageViewController *viewController = (SwrveMessageViewController *)[testDelegate viewControllerUsed];
    [viewController viewDidAppear:NO];

    XCTAssertEqualObjects(viewController.view.backgroundColor, [UIColor redColor]);
    XCTAssertEqualObjects(viewController.inAppConfig.personalisationForegroundColor, [UIColor blueColor]);
    XCTAssertEqualObjects(viewController.inAppConfig.personalisationBackgroundColor, [UIColor blackColor]);
    XCTAssertEqualObjects(viewController.inAppConfig.personalisationFont, [UIFont italicSystemFontOfSize:1]);
}

/**
 * Test configurable RRGGBB color from template
 */
- (void)testBackgroundColorFromTemplateRRGGBB {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.inAppMessageBackgroundColor = [UIColor blueColor];

    id swrveMock = [self swrveMockWithTestJson:@"campaignsRRGGBB" withConfig:config];
    SwrveMessageController *controller = [swrveMock messaging];

    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    SwrveMessage *message = [controller messageForEvent:@"Swrve.currency_given"];
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
    config.inAppMessageBackgroundColor = [UIColor blueColor];

    id swrveMock = [self swrveMockWithTestJson:@"campaignsAARRGGBB" withConfig:config];
    SwrveMessageController *controller = [swrveMock messaging];

    TestShowMessageDelegateWithViewController *testDelegate = [[TestShowMessageDelegateWithViewController alloc] init];
    [testDelegate setController:controller];
    [controller setShowMessageDelegate:testDelegate];

    SwrveMessage *message = [controller messageForEvent:@"Swrve.currency_given"];
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
    [[swrveMock messaging] updateCampaigns:jsonDict];

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
    [[swrveMock messaging] updateCampaigns:jsonDict];

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
    
    SwrveMessage *message = [controller messageForEvent:@"Swrve.currency_given"];
    XCTAssertNotNil(message);

    NSArray *eventsBuffer = [swrveMock eventBuffer];
    XCTAssertEqual([eventsBuffer count], 1);

    NSString *eventString = (NSString *)(eventsBuffer[0]);
    NSDictionary *event = [NSJSONSerialization JSONObjectWithData:[eventString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    XCTAssertEqualObjects(event[@"name"], @"Swrve.Messages.message_returned");
    XCTAssertNotNil(event[@"payload"]);

    NSDictionary *payload = event[@"payload"];
    XCTAssertNotNil([payload objectForKey:@"id"]);
    XCTAssertEqualObjects(payload[@"id"], @"165");
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

#pragma mark - orientation checks

#if TARGET_OS_IOS
- (void)changeOrientation:(UIInterfaceOrientation)orientation {
    [SwrveTestHelper changeToOrientation:orientation];
}
#endif
@end
