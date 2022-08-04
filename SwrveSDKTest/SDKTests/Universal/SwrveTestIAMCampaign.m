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
    [SwrveTestHelper createDummyPngAssets:@[asset2, asset4, asset6, asset8]];

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
    UIButton *button5 = (messageUiView.subviews[4]);
    NSURL *button5URL = [button5 sd_backgroundImageURLForState:UIControlStateNormal];
    NSString *asset5Gif = [asset5 stringByAppendingString:@".gif"];
    XCTAssertTrue([[button5URL path] hasSuffix:asset5Gif]);                                 // 5 - external url gif button
    UIButton *button6 = (messageUiView.subviews[5]);
    XCTAssertNotNil([button6 backgroundImageForState:UIControlStateNormal]);                // 6 - external url png button
    UIButton *button7 = (messageUiView.subviews[6]);
    NSURL *button7URL = [button7 sd_backgroundImageURLForState:UIControlStateNormal];
    NSString *asset7Gif = [asset7 stringByAppendingString:@".gif"];
    XCTAssertTrue([[button7URL path] hasSuffix:asset7Gif]);                                 // 7 - gif button
    UIButton *button8 = (messageUiView.subviews[7]);
    XCTAssertNotNil([button8 backgroundImageForState:UIControlStateNormal]);                // 6 - png button
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

@end
