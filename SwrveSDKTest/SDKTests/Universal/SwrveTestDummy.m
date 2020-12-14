#import <XCTest/XCTest.h>

#import "SwrveTestHelper.h"
#import "SwrveSDK.h"
#import "SwrveEmpty.h"
#import "SwrveButton.h"
#import "SwrveCampaign.h"
#import "SwrveQA.h"

#import <OCMock/OCMock.h>

#import "SwrveMessageController+Private.h"

@interface SwrveTestDummy : XCTestCase

@end

@implementation SwrveTestDummy

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

- (void)testOSVersions {
    // Test unsupported OS versions (should return SwrveEmpty)
    NSArray *unsupportedOsVersions = @[@"6.0", @"6.1", @"7.0", @"7.2", @"8.0", @"9.0"];
    for(NSString *osVersion in unsupportedOsVersions) {
        id mockCurrentDevice = OCMPartialMock([UIDevice currentDevice]);
        OCMStub([(UIDevice*)mockCurrentDevice systemVersion]).andReturn(osVersion);

        [SwrveTestHelper destroySharedInstance];
        [SwrveSDK sharedInstanceWithAppID:572 apiKey:@"SomeAPIKey"];
        SwrveEmpty *swrve = (SwrveEmpty *)[SwrveSDK sharedInstance];

        XCTAssertNotNil(swrve);
        XCTAssert([swrve isKindOfClass:[SwrveEmpty class]]);

        [mockCurrentDevice stopMocking];
    }

    // Test supported OS versions (should return Swrve instance)
    NSArray *supportedOsVersions = @[@"10.0", @"11.0", @"12.0"];
    for(NSString *osVersion in supportedOsVersions) {
        id mockCurrentDevice = OCMPartialMock([UIDevice currentDevice]);
        OCMStub([(UIDevice*)mockCurrentDevice systemVersion]).andReturn(osVersion);

        [SwrveTestHelper destroySharedInstance];
        [SwrveSDK sharedInstanceWithAppID:572 apiKey:@"SomeAPIKey"];
        XCTAssertNotNil([SwrveSDK sharedInstance]);
        XCTAssert([[SwrveSDK sharedInstance] isKindOfClass:[Swrve class]]);

        [mockCurrentDevice stopMocking];
    }
}

- (void)testAllDummyMethods {
    // Fake the return of runtime OS version to obtain a SwrveEmpty
    id mockCurrentDevice = OCMPartialMock([UIDevice currentDevice]);
    OCMStub([(UIDevice*)mockCurrentDevice systemVersion]).andReturn(@"6.0");
    [SwrveTestHelper destroySharedInstance];
    [SwrveSDK sharedInstanceWithAppID:572 apiKey:@"SomeAPIKey"];
    SwrveEmpty *swrve = (SwrveEmpty *)[SwrveSDK sharedInstance];

    XCTAssertNotNil(swrve);
    XCTAssert([swrve isKindOfClass:[SwrveEmpty class]]);
    [mockCurrentDevice stopMocking];

    // Test the public methods of the Swrve SDK (should not crash)
    [swrve purchaseItem:@"item" currency:@"gold" cost:20 quantity:2];

    id dummyTransaction = OCMPartialMock([SKPaymentTransaction new]);
    OCMExpect([dummyTransaction transactionState]).andReturn(SKPaymentTransactionStatePurchased);
    SKProduct *dummyProduct = OCMPartialMock([SKProduct new]);
    [swrve iap:dummyTransaction product:dummyProduct];

    SwrveIAPRewards* iapRewards = [SwrveIAPRewards new];
    [iapRewards addCurrency:@"gold" withAmount:18];
    [swrve iap:dummyTransaction product:dummyProduct rewards:iapRewards];

    [swrve unvalidatedIap:iapRewards localCost:20 localCurrency:@"EUR" productId:@"productId" productIdQuantity:1];

    [swrve event:@"cusstom_event"];

    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys: @"FirstValue", @"FirstKey", @"SecondValue", @"SecondKey", [NSNumber numberWithInt:3], @"ThirdKey", nil];
    [swrve event:@"cusstom_event" payload:dic];

    [swrve currencyGiven:@"gold" givenAmount:20];

    [swrve userUpdate:dic];

    [swrve refreshCampaignsAndResources];

    XCTAssertNotNil([swrve resourceManager]);

    [swrve userResources:^(NSDictionary *resources, NSString *resourcesAsJSON) {
    }];

    [swrve userResourcesDiff:^(NSDictionary *oldResourcesValues, NSDictionary *newResourcesValues, NSString *resourcesAsJSON) {
    }];

    [swrve sendQueuedEvents];

    [swrve saveEventsToDisk];

    [swrve setEventQueuedCallback:^(NSDictionary *eventPayload, NSString *eventsPayloadAsJSON) {
    }];

    [swrve eventWithNoCallback:@"cusstom_event" payload:dic];

    [swrve shutdown];

#if TARGET_OS_IOS
    [swrve sendPushNotificationEngagedEvent:@"test"];
#endif

    XCTAssertNotNil(swrve.config);
    XCTAssertEqual(swrve.appID, 572);
    XCTAssertEqualObjects(swrve.apiKey, @"SomeAPIKey");
    XCTAssertNil(swrve.userID);
    XCTAssertNil([((id<SwrveCommonDelegate>)swrve) deviceInfo]);
    XCTAssertNotNil(swrve.messaging);
    XCTAssertNotNil(swrve.resourceManager);
    
#if TARGET_OS_IOS
    XCTAssertNil(swrve.deviceToken);
#endif

    // Test public Talk methods of the Swrve SDK (should not crash)
    XCTAssertNil([swrve.messaging messageForEvent:@"event"]);

    XCTAssertNil([swrve.messaging conversationForEvent:@"event"]);

    SwrveButton* button = [[SwrveButton alloc] init];
    [swrve.messaging buttonWasPressedByUser:button];

    SwrveMessage* message = [[SwrveMessage alloc] init];
    [swrve.messaging messageWasShownToUser:message];

    XCTAssertNil([swrve.messaging appStoreURLForAppId:1]);

#if TARGET_OS_IOS
   [swrve setDeviceToken:[[NSData alloc] init]];
#endif

    [swrve.messaging dismissMessageWindow];

    XCTAssert([[swrve.messaging messageCenterCampaigns] count] == 0);
    
    XCTAssert([[swrve.messaging messageCenterCampaignsWithPersonalisation:nil] count] == 0);
 
#if TARGET_OS_IOS
    XCTAssert([[swrve.messaging messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationPortrait] count] == 0);
    
    XCTAssert([[swrve.messaging messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationPortrait withPersonalisation:nil] count] == 0);
#endif

    SwrveCampaign* campaign = [[SwrveCampaign alloc] init];
    [swrve.messaging showMessageCenterCampaign:campaign];
    
    [swrve.messaging showMessageCenterCampaign:campaign withPersonalisation:nil];

    [swrve.messaging removeMessageCenterCampaign:campaign];
    
    [swrve.messaging markMessageCenterCampaignAsSeen:campaign];

    [swrve.messaging saveCampaignsState];

    [swrve.messaging cleanupConversationUI];

    NSDictionary* event = @{@"type": @"event", @"name": @"sample_event"};
    [swrve.messaging eventRaised:event];

    XCTAssertFalse([[SwrveQA sharedInstance] isQALogging]);

    [swrve.messaging supportsDeviceFilters:[[NSArray alloc] init]];

    XCTAssertNil(swrve.messaging.analyticsSDK);
}

@end
