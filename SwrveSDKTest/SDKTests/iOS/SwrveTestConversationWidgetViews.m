#import <XCTest/XCTest.h>
#if TARGET_OS_IOS
#import "Swrve.h"
#import "SwrveConversation.h"
#import "SwrveConversationButton.h"
#import "SwrveConversationCampaign.h"
#import "SwrveConversationPane.h"
#import "SwrveContentHTML.h"
#import "SwrveContentImage.h"
#import "SwrveContentVideo.h"
#import "SwrveContentSpacer.h"
#import "SwrveContentStarRating.h"
#import "SwrveTestConversationsHelper.h"
#import "SwrveTestHelper.h"

@interface SwrveTestConversationWidgetViews : XCTestCase

@end

@implementation SwrveTestConversationWidgetViews

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

- (void)testConversationButtonView {
    SwrveConversation* swrveConversation = [SwrveTestConversationsHelper createConversationForCampaign:@"conversationAnnounce"
                                                                                 andEvent:@"conversation_test_event"];
    SwrveConversationPane *swrveConversationPane = [swrveConversation pageAtIndex:0];
    SwrveConversationButton *swrveConversationButton1 = swrveConversationPane.controls[0];
    SwrveConversationButton *swrveConversationButton2 = swrveConversationPane.controls[1];

    UIButton *uiButton1 = (UIButton *)[swrveConversationButton1 view];
    XCTAssertNotNil(uiButton1);
    XCTAssertEqualObjects(uiButton1.titleLabel.text, @"Next Page");
    
    UIButton *uiButton2 = (UIButton *)[swrveConversationButton2 view];
    XCTAssertNotNil(uiButton2);
    XCTAssertEqualObjects(uiButton2.titleLabel.text, @"Call a number");
}

-(void)testPageForTag {
    SwrveConversation* swrveConversation = [SwrveTestConversationsHelper createConversationForCampaign:@"conversationAnnounce"
                                                                                              andEvent:@"conversation_test_event"];
    XCTAssertNil([swrveConversation pageForTag:@"faketag"]);
    SwrveConversationPane *swrveConversationPane = [swrveConversation pageForTag:@"1427220284416-2Button"];
    XCTAssertNotNil(swrveConversationPane);
    XCTAssertEqualObjects(swrveConversationPane.title, @"Page 1");
}

-(void)testSwrveConversationLoadedFromJson {
    SwrveConversation* swrveConversation = [SwrveTestConversationsHelper createConversationForCampaign:@"conversationAnnounce"
                                                                                              andEvent:@"conversation_test_event"];
    XCTAssertNotNil(swrveConversation);
    XCTAssertEqual([swrveConversation.conversationID intValue], 4);
    XCTAssertEqualObjects(swrveConversation.name, @"Conversation Name");
    XCTAssertNotNil(swrveConversation.pages);
    XCTAssertEqual([swrveConversation.pages count], 2);
    XCTAssertNotNil(swrveConversation.campaign);
}

-(void)testConversationWasShownToUser {
    SwrveConversation* swrveConversation = [SwrveTestConversationsHelper createConversationForCampaign:@"conversationAnnounce"
                                                                                              andEvent:@"conversation_test_event"];
    XCTAssertNotNil(swrveConversation.campaign);
    SwrveConversationCampaign *swrveConversationCampaign = swrveConversation.campaign;
    
    XCTAssertNil([swrveConversationCampaign.state showMsgsAfterDelay]);
    [swrveConversationCampaign conversationWasShownToUser:swrveConversation];
    XCTAssertNotNil([swrveConversationCampaign.state showMsgsAfterDelay]);
}

-(void)testConversationDismissed {
    SwrveConversation* swrveConversation = [SwrveTestConversationsHelper createConversationForCampaign:@"conversationAnnounce"
                                                                                              andEvent:@"conversation_test_event"];
    XCTAssertNotNil(swrveConversation.campaign);
    SwrveConversationCampaign *swrveConversationCampaign = swrveConversation.campaign;
    
    XCTAssertNil([swrveConversationCampaign.state showMsgsAfterDelay]);
    [swrveConversationCampaign conversationDismissed:[NSDate date]];
    XCTAssertNotNil([swrveConversationCampaign.state showMsgsAfterDelay]);
}

-(void)testGetConversationForEventInvalidEvent{
    TestableSwrve *testableSwrve = [SwrveTestConversationsHelper initializeWithCampaignsFile:@"conversationAnnounce" andConfig:nil];
    SwrveMessageController* swrveMessageController = testableSwrve.messaging;
    [testableSwrve setCustomNowDate:[NSDate dateWithTimeInterval:280 sinceDate:[testableSwrve getNow]]];
    SwrveConversationCampaign *swrveConversationCampaign = [swrveMessageController campaigns][0];
    SwrveConversation* swrveConversation = [swrveConversationCampaign conversationForEvent:@"fake.event" withAssets:[NSSet set] atTime:[testableSwrve getNow]];
    XCTAssertNil(swrveConversation);
}

-(void)testGetConversationForEventInvalidConversation{
    TestableSwrve *testableSwrve = [SwrveTestConversationsHelper initializeWithCampaignsFile:@"conversationAnnounce" andConfig:nil];
    SwrveMessageController* swrveMessageController = testableSwrve.messaging;
    [testableSwrve setCustomNowDate:[NSDate dateWithTimeInterval:280 sinceDate:[testableSwrve getNow]]];
    SwrveConversationCampaign *swrveConversationCampaign = [swrveMessageController campaigns][0];
    SwrveConversation* swrveConversation = [swrveConversationCampaign conversationForEvent:@"conversation_test_event" withAssets:[NSSet set] atTime:[testableSwrve getNow]];
    XCTAssertNil(swrveConversation);
}

-(void)testGetConversationForEventInvalidTime{
    TestableSwrve *testableSwrve = [SwrveTestConversationsHelper initializeWithCampaignsFile:@"conversationAnnounce" andConfig:nil];
    SwrveMessageController* swrveMessageController = testableSwrve.messaging;
    [testableSwrve setCustomNowDate:[NSDate dateWithTimeInterval:280 sinceDate:[testableSwrve getNow]]];
    SwrveConversationCampaign *swrveConversationCampaign = [swrveMessageController campaigns][0];
    SwrveConversation* swrveConversation = [swrveConversationCampaign conversationForEvent:@"conversation_test_event" withAssets:[NSSet set] atTime:[NSDate date]];
    XCTAssertNil(swrveConversation);
}

-(void)testGetConversationForEventNoAssets{
    TestableSwrve *testableSwrve = [SwrveTestConversationsHelper initializeWithCampaignsFile:@"conversationAnnounce" andConfig:nil];
    SwrveMessageController* swrveMessageController = testableSwrve.messaging;
    [testableSwrve setCustomNowDate:[NSDate dateWithTimeInterval:280 sinceDate:[testableSwrve getNow]]];
    SwrveConversationCampaign *swrveConversationCampaign = [swrveMessageController campaigns][0];
    SwrveConversation* swrveConversation = [swrveConversationCampaign conversationForEvent:@"conversation_test_event" withAssets:[NSSet set] atTime:[testableSwrve getNow]];
    XCTAssertNil(swrveConversation);
}

- (void)testSwrveContentHTML {
    SwrveConversation* swrveConversation = [SwrveTestConversationsHelper createConversationForCampaign:@"conversationAnnounce"
                                                                                              andEvent:@"conversation_test_event"];
    SwrveConversationPane *swrveConversationPane = [swrveConversation pageAtIndex:0];
    XCTAssertEqual([swrveConversationPane.content count], 7);
    
    SwrveConversationAtom *swrveConversationAtomHTML = swrveConversationPane.content[0];
    XCTAssertEqualObjects(swrveConversationAtomHTML.type, @"html-fragment");
    XCTAssertEqualObjects(swrveConversationAtomHTML.tag, @"1427220312018-fragment");
    SwrveContentHTML *swrveContentHTML = swrveConversationPane.content[0];
    XCTAssertEqualObjects(swrveContentHTML.value, @"<div style=\"text-align: center; font-size: 12pt; text-shadow: 0 -1px 0 #fff\" class=\"editable\" contenteditable=\"false\" id=\"textedit-1427220312018-fragment\">First page</div>");
}

- (void)testSwrveContentImage {
    SwrveConversation* swrveConversation = [SwrveTestConversationsHelper createConversationForCampaign:@"conversationAnnounce"
                                                                                              andEvent:@"conversation_test_event"];
    SwrveConversationPane *swrveConversationPane = [swrveConversation pageAtIndex:0];
    XCTAssertEqual([swrveConversationPane.content count], 7);
    
    SwrveConversationAtom *swrveConversationAtomImage = swrveConversationPane.content[1];
    XCTAssertEqualObjects(swrveConversationAtomImage.type, @"image");
    XCTAssertEqualObjects(swrveConversationAtomImage.tag, @"1428413702105-fragment");
    SwrveContentImage *swrveContentImage = swrveConversationPane.content[1];
    XCTAssertEqualObjects(swrveContentImage.value, @"281af8272a42b2da21886fd36eef3829e6aadb80");
}

- (void)testSwrveContentVideo {
    SwrveConversation* swrveConversation = [SwrveTestConversationsHelper createConversationForCampaign:@"conversationAnnounce"
                                                                                              andEvent:@"conversation_test_event"];
    SwrveConversationPane *swrveConversationPane = [swrveConversation pageAtIndex:0];
    XCTAssertEqual([swrveConversationPane.content count], 7);
    
    SwrveConversationAtom *swrveConversationAtomVideo = swrveConversationPane.content[2];
    XCTAssertEqualObjects(swrveConversationAtomVideo.type, @"video");
    XCTAssertEqualObjects(swrveConversationAtomVideo.tag, @"1430239421165-fragment");
    SwrveContentVideo *swrveContentVideo = swrveConversationPane.content[2];
    XCTAssertEqualObjects(swrveContentVideo.value, @"https://www.youtube.com/embed/WaBxJKx0z0c?html5=1&iv_load_policy=3&modestbranding=1&showinfo=0&rel=0");
    XCTAssertEqual(swrveContentVideo.height, 180);
}

- (void)testSwrveContentSpacer {
    SwrveConversation* swrveConversation = [SwrveTestConversationsHelper createConversationForCampaign:@"conversationAnnounce"
                                                                                              andEvent:@"conversation_test_event"];
    SwrveConversationPane *swrveConversationPane = [swrveConversation pageAtIndex:0];
    XCTAssertEqual([swrveConversationPane.content count], 7);
    
    SwrveConversationAtom *swrveConversationAtomSpacer = swrveConversationPane.content[4];
    XCTAssertEqualObjects(swrveConversationAtomSpacer.type, @"spacer");
    XCTAssertEqualObjects(swrveConversationAtomSpacer.tag, @"1433942531169-fragment");
    SwrveContentSpacer *swrveContentSpacer = swrveConversationPane.content[4];
    XCTAssertEqual(swrveContentSpacer.height, 20);
}

- (void)testSwrveContentStarRating {
    SwrveConversation* swrveConversation = [SwrveTestConversationsHelper createConversationForCampaign:@"conversationAnnounce"
                                                                                              andEvent:@"conversation_test_event"];
    SwrveConversationPane *swrveConversationPane = [swrveConversation pageAtIndex:0];
    XCTAssertEqual([swrveConversationPane.content count], 7);

    //html-fragment atom
    SwrveConversationAtom *swrveConversationAtomHtmlFragment = swrveConversationPane.content[5];
    XCTAssertEqualObjects(swrveConversationAtomHtmlFragment.type, @"html-fragment");
    XCTAssertEqualObjects(swrveConversationAtomHtmlFragment.tag, @"1430239421170-fragment");
    
    SwrveContentHTML *swrveHtml = swrveConversationPane.content[5];
    XCTAssertEqualObjects(swrveHtml.value, @"<h1>Customer Service</h1>");
    
    //star-rating
    SwrveConversationAtom *swrveConversationAtomStarRating = swrveConversationPane.content[6];
    XCTAssertEqualObjects(swrveConversationAtomStarRating.type, @"star-rating");
    XCTAssertEqualObjects(swrveConversationAtomStarRating.tag, @"1430239421170-fragment");
    
    SwrveContentStarRating *swrveStarRating = swrveConversationPane.content[6];
    
    XCTAssertEqual(swrveStarRating.currentRating, 0.0f);
}

@end
#endif // TARGET_OS_TV == 0
