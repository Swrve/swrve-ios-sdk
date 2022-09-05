#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SwrveTestHelper.h"
#import "SwrveConversationStyler.h"
#import "SwrveAssetsManager.h"
#import "SwrveMessageController+Private.h"
#import "SwrveCampaign.h"
#import "UISwrveButton.h"
#import "SwrveButton.h"
#import "SwrveConversationCampaign.h"

@interface Swrve()

@property (atomic) SwrveRESTClient *restClient;
@property (atomic, readonly) SwrveMessageController *messaging;
- (void)initSwrveRestClient:(NSTimeInterval)timeOut urlSssionDelegate:(id <NSURLSessionDelegate>)urlSssionDelegate;
- (void)appDidBecomeActive:(NSNotification *)notification;
@end

@interface SwrveMessageController ()

- (id)initWithSwrve:(Swrve*)sdk;
- (void)writeToCampaignCache:(NSData*)campaignData;
- (void)updateCampaigns:(NSDictionary *)campaignDic withLoadingPreviousCampaignState:(BOOL) isLoadingPreviousCampaignState;
- (NSDate *)getNow;
@property (nonatomic, retain) SwrveAssetsManager *assetsManager;

@property (nonatomic, retain) NSDate *initialisedTime;
@end

@interface SwrveTestMessageCenterAPIIOS : XCTestCase

@end

@implementation SwrveTestMessageCenterAPIIOS

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

- (void)testConversationMessageCenter {
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];

    CGFloat height = [[UIScreen mainScreen] bounds].size.height;

    XCTestExpectation *expectation = [self expectationWithDescription:@"Screen"];
    [SwrveTestHelper waitForBlock:0.005 conditionBlock:^BOOL(){
        CGRect bounds = [[UIApplication sharedApplication] keyWindow].bounds;
        return bounds.size.height == height;

    } expectation:expectation];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];

    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationLandscapeRight];

    expectation = [self expectationWithDescription:@"WaitForRotation"];
    [SwrveTestHelper waitForBlock:0.005 conditionBlock:^BOOL(){
        CGRect frame = [[UIApplication sharedApplication] keyWindow].frame;
        return frame.size.width == height;

    } expectation:expectation];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];

    [SwrveTestHelper createDummyAssets:[SwrveTestMessageCenterAPIIOS testJSONAssets]];
    
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

    XCTAssertEqual([[controller messageCenterCampaigns] count], 3);

    SwrveConversationCampaign *campaign = [controller messageCenterCampaignWithID:15679 andPersonalization:nil];
    XCTAssertEqual(campaign.state.status,SWRVE_CAMPAIGN_STATUS_UNSEEN);
    XCTAssertEqualObjects(campaign.subject,@"Conversation subject");
    XCTAssertEqual([campaign.priority intValue], 5);

    // Display in-app message
    [controller showMessageCenterCampaign:campaign];
    
    UIColor *lbUIColor = [SwrveConversationStyler convertToUIColor:@"#FFFF0000"];
    expectation = [self expectationWithDescription:@"WaitForMessageLoad"];
    [SwrveTestHelper waitForBlock:0.005 conditionBlock:^BOOL(){
        bool expectedColor = CGColorEqualToColor(controller.swrveConversationItemViewController.view.superview.backgroundColor.CGColor, lbUIColor.CGColor);
        return (controller.swrveConversationItemViewController != nil && expectedColor );

    } expectation:expectation];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    
    //ensure that the corner radius was changed by the campaign JSON
    XCTAssertEqual(controller.swrveConversationItemViewController.view.layer.cornerRadius,22.5);

    // Dismiss the conversation
    [controller.swrveConversationItemViewController cancelButtonTapped:nil];

    expectation = [self expectationWithDescription:@"WaitForDismiss"];
    [SwrveTestHelper waitForBlock:0.005 conditionBlock:^BOOL(){
        return (controller.swrveConversationItemViewController == nil);

    } expectation:expectation];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];

    XCTAssertEqual(campaign.state.impressions,1);
    XCTAssertEqual(campaign.state.status,SWRVE_CAMPAIGN_STATUS_SEEN);

    // We don't get the conversation because the assets suddently dissapeared
    SwrveAssetsManager *assetsManager = [swrveMock messaging].assetsManager;
    NSMutableSet* assetsOnDisk = [assetsManager valueForKey:@"assetsOnDiskSet"];
    NSArray* previousAssets = [assetsOnDisk allObjects];
    [assetsOnDisk removeAllObjects];
    XCTAssertEqual([[controller messageCenterCampaigns] count], 1); // there is 1 embedded campaign

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
    [SwrveTestHelper setScreenOrientation:UIInterfaceOrientationPortrait];
}

@end
