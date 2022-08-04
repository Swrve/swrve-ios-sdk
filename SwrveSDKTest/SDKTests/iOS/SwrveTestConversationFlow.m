#import <XCTest/XCTest.h>
#if TARGET_OS_IOS
#import "Swrve.h"
#import "TestableSwrve.h"
#import "SwrveTestHelper.h"
#import "SwrveConversation.h"
#import "SwrveContentVideo.h"
#import "SwrveContentImage.h"
#import "SwrveContentHTML.h"
#import "SwrveContentStarRating.h"
#import "SwrveTestConversationsHelper.h"
#import "SwrveConversationStyler.h"
#import "SwrveAssetsManager.h"
#import "SwrveMessageController+Private.h"
#import "SwrvePermissions.h"

#import <OCMock/OCMock.h>

@interface SwrveConversationItemViewController (InternalAccess)
+ (bool)hasUnknownContentAtoms:(SwrveBaseConversation *)conversation;
@end

@interface SwrveMessageController ()
- (void)showConversation:(SwrveConversation *)conversation queue:(bool)isQueued;
- (SwrveConversation*)conversationForEvent:(NSString *) eventName withPayload:(NSDictionary *)payload;
@end

@interface SwrveTestConversationFlow : XCTestCase {
    id pushMock;
}
@end

@implementation SwrveTestConversationFlow

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
    pushMock = [SwrveTestHelper mockPushRequest];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

-(void)testShowConversation {
    TestableSwrve *testableSwrve = [SwrveTestConversationsHelper initializeWithCampaignsFile:@"conversationAnnounce" andConfig:nil];
    SwrveMessageController* swrveMessageController = testableSwrve.messaging;
    [testableSwrve setCustomNowDate:[NSDate dateWithTimeInterval:280 sinceDate:[testableSwrve getNow]]];
    
    SwrveConversation* swrveConversation = [swrveMessageController conversationForEvent:@"conversation_test_event" withPayload:nil];
    XCTAssertNotNil(swrveConversation);
    
    SwrveConversationPane *swrveConversationPane = [swrveConversation pageAtIndex:0];
    SwrveConversationButton *swrveConversationButton = swrveConversationPane.controls[1];
    XCTAssertEqualObjects(swrveConversationButton.actions[@"call"], @"0831012430");

    [swrveMessageController showConversation:swrveConversation queue:false];
    XCTAssertNotNil(swrveMessageController.swrveConversationItemViewController);

    XCTAssertNil([swrveMessageController showMessagesAfterDelay]);
    [swrveConversation wasShownToUser];
    XCTAssertNotNil([swrveMessageController showMessagesAfterDelay]);
    
    XCTestExpectation *conversationShown = [self expectationWithDescription:@"Conversation Shown"];
    // windowLevel is set in another dispatch_async, so we do this so its executed after that code
    dispatch_async(dispatch_get_main_queue(), ^{
        XCTAssertEqual(swrveMessageController.conversationWindow.windowLevel, UIWindowLevelAlert + 1);
        XCTAssertEqual(swrveMessageController.conversationWindow.backgroundColor, [UIColor clearColor]);
        [conversationShown fulfill];
    });
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"No message shown");
        }
    }];
    
    [swrveMessageController cleanupConversationUI];
}

-(void)testShowConversationWithUnknownAtom {
    TestableSwrve *testableSwrve = [SwrveTestConversationsHelper initializeWithCampaignsFile:@"conversationAnnounce" andConfig:nil];
    SwrveMessageController* swrveMessageController = testableSwrve.messaging;
    [testableSwrve setCustomNowDate:[NSDate dateWithTimeInterval:280 sinceDate:[testableSwrve getNow]]];

    SwrveConversation* swrveConversation = [swrveMessageController conversationForEvent:@"conversation_test_event" withPayload:nil];
    XCTAssertNotNil(swrveConversation);

    bool success = ![SwrveConversationItemViewController hasUnknownContentAtoms:swrveConversation];
    XCTAssertTrue(success);

    // add an unknown atom to existing conversation and test again
    SwrveContentItem *unknownContent = [[SwrveContentItem alloc] initWithTag:@"tag" type:kSwrveContentUnknown andDictionary:nil];
    NSMutableArray *pages = [swrveConversation.pages mutableCopy];
    for (SwrveConversationPane *page in pages) {
        NSMutableArray *content = [page.content mutableCopy];
        [content addObject:unknownContent];
        page.content = content;
    }
    success = ![SwrveConversationItemViewController hasUnknownContentAtoms:swrveConversation];
    XCTAssertFalse(success);

    // Remove the already added unknown atom and test again
    pages = [swrveConversation.pages mutableCopy];
    for (SwrveConversationPane *page in pages) {
        NSMutableArray *content = [page.content mutableCopy];
        [content removeLastObject];
        page.content = content;
    }
    success = ![SwrveConversationItemViewController hasUnknownContentAtoms:swrveConversation];
    XCTAssertTrue(success);
}

-(void)testConversationStylesDictionaryPresent {
    TestableSwrve *testableSwrve = [SwrveTestConversationsHelper initializeWithCampaignsFile:@"conversationAnnounce" andConfig:nil];
    SwrveMessageController* swrveMessageController = testableSwrve.messaging;
    [testableSwrve setCustomNowDate:[NSDate dateWithTimeInterval:280 sinceDate:[testableSwrve getNow]]];
    
    SwrveConversation* swrveConversation = [swrveMessageController conversationForEvent:@"conversation_test_event" withPayload:nil];
    XCTAssertNotNil(swrveConversation);
    
    SwrveConversationPane *swrveConversationPane = [swrveConversation pageAtIndex:0];
    
    NSDictionary *style = swrveConversationPane.pageStyle;
    XCTAssertTrue([style.allKeys containsObject:@"bg"]);
    NSDictionary *bg = [style objectForKey:@"bg"];
    XCTAssertEqualObjects([bg objectForKey:@"type"], @"color");
    XCTAssertEqualObjects([bg objectForKey:@"value"], @"#cc8534");
    
    XCTAssertTrue([style.allKeys containsObject:@"lb"]);
    NSDictionary *lb = [style objectForKey:@"lb"];
    XCTAssertEqualObjects([lb objectForKey:@"type"], @"color");
    XCTAssertEqualObjects([lb objectForKey:@"value"], @"#FFffffff");

    XCTAssertTrue([style.allKeys containsObject:@"border_radius"]);
    XCTAssertEqual([[style objectForKey:@"border_radius"] floatValue], 100.0);
}

/*-(void)testViewDidLoad {
    TestableSwrve *testableSwrve = [SwrveTestConversationsHelper initializeWithCampaignsFile:@"conversationAnnounce" andConfig:nil];
    SwrveMessageController* swrveMessageController = testableSwrve.messaging;
    [testableSwrve setCustomNowDate:[NSDate dateWithTimeInterval:280 sinceDate:[testableSwrve getNow]]];

    SwrveConversation* swrveConversation = [swrveMessageController conversationForEvent:@"conversation_test_event"];
    SwrveConversationItemViewController *swrveConversationItemViewController = [[SwrveConversationItemViewController alloc] init];
    [swrveConversationItemViewController setConversation:swrveConversation andMessageController:testableSwrve.messaging];
    XCTAssertNotNil(swrveConversationItemViewController);
    [swrveConversationItemViewController viewDidLoad];
    XCTAssertNotNil(swrveConversationItemViewController.buttonsBackgroundImageView.image); // TODO
}*/

-(void)testViewContentImage {
    NSDictionary *dict = @{ @"value" : @"some image url" };
    SwrveContentImage *swrveContentImage = [[SwrveContentImage alloc] initWithTag:@"imagetag" andDictionary:dict];
    UIView *uiView = [swrveContentImage view];
    XCTAssertNil(uiView); // loaded asynchronously so nil value
}

-(void)testViewContentHTML {
    NSDictionary *dict = @{ @"value" : @"some html content" };
    SwrveContentHTML *swrveContentHTML = [[SwrveContentHTML alloc] initWithTag:@"htmltag" andDictionary:dict];
    UIView *containerView = [[UIView alloc] init];
    [swrveContentHTML loadViewWithContainerView:containerView];
    XCTAssertNotNil([swrveContentHTML view]);
}

-(void)testViewContentVideo {
    NSDictionary *dict = @{ @"value" : @"https://www.youtube.com/embed/9bZkp7q19f0" };
    SwrveContentVideo *swrveContentVideo = [[SwrveContentVideo alloc] initWithTag:@"videotag" andDictionary:dict];
    UIView *containerView = [[UIView alloc] init];
    [swrveContentVideo loadViewWithContainerView:containerView];
    XCTAssertNotNil([swrveContentVideo view]);
}

-(void)testViewContentStarRating {
    NSDictionary *dict = @{ @"value" : @"some html content", @"star_color" : @"#abcabc" };
    SwrveContentStarRating *swrveStarRating = [[SwrveContentStarRating alloc] initWithTag:@"startag" andDictionary:dict];
    UIView *containerView = [[UIView alloc] init];
    [swrveStarRating loadViewWithContainerView:containerView];
    XCTAssertNotNil([swrveStarRating view]);
}

-(void)testShowContentVideoAndStop {
    // bootstrap a conversation with full details from json
    TestableSwrve *testableSwrve = [SwrveTestConversationsHelper initializeWithCampaignsFile:@"conversationAnnounce" andConfig:nil];
    SwrveMessageController* swrveMessageController = testableSwrve.messaging;
    [testableSwrve setCustomNowDate:[NSDate dateWithTimeInterval:280 sinceDate:[testableSwrve getNow]]];
    SwrveConversation* swrveConversation = [swrveMessageController conversationForEvent:@"conversation_test_event" withPayload:nil];
    SwrveConversationPane *swrveConversationPane = [swrveConversation pageAtIndex:0];
    
    // swap in appropriate content to test
    NSDictionary *dict = @{ @"value" : @"https://www.youtube.com/embed/9bZkp7q19f0" };
    SwrveContentVideo *swrveContentVideo = [[SwrveContentVideo alloc] initWithTag:@"videotag" andDictionary:dict];
    NSArray *content = @[swrveContentVideo];
    [swrveConversationPane setContent:content];
    SwrveConversationItemViewController *swrveConversationItemViewController = [[SwrveConversationItemViewController alloc] init];
    [swrveConversationItemViewController setConversation:swrveConversation andMessageController:testableSwrve.messaging];
    [swrveConversationItemViewController setConversationPane:swrveConversationPane];

    // show conversation
    UIView *uiView = [swrveContentVideo view];
    XCTAssertFalse([uiView isHidden]);
    
    // tap done
    SwrveConversationButton *swrveConversationButton = swrveConversationPane.controls[1];
    id mockSwrveContentVideo = OCMPartialMock(swrveContentVideo);
    OCMExpect([mockSwrveContentVideo stop]);
    [swrveConversationItemViewController buttonTapped:swrveConversationButton.view]; // tap done and video should be stopped
    OCMVerifyAllWithDelay(mockSwrveContentVideo, 5); // verify video stop was called
    XCTAssertFalse([uiView isHidden]);
}

-(void)testPerformActionVisitWithValidUrl {
    SwrveMessageController* controller = [SwrveMessageController alloc];
    SwrveConversation* swrveConversation = [SwrveTestConversationsHelper createConversationForCampaign:@"conversationAnnounce" andEvent:@"conversation_test_event" andPayload:nil withController: controller];
    SwrveConversationItemViewController *swrveConversationItemViewController = [[SwrveConversationItemViewController alloc] init];
    [swrveConversationItemViewController setConversation:swrveConversation andMessageController:controller];
    SwrveConversationPane *swrveConversationPane = [swrveConversation pageAtIndex:0];
    [swrveConversationItemViewController setConversationPane:swrveConversationPane];

    // swap in appropriate control to test
    NSDictionary *visit = @{ @"url" : @"https://google.com", @"ext" : @"false" };
    NSDictionary *action = @{ @"visit" : visit };
    NSDictionary *dict = @{ @"description" : @"someDesc", @"action" : action };
    SwrveConversationButton *swrveConversationButton = [[SwrveConversationButton alloc] initWithTag:@"sometag" andDictionary:dict];

    NSURL *url = [NSURL URLWithString:@"https://google.com"];
    id mockUIApplication = OCMPartialMock([UIApplication sharedApplication]);
    OCMExpect([mockUIApplication openURL:url options:OCMOCK_ANY completionHandler:OCMOCK_ANY]);

    [swrveConversationItemViewController performActions:swrveConversationButton];

    OCMVerifyAllWithDelay(mockUIApplication,5);
    [mockUIApplication stopMocking];
}

-(void)testPerformActionVisitWithInvalidUrl {
    SwrveMessageController* controller = [SwrveMessageController alloc];
    SwrveConversation* swrveConversation = [SwrveTestConversationsHelper createConversationForCampaign:@"conversationAnnounce"
                                                                                              andEvent:@"conversation_test_event"
                                                                                            andPayload:nil
                                                                                        withController:controller];
    SwrveConversationItemViewController *swrveConversationItemViewController = [[SwrveConversationItemViewController alloc] init];
    [swrveConversationItemViewController setConversation:swrveConversation andMessageController:controller];
    SwrveConversationPane *swrveConversationPane = [swrveConversation pageAtIndex:0];
    [swrveConversationItemViewController setConversationPane:swrveConversationPane];
    
    // swap in appropriate control to test
    NSDictionary *visit = @{ @"url" : @"some invalid url", @"ext" : @"false" };
    NSDictionary *action = @{ @"visit" : visit };
    NSDictionary *dict = @{ @"description" : @"someDesc", @"action" : action };
    SwrveConversationButton *swrveConversationButton = [[SwrveConversationButton alloc] initWithTag:@"sometag" andDictionary:dict];
    
    id mockApplication = OCMPartialMock([UIApplication sharedApplication]);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [[mockApplication reject] openURL:nil options:OCMOCK_ANY completionHandler:OCMOCK_ANY];
#pragma clang diagnostic pop
    [swrveConversationItemViewController performActions:swrveConversationButton];
    
    OCMVerifyAll(mockApplication);
    [mockApplication stopMocking];
}

-(void)testPerformActionVisitWithNoUrl {
    SwrveMessageController* controller = [SwrveMessageController alloc];
    SwrveConversation* swrveConversation = [SwrveTestConversationsHelper createConversationForCampaign:@"conversationAnnounce" andEvent:@"conversation_test_event" andPayload:nil withController:controller];
    SwrveConversationItemViewController *swrveConversationItemViewController = [[SwrveConversationItemViewController alloc] init];
    [swrveConversationItemViewController setConversation:swrveConversation andMessageController:controller];
    SwrveConversationPane *swrveConversationPane = [swrveConversation pageAtIndex:0];
    [swrveConversationItemViewController setConversationPane:swrveConversationPane];
    
    // swap in appropriate control to test
    NSDictionary *visit = @{ };
    NSDictionary *action = @{ @"visit" : visit };
    NSDictionary *dict = @{ @"description" : @"someDesc", @"action" : action };
    SwrveConversationButton *swrveConversationButton = [[SwrveConversationButton alloc] initWithTag:@"sometag" andDictionary:dict];

    id mockUIApplication = OCMPartialMock([UIApplication sharedApplication]);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [[mockUIApplication reject] openURL:nil options:OCMOCK_ANY completionHandler:OCMOCK_ANY];
#pragma clang diagnostic pop
    [swrveConversationItemViewController performActions:swrveConversationButton];
    
    OCMVerifyAll(mockUIApplication);
    [mockUIApplication stopMocking];
}

-(void)testPerformActionCall {
    SwrveMessageController* controller = [SwrveMessageController alloc];
    SwrveConversation* swrveConversation = [SwrveTestConversationsHelper createConversationForCampaign:@"conversationAnnounce"
                                                                                              andEvent:@"conversation_test_event" andPayload:nil
                                                                                        withController:controller];
    SwrveConversationItemViewController *swrveConversationItemViewController = [[SwrveConversationItemViewController alloc] init];
    [swrveConversationItemViewController setConversation:swrveConversation andMessageController:controller];
    SwrveConversationPane *swrveConversationPane = [swrveConversation pageAtIndex:0];
    [swrveConversationItemViewController setConversationPane:swrveConversationPane];
    
    // swap in appropriate control to test
    NSDictionary *action = @{ @"call" : @"123456789" };
    NSDictionary *dict = @{ @"description" : @"someDesc", @"action" : action };
    SwrveConversationButton *swrveConversationButton = [[SwrveConversationButton alloc] initWithTag:@"sometag" andDictionary:dict];

    NSURL *url = [NSURL URLWithString:@"tel:123456789"];
    id mockUIApplication = OCMPartialMock([UIApplication sharedApplication]);
    OCMExpect([mockUIApplication openURL:url options:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
    
    [swrveConversationItemViewController performActions:swrveConversationButton];

    OCMVerifyAllWithDelay(mockUIApplication,5);
    [mockUIApplication stopMocking];
}

-(void)testConversationAssetsQueued {
    // bootstrap a conversation with full details from any json
    TestableSwrve *testableSwrve = [SwrveTestConversationsHelper initializeWithCampaignsFile:@"conversationAnnounce" andConfig:nil];
    SwrveMessageController* swrveMessageController = testableSwrve.messaging;
    [testableSwrve setCustomNowDate:[NSDate dateWithTimeInterval:280 sinceDate:[testableSwrve getNow]]];
    
    // swap in appropriate content to test
    NSDictionary *imageContentDict = @{ @"type" : @"image", @"value" : @"someImageUrl" };
    NSArray *contentArray = @[imageContentDict];
    
    NSDictionary *pagesDict = [[NSMutableDictionary alloc] init];
    [pagesDict setValue:(contentArray) forKey:@"content"];
    NSArray *pagesArray = @[pagesDict];

    NSDictionary *conversationDict = [[NSMutableDictionary alloc] init];
    [conversationDict setValue:(pagesArray) forKey:@"pages"];

    NSDictionary *jsonDict = [[NSMutableDictionary alloc] init];
    [jsonDict setValue:(conversationDict) forKey:@"conversation"];

    NSMutableSet* assetsQ = [[NSMutableSet alloc] init];
    SwrveCampaign *campaign = [[SwrveConversationCampaign alloc] initAtTime:[NSDate new] fromDictionary:jsonDict withAssetsQueue:assetsQ forController:swrveMessageController];
    XCTAssertNotNil(campaign);
    XCTAssertEqual([assetsQ count], 1);
    NSMutableDictionary *assetQItem = [SwrveAssetsManager assetQItemWith:@"someImageUrl" andDigest:@"someImageUrl" andIsExternal:NO andIsImage:YES];
    XCTAssertTrue([assetsQ containsObject:assetQItem]);
}

-(void)testConversationFontAssetsQueued {
    NSURL *filePathFromTestBundle = [[NSBundle mainBundle] URLForResource:@"conversation_campaign_with_diff_fonts" withExtension:@"json"];
    NSString* campaignJson = [NSString stringWithContentsOfURL:filePathFromTestBundle encoding:NSUTF8StringEncoding error:nil];
    NSData *campaignData = [campaignJson dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:campaignData options:NSJSONReadingMutableContainers error:nil];

    NSMutableSet* assetsQ = [[NSMutableSet alloc] init];

    NSArray* jsonCampaigns = [jsonDict objectForKey:@"campaigns"];
    XCTAssertNotNil(jsonCampaigns);
    XCTAssertEqual([jsonCampaigns count], 1);
    NSDictionary *conversationCampiagnDict = [jsonCampaigns objectAtIndex:0];
    XCTAssertNotNil(conversationCampiagnDict);
    SwrveCampaign *campaign = [[SwrveConversationCampaign alloc] initAtTime:[NSDate new] fromDictionary:conversationCampiagnDict withAssetsQueue:assetsQ forController:[SwrveMessageController new]];
    XCTAssertNotNil(campaign);
    XCTAssertEqual([assetsQ count], 7);

    // assets queue should not increase if we do it again with same assets
    campaign = [[SwrveConversationCampaign alloc] initAtTime:[NSDate new] fromDictionary:conversationCampiagnDict withAssetsQueue:assetsQ forController:[SwrveMessageController new]];
    XCTAssertNotNil(campaign);
    XCTAssertEqual([assetsQ count], 7);
}

-(void)testConversationMissingAssets {
    NSString *fontMVITitle      = @"2617fb3c279e30dd7c180de8679a2e2d33cf3551";
    NSString *fontMVIOption1    = @"2617fb3c279e30dd7c180de8679a2e2d33cf3552";
    NSString *fontMVIOption2    = @"2617fb3c279e30dd7c180de8679a2e2d33cf3553";
    NSString *fontHtmlFrag      = @"2617fb3c279e30dd7c180de8679a2e2d33cf3554";
    NSString *fontStarRating    = @"2617fb3c279e30dd7c180de8679a2e2d33cf3555";
    NSString *fontButton1       = @"2617fb3c279e30dd7c180de8679a2e2d33cf3556";
    NSString *fontButton2       = @"2617fb3c279e30dd7c180de8679a2e2d33cf3557";

    // missing all assets
    [SwrveTestHelper removeAllAssets];
    SwrveConfig *config = [[SwrveConfig alloc] init];
    [config setAutoDownloadCampaignsAndResources:NO];
    TestableSwrve *swrve = [SwrveTestConversationsHelper initializeWithCampaignsFile:@"conversation_campaign_with_diff_fonts" andConfig:config andAssets:nil andDate:[NSDate date]];
    SwrveMessageController* swrveMessageController = swrve.messaging;
    XCTAssertEqual([[swrveMessageController campaigns] count], 1);
    SwrveConversation *conversation = [swrveMessageController conversationForEvent:@"swrve.messages.showatsessionstart" withPayload:nil];
    XCTAssertNil(conversation);

    // contains all assets
    [SwrveTestHelper removeAllAssets];
    NSMutableArray *assetsAll = [NSMutableArray arrayWithArray:@[ fontMVITitle, fontMVIOption1, fontMVIOption2, fontHtmlFrag, fontStarRating, fontButton1, fontButton2 ]];
    swrve = [SwrveTestConversationsHelper initializeWithCampaignsFile:@"conversation_campaign_with_diff_fonts" andConfig:config andAssets:assetsAll andDate:[NSDate date]];
    swrveMessageController = swrve.messaging;
    XCTAssertEqual([[swrveMessageController campaigns] count], 1);
    conversation = [swrveMessageController conversationForEvent:@"swrve.messages.showatsessionstart" withPayload:nil];
    XCTAssertNotNil(conversation);

    // missing fontButton2 asset
    [SwrveTestHelper removeAllAssets];
    NSMutableArray *assetsMissingFontButton2 = [NSMutableArray arrayWithArray:@[ fontMVITitle, fontMVIOption1, fontMVIOption2, fontHtmlFrag, fontStarRating, fontButton1 ]];
    swrve = [SwrveTestConversationsHelper initializeWithCampaignsFile:@"conversation_campaign_with_diff_fonts" andConfig:config andAssets:assetsMissingFontButton2 andDate:[NSDate date]];
    swrveMessageController = swrve.messaging;
    XCTAssertEqual([[swrveMessageController campaigns] count], 1);
    conversation = [swrveMessageController conversationForEvent:@"swrve.messages.showatsessionstart" withPayload:nil];
    XCTAssertNil(conversation);

    // missing fontButton1 asset
    [SwrveTestHelper removeAllAssets];
    NSMutableArray *assetsMissingFontButton1 = [NSMutableArray arrayWithArray:@[ fontMVITitle, fontMVIOption1, fontMVIOption2, fontHtmlFrag, fontStarRating, fontButton2 ]];
    swrve = [SwrveTestConversationsHelper initializeWithCampaignsFile:@"conversation_campaign_with_diff_fonts" andConfig:config andAssets:assetsMissingFontButton1 andDate:[NSDate date]];
    swrveMessageController = swrve.messaging;
    XCTAssertEqual([[swrveMessageController campaigns] count], 1);
    conversation = [swrveMessageController conversationForEvent:@"swrve.messages.showatsessionstart" withPayload:nil];
    XCTAssertNil(conversation);

    // missing fontStarRating asset
    [SwrveTestHelper removeAllAssets];
    NSMutableArray *assetsMissingFontStarRating = [NSMutableArray arrayWithArray:@[ fontMVITitle, fontMVIOption1, fontMVIOption2, fontHtmlFrag, fontButton1, fontButton2 ]];
    swrve = [SwrveTestConversationsHelper initializeWithCampaignsFile:@"conversation_campaign_with_diff_fonts" andConfig:config andAssets:assetsMissingFontStarRating andDate:[NSDate date]];
    swrveMessageController = swrve.messaging;
    XCTAssertEqual([[swrveMessageController campaigns] count], 1);
    conversation = [swrveMessageController conversationForEvent:@"swrve.messages.showatsessionstart" withPayload:nil];
    XCTAssertNil(conversation);

    // missing fontHtmlFrag asset
    [SwrveTestHelper removeAllAssets];
    NSMutableArray *assetsMissingFontHtmlFrag = [NSMutableArray arrayWithArray:@[ fontMVITitle, fontMVIOption1, fontMVIOption2, fontStarRating, fontButton1, fontButton2 ]];
    swrve = [SwrveTestConversationsHelper initializeWithCampaignsFile:@"conversation_campaign_with_diff_fonts" andConfig:config andAssets:assetsMissingFontHtmlFrag andDate:[NSDate date]];
    swrveMessageController = swrve.messaging;
    XCTAssertEqual([[swrveMessageController campaigns] count], 1);
    conversation = [swrveMessageController conversationForEvent:@"swrve.messages.showatsessionstart" withPayload:nil];
    XCTAssertNil(conversation);

    // missing fontMVIOption2 asset
    [SwrveTestHelper removeAllAssets];
    NSMutableArray *assetsMissingFontMVIOption2 = [NSMutableArray arrayWithArray:@[ fontMVITitle, fontMVIOption1, fontHtmlFrag, fontStarRating, fontButton1, fontButton2 ]];
    swrve = [SwrveTestConversationsHelper initializeWithCampaignsFile:@"conversation_campaign_with_diff_fonts" andConfig:config andAssets:assetsMissingFontMVIOption2 andDate:[NSDate date]];
    swrveMessageController = swrve.messaging;
    XCTAssertEqual([[swrveMessageController campaigns] count], 1);
    conversation = [swrveMessageController conversationForEvent:@"swrve.messages.showatsessionstart" withPayload:nil];
    XCTAssertNil(conversation);

    // missing fontMVIOption1 asset
    [SwrveTestHelper removeAllAssets];
    NSMutableArray *assetsMissingFontMVIOption1 = [NSMutableArray arrayWithArray:@[ fontMVITitle, fontMVIOption2, fontHtmlFrag, fontStarRating, fontButton1, fontButton2 ]];
    swrve = [SwrveTestConversationsHelper initializeWithCampaignsFile:@"conversation_campaign_with_diff_fonts" andConfig:config andAssets:assetsMissingFontMVIOption1 andDate:[NSDate date]];
    swrveMessageController = swrve.messaging;
    XCTAssertEqual([[swrveMessageController campaigns] count], 1);
    conversation = [swrveMessageController conversationForEvent:@"swrve.messages.showatsessionstart" withPayload:nil];
    XCTAssertNil(conversation);

    // missing fontMVITitle asset
    [SwrveTestHelper removeAllAssets];
    NSMutableArray *assetsMissingFontMVITitle = [NSMutableArray arrayWithArray:@[ fontMVIOption1, fontMVIOption2, fontHtmlFrag, fontStarRating, fontButton1, fontButton2 ]];
    swrve = [SwrveTestConversationsHelper initializeWithCampaignsFile:@"conversation_campaign_with_diff_fonts" andConfig:config andAssets:assetsMissingFontMVITitle andDate:[NSDate date]];
    swrveMessageController = swrve.messaging;
    XCTAssertEqual([[swrveMessageController campaigns] count], 1);
    conversation = [swrveMessageController conversationForEvent:@"swrve.messages.showatsessionstart" withPayload:nil];
    XCTAssertNil(conversation);

    // contains all assets
    [SwrveTestHelper removeAllAssets];
    //NSMutableArray *assetsAll = @[ fontMVITitle, fontMVIOption1, fontMVIOption2, fontHtmlFrag, fontStarRating, fontButton1, fontButton2 ];
    swrve = [SwrveTestConversationsHelper initializeWithCampaignsFile:@"conversation_campaign_with_diff_fonts" andConfig:config andAssets:assetsAll andDate:[NSDate date]];
    swrveMessageController = swrve.messaging;
    XCTAssertEqual([[swrveMessageController campaigns] count], 1);
    conversation = [swrveMessageController conversationForEvent:@"swrve.messages.showatsessionstart" withPayload:nil];
    XCTAssertNotNil(conversation);
}

-(void)testConversationAssetsAreDownloaded {
    NSDictionary *imageContentDict1 = @{ @"type" : @"image", @"value" : @"someImageUrl1" };
    NSDictionary *imageContentDict2 = @{ @"type" : @"image", @"value" : @"someImageUrl2" };
    NSArray *contentArray = @[imageContentDict1, imageContentDict2];
    NSDictionary *pagesDict = [[NSMutableDictionary alloc] init];
    [pagesDict setValue:(contentArray) forKey:@"content"];
    NSArray *pagesArray = @[pagesDict];
    NSDictionary *conversationDict = [[NSMutableDictionary alloc] init];
    [conversationDict setValue:(pagesArray) forKey:@"pages"];
    SwrveConversation *swrveConversation = [[SwrveConversation alloc] initWithJSON:conversationDict forCampaign:nil forController:nil];

    NSSet *assets1 = [NSSet setWithObjects:@"blah", nil];
    XCTAssertFalse([swrveConversation assetsReady:assets1]);

    NSSet *assets2 = [NSSet setWithObjects:@"someImageUrl1", @"someImageUrl2", nil];
    XCTAssertTrue([swrveConversation assetsReady:assets2]);
}

-(void)testStyleViewForUIImageView {
    NSDictionary *bgDict = [[NSMutableDictionary alloc] init];
    [bgDict setValue:(@"color") forKey:@"type"];
    [bgDict setValue:(@"#cc8534") forKey:@"value"];
    NSDictionary *styleDict = [[NSMutableDictionary alloc] init];
    [styleDict setValue:(bgDict) forKey:@"bg"];
    
    UIImageView *uiImageView = [[UIImageView alloc] init];
    XCTAssertNil(uiImageView.backgroundColor);

    [SwrveConversationStyler styleView:uiImageView withStyle:styleDict];

    XCTAssertNotNil(uiImageView.backgroundColor);
    UIColor *uiColor = [SwrveConversationStyler convertToUIColor:@"#cc8534"];
    XCTAssertTrue(CGColorEqualToColor(uiImageView.backgroundColor.CGColor, uiColor.CGColor));
}

-(void)testTransparentStyleViewForUITableViewCell {
    NSDictionary *styleDict = [[NSMutableDictionary alloc] init];

    NSDictionary *bgDict = [[NSMutableDictionary alloc] init];
    [bgDict setValue:(@"transparent") forKey:@"type"];
    [styleDict setValue:(bgDict) forKey:@"bg"];

    NSDictionary *fgDict = [[NSMutableDictionary alloc] init];
    [fgDict setValue:(@"color") forKey:@"type"];
    [fgDict setValue:(@"#cc8534") forKey:@"value"];
    [styleDict setValue:(fgDict) forKey:@"fg"];

    UITableViewCell *uiTableViewCell = [[UITableViewCell alloc] init];
    XCTAssertNil(uiTableViewCell.backgroundColor);

    [SwrveConversationStyler styleView:uiTableViewCell withStyle:styleDict];

    XCTAssertNotNil(uiTableViewCell.backgroundColor);
    UIColor *uiColor = [SwrveConversationStyler convertToUIColor:@"#cc8534"];
    XCTAssertTrue(CGColorEqualToColor(uiTableViewCell.backgroundColor.CGColor, [UIColor clearColor].CGColor));

    XCTAssertNotNil(uiTableViewCell.textLabel.textColor);
    XCTAssertTrue(CGColorEqualToColor(uiTableViewCell.textLabel.textColor.CGColor, uiColor.CGColor));
}

-(void)testConvertContentToHtmlWithSystemFont {
    NSDictionary *styleDict = [[NSMutableDictionary alloc] init];
    
    NSDictionary *bgDict = [[NSMutableDictionary alloc] init];
    [bgDict setValue:(@"transparent") forKey:@"type"];
    [styleDict setValue:(bgDict) forKey:@"bg"];
    
    NSDictionary *fgDict = [[NSMutableDictionary alloc] init];
    [fgDict setValue:(@"color") forKey:@"type"];
    [fgDict setValue:(@"#cc8534") forKey:@"value"];
    [styleDict setValue:(fgDict) forKey:@"fg"];

    [styleDict setValue:@"_system_font_" forKey:@"font_file"];
    
    NSString *content = @"<div style=\"text-align: center; font-size: 12pt; text-shadow: 0 -1px 0 #fff\" class=\"editable\" contenteditable=\"false\" id=\"textedit-1427220312018-fragment\">First page</div>";
    NSString *html = [SwrveConversationStyler convertContentToHtml:content withPageCSS:@"h2 { font-size: 30px }" withStyle:styleDict];
    html = [html stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSString *htmlToCompare = @"<html><head><styletype=\"text/css\">h2{font-size:30px}html{color:#cc8534;}body{background-color:transparent;}</style><metaname=\"viewport\"content=\"initial-scale=1.0,user-scalable=no\"/></head><body><divid=\"swrve_content\"><divstyle=\"text-align:center;font-size:12pt;text-shadow:0-1px0#fff\"class=\"editable\"contenteditable=\"false\"id=\"textedit-1427220312018-fragment\">Firstpage</div></div></body></html>";

    htmlToCompare = [htmlToCompare stringByReplacingOccurrencesOfString:@" " withString:@""];

    XCTAssertEqualObjects(html, htmlToCompare);    
}

-(void)testConvertContentToHtmlWithCustomOtfFont {

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cache = [SwrveLocalStorage swrveCacheFolder];
    if ([fileManager fileExistsAtPath:cache] == NO) {
        [fileManager createDirectoryAtPath:cache withIntermediateDirectories:NO attributes:nil error:nil]; //Create folder
    }
    [SwrveTestHelper deleteFilesInDirectory:cache];

    NSString *fontFile = @"040843601e697027b119f93a3fdb2c9c04d1ea63.otf";
    NSError *error;
    NSString *filePath = [cache stringByAppendingPathComponent:fontFile];
    if ([fileManager fileExistsAtPath:filePath] == NO) {
        NSString *srcPath = [[NSBundle mainBundle] pathForResource:@"040843601e697027b119f93a3fdb2c9c04d1ea63" ofType:@"otf"];
        BOOL success = [fileManager copyItemAtPath:srcPath toPath:filePath error:&error];
        NSLog(success ? @"testConvertContentToHtmlWithCustomOtfFont:Successfully copied custom font to cache" : @"testConvertContentToHtmlWithCustomOtfFont:Error copying custom font to cache");
    }

    NSDictionary *styleDict = [[NSMutableDictionary alloc] init];
    [styleDict setValue:fontFile forKey:@"font_file"];
    [styleDict setValue:@"myfont" forKey:@"font_postscript_name"];

    NSDictionary *bgDict = [[NSMutableDictionary alloc] init];
    [bgDict setValue:(@"transparent") forKey:@"type"];
    [styleDict setValue:(bgDict) forKey:@"bg"];

    NSDictionary *fgDict = [[NSMutableDictionary alloc] init];
    [fgDict setValue:(@"color") forKey:@"type"];
    [fgDict setValue:(@"#cc8534") forKey:@"value"];
    [styleDict setValue:(fgDict) forKey:@"fg"];

    NSString *content = @"<div style=\"text-align: center; font-size: 12pt; text-shadow: 0 -1px 0 #fff\" class=\"editable\" contenteditable=\"false\" id=\"textedit-1427220312018-fragment\">First page</div>";
    NSString *html = [SwrveConversationStyler convertContentToHtml:content withPageCSS:@"h2 { font-size: 30px }" withStyle:styleDict];
    html = [html stringByReplacingOccurrencesOfString:@" " withString:@""];

    // base64 encode the custom font file
    NSString *base64FontFile = [[NSData dataWithContentsOfFile:filePath] base64EncodedStringWithOptions:0];;
    NSString *htmlWithoutBase64FontFile = @"<html><head><styletype=\"text/css\">h2{font-size:30px}html{color:#cc8534;}body{background-color:transparent;}@font-face{font-family:'myfont';src:url(data:font/otf;base64,%@)format('opentype');}</style><metaname=\"viewport\"content=\"initial-scale=1.0,user-scalable=no\"/></head><body><divid=\"swrve_content\"><divstyle=\"text-align:center;font-size:12pt;text-shadow:0-1px0#fff\"class=\"editable\"contenteditable=\"false\"id=\"textedit-1427220312018-fragment\">Firstpage</div></div></body></html>";
    NSString *htmlToCompare = [NSString stringWithFormat:htmlWithoutBase64FontFile, base64FontFile];
    htmlToCompare = [htmlToCompare stringByReplacingOccurrencesOfString:@" " withString:@""];

    XCTAssertEqualObjects(html, htmlToCompare);
}

-(void)testConvertContentToHtmlWithCustomTtfFont {

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cache = [SwrveLocalStorage swrveCacheFolder];
    if ([fileManager fileExistsAtPath:cache] == NO) {
        [fileManager createDirectoryAtPath:cache withIntermediateDirectories:NO attributes:nil error:nil]; //Create folder
    }
    [SwrveTestHelper deleteFilesInDirectory:cache];

    NSString *fontFile = @"11f95d706be64c4654c18918065a40935531973b.ttf";
    NSError *error;
    NSString *filePath = [cache stringByAppendingPathComponent:fontFile];
    if ([fileManager fileExistsAtPath:filePath] == NO) {
        NSString *srcPath = [[NSBundle mainBundle] pathForResource:@"11f95d706be64c4654c18918065a40935531973b" ofType:@"ttf"];
        BOOL success = [fileManager copyItemAtPath:srcPath toPath:filePath error:&error];
        NSLog(success ? @"testConvertContentToHtmlWithCustomTtfFont:Successfully copied custom font to cache" : @"testConvertContentToHtmlWithCustomTtfFont:Error copying custom font to cache");
    }

    NSDictionary *styleDict = [[NSMutableDictionary alloc] init];
    [styleDict setValue:fontFile forKey:@"font_file"];
    [styleDict setValue:@"myfont" forKey:@"font_postscript_name"];

    NSDictionary *bgDict = [[NSMutableDictionary alloc] init];
    [bgDict setValue:(@"transparent") forKey:@"type"];
    [styleDict setValue:(bgDict) forKey:@"bg"];

    NSDictionary *fgDict = [[NSMutableDictionary alloc] init];
    [fgDict setValue:(@"color") forKey:@"type"];
    [fgDict setValue:(@"#cc8534") forKey:@"value"];
    [styleDict setValue:(fgDict) forKey:@"fg"];

    NSString *content = @"<div style=\"text-align: center; font-size: 12pt; text-shadow: 0 -1px 0 #fff\" class=\"editable\" contenteditable=\"false\" id=\"textedit-1427220312018-fragment\">First page</div>";
    NSString *html = [SwrveConversationStyler convertContentToHtml:content withPageCSS:@"h2 { font-size: 30px }" withStyle:styleDict];
    html = [html stringByReplacingOccurrencesOfString:@" " withString:@""];

    // base64 encode the custom font file
    NSString *base64FontFile = [[NSData dataWithContentsOfFile:filePath] base64EncodedStringWithOptions:0];;
    NSString *htmlWithoutBase64FontFile = @"<html><head><styletype=\"text/css\">h2{font-size:30px}html{color:#cc8534;}body{background-color:transparent;}@font-face{font-family:'myfont';src:url(data:font/ttf;base64,%@)format('truetype');}</style><metaname=\"viewport\"content=\"initial-scale=1.0,user-scalable=no\"/></head><body><divid=\"swrve_content\"><divstyle=\"text-align:center;font-size:12pt;text-shadow:0-1px0#fff\"class=\"editable\"contenteditable=\"false\"id=\"textedit-1427220312018-fragment\">Firstpage</div></div></body></html>";
    NSString *htmlToCompare = [NSString stringWithFormat:htmlWithoutBase64FontFile, base64FontFile];
    htmlToCompare = [htmlToCompare stringByReplacingOccurrencesOfString:@" " withString:@""];

    XCTAssertEqualObjects(html, htmlToCompare);
}

@end
#endif // TARGET_OS_TV



