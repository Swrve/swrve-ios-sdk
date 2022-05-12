#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SwrveSDK.h"
#import "SwrveDeeplinkManager.h"
#import "SwrveCommon.h"
#import "SwrveRESTClient.h"
#import "SwrveTestHelper.h"
#import "SwrveLocalStorage.h"
#import "SwrveConversationItemViewController.h"
#import "SwrveCampaign.h"
#import "SwrveMessageController.h"

@interface SwrveMessageController ()
- (NSString *)campaignQueryString API_AVAILABLE(ios(7.0));
@property (nonatomic, retain) UIWindow *inAppMessageWindow;
@property (nonatomic, retain) UIWindow *conversationWindow;
@property (nonatomic, retain) SwrveConversationItemViewController *swrveConversationItemViewController;
@end

@interface SwrveDeeplinkManager ()
- (void)queueDeeplinkGenericEvent:(NSString *)installSource campaignID:(NSString *)campaignID campaignName:(NSString *)campaignName acitonType:(NSString *)actionType;
- (void)fetchCampaign:(NSURL *)url
           completion:(void (^)(NSURLResponse *response,NSDictionary *responseDic, NSError *error))completion;
- (void)writeCampaignDataToCache:(NSDictionary *)response fileType:(int)fileType;
- (void)campaignAssets:(NSDictionary *)campaignJson withCompletionHandler:(void (^)(SwrveCampaign * campaign))completionHandler;
- (void)showCampaign:(SwrveCampaign *)campaign;
- (NSURL *)campaignURL:(NSString *)campaignID;

@end

@interface Swrve()
@property(atomic) SwrveMessageController *messaging;
@property(atomic) SwrveRESTClient *restClient;
@property NSMutableArray* eventBuffer;
@property NSURL* eventFilename;
- (NSString *)signatureKey;
- (int)queueEvent:(NSString *)eventType data:(NSMutableDictionary *)eventData triggerCallback:(bool)triggerCallback;
- (NSString *)appVersion;
- (UInt64)joinedDateMilliSeconds;
- (NSString *)userID;
@end

@interface SwrveDeeplinkManager()
- (void)writeCampaignDataToCache:(NSDictionary *)response fileType:(int)fileType;
- (NSDictionary *)campaignsInCache:(int)fileType;
- (void)campaignAssets:(NSDictionary *)campaignJson withCompletionHandler:(void (^)(SwrveCampaign * campaign))completionHandler;
- (void)fetchCampaign:(NSURL *)url
           completion:(void (^)(NSURLResponse *response,NSDictionary *responseDic, NSError *error))completion;
- (SwrveSignatureProtectedFile *)signatureFileWithType:(int)type errorDelegate:(id <SwrveSignatureErrorDelegate>)delegate;
@end


@interface SwrveTestDeeplinkManager : XCTestCase

@end

@implementation SwrveTestDeeplinkManager

NSString *mockCacheDir;

- (void)setUp {
    [super setUp];
    mockCacheDir = [[NSBundle bundleForClass:[self class]] resourcePath]; // required for unit tests
    [SwrveTestHelper setUp];

}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

-(void)testFetchOfflineCampaignUrl {
    
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop
    
    SwrveDeeplinkManager *swrveDeeplinkManager = [[SwrveDeeplinkManager alloc] initWithSwrve:swrveMock];
    id mockSwrveDeeplinkManager = OCMPartialMock(swrveDeeplinkManager);
    
    NSMutableString *queryString = [NSMutableString stringWithFormat:@"?in_app_campaign_id=%@&user=%@&api_key=%@&app_version=%@&joined=%llu",
                                    @1,swrve.userID, swrve.apiKey, swrve.appVersion, swrve.joinedDateMilliSeconds];
    
    NSString *campaignQueryString = [[swrveMock messaging] campaignQueryString];
    [queryString appendFormat:@"&%@", campaignQueryString];
    
    NSURL *base_content_url = [NSURL URLWithString:[swrveMock config].contentServer];
    NSURL *adCampaignURL = [NSURL URLWithString:SWRVE_AD_CAMPAIGN_URL relativeToURL:base_content_url];
    NSURL *expected = [NSURL URLWithString:queryString relativeToURL:adCampaignURL];
    
    [mockSwrveDeeplinkManager fetchNotificationCampaigns:[[NSSet setWithObjects:@1,nil] mutableCopy]];
    
    OCMVerify([mockSwrveDeeplinkManager fetchCampaign:expected completion:OCMOCK_ANY]);
}

- (void)testFetchNotificationCampaigns {
    SwrveDeeplinkManager *swrveDeeplinkManager = [[SwrveDeeplinkManager alloc] initWithSwrve:nil];
    id mockSwrveDeeplinkManager = OCMPartialMock(swrveDeeplinkManager);
    
    OCMExpect([mockSwrveDeeplinkManager campaignAssets:OCMOCK_ANY withCompletionHandler:OCMOCK_ANY]);
    OCMExpect([mockSwrveDeeplinkManager writeCampaignDataToCache:@{
                                                                   @"1": @{
                                                                           @"campaign": @{
                                                                                   @"id":@1
                                                                                   }
                                                                           }
                                                                   }
                                                        fileType:SWRVE_NOTIFICATION_CAMPAIGNS_FILE]);
    
    id mockResponse = OCMClassMock([NSHTTPURLResponse class]);
    OCMExpect([mockResponse statusCode]).andReturn(200);
    NSDictionary *responseDic = @{
                                  @"campaign": @{
                                          @"id":@1
                                          }
                                  };
    OCMStub([mockSwrveDeeplinkManager fetchCampaign:OCMOCK_ANY completion:([OCMArg invokeBlockWithArgs:mockResponse,responseDic,[NSNull null],nil])]);
    [mockSwrveDeeplinkManager fetchNotificationCampaigns:[[NSSet setWithObjects:@1,nil] mutableCopy]];
    
    OCMVerifyAllWithDelay(mockSwrveDeeplinkManager,0.05);
}

- (void)testNotificationCache {
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop
   
    id localStorage = OCMClassMock([SwrveLocalStorage class]);
    OCMStub([localStorage swrveAppSupportDir]).andReturn(mockCacheDir);

    SwrveDeeplinkManager *swrveDeeplinkManager = [[SwrveDeeplinkManager alloc] initWithSwrve:swrveMock];
    id mockSwrveDeeplinkManager = OCMPartialMock(swrveDeeplinkManager);
    
    NSDictionary *expected = @{
                               @"1": @{
                                       @"campaign": @{
                                               @"id":@1
                                               }
                                       }
                               };
    
    [mockSwrveDeeplinkManager writeCampaignDataToCache:expected fileType:SWRVE_NOTIFICATION_CAMPAIGNS_FILE];
    NSDictionary *result = [mockSwrveDeeplinkManager campaignsInCache:SWRVE_NOTIFICATION_CAMPAIGNS_FILE];
    XCTAssertEqualObjects(expected, result);
}

- (void)testHandleDeeplink_Verfiy_QueueEvent_Content {
    id swrveMock = OCMClassMock([Swrve class]);
    
    SwrveDeeplinkManager *swrveDeeplinkManager = [[SwrveDeeplinkManager alloc]initWithSwrve:swrveMock];
    id mockSwrveDeeplinkManager = OCMPartialMock(swrveDeeplinkManager);
    OCMStub([mockSwrveDeeplinkManager fetchCampaign:OCMOCK_ANY completion:([OCMArg invokeBlockWithArgs:[NSNull null], [NSNull null], [NSNull null], nil])]);
    
    NSURL *url = [NSURL URLWithString:@"swrve://app?ad_content=295411&ad_source=facebook&ad_campaign=BlackFriday"];
    [mockSwrveDeeplinkManager handleDeeplink:url];
    
    NSDictionary *eventData = @{@"campaignType" :@"external_source_facebook",
                                @"actionType"   :@"reengage",
                                @"campaignId"   :@"295411",
                                @"contextId"    :@"BlackFriday",
                                @"id"           :@-1
                                };
    
    OCMVerify([swrveMock queueEvent:@"generic_campaign_event" data:[eventData mutableCopy] triggerCallback:NO]);
}

- (void)testHandleDeeplink_QueueDeeplinkGenericEvent_Called {
    SwrveDeeplinkManager *swrveDeeplinkManager = [[SwrveDeeplinkManager alloc]initWithSwrve:nil];
    id mockSwrveDeeplinkManager = OCMPartialMock(swrveDeeplinkManager);
    
    OCMStub([mockSwrveDeeplinkManager fetchCampaign:OCMOCK_ANY completion:([OCMArg invokeBlockWithArgs:[NSNull null], [NSNull null], [NSNull null], nil])]);
    
    NSURL *url = [NSURL URLWithString:@"swrve://app?ad_content=295411&ad_source=facebook&ad_campaign=BlackFriday"];
    [mockSwrveDeeplinkManager handleDeeplink:url];
    
    OCMVerify([mockSwrveDeeplinkManager queueDeeplinkGenericEvent:@"facebook" campaignID:@"295411" campaignName:@"BlackFriday" acitonType:@"reengage"]);
}

- (void)testQueueDeeplinkGenericEvent_InvalidContent_Rejected {
    id swrveMock = OCMClassMock([Swrve class]);
    OCMReject([swrveMock queueEvent:@"generic_campaign_event" data:OCMOCK_ANY triggerCallback:NO]);
    
    SwrveDeeplinkManager *swrveDeeplinkManager = [[SwrveDeeplinkManager alloc]initWithSwrve:swrveMock];
    
    //Try to add some invalid events on queue.
    [swrveDeeplinkManager queueDeeplinkGenericEvent:nil campaignID:nil campaignName:nil acitonType:nil];
    [swrveDeeplinkManager queueDeeplinkGenericEvent:@"" campaignID:@"291145" campaignName:@"blackfriday" acitonType:@"install"];
}

- (void)testHandleDeeplink_MessageShown {
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop

    NSDictionary *payload = @{@"embedded": @"false"};
    OCMExpect([swrveMock eventInternal:@"Swrve.Messages.Message-298085.impression" payload:payload triggerCallback:false]);

    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
    id mockRestClient = OCMPartialMock(restClient);
    OCMStub([swrveMock restClient]).andReturn(mockRestClient);
    id mockResponse = OCMClassMock([NSHTTPURLResponse class]);
    OCMExpect([mockResponse statusCode]).andReturn(200);
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"ad_journey_campaign_message" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];

    OCMStub([mockRestClient sendHttpRequest:OCMOCK_ANY
                          completionHandler:([OCMArg invokeBlockWithArgs:mockResponse, mockData, [NSNull null], nil])]);
    
    SwrveDeeplinkManager *swrveDeeplinkManger = [[SwrveDeeplinkManager alloc]initWithSwrve:swrveMock];
    NSURL *url = [NSURL URLWithString:@"swrve://app?ad_content=295411&ad_source=facebook&ad_campaign=BlackFriday"];
    [swrveDeeplinkManger handleDeeplink:url];
    
    SwrveMessageController *vc = swrve.messaging;
    XCTAssertTrue(vc != nil);
    
    SwrveMessageViewController *mvc = (SwrveMessageViewController*)vc.inAppMessageWindow.rootViewController;
    XCTAssertTrue(mvc != nil);
    XCTAssertEqual(vc.inAppMessageWindow.backgroundColor, [UIColor clearColor]);
    
    SwrveMessage *message = mvc.message;
    
    XCTAssertTrue([message.name isEqualToString:@"Double format"]);
    XCTAssertTrue([message.messageID isEqualToNumber:@298085]);

    OCMVerifyAllWithDelay(swrveMock, 5);
}

- (void)testHandleDeeplink_ConversationShown {
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop
    
    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
    id mockRestClient = OCMPartialMock(restClient);
    OCMStub([swrveMock restClient]).andReturn(mockRestClient);
    id mockResponse = OCMClassMock([NSHTTPURLResponse class]);
    OCMExpect([mockResponse statusCode]).andReturn(200);
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"ad_journey_campaign_conversation" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    
    OCMStub([mockRestClient sendHttpRequest:OCMOCK_ANY
                          completionHandler:([OCMArg invokeBlockWithArgs:mockResponse, mockData, [NSNull null], nil])]);
    
    SwrveDeeplinkManager *swrveDeeplinkManger = [[SwrveDeeplinkManager alloc]initWithSwrve:swrveMock];
    NSURL *url = [NSURL URLWithString:@"swrve://app?ad_content=295412&ad_source=facebook&ad_campaign=BlackFriday"];
    [swrveDeeplinkManger handleDeeplink:url];
    
    SwrveMessageController *vc = swrve.messaging;
    XCTAssertTrue(vc != nil);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Event"];
    [SwrveTestHelper waitForBlock:0.005 conditionBlock:^BOOL(){
        return (vc.conversationWindow != nil);
    } expectation:expectation];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    
    XCTAssertTrue(vc.conversationWindow != nil);
    
    SwrveConversationItemViewController *swrveConversationItemViewController = vc.swrveConversationItemViewController;
    XCTAssertTrue(swrveConversationItemViewController != nil);
    
    XCTAssertTrue([swrveConversationItemViewController.conversation.name isEqualToString:@"FB Ad Journey Conversation Test"]);
    XCTAssertTrue([swrveConversationItemViewController.conversation.conversationID isEqualToNumber:@8587]);
    
    //Check events buffer for start and impression event
    NSArray *eventsBuffer = [swrveMock eventBuffer];
    NSString *bufferStringStart = (NSString*)(eventsBuffer[0]);
    NSDictionary *bufferDicStart = [NSJSONSerialization JSONObjectWithData:[bufferStringStart dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    XCTAssertTrue([bufferDicStart[@"name"] isEqualToString:@"Swrve.Conversations.Conversation-8587.start"]);
    
    NSString *bufferStringImpression = (NSString*)(eventsBuffer[1]);
    NSDictionary *bufferDicImpression = [NSJSONSerialization JSONObjectWithData:[bufferStringImpression dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    XCTAssertTrue([bufferDicImpression[@"name"] isEqualToString:@"Swrve.Conversations.Conversation-8587.impression"]);
}

- (void)testHandleDeeplink_MessageShownOncePerAppLoad {
    //once showCampaign is called, fetchCampaign should no longer be called due to alreadySeenCampaignID check.
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop
    
    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
    id mockRestClient = OCMPartialMock(restClient);
    OCMStub([swrveMock restClient]).andReturn(mockRestClient);
    id mockResponse = OCMClassMock([NSHTTPURLResponse class]);
    OCMExpect([mockResponse statusCode]).andReturn(OCMOCK_VALUE(200));
    
    OCMStub([mockRestClient sendHttpRequest:OCMOCK_ANY
                          completionHandler:([OCMArg invokeBlockWithArgs:[NSNull null], [NSNull null], [NSNull null], nil])]);
    
    SwrveDeeplinkManager *swrveDeeplinkManager = [[SwrveDeeplinkManager alloc]initWithSwrve:swrveMock];
    id mockSwrveDeeplinkManager = OCMPartialMock(swrveDeeplinkManager);
    
    SwrveCampaign *campaign = [SwrveCampaign new];
    campaign.ID = 295412;
    
    OCMStub([mockSwrveDeeplinkManager campaignAssets:OCMOCK_ANY withCompletionHandler:([OCMArg invokeBlockWithArgs:campaign, nil])]);
    OCMStub([mockSwrveDeeplinkManager writeCampaignDataToCache:nil fileType:3]);
    
    //confirm handleDeferredDeeplink is only processed once.
    NSURL *url = [NSURL URLWithString:@"swrve://app?ad_content=295412&ad_source=facebook&ad_campaign=BlackFriday"];
    [mockSwrveDeeplinkManager handleDeferredDeeplink:url];
    OCMVerify([mockSwrveDeeplinkManager fetchCampaign:OCMOCK_ANY completion:OCMOCK_ANY]);
    
    //confirm further calls with same id aren't processed
    OCMReject([mockSwrveDeeplinkManager fetchCampaign:OCMOCK_ANY completion:OCMOCK_ANY]);
    url = [NSURL URLWithString:@"swrve://app?ad_content=295412&ad_source=facebook&ad_campaign=BlackFriday"];
    [mockSwrveDeeplinkManager handleDeferredDeeplink:url];
}

- (void)testIsSwrveDeeplink {
    XCTAssertTrue([SwrveDeeplinkManager isSwrveDeeplink:nil] == false);
    
    NSURL *url = [NSURL URLWithString:@"swrve://app?"];
    XCTAssertTrue([SwrveDeeplinkManager isSwrveDeeplink:url] == false);
    
    url = [NSURL URLWithString:@"swrve://app?param1=1&param2=2"];
    XCTAssertTrue([SwrveDeeplinkManager isSwrveDeeplink:url] == false);
    
    url = [NSURL URLWithString:@"swrve://app?param1=1&ad_content=2"];
    XCTAssertTrue([SwrveDeeplinkManager isSwrveDeeplink:url] == true);
    
    url = [NSURL URLWithString:@"customer://?param1=1&ad_content=2"];
    XCTAssertTrue([SwrveDeeplinkManager isSwrveDeeplink:url] == true);
}

- (void)testFetchCampaign_Nil {
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop
    
    SwrveDeeplinkManager *swrveDeeplinkManager = [[SwrveDeeplinkManager alloc]initWithSwrve:swrveMock];
    
    XCTestExpectation *campaignResponse = [self expectationWithDescription:@"Load Campaign"];
    @try {
        [swrveDeeplinkManager fetchCampaign:nil
                                 completion:^(NSURLResponse *response, NSDictionary *responseDic, NSError *error) {
                [campaignResponse fulfill];
        }];
        
    } @catch (NSError *error) {
        XCTFail("Load campaign throw an error");
    }
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"loadCampaign callback failed");
        }
    }];
}

- (void)testWriteCache_Nil {
    SwrveDeeplinkManager *swrveDeeplinkManger = [[SwrveDeeplinkManager alloc]initWithSwrve:nil];
    @try {
        [swrveDeeplinkManger writeCampaignDataToCache:nil fileType:0];
    } @catch (NSError *error) {
        XCTFail("writeCampaignDataToCache throw an error");
    }
}

- (void)testMessageLoadedFromCache {
    id localStorage = OCMClassMock([SwrveLocalStorage class]);
    OCMStub([localStorage swrveAppSupportDir]).andReturn(mockCacheDir);
    
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop
    
    SwrveDeeplinkManager *swrveDeeplinkManager = [[SwrveDeeplinkManager alloc] initWithSwrve:swrveMock];
    id mockSwrveDeeplinkManager = OCMPartialMock(swrveDeeplinkManager);
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"external_campaigns" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:mockData
                                                         options:NSJSONReadingMutableContainers
                                                           error:nil];
    
    [mockSwrveDeeplinkManager writeCampaignDataToCache:json
                                              fileType:SWRVE_NOTIFICATION_CAMPAIGNS_FILE];
    
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: NSLocalizedString(@"Operation was unsuccessful.", nil),
                               NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The operation timed out.", nil),
                               NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Have you tried turning it off and on again?", nil)
                               };
    NSError *error = [NSError errorWithDomain:@"Swrve" code:500 userInfo:userInfo];
    
    SwrveCampaign *campaign = [SwrveCampaign new];
    campaign.ID = 295412;
    
    NSDictionary *cachedCampaign = [json objectForKey:@"1"];
    OCMStub([mockSwrveDeeplinkManager campaignAssets:cachedCampaign withCompletionHandler:([OCMArg invokeBlockWithArgs:campaign, nil])]);
    OCMStub([mockSwrveDeeplinkManager fetchCampaign:OCMOCK_ANY completion:([OCMArg invokeBlockWithArgs:[NSNull null],[NSNull null],error,nil])]);
    
    [mockSwrveDeeplinkManager handleNotificationToCampaign:@"1"];
    
    OCMVerify([mockSwrveDeeplinkManager showCampaign:[OCMArg checkWithBlock:^(SwrveCampaign *campaign){
        XCTAssertEqual(campaign.ID,295412);
        return [campaign isKindOfClass:[SwrveCampaign class]];
    }]]);
}

- (void)testHandleDeeplink_Personalization_MessageShown {
    Swrve *swrve = [Swrve alloc];

    SwrveMessagePersonalizationCallback personalizationCallback = ^(NSDictionary* eventPayload) {
        return @{@"test_key": @"test_value"};
    };
    
    id swrveMock = OCMPartialMock(swrve);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop

    NSDictionary *payload = @{@"embedded": @"false"};
    OCMExpect([swrveMock eventInternal:@"Swrve.Messages.Message-298085.impression" payload:payload triggerCallback:false]);

    SwrveMessageController *vc = swrve.messaging;
    [vc setPersonalizationCallback:personalizationCallback];
    
    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
    id mockRestClient = OCMPartialMock(restClient);
    OCMStub([swrveMock restClient]).andReturn(mockRestClient);
    id mockResponse = OCMClassMock([NSHTTPURLResponse class]);
    OCMExpect([mockResponse statusCode]).andReturn(200);
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"ad_journey_campaign_message_personalization" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    
    OCMStub([mockRestClient sendHttpRequest:OCMOCK_ANY
                          completionHandler:([OCMArg invokeBlockWithArgs:mockResponse, mockData, [NSNull null], nil])]);
    
    SwrveDeeplinkManager *swrveDeeplinkManger = [[SwrveDeeplinkManager alloc]initWithSwrve:swrveMock];
    NSURL *url = [NSURL URLWithString:@"swrve://app?ad_content=295411&ad_source=facebook&ad_campaign=BlackFriday"];
    [swrveDeeplinkManger handleDeeplink:url];
    
    XCTAssertTrue(vc != nil);
    
    SwrveMessageViewController *mvc = (SwrveMessageViewController*)vc.inAppMessageWindow.rootViewController;
    XCTAssertTrue(mvc != nil);
    XCTAssertEqual(vc.inAppMessageWindow.backgroundColor, [UIColor clearColor]);
    
    SwrveMessage *message = mvc.message;
    
    XCTAssertTrue([message.name isEqualToString:@"Double format"]);
    XCTAssertTrue([message.messageID isEqualToNumber:@298085]);

    OCMVerifyAllWithDelay(swrveMock, 5);
}

- (void)testHandleDeeplink_Personalization_MessageNotShown {
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop
    
    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
    id mockRestClient = OCMPartialMock(restClient);
    OCMStub([swrveMock restClient]).andReturn(mockRestClient);
    id mockResponse = OCMClassMock([NSHTTPURLResponse class]);
    OCMExpect([mockResponse statusCode]).andReturn(200);
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"ad_journey_campaign_message_personalization" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    
    OCMStub([mockRestClient sendHttpRequest:OCMOCK_ANY
                          completionHandler:([OCMArg invokeBlockWithArgs:mockResponse, mockData, [NSNull null], nil])]);
    
    SwrveDeeplinkManager *swrveDeeplinkManger = [[SwrveDeeplinkManager alloc]initWithSwrve:swrveMock];
    NSURL *url = [NSURL URLWithString:@"swrve://app?ad_content=295411&ad_source=facebook&ad_campaign=BlackFriday"];
    [swrveDeeplinkManger handleDeeplink:url];
    
    SwrveMessageController *vc = swrve.messaging;
    XCTAssertTrue(vc != nil);
    
    SwrveMessageViewController *mvc = (SwrveMessageViewController*)vc.inAppMessageWindow.rootViewController;
    XCTAssertNil(mvc);
}

- (void)testHandleDeeplink_ImagePersonalization_MessageShown {
    Swrve *swrve = [Swrve alloc];
    SwrveMessagePersonalizationCallback personalizationCallback = ^(NSDictionary* eventPayload) {
        return @{@"test_key_with_fallback": @"asset1"};
    };
    
    SwrveConfig *config = [SwrveConfig new];
    SwrveInAppMessageConfig *inAppConfig = [SwrveInAppMessageConfig new];
    [inAppConfig setPersonalizationCallback:personalizationCallback];
    [config setInAppMessageConfig:inAppConfig];
    
    id swrveMock = OCMPartialMock(swrve);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey" config:config];
#pragma clang diagnostic pop

    NSDictionary *payload = @{@"embedded": @"false"};
    OCMExpect([swrveMock eventInternal:@"Swrve.Messages.Message-298087.impression" payload:payload triggerCallback:false]);

    SwrveMessageController *vc = swrve.messaging;
    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
    id mockRestClient = OCMPartialMock(restClient);
    OCMStub([swrveMock restClient]).andReturn(mockRestClient);
    id mockResponse = OCMClassMock([NSHTTPURLResponse class]);
    OCMExpect([mockResponse statusCode]).andReturn(200);
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"ad_journey_campaign_message_image_personalization" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    
    OCMStub([mockRestClient sendHttpRequest:OCMOCK_ANY
                          completionHandler:([OCMArg invokeBlockWithArgs:mockResponse, mockData, [NSNull null], nil])]);
    
    SwrveDeeplinkManager *swrveDeeplinkManger = [[SwrveDeeplinkManager alloc]initWithSwrve:swrveMock];
    NSURL *url = [NSURL URLWithString:@"swrve://app?ad_content=295411&ad_source=facebook&ad_campaign=BlackFriday"];
    [swrveDeeplinkManger handleDeeplink:url];
    
    XCTAssertTrue(vc != nil);
    
    SwrveMessageViewController *mvc = (SwrveMessageViewController*)vc.inAppMessageWindow.rootViewController;
    XCTAssertTrue(mvc != nil);
    XCTAssertEqual(vc.inAppMessageWindow.backgroundColor, [UIColor clearColor]);
    
    SwrveMessage *message = mvc.message;
    XCTAssertTrue([message.name isEqualToString:@"Image Personalization Campaign"]);
    XCTAssertTrue([message.messageID isEqualToNumber:@298087]);

    OCMVerifyAllWithDelay(swrveMock, 5);
}

- (void)testHandleDeeplink_Embedded_CallbackFired {
    Swrve *swrve = [Swrve alloc];
    
    __block SwrveEmbeddedMessage *embmessage = nil;
    SwrveConfig *config = [SwrveConfig new];
    SwrveEmbeddedMessageConfig *embConfig = [SwrveEmbeddedMessageConfig new];
    [embConfig setEmbeddedMessageCallback:^(SwrveEmbeddedMessage *message) {
        embmessage = message;
    }];
    
    id swrveMock = OCMPartialMock(swrve);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey" config:config];
#pragma clang diagnostic pop
    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
    id mockRestClient = OCMPartialMock(restClient);
    OCMStub([swrveMock restClient]).andReturn(mockRestClient);
    id mockResponse = OCMClassMock([NSHTTPURLResponse class]);
    OCMExpect([mockResponse statusCode]).andReturn(200);
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"ad_journey_campaign_embedded_message" ofType:@"json"];
    NSData *mockData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    
    OCMStub([mockRestClient sendHttpRequest:OCMOCK_ANY
                          completionHandler:([OCMArg invokeBlockWithArgs:mockResponse, mockData, [NSNull null], nil])]);
    
    SwrveDeeplinkManager *swrveDeeplinkManger = [[SwrveDeeplinkManager alloc]initWithSwrve:swrveMock];
    NSURL *url = [NSURL URLWithString:@"swrve://app?ad_content=295411&ad_source=facebook&ad_campaign=BlackFriday"];
    [swrveDeeplinkManger handleDeeplink:url];

    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Callback"];
    [SwrveTestHelper waitForBlock:0.005 conditionBlock:^BOOL(){
        return !(embmessage = nil);
    } expectation:expectation];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

@end
