#import <XCTest/XCTest.h>

#import "SwrveTestHelper.h"
#import "SwrveSDK.h"
#import "SwrveEmpty.h"
#import "SwrveButton.h"
#import "SwrveCampaign.h"
#import "SwrveQA.h"

#import <OCMock/OCMock.h>

#import "SwrveMessageController+Private.h"

@interface Swrve(privateAccess)
@property(atomic) SwrveMessageController *messaging;
@end

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

    [swrve userResourcesDiffWithListener:^(NSDictionary *oldResourcesValues, NSDictionary *newResourcesValues, NSString *resourcesAsJSON, BOOL fromServer, NSError *error) {
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
    XCTAssertNotNil(swrve.resourceManager);
    
#if TARGET_OS_IOS
    XCTAssertNil(swrve.deviceToken);
#endif

#if TARGET_OS_IOS
   [swrve setDeviceToken:[[NSData alloc] init]];
#endif

    XCTAssert([[swrve messageCenterCampaigns] count] == 0);
    
    XCTAssert([[swrve messageCenterCampaignsWithPersonalization:nil] count] == 0);
 
#if TARGET_OS_IOS
    XCTAssert([[swrve messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationPortrait] count] == 0);
    
    XCTAssert([[swrve messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationPortrait withPersonalization:nil] count] == 0);
#endif

    SwrveCampaign* campaign = [[SwrveCampaign alloc] init];
    [swrve showMessageCenterCampaign:campaign];
    
    [swrve showMessageCenterCampaign:campaign withPersonalization:nil];

    [swrve removeMessageCenterCampaign:campaign];
    
    [swrve markMessageCenterCampaignAsSeen:campaign];

    XCTAssertFalse([[SwrveQA sharedInstance] isQALogging]);
}

@end
