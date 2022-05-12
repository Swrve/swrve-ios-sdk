#import <XCTest/XCTest.h>
#import "SwrveTestHelper.h"
#import "SwrveTestConversationsHelper.h"
#import "SwrvePush.h"
#import "SwrveNotificationConstants.h"
#import "SwrveNotificationManager.h"
#import "SwrveMessageController+Private.h"

@interface SwrveNotificationManager (InternalAccess)
+ (void)updateLastProcessedPushId:(NSString *)pushId;
@end

@interface SwrveMessageController ()
@property (nonatomic, retain) UIWindow *inAppMessageWindow;
@property (nonatomic, retain) UIWindow *conversationWindow;
@end

@interface Swrve()
@property(atomic) SwrveRESTClient *restClient;

- (void)processNotificationResponseWithIdentifier:(NSString *)identifier andUserInfo:(NSDictionary *)userInfo;
- (NSString *)signatureKey;
@end

@interface MockRestClientNotifcationToCampaign : SwrveRESTClient

@end

@implementation MockRestClientNotifcationToCampaign

//Mock responses
- (void)sendHttpRequest:(NSMutableURLRequest *)request completionHandler:(void (^)(NSURLResponse *, NSData *, NSError *))handler {
    NSData *data = nil;
    NSError *error = nil;
    NSDictionary *headers = @{@"Content-Type" : @"application/json; charset=utf-8"};
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc]initWithURL:request.URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:headers];

    if ([request.URL.absoluteString containsString:@"fc972adec8076d203cbdfd8ca0e4b1bfa483abfb"]) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"fc972adec8076d203cbdfd8ca0e4b1bfa483abfb" ofType:nil];
        data = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
    } else if ([request.URL.absoluteString containsString:@"in_app_campaign_id=295411"]) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"ad_journey_campaign_message" ofType:@"json"];
        data = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
    } else if ([request.URL.absoluteString containsString:@"in_app_campaign_id=295412"]) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"ad_journey_campaign_conversation" ofType:@"json"];
        data = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
    } else if ([request.URL.absoluteString containsString:@"batch"]) {
        NSString *emptyJson = @"{}";
        data = [emptyJson dataUsingEncoding:NSUTF8StringEncoding];

        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey: NSLocalizedString(@"Operation was unsuccessful.", nil),
                                   NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The operation timed out.", nil),
                                   NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Have you tried turning it off and on again?", nil)
                                   };
        error = [NSError errorWithDomain:@"Swrve" code:500 userInfo:userInfo];
    }

    handler(response, data, error);
}

@end

@interface SwrveTestNotificationToCampaign : XCTestCase <SwrvePushResponseDelegate>

@end

@implementation SwrveTestNotificationToCampaign

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
    [SwrveNotificationManager updateLastProcessedPushId:@""];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

-(Swrve *)startSwrveAndProcessPush {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.autoDownloadCampaignsAndResources = false;

    TestableSwrve *swrve = [SwrveTestConversationsHelper initializeWithCampaignsFile:@"campaignsNone" andConfig:config];
    swrve.restClient = [MockRestClientNotifcationToCampaign new];

    NSDictionary *payload = @{
                @"text":@"Test",
                @"_p":@"123456",
                @"_sw":@{
                        @"campaign": @{
                                @"id":@"295411"
                                },
                        @"subtitle": @"Test Subtitle",
                        @"title": @"Test Title",
                        @"media": @{
                                @"title": @"Test Title",
                                @"body":  @"Test Body",
                                @"subtitle": @"Test Subtitle"
                                },
                        @"buttons": @[@{
                                          @"title": @"IAM",
                                          @"action_type": @"open_campaign",
                                          @"action": @298233
                                          }],
                        @"version" : @1
                        }
                };

    [swrve processNotificationResponseWithIdentifier:SwrveNotificationResponseDefaultActionKey andUserInfo:payload];
    
    return swrve;
}

- (void)testCampaignFromNotification_Shown {
    Swrve *swrve = [self startSwrveAndProcessPush];

    SwrveMessageController *vc = swrve.messaging;
    XCTAssertTrue(vc != nil);

    SwrveMessageViewController *mvc = (SwrveMessageViewController*)vc.inAppMessageWindow.rootViewController;
    XCTAssertTrue(mvc != nil);

    SwrveMessage *message = mvc.message;

    XCTAssertTrue([message.name isEqualToString:@"Double format"]);
    XCTAssertTrue([message.messageID isEqualToNumber:@298085]);
    [vc cleanupConversationUI];
}

- (void)testCampaignFromNotification_WrittenToCache {
    Swrve *swrve = [self startSwrveAndProcessPush];

    SwrveSignatureProtectedFile *campaignFile =  [[SwrveSignatureProtectedFile alloc] protectedFileType:SWRVE_NOTIFICATION_CAMPAIGN_FILE_DEBUG
                                                                                                 userID:swrve.userID
                                                                                           signatureKey:[swrve signatureKey]
                                                                                          errorDelegate:nil];
    NSData *data = [campaignFile readWithRespectToPlatform];
    NSDictionary *cachedDic = nil;
    if (data != nil) {

        NSError *error;
        cachedDic = [NSJSONSerialization JSONObjectWithData:data
                                                                  options:kNilOptions
                                                                    error:&error];
    }


    NSDictionary *campaignDic = [cachedDic objectForKey:@"campaign"];
    NSDictionary *additionalInfoDic = [cachedDic objectForKey:@"additional_info"];
    XCTAssertTrue([additionalInfoDic[@"version"] isEqualToNumber:@2]);

    NSDictionary *messageDic = [campaignDic objectForKey:@"message"];
    XCTAssertTrue([messageDic[@"id"] isEqualToNumber:@298085]);
    XCTAssertTrue([messageDic[@"name"] isEqualToString:@"Double format"]);
}

- (void)testCampaignFromNotification_PushEngagedEvent {
    Swrve *swrve = [self startSwrveAndProcessPush];

    NSMutableData *contents = [[NSMutableData alloc] initWithContentsOfURL:[swrve eventFilename]];
    if (contents == nil) { XCTFail(@"Event file nil"); return;}

    const NSUInteger length = [contents length];
    if (length <= 2) { XCTFail(@"Event file no content"); return;}

    [contents setLength:[contents length] - 2];
    NSString* file_contents = [[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding];

    NSString *eventArray = [NSString stringWithFormat:@"[%@]", file_contents];
    NSData *bodyData = [eventArray dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *body = [NSJSONSerialization JSONObjectWithData:bodyData  options:NSJSONReadingMutableContainers error:nil];

    NSArray *filtered = [body filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(name == %@)", @"Swrve.Messages.Push-123456.engaged"]];
    if ([filtered count] == 0) { XCTFail(@"Missing Swrve.Messages.Push-123456.engaged event"); return;}
}

- (void)testCampaignFromNotification_ImpressionEvent {
    Swrve *swrve = [self startSwrveAndProcessPush];

    XCTestExpectation *expectation = [self expectationWithDescription:@"ImpressionEvent"];
    [SwrveTestHelper waitForBlock:0.005 conditionBlock:^BOOL(){
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains %@",@"Swrve.Messages.Message-298085.impression"];
        NSArray *result = [[swrve eventBuffer] filteredArrayUsingPredicate:predicate];

        return [result count] == 1;

    } expectation:expectation];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];

}

@end
