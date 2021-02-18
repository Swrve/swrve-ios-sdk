#import <XCTest/XCTest.h>
#import "Swrve.h"
#import "SwrveTestHelper.h"
#import "SwrveConversation.h"
#import "SwrveTestConversationsHelper.h"

#if TARGET_OS_IOS /** exclude tvOS **/
@interface SwrveTestConversations : XCTestCase

@end

@implementation SwrveTestConversations

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

- (void)testConversationsAreFilteredByConversationVersion {
    // NOTE: You have to update the file campaignsConversationVersion when upping the supported SDK conversation_version
    
    SwrveConversation* conv = nil;
    // No version, should be displayable
    conv = [SwrveTestConversationsHelper createConversationForCampaign:@"campaignsConversationVersion" andEvent:@"event1"];
    XCTAssertNotNil(conv);

    // Current version (1), should be ok
    conv = [SwrveTestConversationsHelper createConversationForCampaign:@"campaignsConversationVersion" andEvent:@"event2"];
    XCTAssertNotNil(conv);

    
    conv = [SwrveTestConversationsHelper createConversationForCampaign:@"campaignsConversationVersion" andEvent:@"event3"];
    XCTAssertNotNil(conv);
    
    // Unsupported higher version (3+)
    conv = [SwrveTestConversationsHelper createConversationForCampaign:@"campaignsConversationVersion" andEvent:@"event4"];
    XCTAssertNil(conv);
}

- (void)testConversationsAreFilteredByDeviceFilters {
    SwrveConversation* conv = nil;
    // No filters, should be displayable
    conv = [SwrveTestConversationsHelper createConversationForCampaign:@"campaignsConversationFilters" andEvent:@"event1"];
    XCTAssertNotNil(conv);
    
    // Supported filter ("ios"), should be displayable
    conv = [SwrveTestConversationsHelper createConversationForCampaign:@"campaignsConversationFilters" andEvent:@"event2"];
    XCTAssertNotNil(conv);
    
    // Unsupported filter
    conv = [SwrveTestConversationsHelper createConversationForCampaign:@"campaignsConversationFilters" andEvent:@"event3"];
    XCTAssertNil(conv);
}


@end
#endif // TARGET_OS_IOS /** exclude tvOS **/
