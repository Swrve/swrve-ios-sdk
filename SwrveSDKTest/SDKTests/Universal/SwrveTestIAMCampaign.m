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
    NSString *filePath = [[NSBundle mainBundle] pathForResource:jsonFileName ofType:@"json"];
    NSData *mockJsonData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:mockJsonData options:0 error:nil];
    return [self swrveMockWithCampaigns:jsonDict withConfig:config];
}

- (id)swrveMockWithCampaigns:(NSDictionary *)jsonDict withConfig:(SwrveConfig *)config {
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

    BOOL isLoadingPreviousCampaignState = ![[SwrveQA sharedInstance] resetDeviceState];
    [[swrveMock messaging] updateCampaigns:jsonDict withLoadingPreviousCampaignState:isLoadingPreviousCampaignState notifyCampaignsUpdated:NO];

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

// ---------------------------------------------------------------------------
// MARK: - Assets queued for buttons
// ---------------------------------------------------------------------------

- (NSDictionary *)firstCampaignInFile:(NSString *)jsonFileName {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:jsonFileName ofType:@"json"];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:filePath] options:0 error:nil];
    return [[json objectForKey:@"campaigns"] firstObject];
}

// campaign_native_button_basics, with the first format's MButton1 changed by the block
- (NSDictionary *)buttonBasicsCampaignWithFirstButton:(void (^)(NSMutableDictionary *button))change {
    NSData *data = [NSJSONSerialization dataWithJSONObject:[self firstCampaignInFile:@"campaign_native_button_basics"] options:0 error:nil];
    NSMutableDictionary *campaignDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    NSDictionary *format = [[campaignDict valueForKeyPath:@"message.template.formats"] firstObject];
    change([[format objectForKey:@"buttons"] firstObject]);
    return campaignDict;
}

// What campaign_native_button_basics queues as it is
- (NSSet<NSString *> *)buttonBasicsAssets {
    return [NSSet setWithArray:@[
            @"1111111111111111111111111", // background image
            @"9973b5003e299dab6394258c459e82b58a7a7633", // Msystem 12 background
            @"73efb349f6e6ab7753bdfc1073d2035d607bbd40", // Msystem 12 pressed and focused background
            @"535.1030.b60343e5f678c56d52e80b00e604104a73d256f2.ttf" // MComic 16 font
    ]];
}

- (SwrveInAppCampaign *)campaignFromDictionary:(NSDictionary *)campaignDict assetsQueue:(NSMutableSet *)assetsQueue {
    XCTAssertNotNil(campaignDict);
    SwrveInAppCampaign *campaign = [[SwrveInAppCampaign alloc] initAtTime:[NSDate date]
                                                           fromDictionary:campaignDict
                                                          withAssetsQueue:assetsQueue
                                                            forController:[[SwrveMessageController alloc] init]
                                                      withPersonalization:@{}];
    XCTAssertNotNil(campaign);
    return campaign;
}

// Names of the assets queued when the campaign loads
- (NSSet<NSString *> *)queuedAssetNamesForCampaign:(NSDictionary *)campaignDict {
    NSMutableSet *assetsQueue = [NSMutableSet new];
    [self campaignFromDictionary:campaignDict assetsQueue:assetsQueue];
    NSMutableSet *names = [NSMutableSet new];
    for (NSDictionary *item in assetsQueue) {
        [names addObject:[item objectForKey:@"name"]];
    }
    return names;
}

- (NSString *)sha1ForUrl:(NSString *)url {
    return [SwrveUtils sha1:[url dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
}

- (void)testThemedButtonsQueueOnlyThemeAssets {
    // MButton1 and MButton2 have an empty image_up, the other two have none
    NSSet *names = [self queuedAssetNamesForCampaign:[self firstCampaignInFile:@"campaign_native_button_basics"]];

    XCTAssertEqualObjects(names, [self buttonBasicsAssets]);
}

- (void)testImageButtonQueuesImageUp {
    NSDictionary *campaignDict = [self buttonBasicsCampaignWithFirstButton:^(NSMutableDictionary *button) {
        [button removeObjectForKey:@"theme"];
        [button setObject:@{@"type": @"asset", @"value": @"image_button_asset"} forKey:@"image_up"];
    }];

    NSSet *names = [self queuedAssetNamesForCampaign:campaignDict];

    XCTAssertEqualObjects(names, [[self buttonBasicsAssets] setByAddingObject:@"image_button_asset"]);
}

- (void)testDynamicImageButtonWithoutImageUpQueuesOnlyDynamicImage {
    NSDictionary *campaignDict = [self buttonBasicsCampaignWithFirstButton:^(NSMutableDictionary *button) {
        [button removeObjectForKey:@"theme"];
        [button removeObjectForKey:@"image_up"];
        [button setObject:@"https://fakeitem/dynamic.png" forKey:@"dynamic_image_url"];
    }];

    NSSet *names = [self queuedAssetNamesForCampaign:campaignDict];

    NSString *dynamicImage = [self sha1ForUrl:@"https://fakeitem/dynamic.png"];
    XCTAssertEqualObjects(names, [[self buttonBasicsAssets] setByAddingObject:dynamicImage]);
}

- (void)testButtonImageIsImageUpOrNil {
    NSDictionary *imageUp = @{@"image_up": @{@"type": @"asset", @"value": @"image_button_asset"}};
    XCTAssertEqualObjects([[SwrveButton alloc] initWithDictionary:imageUp campaignId:1 messageId:1].image, @"image_button_asset");

    // No image_up means no image, so a dynamic image is reported to QA as having no fallback
    XCTAssertNil([[SwrveButton alloc] initWithDictionary:@{} campaignId:1 messageId:1].image);
}

- (void)testAssetsReadyForThemedButtons {
    SwrveInAppCampaign *campaign = [self campaignFromDictionary:[self firstCampaignInFile:@"campaign_native_button_basics"]
                                                    assetsQueue:[NSMutableSet new]];

    XCTAssertTrue([campaign.message assetsReady:[self buttonBasicsAssets] withPersonalization:@{}]);
}

- (void)testAssetsNotReadyForButtonWithoutThemeOrImage {
    NSDictionary *campaignDict = [self buttonBasicsCampaignWithFirstButton:^(NSMutableDictionary *button) {
        [button removeObjectForKey:@"theme"];
        [button removeObjectForKey:@"image_up"];
    }];
    SwrveInAppCampaign *campaign = [self campaignFromDictionary:campaignDict assetsQueue:[NSMutableSet new]];

    // The button has nothing to draw, so the message can never show
    XCTAssertFalse([campaign.message assetsReady:[self buttonBasicsAssets] withPersonalization:@{}]);
}

- (void)testAssetsReadyForDynamicImageButtonOnceDynamicImageDownloaded {
    NSDictionary *campaignDict = [self buttonBasicsCampaignWithFirstButton:^(NSMutableDictionary *button) {
        [button removeObjectForKey:@"theme"];
        [button removeObjectForKey:@"image_up"];
        [button setObject:@"https://fakeitem/dynamic.png" forKey:@"dynamic_image_url"];
    }];
    SwrveInAppCampaign *campaign = [self campaignFromDictionary:campaignDict assetsQueue:[NSMutableSet new]];

    XCTAssertFalse([campaign.message assetsReady:[self buttonBasicsAssets] withPersonalization:@{}]);
    NSSet *downloaded = [[self buttonBasicsAssets] setByAddingObject:[self sha1ForUrl:@"https://fakeitem/dynamic.png"]];
    XCTAssertTrue([campaign.message assetsReady:downloaded withPersonalization:@{}]);
}

- (void)testDynamicImageButtonWithUndecodableImageAndNoImageUpShows {
    // The dynamic image is downloaded but does not decode, and there is no image_up to fall back to
    NSString *dynamicImageUrl = @"https://fakeitem/dynamic.png";
    [SwrveTestHelper createDummyAssets:@[[self sha1ForUrl:dynamicImageUrl]]];

    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaign_visible_if" ofType:@"json"];
    NSMutableDictionary *json = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:filePath] options:NSJSONReadingMutableContainers error:nil];
    for (NSMutableDictionary *format in [[[json objectForKey:@"campaigns"] firstObject] valueForKeyPath:@"message.template.formats"]) {
        for (NSMutableDictionary *button in [format objectForKey:@"buttons"]) {
            if ([[button objectForKey:@"name"] isEqualToString:@"always_visible"]) {
                [button removeObjectForKey:@"image_up"];
                [button setObject:dynamicImageUrl forKey:@"dynamic_image_url"];
            }
        }
    }

    NSDictionary *personalization = @{@"Recipient.show_button": @"false"};
    id swrveMock = [self swrveMockWithCampaigns:json withConfig:[SwrveConfig new]];
    SwrveMessageController *controller = [swrveMock messaging];
    SwrveCampaign *campaign = [[controller messageCenterCampaignsWithPersonalization:personalization] firstObject];
    XCTAssertNotNil(campaign);

    [controller showMessageCenterCampaign:campaign withPersonalization:personalization];

    SwrveMessageViewController *messageViewController = [self messageViewControllerFrom:controller];
    XCTAssertNotNil(messageViewController);
    SwrveMessageUIView *view = [self swrveMessageUIViewFromController:messageViewController];
    SwrveUIButton *buttonView = nil;
    for (UIView *subview in view.subviews) {
        if ([subview.accessibilityIdentifier isEqualToString:@"always_visible"]) {
            buttonView = (SwrveUIButton *)subview;
        }
    }
    XCTAssertNotNil(buttonView);
    XCTAssertNil([buttonView backgroundImageForState:UIControlStateNormal]);
}

@end
