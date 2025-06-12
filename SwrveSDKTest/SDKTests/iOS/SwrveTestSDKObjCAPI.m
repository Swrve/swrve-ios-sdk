
#import <XCTest/XCTest.h>
#import "SwrveSDK/Swrve.h"

@interface SwrveTestSDKObjCAPI : XCTestCase
@end

@interface SwrveSDK (InternalAccess)
+ (void)resetSwrveSharedInstance;
+ (void)addSharedInstance:(Swrve*)instance;
@end

@implementation SwrveTestSDKObjCAPI

- (void)testSwrveSDKObjcPublicAPI {
    // Initialize SDK
    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"SwrveTestKey"];
    [SwrveSDK resetSwrveSharedInstance];

    SwrveConfig *config = [[SwrveConfig alloc] init];
    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"SwrveTestKey" config: config];
    [SwrveSDK resetSwrveSharedInstance];

    // Purchase item
    XCTAssertThrows([SwrveSDK purchaseItem:@"" currency:@"" cost:1 quantity:1]);
    
    // IAP transactions
    SKPaymentTransaction *transaction = [[SKPaymentTransaction alloc] init];
    SKProduct *product = [[SKProduct alloc] init];
    SwrveIAPRewards *rewards = [[SwrveIAPRewards alloc] init];
    XCTAssertThrows([SwrveSDK iap:transaction product:product]);
    XCTAssertThrows([SwrveSDK iap:transaction product:product rewards:rewards]);
    
    // Unvalidated IAP
    XCTAssertThrows([SwrveSDK unvalidatedIap:rewards localCost:10.0 localCurrency:@"USD" productId:@"product_id" productIdQuantity:1]);
    
    // Event tracking
    XCTAssertThrows([SwrveSDK event:@"eventName"]);
    XCTAssertThrows([SwrveSDK event:@"eventName" payload:@{@"key": @"value"}]);
    
    // Currency given
    XCTAssertThrows([SwrveSDK currencyGiven:@"currency" givenAmount:100.0]);
    
    // User update
    XCTAssertThrows([SwrveSDK userUpdate:@{@"attributeKey": @"attributeValue"}]);
    XCTAssertThrows([SwrveSDK userUpdate:@"userAttribute" withDate:[NSDate date]]);
    
    // Refresh campaigns and resources
    XCTAssertThrows([SwrveSDK refreshCampaignsAndResources]);

    // Refresh content
    XCTAssertThrows([SwrveSDK refreshContent:nil]);

    // Resource manager
   XCTAssertThrows([SwrveSDK resourceManager]);
    
    // User resources
    
    
    XCTAssertThrows([SwrveSDK userResources:^(NSDictionary *resources, NSString *resourcesAsJSON) {
        
    }]);
    
    XCTAssertThrows([SwrveSDK userResourcesDiffWithListener:^(NSDictionary *oldResourcesValues, NSDictionary *newResourcesValues, NSString *resourcesAsJSON, BOOL fromServer, NSError *error) {
        
    }]);
    
    // Real-time user properties
    XCTAssertThrows([SwrveSDK realTimeUserProperties:^(NSDictionary *properties) {
        // Handle real-time user properties callback
    }]);
    
    // Event queue
    XCTAssertThrows([SwrveSDK sendQueuedEvents]);
    XCTAssertThrows([SwrveSDK saveEventsToDisk]);
    
    XCTAssertThrows([SwrveSDK setEventQueuedCallback:^(NSDictionary *eventPayload, NSString *eventsPayloadAsJSON) {
        
    }]);
    
    // Event with no callback
    XCTAssertThrows([SwrveSDK eventWithNoCallback:@"eventName" payload:@{@"key": @"value"}]);
    
    // Shutdown
    XCTAssertThrows([SwrveSDK shutdown]);
    
#if TARGET_OS_IOS
    // Device updates
    // XCTAssertThrows([SwrveSDK sendDeviceUpdate];
    XCTAssertThrows([SwrveSDK setDeviceToken:[NSData data]]);
    //NSString *deviceToken = XCTAssertThrows([SwrveSDK deviceToken]);
    
    // Remote notifications
    XCTAssertThrows([SwrveSDK didReceiveRemoteNotification:@{@"key": @"value"} withBackgroundCompletionHandler:^(UIBackgroundFetchResult result, NSDictionary *userInfo) {
        // Handle background completion handler
    }]);
    XCTAssertThrows([SwrveSDK sendPushEngagedEvent:@"pushId"]);
    //XCTAssertThrows([SwrveSDK processNotificationResponse:[[UNNotificationResponse alloc] init]];
#endif
    
    // Handle deeplinks
    XCTAssertThrows([SwrveSDK handleDeeplink:[NSURL URLWithString:@"https://example.com"]]);
    XCTAssertThrows([SwrveSDK handleDeferredDeeplink:[NSURL URLWithString:@"https://example.com"]]);
    XCTAssertThrows([SwrveSDK installAction:[NSURL URLWithString:@"https://example.com"]]);
    
    // Identify
    XCTAssertThrows([SwrveSDK identify:@"externalUserId" onSuccess:^(NSString *status, NSString *swrveUserId) {
        // Handle success
    } onError:^(NSInteger httpCode, NSString *errorMessage) {
        // Handle error
    }]);
    
    // External user ID
    XCTAssertThrows([SwrveSDK externalUserId]);
    
    config.initMode = SwrveInitModeManaged;
    
    // Start
    XCTAssertThrows([SwrveSDK start]);
    
    
    // Check if started
    XCTAssertThrows([SwrveSDK started]);
    
    // Stop tracking
    XCTAssertThrows([SwrveSDK stopTracking]);
    
    // Messaging
    SwrveEmbeddedMessage *embeddedMessage = [[SwrveEmbeddedMessage alloc] init];
    XCTAssertThrows([SwrveSDK embeddedControlMessageImpressionEvent:embeddedMessage]);
    XCTAssertThrows([SwrveSDK embeddedMessageWasShownToUser:embeddedMessage]);
    XCTAssertThrows([SwrveSDK embeddedButtonWasPressed:embeddedMessage buttonName:@"buttonName"]);
    
    // Personalize embedded message data
    XCTAssertThrows([SwrveSDK personalizeEmbeddedMessageData:embeddedMessage withPersonalization:@{@"key": @"value"}]);
    XCTAssertThrows([SwrveSDK personalizeText:@"text" withPersonalization:@{@"key": @"value"}]);
    
    // Message center campaigns
    XCTAssertThrows([SwrveSDK messageCenterCampaigns]);
    XCTAssertThrows([SwrveSDK messageCenterCampaignsWithPersonalization:@{@"key": @"value"}]);
    XCTAssertThrows([SwrveSDK messageCenterCampaignWithID:1 andPersonalization:@{@"key": @"value"}]);
    
#if TARGET_OS_IOS
    // Message center campaigns with orientation
    XCTAssertThrows([SwrveSDK messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationPortrait]);
    XCTAssertThrows([SwrveSDK messageCenterCampaignsThatSupportOrientation:UIInterfaceOrientationPortrait withPersonalization:@{@"key": @"value"}]);
#endif
    
    
    // Show and remove message center campaign
    XCTAssertThrows([SwrveSDK showMessageCenterCampaign:@[]]);
    XCTAssertThrows([SwrveSDK showMessageCenterCampaign:@[] withPersonalization:@{@"key": @"value"}]);
    XCTAssertThrows([SwrveSDK removeMessageCenterCampaign:@[]]);
    XCTAssertThrows([SwrveSDK markMessageCenterCampaignAsSeen:@[]]);
    
    // IDFA
    XCTAssertThrows([SwrveSDK idfa:@"idfa_string"]);
    
}


- (void)testStartWithUserIdAPI {
    SwrveConfig *anotherConfig = [[SwrveConfig alloc] init];
    anotherConfig.initMode = SwrveInitModeManaged;
    [SwrveSDK sharedInstanceWithAppID:1030 apiKey:@"SwrveTestKey" config: anotherConfig];
    [SwrveSDK startWithUserId:@"userId"];
}

- (void)testSwrveLogger {

    [SwrveLogger setLogLevel:SwrveLogLevelNone];
    [SwrveLogger setLogLevel:NONE];
    
    [SwrveLogger setLogLevel:SwrveLogLevelVerbose];
    [SwrveLogger setLogLevel:VERBOSE];
    [SwrveLogger debug:@"This is a debug message"];
    
    [SwrveLogger setLogLevel:SwrveLogLevelWarning];
    [SwrveLogger setLogLevel:WARNING];
    [SwrveLogger warning:@"This is a warning message"];
    
    [SwrveLogger setLogLevel:SwrveLogLevelError];
    [SwrveLogger setLogLevel:ERROR];
    [SwrveLogger error:@"This is an error message"];
}

@end
