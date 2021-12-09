#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <StoreKit/StoreKit.h>

#import "SwrveMessageController+Private.h"
#import "SwrveTestHelper.h"
#import "SwrveLocalStorage.h"
#import "SwrveUtils.h"
#import "SwrvePermissions.h"
#import "SwrveRESTClient.h"

@interface SwrveReceiptProvider()
- (NSData *)readMainBundleAppStoreReceipt API_AVAILABLE(ios(8.0));
@end

@interface Swrve()
@property (atomic) double campaignsAndResourcesFlushFrequency;
@property (atomic) double campaignsAndResourcesFlushRefreshDelay;
@property (atomic) NSTimer *campaignsAndResourcesTimer;
@property (atomic) int campaignsAndResourcesTimerSeconds;
@property (nonatomic) SwrveReceiptProvider *receiptProvider;
@property (atomic) SwrveRESTClient *restClient;

- (void)campaignsAndResourcesTimerTick:(NSTimer *)timer;
- (void)checkForCampaignAndResourcesUpdates:(NSTimer *)timer;
- (void)appDidBecomeActive:(NSNotification *)notification;
- (UInt64)secondsSinceEpoch;
- (UInt64)joinedDateMilliSeconds;
- (NSURL *)campaignsAndResourcesURL;
- (NSURL *)userResourcesDiffURL;
- (void)initSwrveRestClient:(NSTimeInterval)timeOut urlSssionDelegate:(id <NSURLSessionDelegate>)urlSssionDelegate;

@end

@interface SwrveTestCampaignAndResourcesUpdate : XCTestCase
@end

@implementation SwrveTestCampaignAndResourcesUpdate

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];

#if TARGET_OS_IOS /** exclude tvOS **/
    id classMock = OCMClassMock([SwrvePermissions class]);
    OCMStub(ClassMethod([classMock pushAuthorizationWithSDK:OCMOCK_ANY])).andReturn(@"unittest");
#endif
    
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

- (void)testCampaignsAndResourcesTimer {
    
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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop
    XCTAssertNil([swrve campaignsAndResourcesTimer], "Timer will be nil until session is started.");

    [swrveMock appDidBecomeActive:nil];
    XCTAssertNotNil([swrveMock campaignsAndResourcesTimer], "Timer will be not be nil after session is started.");
    OCMVerify([swrveMock refreshCampaignsAndResources]); // refresh called once immediately

    NSTimeInterval interval = [[swrveMock campaignsAndResourcesTimer] timeInterval];
    XCTAssertEqual(interval, 1, @"The timer should be set to 1 second intervals.");
}

- (void)testCampaignsAndResourcesTimerTickShouldNotCallRefresh {
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop

    [swrve setCampaignsAndResourcesFlushFrequency: 3.0]; // should be 3 ticks before checkForCampaignAndResourcesUpdates called

    OCMReject([swrveMock checkForCampaignAndResourcesUpdates:nil]);
    [swrve campaignsAndResourcesTimerTick:nil]; // first tick
    [swrve campaignsAndResourcesTimerTick:nil]; // second tick
}

- (void)testCampaignsAndResourcesTimerTickShouldCallRefresh {
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop
    
    [swrve setCampaignsAndResourcesFlushFrequency: 3.0]; // should be 3 ticks before checkForCampaignAndResourcesUpdates called
    
    [swrve campaignsAndResourcesTimerTick:nil]; // first tick
    [swrve campaignsAndResourcesTimerTick:nil]; // second tick
    [swrve campaignsAndResourcesTimerTick:nil]; // third tick
    OCMVerify([swrveMock checkForCampaignAndResourcesUpdates:OCMOCK_ANY]);
}

- (void)testCheckForCampaignAndResourcesUpdatesFromIAP {
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrve initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop
    
    id receiptProviderPartialMock = OCMPartialMock(swrve.receiptProvider);
    OCMStub([receiptProviderPartialMock readMainBundleAppStoreReceipt]).andReturn([@"fake_receipt" dataUsingEncoding:NSUTF8StringEncoding]);
    swrve.receiptProvider = receiptProviderPartialMock;

    // trigger invalid iap which should not call checkForCampaignAndResourcesUpdates
    SKPaymentTransaction *dummyTransactionFailed = OCMClassMock([SKPaymentTransaction class]);
    
    OCMStub([dummyTransactionFailed transactionState]).andReturn(SKPaymentTransactionStateFailed);
    
    //[given([dummyTransactionFailed transactionState]) willReturn:[[NSNumber alloc] initWithInt:SKPaymentTransactionStateFailed]];
    SKProduct *dummyProduct = OCMClassMock([SKProduct class]);
    [swrve iap:dummyTransactionFailed product:dummyProduct];

    OCMReject([swrveMock checkForCampaignAndResourcesUpdates:OCMOCK_ANY]);

    [swrveMock stopMocking]; // reset
    swrveMock = OCMPartialMock(swrve);

    // trigger valid iap which should call checkForCampaignAndResourcesUpdates
    SKPaymentTransaction * dummyTransactionSuccess = OCMClassMock([SKPaymentTransaction class]);
    OCMStub([dummyTransactionSuccess transactionState]).andReturn(SKPaymentTransactionStatePurchased);
    
    [swrve iap:dummyTransactionSuccess product:dummyProduct];

    OCMVerify([swrveMock checkForCampaignAndResourcesUpdates:OCMOCK_ANY]);
}

- (void)testJoinedDateMilliSeconds {
    
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
    
    OCMStub([swrveMock secondsSinceEpoch]).andReturn(1451610000);
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey"];
#pragma clang diagnostic pop
    
    UInt64 joinedDateMilliSeconds = [swrve joinedDateMilliSeconds];
    UInt64 expected = 1451610000000; //1451610000 * 1000
    
    XCTAssertEqual(joinedDateMilliSeconds,expected);
}

- (void)testCampaignsAndResourcesURL {
    
    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
    
    SwrveConfig *config = [SwrveConfig new];
    config.language = @"en-US";
    
    OCMStub([swrveMock secondsSinceEpoch]).andReturn(1451610000);
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey" config:config];
#pragma clang diagnostic pop
    
    NSURL *url = [swrveMock campaignsAndResourcesURL];
    
    // Construct expected url
    NSURLComponents *components = [NSURLComponents componentsWithString:@"https://123.content.swrve.com/api/1/user_content"];
    UIDevice *device = [UIDevice currentDevice];
    CGRect screen_bounds = [SwrveUtils deviceScreenBounds];
    
    components.queryItems = @[
                                [NSURLQueryItem queryItemWithName:@"user" value:[swrveMock userID]],
                                [NSURLQueryItem queryItemWithName:@"api_key" value:@"SomeAPIKey"],
                                [NSURLQueryItem queryItemWithName:@"app_version" value:@"1.0"],
                                [NSURLQueryItem queryItemWithName:@"joined" value:[NSString stringWithFormat:@"%ld", 1451610000000]],
                                [NSURLQueryItem queryItemWithName:@"version" value:[NSString stringWithFormat:@"%d", CAMPAIGN_VERSION]],
                                [NSURLQueryItem queryItemWithName:@"orientation" value:@"both"],
                                [NSURLQueryItem queryItemWithName:@"language" value:@"en-US"],
                                [NSURLQueryItem queryItemWithName:@"app_store" value:@"apple"],
                                [NSURLQueryItem queryItemWithName:@"device_width" value:[NSString stringWithFormat:@"%d", (int) screen_bounds.size.width]],
                                [NSURLQueryItem queryItemWithName:@"device_height" value:[NSString stringWithFormat:@"%d", (int) screen_bounds.size.height]],
                                [NSURLQueryItem queryItemWithName:@"os_version" value:[device systemVersion]],
                                [NSURLQueryItem queryItemWithName:@"device_name" value:[device model]],
                                [NSURLQueryItem queryItemWithName:@"conversation_version" value:[NSString stringWithFormat:@"%d", CONVERSATION_VERSION]],
                                [NSURLQueryItem queryItemWithName:@"os" value:[[device systemName] lowercaseString]],
                                [NSURLQueryItem queryItemWithName:@"device_type" value:[SwrveUtils platformDeviceType]],
                                [NSURLQueryItem queryItemWithName:@"embedded_campaign_version" value:[NSString stringWithFormat:@"%d", EMBEDDED_CAMPAIGN_VERSION]],
                                [NSURLQueryItem queryItemWithName:@"in_app_version" value:[NSString stringWithFormat:@"%d", IN_APP_CAMPAIGN_VERSION]]
                             ];
 
    NSURL *expectedUrl = components.URL;
    
    XCTAssertEqualObjects([url absoluteString],[expectedUrl absoluteString]);
}


- (void)testUserResourcesDiffURL {

    Swrve *swrve = [Swrve alloc];
    id swrveMock = OCMPartialMock(swrve);
    
    SwrveConfig *config = [SwrveConfig new];
    config.language = @"en-US";
    
    OCMStub([swrveMock secondsSinceEpoch]).andReturn(1451610000);
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [swrveMock initWithAppID:123 apiKey:@"SomeAPIKey" config:config];
#pragma clang diagnostic pop
    
    NSURL *url = [swrveMock userResourcesDiffURL];
    
    // Construct expected url
    NSURLComponents *components = [NSURLComponents componentsWithString:@"https://123.content.swrve.com/api/1/user_resources_diff"];
    components.queryItems = @[
                              [NSURLQueryItem queryItemWithName:@"user" value:[swrveMock userID]],
                              [NSURLQueryItem queryItemWithName:@"api_key" value:@"SomeAPIKey"],
                              [NSURLQueryItem queryItemWithName:@"app_version" value:@"1.0"],
                              [NSURLQueryItem queryItemWithName:@"joined" value:[NSString stringWithFormat:@"%ld", 1451610000000]],
                              ];
    
    NSURL *expectedUrl = components.URL;
    
    XCTAssertEqualObjects([url absoluteString],[expectedUrl absoluteString]);
}

@end
