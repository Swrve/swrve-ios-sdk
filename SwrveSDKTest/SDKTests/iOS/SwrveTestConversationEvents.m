#import <XCTest/XCTest.h>
#import "TestableSwrve.h"
#import "SwrveTestHelper.h"
#import "SwrveTestConversationsHelper.h"
#import "SwrveInputMultiValue.h"
#import "SwrveContentStarRating.h"
#import "TestPermissionsDelegate.h"
#import "TestableSwrveRESTClient.h"
#import "SwrvePermissions.h"

#import <OCMock/OCMock.h>

#if TARGET_OS_IOS /** exclude tvOS **/

@interface SwrveMessageController ()
- (SwrveConversation*)conversationForEvent:(NSString *) eventName withPayload:(NSDictionary *)payload;
@end

@interface SwrveTestConversationEvents : XCTestCase
@end

@implementation SwrveTestConversationEvents

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

-(TestableSwrve*) helpSetupConversation:(NSString*)name {
    return [self helpSetupConversation:name permissionsDelegate:nil];
}

-(TestableSwrve*) helpSetupConversation:(NSString*)name permissionsDelegate:(TestPermissionsDelegate*)permissionsDelegate {
    SwrveConfig *config = [[SwrveConfig alloc] init];
    config.permissionsDelegate = permissionsDelegate;
    
    TestableSwrve *testableSwrve = [SwrveTestConversationsHelper initializeWithCampaignsFile:name andConfig:config];
    [testableSwrve setCustomNowDate:[NSDate dateWithTimeInterval:280 sinceDate:[testableSwrve getNow]]];

    // Ensure the event queue is empty before starting
    NSArray* eventsBuffer = [testableSwrve eventBuffer];
    XCTAssertEqual([eventsBuffer count], 0);

    return testableSwrve;
}

- (void)testConversationStartEventBehaviour {
    [SwrveTestHelper destroySharedInstance];
    TestableSwrve* testableSwrve = [self helpSetupConversation:@"conversationAnnounce"];
    SwrveConversation* swrveConversation = [testableSwrve.messaging conversationForEvent:@"conversation_test_event" withPayload:nil];

    XCTAssertNotNil(testableSwrve);
    XCTAssertNotNil(swrveConversation);

    // Creating the conversation item view controller will
    // cause the conversation to be 'started' before it the
    // view actually appears to the user
    SwrveConversationItemViewController *scivc = [[SwrveConversationItemViewController alloc] init];
    [scivc setConversation:swrveConversation andMessageController:testableSwrve.messaging];
#pragma unused(scivc)

    // Two events should be present in the event buffer, the first one will be the
    // conversation start event, the second will be the impression event generated
    // by the assignment of the first page
    NSArray *eventsBuffer = [testableSwrve eventBuffer];
    XCTAssertEqual([eventsBuffer count], 2);

    SwrveConversationPane *page = [scivc conversationPane];
    NSString *evRoot = [NSString stringWithFormat:@"Swrve.Conversations.Conversation-%@", swrveConversation.conversationID];

    NSDictionary *startEv = [SwrveTestHelper makeDictionaryFromEventBufferEntry:(NSString*)(eventsBuffer[0])];
    XCTAssertEqualObjects(startEv[@"payload"][@"page"], page.tag);
    XCTAssertEqualObjects(startEv[@"name"], ([NSString stringWithFormat:@"%@.start", evRoot]));

    NSDictionary *impressEv = [SwrveTestHelper makeDictionaryFromEventBufferEntry:(NSString*)(eventsBuffer[1])];
    XCTAssertEqualObjects(impressEv[@"payload"][@"page"], page.tag);
    XCTAssertEqualObjects(impressEv[@"name"], ([NSString stringWithFormat:@"%@.impression", evRoot]));
}

-(void)testConversationChoice_No_CheckMarks_Initially_Showing {
    [SwrveTestHelper destroySharedInstance];
    TestableSwrve* testableSwrve = [self helpSetupConversation:@"conversationAnnounce"];
    SwrveConversation* swrveConversation = [testableSwrve.messaging conversationForEvent:@"conversation_test_event" withPayload:nil];

    // This will start the conversation, placing a start and impression event in the buffer
    SwrveConversationItemViewController *scivc = [[SwrveConversationItemViewController alloc] init];
    [scivc setConversation:swrveConversation andMessageController:testableSwrve.messaging];

    NSArray *contentToAdd = scivc.conversationPane.content;
    for (SwrveConversationAtom *atom in contentToAdd) {
        if([atom.type isEqualToString:kSwrveInputMultiValue]) {
            SwrveInputMultiValue *vgInputMultiValue = (SwrveInputMultiValue *)atom;

            // Ensure there are no Checkmarks selected
            XCTAssert(vgInputMultiValue.selectedIndex == -1);
        }
    }
}

-(void)testConversationChoice_Select_Dismiss_Reopen_No_CheckMarks_Showing {
    [SwrveTestHelper destroySharedInstance];
    TestableSwrve* testableSwrve = [self helpSetupConversation:@"conversationAnnounce"];
    SwrveConversation* swrveConversation = [testableSwrve.messaging conversationForEvent:@"conversation_test_event" withPayload:nil];

    // This will start the conversation, placing a start and impression event in the buffer
    SwrveConversationItemViewController *scivc = [[SwrveConversationItemViewController alloc] init];
    [scivc setConversation:swrveConversation andMessageController:testableSwrve.messaging];

    // First page of this conversation has a multiple choice on it, we'll use that for interactions
    SwrveConversationPane *page = [scivc conversationPane];

    NSString *fragmentId = @"1431355297048-fragment";
    SwrveConversationAtom *mvAtom = [[page contentForTag:fragmentId] firstObject];
    XCTAssert([mvAtom isKindOfClass:[SwrveInputMultiValue class]]);

    // Make a selection which will show Checkmark
    SwrveInputMultiValue *choice = (SwrveInputMultiValue *)mvAtom;
    choice.selectedIndex = 2;

    [scivc dismiss];

    // Open the conversation again
    SwrveConversationItemViewController *scivc2 = [[SwrveConversationItemViewController alloc] init];
    [scivc2 setConversation:swrveConversation andMessageController:testableSwrve.messaging];

    // updateUI, should deselect all checkmarks by setting selectedIndex to -1
    [scivc2 updateUI];

    NSArray *contentToAdd = scivc2.conversationPane.content;
    for (SwrveConversationAtom *atom in contentToAdd) {
        if([atom.type isEqualToString:kSwrveInputMultiValue]) {
            SwrveInputMultiValue *vgInputMultiValue = (SwrveInputMultiValue *)atom;

            //Ensure there are no Checkmarks selected
            XCTAssert(vgInputMultiValue.selectedIndex == -1);
        }
    }
}

-(void)testConversationChoiceEventBehaviour {
    [SwrveTestHelper destroySharedInstance];
    TestableSwrve* testableSwrve = [self helpSetupConversation:@"conversationAnnounce"];
    SwrveConversation* swrveConversation = [testableSwrve.messaging conversationForEvent:@"conversation_test_event" withPayload:nil];

    // This will start the conversation, placing a start and impression event in the buffer
    SwrveConversationItemViewController *scivc = [[SwrveConversationItemViewController alloc] init];
    [scivc setConversation:swrveConversation andMessageController:testableSwrve.messaging];
#pragma unused(scivc)

    // First page of this conversation has a multiple choice on it, we'll use that for interactions
    SwrveConversationPane *page = [scivc conversationPane];

    // Find the multi-value input, and select the second choice, which for the
    // 'conversationAnnounce' model is composed of:
    //    {
    //        "answer_id": "83319030-option",
    //        "answer_text": "Option 2"
    //    }
    NSString *fragmentId = @"1431355297048-fragment";
    SwrveConversationAtom *mvAtom = [[page contentForTag:fragmentId] firstObject];
    XCTAssert([mvAtom isKindOfClass:[SwrveInputMultiValue class]]);

    SwrveInputMultiValue *choice = (SwrveInputMultiValue *)mvAtom;
    choice.selectedIndex = 2;  // Pick the second in the list, there are three.

    // Now, let us move to the next page. The transition will emit an event that corresponds
    // to the choice selected above.
    SwrveConversationButton *nextP = (SwrveConversationButton*)page.controls[0];  // Control 0 goes to next page
    XCTAssertTrue([scivc transitionWithControl:nextP]);

    // At this point in time we have these as the first 3 events in the buffer:
    //
    // start / impression / choice  (there are others after this...)
    NSArray *eventsBuffer = [testableSwrve eventBuffer];
    NSString *evRoot = [NSString stringWithFormat:@"Swrve.Conversations.Conversation-%@", swrveConversation.conversationID];
    NSDictionary *choiceEv = [SwrveTestHelper makeDictionaryFromEventBufferEntry:(NSString*)(eventsBuffer[2])];
    XCTAssertEqualObjects(choiceEv[@"payload"][@"page"], page.tag);
    XCTAssertEqualObjects(choiceEv[@"payload"][@"fragment"], fragmentId);
    XCTAssertEqualObjects(choiceEv[@"name"], ([NSString stringWithFormat:@"%@.choice", evRoot]));
    XCTAssertEqualObjects(choiceEv[@"payload"][@"result"], [choice userResponse]);
}

-(void)testConversationStarRatingEventBehaviour {
    [SwrveTestHelper destroySharedInstance];
    TestableSwrve* testableSwrve = [self helpSetupConversation:@"conversationAnnounce"];
    SwrveConversation* swrveConversation = [testableSwrve.messaging conversationForEvent:@"conversation_test_event" withPayload:nil];

    // This will start the conversation, placing a start and impression event in the buffer
    SwrveConversationItemViewController *scivc = [[SwrveConversationItemViewController alloc] init];
    [scivc setConversation:swrveConversation andMessageController:testableSwrve.messaging];
#pragma unused(scivc)

    SwrveConversationPane *page = [scivc conversationPane];

    NSString *fragmentId = @"1430239421170-fragment";
    SwrveConversationAtom *mvAtom = [[page contentForTag:fragmentId] lastObject];
    XCTAssert([mvAtom isKindOfClass:[SwrveContentStarRating class]]);

    SwrveContentStarRating *starRating = (SwrveContentStarRating *)mvAtom;
    starRating.currentRating = 5.0f;

    SwrveConversationButton *nextP = (SwrveConversationButton*)page.controls[0];  // Control 0 goes to next page
    XCTAssertTrue([scivc transitionWithControl:nextP]);

    NSArray *eventsBuffer = [testableSwrve eventBuffer];
    NSString *evRoot = [NSString stringWithFormat:@"Swrve.Conversations.Conversation-%@", swrveConversation.conversationID];
    NSDictionary *starEv = [SwrveTestHelper makeDictionaryFromEventBufferEntry:(NSString*)(eventsBuffer[2])];
    XCTAssertEqualObjects(starEv[@"payload"][@"page"], page.tag);
    XCTAssertEqualObjects(starEv[@"payload"][@"fragment"], fragmentId);
    XCTAssertEqualObjects(starEv[@"name"], ([NSString stringWithFormat:@"%@.star-rating", evRoot]));
    XCTAssertEqualObjects(starEv[@"payload"][@"result"], ([NSString stringWithFormat:@"%.01f",[starRating currentRating]]));
}

- (void)testConversationContactsPermission {
    [SwrveTestHelper destroySharedInstance];
    // Set the Contacts permission as if it was not active (and check that it changes and the delegate is called)
    TestPermissionsDelegate* permissionsDelegate = [[TestPermissionsDelegate alloc] init];
    permissionsDelegate.mockContactPermissionState = SwrvePermissionStateUnknown;
    permissionsDelegate.mockNextContactPermissionState = SwrvePermissionStateAuthorized;
    id permissionsMock = OCMPartialMock(permissionsDelegate);
    OCMExpect([permissionsMock requestContactsPermission:OCMOCK_ANY]).andForwardToRealObject();
    TestableSwrve *testableSwrve = [self helpSetupConversation:@"conversationContactsPermission" permissionsDelegate:permissionsMock];
    
    // Check that the permission is unknown at the start
    NSDictionary *deviceInfo = [(id<SwrveCommonDelegate>)testableSwrve deviceInfo];
    XCTAssertNotNil(deviceInfo);
    XCTAssertEqualObjects(deviceInfo[@"Swrve.permission.ios.contacts"], @"unknown");
    
    SwrveConversation *swrveConversation = [testableSwrve.messaging conversationForEvent:@"conversation_test_event" withPayload:nil];
    
    // This will start the conversation, placing a start and impression event in the buffer
    SwrveConversationItemViewController *scivc = [[SwrveConversationItemViewController alloc] init];
    [scivc setConversation:swrveConversation andMessageController:testableSwrve.messaging];
#pragma unused(scivc)
    
    // Click on the button that requests the permission
    SwrveConversationPane *page = [scivc conversationPane];
    SwrveConversationButton *permissionButton = (SwrveConversationButton*)page.controls[0];  // Control 0 goes to next page
    XCTAssertTrue([scivc transitionWithControl:permissionButton]);
    
    // Delegate should have been called to request the camera permission
    OCMVerifyAllWithDelay(permissionsMock,5);
    
    // Check that the device properties have changed
    deviceInfo = [(id<SwrveCommonDelegate>)testableSwrve deviceInfo];
    XCTAssertNotNil(deviceInfo);
    XCTAssertEqualObjects(deviceInfo[@"Swrve.permission.ios.contacts"], @"authorized");
    
    // We only check the diff in permission states to send eventes on new sessions
    // so for that we shutdown and restart the SDK again
    [SwrveTestHelper destroySharedInstance];
    testableSwrve = [self helpSetupConversation:@"conversationContactsPermission" permissionsDelegate:permissionsMock];
    TestableSwrveRESTClient *restClient = (TestableSwrveRESTClient *)[testableSwrve restClient];
    XCTAssert([[[restClient.savedRequests valueForKey:@"eventRequests"] objectAtIndex:0] containsString:@"Swrve.permission.ios.contacts.on"]);
    
    [permissionsMock stopMocking];
}

-(void)testConversationContactsPermissionDenied {
    [SwrveTestHelper destroySharedInstance];
    // Set the Contacts permission as if it was not active (and check that it changes and the delegate is called)
    TestPermissionsDelegate *permissionsDelegate = [[TestPermissionsDelegate alloc] init];
    permissionsDelegate.mockContactPermissionState = SwrvePermissionStateDenied;
    TestableSwrve *testableSwrve = [self helpSetupConversation:@"conversationContactsPermission" permissionsDelegate:permissionsDelegate];
    
    // Check that the permission is unknown at the start
    NSDictionary *deviceInfo = [(id<SwrveCommonDelegate>)testableSwrve deviceInfo];
    XCTAssertNotNil(deviceInfo);
    XCTAssertEqualObjects(deviceInfo[@"Swrve.permission.ios.contacts"], @"denied");
    
    SwrveConversation* swrveConversation = [testableSwrve.messaging conversationForEvent:@"conversation_test_event" withPayload:nil];
    XCTAssertNil(swrveConversation);
}

- (void)testConversationLocationWhenInUsePermission {
    [SwrveTestHelper destroySharedInstance];
    // Set the Location permission as if it was not active (and check that it changes and the delegate is called)
    TestPermissionsDelegate *permissionsDelegate = [[TestPermissionsDelegate alloc] init];
    permissionsDelegate.mockLocationWhenInUsePermissionState = SwrvePermissionStateUnknown;
    permissionsDelegate.mockNextLocationAlwaysPermissionState = SwrvePermissionStateAuthorized;
    id permissionsMock = OCMPartialMock(permissionsDelegate);
    OCMExpect([permissionsMock requestLocationWhenInUsePermission:OCMOCK_ANY]).andForwardToRealObject();
    TestableSwrve* testableSwrve = [self helpSetupConversation:@"conversationLocationWhenInUsePermission" permissionsDelegate:permissionsMock];
    
    // Check that the permission is unknown at the start
    NSDictionary *deviceInfo = [(id<SwrveCommonDelegate>)testableSwrve deviceInfo];
    XCTAssertNotNil(deviceInfo);
    XCTAssertEqualObjects(deviceInfo[@"Swrve.permission.ios.location.when_in_use"], @"unknown");
    
    SwrveConversation *swrveConversation = [testableSwrve.messaging conversationForEvent:@"conversation_test_event" withPayload:nil];
    
    // This will start the conversation, placing a start and impression event in the buffer
    SwrveConversationItemViewController *scivc = [[SwrveConversationItemViewController alloc] init];
    [scivc setConversation:swrveConversation andMessageController:testableSwrve.messaging];
#pragma unused(scivc)
    
    // Click on the button that requests the permission
    SwrveConversationPane *page = [scivc conversationPane];
    SwrveConversationButton *permissionButton = (SwrveConversationButton*)page.controls[0];  // Control 0 goes to next page
    XCTAssertTrue([scivc transitionWithControl:permissionButton]);
    
    // Delegate should have been called to request the camera permission
    OCMVerifyAllWithDelay(permissionsMock,5);
    
    // Check that the device properties have changed
    deviceInfo = [(id<SwrveCommonDelegate>)testableSwrve deviceInfo];
    XCTAssertNotNil(deviceInfo);
    XCTAssertEqualObjects(deviceInfo[@"Swrve.permission.ios.location.when_in_use"], @"authorized");
    
    // We only check the diff in permission states to send eventes on new sessions
    // so for that we shutdown and restart the SDK again
    [SwrveTestHelper destroySharedInstance];
    testableSwrve = [self helpSetupConversation:@"conversationLocationWhenInUsePermission" permissionsDelegate:permissionsMock];
    TestableSwrveRESTClient *restClient = (TestableSwrveRESTClient *)[testableSwrve restClient];
    XCTAssert([[[restClient.savedRequests valueForKey:@"eventRequests"] objectAtIndex:0] containsString:@"Swrve.permission.ios.location.when_in_use.on"]);
    
    [permissionsMock stopMocking];
}

- (void)testConversationLocationWhenInUsePermissionDenied {
    [SwrveTestHelper destroySharedInstance];
    // Set the Location permission as if it was not active (and check that it changes and the delegate is called)
    TestPermissionsDelegate* permissionsDelegate = [[TestPermissionsDelegate alloc] init];
    permissionsDelegate.mockLocationWhenInUsePermissionState = SwrvePermissionStateDenied;
    TestableSwrve* testableSwrve = [self helpSetupConversation:@"conversationLocationWhenInUsePermission" permissionsDelegate:permissionsDelegate];
    
    // Check that the permission is unknown at the start
    NSDictionary * deviceInfo = [(id<SwrveCommonDelegate>)testableSwrve deviceInfo];
    XCTAssertNotNil(deviceInfo);
    XCTAssertEqualObjects(deviceInfo[@"Swrve.permission.ios.location.when_in_use"], @"denied");
    
    SwrveConversation* swrveConversation = [testableSwrve.messaging conversationForEvent:@"conversation_test_event" withPayload:nil];
    XCTAssertNil(swrveConversation);
}

- (void)testConversationLocationAlwaysPermission {
    [SwrveTestHelper destroySharedInstance];
    // Set the Photo permission as if it was not active (and check that it changes and the delegate is called)
    TestPermissionsDelegate *permissionsDelegate = [[TestPermissionsDelegate alloc] init];
    permissionsDelegate.mockLocationAlwaysPermissionState = SwrvePermissionStateUnknown;
    permissionsDelegate.mockNextLocationAlwaysPermissionState = SwrvePermissionStateAuthorized;
    id permissionsMock = OCMPartialMock(permissionsDelegate);
    OCMExpect([permissionsMock requestLocationAlwaysPermission:OCMOCK_ANY]).andForwardToRealObject();
    TestableSwrve *testableSwrve = [self helpSetupConversation:@"conversationLocationAlwaysPermission" permissionsDelegate:permissionsMock];
    
    // Check that the permission is unknown at the start
    NSDictionary *deviceInfo = [(id<SwrveCommonDelegate>)testableSwrve deviceInfo];
    XCTAssertNotNil(deviceInfo);
    XCTAssertEqualObjects(deviceInfo[@"Swrve.permission.ios.location.always"], @"unknown");
    
    SwrveConversation* swrveConversation = [testableSwrve.messaging conversationForEvent:@"conversation_test_event" withPayload:nil];
    
    // This will start the conversation, placing a start and impression event in the buffer
    SwrveConversationItemViewController *scivc = [[SwrveConversationItemViewController alloc] init];
    [scivc setConversation:swrveConversation andMessageController:testableSwrve.messaging];
#pragma unused(scivc)
    
    // Click on the button that requests the permission
    SwrveConversationPane *page = [scivc conversationPane];
    SwrveConversationButton *permissionButton = (SwrveConversationButton*)page.controls[0];  // Control 0 goes to next page
    XCTAssertTrue([scivc transitionWithControl:permissionButton]);
    
    // Delegate should have been called to request the camera permission
    OCMVerifyAllWithDelay(permissionsMock,5);
    
    // Check that the device properties have changed
    deviceInfo = [(id<SwrveCommonDelegate>)testableSwrve deviceInfo];
    XCTAssertNotNil(deviceInfo);
    XCTAssertEqualObjects(deviceInfo[@"Swrve.permission.ios.location.always"], @"authorized");
    
    // We only check the diff in permission states to send eventes on new sessions
    // so for that we shutdown and restart the SDK again
    [SwrveTestHelper destroySharedInstance];
    testableSwrve = [self helpSetupConversation:@"conversationLocationAlwaysPermission" permissionsDelegate:permissionsMock];
    TestableSwrveRESTClient *restClient = (TestableSwrveRESTClient *)[testableSwrve restClient];
    XCTAssert([[[restClient.savedRequests valueForKey:@"eventRequests"] objectAtIndex:0] containsString:@"Swrve.permission.ios.location.always.on"]);
    
    [permissionsMock stopMocking];
}

- (void)testConversationLocationAlwaysPermissionDenied {
    [SwrveTestHelper destroySharedInstance];
    // Set the Location permission as if it was not active (and check that it changes and the delegate is called)
    TestPermissionsDelegate *permissionsDelegate = [[TestPermissionsDelegate alloc] init];
    permissionsDelegate.mockLocationAlwaysPermissionState = SwrvePermissionStateDenied;
    TestableSwrve* testableSwrve = [self helpSetupConversation:@"conversationLocationAlwaysPermission" permissionsDelegate:permissionsDelegate];
    
    // Check that the permission is unknown at the start
    NSDictionary *deviceInfo = [(id<SwrveCommonDelegate>)testableSwrve deviceInfo];
    XCTAssertNotNil(deviceInfo);
    XCTAssertEqualObjects(deviceInfo[@"Swrve.permission.ios.location.always"], @"denied");
    
    SwrveConversation *swrveConversation = [testableSwrve.messaging conversationForEvent:@"conversation_test_event" withPayload:nil];
    XCTAssertNil(swrveConversation);
}

- (void)testConversationPhotoPermission {
    [SwrveTestHelper destroySharedInstance];
    // Set the Photo permission as if it was not active (and check that it changes and the delegate is called)
    TestPermissionsDelegate *permissionsDelegate = [[TestPermissionsDelegate alloc] init];
    permissionsDelegate.mockPhotoLibraryPermissionState = SwrvePermissionStateUnknown;
    permissionsDelegate.mockNextPhotoLibraryPermissionState = SwrvePermissionStateAuthorized;
    id permissionsMock = OCMPartialMock(permissionsDelegate);
    OCMExpect([permissionsMock requestPhotoLibraryPermission:OCMOCK_ANY]).andForwardToRealObject();
    TestableSwrve *testableSwrve = [self helpSetupConversation:@"conversationPhotoPermission" permissionsDelegate:permissionsMock];
    
    // Check that the permission is unknown at the start
    NSDictionary *deviceInfo = [(id<SwrveCommonDelegate>)testableSwrve deviceInfo];
    XCTAssertNotNil(deviceInfo);
    XCTAssertEqualObjects(deviceInfo[@"Swrve.permission.ios.photos"], @"unknown");
    
    SwrveConversation* swrveConversation = [testableSwrve.messaging conversationForEvent:@"conversation_test_event" withPayload:nil];
    
    // This will start the conversation, placing a start and impression event in the buffer
    SwrveConversationItemViewController *scivc = [[SwrveConversationItemViewController alloc] init];
    [scivc setConversation:swrveConversation andMessageController:testableSwrve.messaging];
#pragma unused(scivc)
    
    // Click on the button that requests the permission
    SwrveConversationPane *page = [scivc conversationPane];
    SwrveConversationButton *permissionButton = (SwrveConversationButton*)page.controls[0];  // Control 0 goes to next page
    XCTAssertTrue([scivc transitionWithControl:permissionButton]);
    
    // Delegate should have been called to request the camera permission
    OCMVerifyAllWithDelay(permissionsMock,5);
    
    // Check that the device properties have changed
    deviceInfo = [(id<SwrveCommonDelegate>)testableSwrve deviceInfo];
    XCTAssertNotNil(deviceInfo);
    XCTAssertEqualObjects(deviceInfo[@"Swrve.permission.ios.photos"], @"authorized");
    
    // We only check the diff in permission states to send eventes on new sessions
    // so for that we shutdown and restart the SDK again
    [SwrveTestHelper destroySharedInstance];
    testableSwrve = [self helpSetupConversation:@"conversationPhotoPermission" permissionsDelegate:permissionsMock];
    TestableSwrveRESTClient *restClient = (TestableSwrveRESTClient *)[testableSwrve restClient];
    XCTAssert([[[restClient.savedRequests valueForKey:@"eventRequests"] objectAtIndex:0] containsString:@"Swrve.permission.ios.photos.on"]);
    
    [permissionsMock stopMocking];
}

- (void)testConversationPhotoPermissionDenied {
    [SwrveTestHelper destroySharedInstance];
    // Set the Location permission as if it was not active (and check that it changes and the delegate is called)
    TestPermissionsDelegate* permissionsDelegate = [[TestPermissionsDelegate alloc] init];
    permissionsDelegate.mockPhotoLibraryPermissionState = SwrvePermissionStateDenied;
    TestableSwrve* testableSwrve = [self helpSetupConversation:@"conversationPhotoPermission" permissionsDelegate:permissionsDelegate];
    
    // Check that the permission is unknown at the start
    NSDictionary *deviceInfo = [(id<SwrveCommonDelegate>)testableSwrve deviceInfo];
    XCTAssertNotNil(deviceInfo);
    XCTAssertEqualObjects(deviceInfo[@"Swrve.permission.ios.photos"], @"denied");
    
    SwrveConversation *swrveConversation = [testableSwrve.messaging conversationForEvent:@"conversation_test_event" withPayload:nil];
    XCTAssertNil(swrveConversation);
}

- (void)testConversationCameraPermission {
    [SwrveTestHelper destroySharedInstance];
    // Set the Camera permission as if it was not active (and check that it changes and the delegate is called)
    TestPermissionsDelegate *permissionsDelegate = [[TestPermissionsDelegate alloc] init];
    permissionsDelegate.mockCameraPermissionState = SwrvePermissionStateUnknown;
    permissionsDelegate.mockNextCameraPermissionState = SwrvePermissionStateAuthorized;
    id permissionsMock = OCMPartialMock(permissionsDelegate);
    OCMExpect([permissionsMock requestCameraPermission:OCMOCK_ANY]).andForwardToRealObject();
    TestableSwrve *testableSwrve = [self helpSetupConversation:@"conversationCameraPermission" permissionsDelegate:permissionsMock];
    
    // Check that the permission is unknown at the start
    NSDictionary *deviceInfo = [(id<SwrveCommonDelegate>)testableSwrve deviceInfo];
    XCTAssertNotNil(deviceInfo);
    XCTAssertEqualObjects(deviceInfo[@"Swrve.permission.ios.camera"], @"unknown");
    
    SwrveConversation *swrveConversation = [testableSwrve.messaging conversationForEvent:@"conversation_test_event" withPayload:nil];
    
    // This will start the conversation, placing a start and impression event in the buffer
    SwrveConversationItemViewController *scivc = [[SwrveConversationItemViewController alloc] init];
    [scivc setConversation:swrveConversation andMessageController:testableSwrve.messaging];
#pragma unused(scivc)
    
    // Click on the button that requests the permission
    SwrveConversationPane *page = [scivc conversationPane];
    SwrveConversationButton *permissionButton = (SwrveConversationButton*)page.controls[0];  // Control 0 goes to next page
    XCTAssertTrue([scivc transitionWithControl:permissionButton]);
    
    // Delegate should have been called to request the camera permission
    OCMVerifyAllWithDelay(permissionsMock,5);
    
    // Check that the device properties have changed
    deviceInfo = [(id<SwrveCommonDelegate>)testableSwrve deviceInfo];
    XCTAssertNotNil(deviceInfo);
    XCTAssertEqualObjects(deviceInfo[@"Swrve.permission.ios.camera"], @"authorized");
    
    // We only check the diff in permission states to send eventes on new sessions
    // so for that we shutdown and restart the SDK again
    [SwrveTestHelper destroySharedInstance];
    testableSwrve = [self helpSetupConversation:@"conversationCameraPermission" permissionsDelegate:permissionsMock];
    TestableSwrveRESTClient *restClient = (TestableSwrveRESTClient *)[testableSwrve restClient];
    XCTAssert([[[restClient.savedRequests valueForKey:@"eventRequests"] objectAtIndex:0] containsString:@"Swrve.permission.ios.camera.on"]);
    
    [permissionsMock stopMocking];
}

- (void)testConversationCameraPermissionDenied {
    [SwrveTestHelper destroySharedInstance];
    // Set the Camera permission as if it was not active (and check that it changes and the delegate is called)
    TestPermissionsDelegate *permissionsDelegate = [[TestPermissionsDelegate alloc] init];
    permissionsDelegate.mockCameraPermissionState = SwrvePermissionStateDenied;
    TestableSwrve *testableSwrve = [self helpSetupConversation:@"conversationCameraPermission" permissionsDelegate:permissionsDelegate];
    
    // Check that the permission is unknown at the start
    NSDictionary *deviceInfo = [(id<SwrveCommonDelegate>)testableSwrve deviceInfo];
    XCTAssertNotNil(deviceInfo);
    XCTAssertEqualObjects(deviceInfo[@"Swrve.permission.ios.camera"], @"denied");
    
    SwrveConversation *swrveConversation = [testableSwrve.messaging conversationForEvent:@"conversation_test_event" withPayload:nil];
    XCTAssertNil(swrveConversation);
}

-(void)testConversationPushPermissionUnknown {
    [SwrveTestHelper destroySharedInstance];
    
    id classMock = OCMClassMock([SwrvePermissions class]);
    OCMStub(ClassMethod([classMock pushAuthorizationWithSDK:OCMOCK_ANY])).andReturn(@"unknown");
    TestableSwrve* testableSwrve = [self helpSetupConversation:@"conversationPushPermission"];
    
    // Check that the permission is unknown at the start
    NSDictionary * deviceInfo = [(id<SwrveCommonDelegate>)testableSwrve deviceInfo];
    XCTAssertNotNil(deviceInfo);
    XCTAssertEqualObjects(deviceInfo[@"Swrve.permission.ios.push_notifications"], @"unknown");
    
    SwrveConversation* swrveConversation = [testableSwrve.messaging conversationForEvent:@"conversation_test_event" withPayload:nil];
    XCTAssertNotNil(swrveConversation);
    
    [classMock stopMocking];
}

-(void)testConversationPushPermissionDenied {
    [SwrveTestHelper destroySharedInstance];
    
    id classMock = OCMClassMock([SwrvePermissions class]);
    OCMStub(ClassMethod([classMock pushAuthorizationWithSDK:OCMOCK_ANY])).andReturn(@"denied");
    TestableSwrve* testableSwrve = [self helpSetupConversation:@"conversationPushPermission"];
    
    // Check that the permission is unknown at the start
    NSDictionary * deviceInfo = [(id<SwrveCommonDelegate>)testableSwrve deviceInfo];
    XCTAssertNotNil(deviceInfo);
    XCTAssertEqualObjects(deviceInfo[@"Swrve.permission.ios.push_notifications"], @"denied");
    
    SwrveConversation* swrveConversation = [testableSwrve.messaging conversationForEvent:@"conversation_test_event" withPayload:nil];
    XCTAssertNil(swrveConversation);
    
    [classMock stopMocking];
}

-(void)testConversationPushPermissionAuthorized {
    [SwrveTestHelper destroySharedInstance];
    
    id classMock = OCMClassMock([SwrvePermissions class]);
    OCMStub(ClassMethod([classMock pushAuthorizationWithSDK:OCMOCK_ANY])).andReturn(@"authorized");
    TestableSwrve* testableSwrve = [self helpSetupConversation:@"conversationPushPermission"];
    
    // Check that the permission is unknown at the start
    NSDictionary * deviceInfo = [(id<SwrveCommonDelegate>)testableSwrve deviceInfo];
    XCTAssertNotNil(deviceInfo);
    XCTAssertEqualObjects(deviceInfo[@"Swrve.permission.ios.push_notifications"], @"authorized");
    
    SwrveConversation* swrveConversation = [testableSwrve.messaging conversationForEvent:@"conversation_test_event" withPayload:nil];
    XCTAssertNil(swrveConversation);
    
    [classMock stopMocking];
}

-(void)testConversationPushPermissionProvisional {
    [SwrveTestHelper destroySharedInstance];
    
    id classMock = OCMClassMock([SwrvePermissions class]);
    OCMStub(ClassMethod([classMock pushAuthorizationWithSDK:OCMOCK_ANY])).andReturn(@"provisional");
    TestableSwrve* testableSwrve = [self helpSetupConversation:@"conversationPushPermission"];
    
    // Check that the permission is unknown at the start
    NSDictionary * deviceInfo = [(id<SwrveCommonDelegate>)testableSwrve deviceInfo];
    XCTAssertNotNil(deviceInfo);
    XCTAssertEqualObjects(deviceInfo[@"Swrve.permission.ios.push_notifications"], @"provisional");
    
    SwrveConversation* swrveConversation = [testableSwrve.messaging conversationForEvent:@"conversation_test_event" withPayload:nil];
    XCTAssertNotNil(swrveConversation);
    
    [classMock stopMocking];
}

-(void)testPermissionDelegateNotRetained {
    TestPermissionsDelegate *permissionsDelegate = [[TestPermissionsDelegate alloc] init];
    TestableSwrve *testableSwrve = [self helpSetupConversation:@"conversationCameraPermission" permissionsDelegate:permissionsDelegate];
    // reallocate should dealloc the pervious one
    permissionsDelegate = [[TestPermissionsDelegate alloc] init];
    XCTAssertNil(testableSwrve.config.permissionsDelegate);
}

@end
#endif // TARGET_OS_IOS /** exclude tvOS **/
