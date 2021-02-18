#import <XCTest/XCTest.h>
#if TARGET_OS_IOS
#import "TestableSwrve.h"
#import "SwrveTestHelper.h"
#import "SwrveTestConversationsHelper.h"

@interface SwrveTestConversationWidgets : XCTestCase

@end

@implementation SwrveTestConversationWidgets

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

- (void)testConversationPaneHeaders {
    SwrveConversation* conv = [SwrveTestConversationsHelper createConversationForCampaign:@"conversationAnnounce"
                                                                                 andEvent:@"conversation_test_event"];
    XCTAssertEqual(conv.pages.count, 2);
    
    // First page of the conversation
    SwrveConversationPane *p1 = [conv pageAtIndex:0];
    XCTAssertEqualObjects(p1.title, @"Page 1");

    // Second page of the conversation
    SwrveConversationPane *p2 = [conv pageAtIndex:1];
    XCTAssertEqualObjects(p2.title, @"Page 2");

    // Make sure outside index doesn't explode
    XCTAssertNil([conv pageAtIndex:2]);
}

-(void)testButtonControlNavigation {
    SwrveConversation* conv = [SwrveTestConversationsHelper createConversationForCampaign:@"conversationAnnounce"
                                                                                 andEvent:@"conversation_test_event"];

    SwrveConversationPane *p1 = [conv pageAtIndex:0];
    SwrveConversationPane *p2 = [conv pageAtIndex:1];

    XCTAssertEqual(p1.controls.count, 2);
    XCTAssertEqual(p2.controls.count, 1);
    
    SwrveConversationButton *b1 = p1.controls[0];
    SwrveConversationButton *b2 = p1.controls[1];

    // Check the first button on the first page brings the user to the second page
    XCTAssertEqualObjects(b1.target, p2.tag);
    XCTAssertFalse([b1 endsConversation]);
    
    // Check second button on the first page ends the conversation
    XCTAssertNil(b2.target);
    XCTAssertTrue([b2 endsConversation]);
    
    // Check a single button on the second page and it ends conversation
    b1 = p2.controls[0];
    XCTAssertTrue([b1 endsConversation]);
}

-(void)testButtonControlCallAction {
    SwrveConversation* conv = [SwrveTestConversationsHelper createConversationForCampaign:@"conversationAnnounce"
                                                                                 andEvent:@"conversation_test_event"];
    SwrveConversationPane *p = [conv pageAtIndex:0];
    SwrveConversationButton *b = p.controls[1];
    
    XCTAssertEqualObjects(b.actions[@"call"], @"0831012430");
}

@end

#endif // TARGET_OS_TV == 0
