#import <XCTest/XCTest.h>

#import <OCMockMacros.h>
#import <OCMArg.h>
#import <OCMMacroState.h>
#import <OCMockObject.h>
#import <OCMStubRecorder.h>
#import <OCMLocation.h>

#import "SwrveMessageViewController.h"
#import "Swrve.h"
#import "SwrveRESTClient.h"
#import "SwrveQA.h"
#import "SwrveMessageFocus.h"
#import "Swrve+Private.h"
#import "SwrveTestHelper.h"
#import "TestCapabilitiesDelegate.h"
#import "SwrveMigrationsManager.h"

@interface Swrve ()
- (NSDate *)getNow;

- (void)initSwrveRestClient:(NSTimeInterval)timeOut urlSssionDelegate:(id <NSURLSessionDelegate>)urlSssionDelegate;

@property(atomic) SwrveRESTClient *restClient;
@end

@interface SwrveMessageController ()
@property(nonatomic, retain) UIWindow *inAppMessageWindow;

- (void)showMessage:(SwrveMessage *)message withPersonalization:(NSDictionary *)personalization;

- (void)updateCampaigns:(NSDictionary *)campaignJson withLoadingPreviousCampaignState:(BOOL)isLoadingPreviousCampaignState;

@end

@interface SwrveMessageViewController ()
@property(nonatomic, retain) SwrveMessageFocus *messageFocus;
@end

@interface SwrveMigrationsManager ()
+ (void)markAsMigrated;
@end

@interface SwrveTVTestMessageController : XCTestCase
@property NSDate *swrveNowDate;
@end

@implementation SwrveTVTestMessageController

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
    [SwrveTestHelper createDummyAssets:[SwrveTVTestMessageController testJSONAssets]];
    self.swrveNowDate = [NSDate dateWithTimeIntervalSince1970:1362873600];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
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

- (void)testInAppMessageFocusDelegate {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    SwrveInAppMessageConfig *inAppMessageConfig = OCMPartialMock([SwrveInAppMessageConfig new]);
    id mockMessageFocusDelegate = OCMProtocolMock(@protocol(SwrveInAppMessageFocusDelegate));
    OCMStub([inAppMessageConfig inAppMessageFocusDelegate]).andReturn(mockMessageFocusDelegate);
    config.inAppMessageConfig = inAppMessageConfig;

    id swrveMock = [self swrveMockWithTestJson:@"campaigns" withConfig:config];

    SwrveMessageController *controller = [swrveMock messaging];
    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;

    SwrveMessage *message = (SwrveMessage *) [controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message withPersonalization:@{@"test_cp_action": @"some personalized value1", @"test_2": @"some personalized value2"}];

    SwrveMessageViewController *messageViewController = (SwrveMessageViewController *) [[controller inAppMessageWindow] rootViewController];

    // Expect the delegate to be called with mocked info
    id mockFocusUpdateContext = OCMClassMock([UIFocusUpdateContext class]);
    OCMExpect([mockFocusUpdateContext previouslyFocusedView]).andReturn([[UIView alloc] init]);
    OCMExpect([mockFocusUpdateContext nextFocusedView]).andReturn([[UIView alloc] init]);
    id mockFocusAnimationCoordinator = OCMClassMock([UIFocusAnimationCoordinator class]);
    UIView *parentUIView = messageViewController.view;
    OCMExpect([mockMessageFocusDelegate didUpdateFocusInContext:mockFocusUpdateContext
                                       withAnimationCoordinator:mockFocusAnimationCoordinator
                                                     parentView:parentUIView]);

    // Expect the applyFocusOnThemedUIButton to always be called
    id messageFocusMock = OCMPartialMock(messageViewController.messageFocus);
    OCMExpect([messageFocusMock applyFocusOnThemedUIButton:mockFocusUpdateContext]);

    // Fail if applyDefaultFocusInContext is called
    OCMReject([messageFocusMock applyDefaultFocusInContext:mockFocusUpdateContext]);

    // simulate a focus change
    [messageViewController didUpdateFocusInContext:mockFocusUpdateContext withAnimationCoordinator:mockFocusAnimationCoordinator];

    OCMVerifyAll(mockMessageFocusDelegate);
    OCMVerifyAll(messageFocusMock);
}

- (void)testWithoutInAppMessageFocusDelegate {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    id swrveMock = [self swrveMockWithTestJson:@"campaigns" withConfig:config];

    SwrveMessageController *controller = [swrveMock messaging];
    id testCapabilitiesDelegateMock = OCMPartialMock([TestCapabilitiesDelegate new]);
    controller.inAppMessageConfig.inAppCapabilitiesDelegate = testCapabilitiesDelegateMock;

    SwrveMessage *message = (SwrveMessage *) [controller baseMessageForEvent:@"Swrve.currency_given"];
    [controller showMessage:message withPersonalization:@{@"test_cp_action": @"some personalized value1", @"test_2": @"some personalized value2"}];

    SwrveMessageViewController *messageViewController = (SwrveMessageViewController *) [[controller inAppMessageWindow] rootViewController];

    id mockFocusUpdateContext = OCMClassMock([UIFocusUpdateContext class]);
    id mockFocusAnimationCoordinator = OCMClassMock([UIFocusAnimationCoordinator class]);

    // With no delegate, expect the applyFocusOnThemedUIButton and applyDefaultFocusInContext methods to be called
    id messageFocusMock = OCMPartialMock(messageViewController.messageFocus);
    OCMExpect([messageFocusMock applyFocusOnThemedUIButton:mockFocusUpdateContext]);
    OCMExpect([messageFocusMock applyDefaultFocusInContext:mockFocusUpdateContext]);

    // simulate a focus change
    [messageViewController didUpdateFocusInContext:mockFocusUpdateContext withAnimationCoordinator:mockFocusAnimationCoordinator];

    OCMVerifyAll(messageFocusMock);
}

@end
