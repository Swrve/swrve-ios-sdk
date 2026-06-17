#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SwrveTestHelper.h"
#import "SDAnimatedImageView.h"
#import "UIButton+WebCache.h"

@interface Swrve ()
- (void)initSwrveRestClient:(NSTimeInterval)timeOut urlSssionDelegate:(id <NSURLSessionDelegate>)urlSssionDelegate;

@end

@interface SwrveMigrationsManager ()
+ (void)markAsMigrated;
@end


@interface SwrveTestIAMCampaign : XCTestCase

+ (NSArray *)testJSONAssets;

@end

@implementation SwrveTestIAMCampaign

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
    [SwrveTestHelper createDummyAssets:[SwrveTestIAMCampaign testJSONAssets]];
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

- (void)testGifImage {

    // See the campaignsGif.json file for the makeup of the IAM.
    NSString *asset1 = [SwrveUtils sha1:[@"https://fakeitem/asset1.gif" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    NSString *asset2 = [SwrveUtils sha1:[@"https://fakeitem/asset2.png" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    NSString *asset3 = @"asset3_gif_image";
    NSString *asset4 = @"asset4_png_image";
    NSString *asset5 = [SwrveUtils sha1:[@"https://fakeitem/asset5.gif" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    NSString *asset6 = [SwrveUtils sha1:[@"https://fakeitem/asset6.png" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    NSString *asset7 = @"asset7_gif_button";
    NSString *asset8 = @"asset8_png_button";
    [SwrveTestHelper createDummyGifAssets:@[asset1, asset3, asset5, asset7]];
    [SwrveTestHelper createDummyAssets:@[asset2, asset4, asset6, asset8] withResourceName:@"swrve_logo" ofType:@"png"];

    id swrveMock = [self swrveMockWithTestJson:@"campaignsGif" withConfig:[SwrveConfig new]];
    SwrveMessageController *controller = [swrveMock messaging];
    SwrveCampaign *campaign = [[controller messageCenterCampaigns] objectAtIndex:0];
    [controller showMessageCenterCampaign:campaign];

    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    XCTAssertNotNil(messageViewController);
    XCTAssertNotNil(messageViewController.message);

    SwrveMessageUIView *messageUiView = [self swrveMessageUIViewFromController:messageViewController];

    // Basic assertion of type for images
    XCTAssertTrue([messageUiView.subviews[0] isKindOfClass:[SDAnimatedImageView class]]);   // 1 - external url gif image
    XCTAssertTrue([messageUiView.subviews[1] isKindOfClass:[UIImageView class]]);           // 2 - external url png image
    XCTAssertTrue([messageUiView.subviews[2] isKindOfClass:[SDAnimatedImageView class]]);   // 3 - gif image
    XCTAssertTrue([messageUiView.subviews[3] isKindOfClass:[UIImageView class]]);           // 4 - png image

    // Basic (hacky) assertion of background image for buttons.
    SwrveUIButton *button5 = (SwrveUIButton *)(messageUiView.subviews[4]);
#if TARGET_OS_IOS
    XCTAssertTrue([button5.subviews[0] isKindOfClass:[SDAnimatedImageView class]]);
#else
    // tvOS adds a focus view at position 0
    XCTAssertTrue([button5.subviews[1] isKindOfClass:[SDAnimatedImageView class]]);
#endif
    
    SwrveUIButton *button6 = (SwrveUIButton *)(messageUiView.subviews[5]);
    XCTAssertNotNil([button6 backgroundImageForState:UIControlStateNormal]);
    
    SwrveUIButton *button7 = (SwrveUIButton *)(messageUiView.subviews[6]);
#if TARGET_OS_IOS
    XCTAssertTrue([button7.subviews[0] isKindOfClass:[SDAnimatedImageView class]]);
#else
    // tvOS adds a focus view at position 0
    XCTAssertTrue([button7.subviews[1] isKindOfClass:[SDAnimatedImageView class]]);
#endif
    
    SwrveUIButton *button8 = (SwrveUIButton *)(messageUiView.subviews[7]);
    XCTAssertNotNil([button8 backgroundImageForState:UIControlStateNormal]);
}

- (SwrveMessageViewController *)messageViewControllerFrom:(SwrveMessageController *)controller {
    SwrveMessageViewController *viewController = (SwrveMessageViewController *) [[controller inAppMessageWindow] rootViewController];
    return viewController;
}

- (SwrveMessageUIView *)swrveMessageUIViewFromController:(SwrveMessageViewController *)viewController {
    SwrveMessagePageViewController *messagePageViewController = [self loadMessagePageViewController:viewController];
    return [[[messagePageViewController view] subviews] firstObject];
}

- (SwrveMessagePageViewController *)loadMessagePageViewController:(SwrveMessageViewController *)messageViewController {
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

// ---------------------------------------------------------------------------
// MARK: - visible_if render-time element visibility
// ---------------------------------------------------------------------------

- (void)testVisibleIfConditionTrueShowsButton {
    // campaign_visible_if.json: background image + always_visible button + conditional button
    NSDictionary *personalization = @{@"Recipient.show_button": @"true"};
    id swrveMock = [self swrveMockWithTestJson:@"campaign_visible_if"];
    SwrveMessageController *controller = [swrveMock messaging];
    // Pass personalization so canResolvePersonalization passes for the visible_if expression.
    SwrveCampaign *campaign = [[controller messageCenterCampaignsWithPersonalization:personalization] objectAtIndex:0];
    XCTAssertNotNil(campaign);

    [controller showMessageCenterCampaign:campaign withPersonalization:personalization];

    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    XCTAssertNotNil(messageViewController);

    SwrveMessageUIView *view = [self swrveMessageUIViewFromController:messageViewController];
    // image (UIImageView) + always_visible button (SwrveUIButton) + conditional button (SwrveUIButton, true) = 3
    XCTAssertEqual(3, view.subviews.count);
}

- (void)testVisibleIfConditionFalseHidesButton {
    NSDictionary *personalization = @{@"Recipient.show_button": @"false"};
    id swrveMock = [self swrveMockWithTestJson:@"campaign_visible_if"];
    SwrveMessageController *controller = [swrveMock messaging];
    SwrveCampaign *campaign = [[controller messageCenterCampaignsWithPersonalization:personalization] objectAtIndex:0];
    XCTAssertNotNil(campaign);

    [controller showMessageCenterCampaign:campaign withPersonalization:personalization];

    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    XCTAssertNotNil(messageViewController);

    SwrveMessageUIView *view = [self swrveMessageUIViewFromController:messageViewController];
    // image (UIImageView) + always_visible button (SwrveUIButton); conditional button (false) = hidden
    XCTAssertEqual(2, view.subviews.count);
}

@end
