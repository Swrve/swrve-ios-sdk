#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <SwrveMessageUIView.h>
#import "SwrveInAppCampaign.h"
#import "SwrveConversation.h"
#import "SwrveQA.h"
#import "SwrveTestHelper.h"
#import "SwrveUtils.h"
#import "SwrveMessageController+Private.h"
#import "SwrveMigrationsManager.h"
#import "SwrveMessagePageViewController.h"
#import "SDAnimatedImageView.h"
#import "UIButton+WebCache.h"

@interface Swrve ()
@property(atomic) SwrveMessageController *messaging;
- (void)initSwrveRestClient:(NSTimeInterval)timeOut urlSssionDelegate:(id <NSURLSessionDelegate>)urlSssionDelegate;
@property(atomic) SwrveRESTClient *restClient;

@end

@interface SwrveMigrationsManager ()
+ (void)markAsMigrated;
@end

@interface SwrveMessageController ()

- (void)updateCampaigns:(NSDictionary *)campaignJson withLoadingPreviousCampaignState:(BOOL)isLoadingPreviousCampaignState;
@property(nonatomic, retain) UIWindow *inAppMessageWindow;

@end

@interface SwrveTestCampaginHoldouts : XCTestCase

+ (NSArray *)testJSONAssets;

@end

@implementation SwrveTestCampaginHoldouts

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

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
    [SwrveTestHelper createDummyAssets:[SwrveTestCampaginHoldouts testJSONAssets]];
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

    // mock rest calls with success and empty data
    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
    id mockRestClient = OCMPartialMock(restClient);
    id mockResponse = OCMClassMock([NSHTTPURLResponse class]);
    OCMExpect([mockResponse statusCode]).andReturn(200);
    NSData *mockResponseData = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
    OCMStub([mockRestClient sendHttpRequest:OCMOCK_ANY completionHandler:([OCMArg invokeBlockWithArgs:mockResponse, mockResponseData, [NSNull null], nil])]);

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

- (void)testEmbeddedMessageHoldoutCallback {
    SwrveConfig *config = [SwrveConfig new];
    SwrveEmbeddedMessageConfig *embeddedConfig = [SwrveEmbeddedMessageConfig new];
    [embeddedConfig setEmbeddedCallback:^(SwrveEmbeddedMessage *message, NSDictionary *personalizationProperties, bool isControl) {
        XCTAssertTrue(isControl);
    }];

    config.embeddedMessageConfig = embeddedConfig;

    id swrveMock = [self swrveMockWithTestJson:@"campaignsHoldout" withConfig:config];
    SwrveMessageController *controller = [swrveMock messaging];

    NSDictionary* event =  @{@"type": @"event",
                             @"seqnum": @1111,
                             @"name": @"trigger_embedded",
                             @"payload": @{}};
    
    //It's up to dev to call the impression event
    OCMReject([swrveMock eventInternal:@"Swrve.Messages.Message-21.impression" payload: @{@"embedded": @"true"} triggerCallback:false]);
    bool shown = [controller eventRaised:event];
    XCTAssertTrue(shown);
    OCMVerifyAll(swrveMock);
}


- (void)testEmbeddedMessageHoldoutNoCallback {
    id swrveMock = [self swrveMockWithTestJson:@"campaignsHoldout"];
    SwrveMessageController *controller = [swrveMock messaging];

    NSDictionary* event =  @{@"type": @"event",
                             @"seqnum": @1111,
                             @"name": @"trigger_embedded",
                             @"payload": @{}};

    OCMExpect([swrveMock eventInternal:@"Swrve.Messages.Message-21.impression" payload: @{@"embedded": @"true"} triggerCallback:false]);
    bool shown = [controller eventRaised:event];
    XCTAssertFalse(shown);
    OCMVerifyAll(swrveMock);
}

- (void)testIAMMessageHoldout {
    id swrveMock = [self swrveMockWithTestJson:@"campaignsHoldout"];
    SwrveMessageController *controller = [swrveMock messaging];
    
    NSDictionary* event =  @{@"type": @"event",
                             @"seqnum": @1111,
                             @"name": @"trigger_iam",
                             @"payload": @{}};
    
    OCMExpect([swrveMock eventInternal:@"Swrve.Messages.Message-165.impression" payload: @{@"embedded": @"false"} triggerCallback:false]);
    bool shown = [controller eventRaised:event];
    XCTAssertFalse(shown);
    OCMVerifyAll(swrveMock);
}

- (void)testEmbeddedMessageWithControlNotShownButCampaignStateIsSaved{

    id swrveMock = [self swrveMockWithTestJson:@"campaignsHoldout" withConfig:[SwrveConfig new]];
    SwrveMessageController *controller = [swrveMock messaging];
    id mockController = OCMPartialMock(controller);

    NSDictionary* event =  @{@"type": @"event",
                             @"seqnum": @1111,
                             @"name": @"trigger_embedded",
                             @"payload": @{}};
    
    bool shown = [mockController eventRaised:event];
    XCTAssertFalse(shown);
    OCMVerify([mockController saveCampaignsState]);
}


- (void)testMessageWithControlNotShownButCampaignStateIsSaved{

    id swrveMock = [self swrveMockWithTestJson:@"campaignsHoldout" withConfig:[SwrveConfig new]];
    SwrveMessageController *controller = [swrveMock messaging];
    id mockController = OCMPartialMock(controller);

    NSDictionary* event =  @{@"type": @"event",
                             @"seqnum": @1111,
                             @"name": @"trigger_iam",
                             @"payload": @{}};
    
    bool shown = [mockController eventRaised:event];
    XCTAssertFalse(shown);
    OCMVerify([mockController saveCampaignsState]);
}


@end
