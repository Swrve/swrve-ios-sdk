#import "SwrveEmpty.h"
#import "SwrveMessageController+Private.h"
#if __has_include(<SwrveSDKCommon/SwrveCommon.h>)
#import <SwrveSDKCommon/SwrveCommon.h>
#else
#import "SwrveCommon.h"
#endif

#if __has_include(<SwrveSDK/SwrveSDK-Swift.h>)
#import <SwrveSDK/SwrveSDK-Swift.h>
#elif __has_include("SwrveSDK-Swift.h")
#import "SwrveSDK-Swift.h"
#endif

@interface SwrveEmpty() <SwrveCommonDelegate>
@property (atomic)         SwrveMessageController *messaging;
@end

// Used at runtime when the platform is not supported.
@implementation SwrveEmpty {
    SwrveResourceManager* resourceManager;
}

@synthesize config;
@synthesize appID;
@synthesize apiKey;
@synthesize messaging;
@synthesize resourceManager;
@synthesize deviceToken;
@synthesize eventsServer;
@synthesize contentServer;
@synthesize identityServer;
@synthesize joined;
@synthesize language;
@synthesize httpTimeout;
@synthesize deviceUUID;

- (id)initWithAppID:(int)swrveAppID apiKey:(NSString *)swrveAPIKey {
    if (self = [super init]) {
        [self setup:swrveAppID apiKey:swrveAPIKey config:nil];
    }
    return self;
}

- (id)initWithAppID:(int)swrveAppID apiKey:(NSString *)swrveAPIKey config:(SwrveConfig *)swrveConfig {
    if (self = [super init]) {
        [self setup:swrveAppID apiKey:swrveAPIKey config:swrveConfig];
    }
    return self;
}

- (void)setup:(int)swrveAppID apiKey:(NSString *)swrveAPIKey config:(SwrveConfig *)swrveConfig {
    appID = swrveAppID;
    apiKey = swrveAPIKey;
    if (swrveConfig == nil) {
        config = [[SwrveConfig alloc] init];
    } else {
        config = swrveConfig;
    }
    
    resourceManager = [[SwrveResourceManager alloc] init];

    messaging = [[SwrveMessageController alloc] initWithSwrve:nil];

    [SwrveCommon addSharedInstance:self];
}

- (NSString *)swrveSDKVersion {
    return @SWRVE_SDK_VERSION;
}

- (int)purchaseItem:(NSString *)itemName currency:(NSString *)itemCurrency cost:(int)itemCost quantity:(int)itemQuantity {
#pragma unused(itemName, itemCurrency, itemCost, itemQuantity)
    return SWRVE_SUCCESS;
}

- (int)iap:(SKPaymentTransaction*) transaction product:(SKProduct *)product {
#pragma unused(transaction, product)
    return SWRVE_SUCCESS;
}

- (int)iap:(SKPaymentTransaction *) transaction product:(SKProduct *)product rewards:(SwrveIAPRewards*)rewards {
#pragma unused(transaction, product, rewards)
    return SWRVE_SUCCESS;
}

- (int)unvalidatedIap:(SwrveIAPRewards *)rewards
            localCost:(double)localCost
        localCurrency:(NSString *)localCurrency
            productId:(NSString *)productId
    productIdQuantity:(int)productIdQuantity {
#pragma unused(rewards, localCost, localCurrency, productId, productIdQuantity)
    return SWRVE_SUCCESS;
}

- (int)event:(NSString *)eventName {
#pragma unused(eventName)
    return SWRVE_SUCCESS;
}

- (int)event:(NSString *)eventName payload:(NSDictionary *)eventPayload {
#pragma unused(eventName, eventPayload)
    return SWRVE_SUCCESS;
}

- (int)currencyGiven:(NSString *)givenCurrency givenAmount:(double)givenAmount {
#pragma unused(givenCurrency, givenAmount)
    return SWRVE_SUCCESS;
}

- (int)userUpdate:(NSDictionary *)attributes {
#pragma unused(attributes)
    return SWRVE_SUCCESS;
}

- (int)userUpdate:(NSString *)name withDate:(NSDate *)date {
#pragma unused(name, date)
    return SWRVE_SUCCESS;
}

-(void) refreshContent:(id<SwrveRefreshContentDelegate>)listener {
}

- (SwrveResourceManager *) resourceManager {
    return self->resourceManager;
}

-(void)userResources:(SwrveUserResourcesCallback)callbackBlock {
#pragma unused(callbackBlock)
}

- (void)userResourcesDiffWithListener:(SwrveUserResourcesDiffListener)listener {
#pragma unused(listener)
}

-(void) realTimeUserProperties:(SwrveRealTimeUserPropertiesCallback)callbackBlock{
#pragma unused(callbackBlock)
}

- (void)sendQueuedEvents {
}

- (void)saveEventsToDisk {
}

- (void)setEventQueuedCallback:(SwrveEventQueuedCallback)callbackBlock {
#pragma unused(callbackBlock)
}

- (int)eventWithNoCallback:(NSString *)eventName payload:(NSDictionary *)eventPayload {
#pragma unused(eventName, eventPayload)
    return SWRVE_SUCCESS;
}

- (NSArray<SwrvePushInboxMessage *> *)pushInboxMessages {
    return @[];
}

- (void)readPushInboxMessage:(UInt64)messageId listener: (id<SwrvePushInboxDelegate>)listener {
    return;
}

- (void)engagePushInboxMessage:(UInt64)messageId listener: (id<SwrvePushInboxDelegate>)listener {
    return;
}

- (void)deletePushInboxMessage:(UInt64)messageId listener: (id<SwrvePushInboxDelegate>)listener {
    return;
}

- (void)pushInboxUpdateListener:(id<SwrvePushInboxUpdateDelegate>)listener {
    return;
}

- (void)shutdown {
}

#if TARGET_OS_IOS

- (void)sendDeviceUpdate {
}

- (void)setDeviceToken:(NSData*)deviceToken {
#pragma unused(deviceToken)
}

- (void)processNotificationResponse:(UNNotificationResponse *)response {
#pragma unused(response)
}

- (NSString *)deviceToken {
    return nil;
}

- (BOOL)didReceiveRemoteNotification:(NSDictionary *)userInfo withBackgroundCompletionHandler:(void (^)(UIBackgroundFetchResult, NSDictionary *))completionHandler API_AVAILABLE(ios(12.0)) {
#pragma unused(userInfo, completionHandler)
    return NO;
}

#endif //TARGET_OS_IOS

- (void)handleDeeplink:(NSURL *)url {
   #pragma unused(url)
}

- (void)handleDeferredDeeplink:(NSURL *)url {
    #pragma unused(url)
}

- (void)installAction:(NSURL *)url {
#pragma unused(url)
}

// SwrveCommonDelegate
- (int)eventInternal:(NSString *)eventName payload:(NSDictionary *)eventPayload triggerCallback:(bool)triggerCallback {
#pragma unused(eventName, eventPayload, triggerCallback)
    return SWRVE_SUCCESS;
}

- (BOOL)processPermissionRequest:(NSString *)action {
#pragma unused(action)
    return NO;
}

- (int)queueEvent:(NSString *)eventType data:(NSMutableDictionary *)eventData triggerCallback:(bool)triggerCallback {
#pragma unused(eventType, eventData, triggerCallback)
    return 0;
}

- (NSString *)appVersion {
    return config.appVersion;
}

- (NSSet *)notificationCategories{
    return nil;
}

- (NSString *)appGroupIdentifier {
    return nil;
}

- (void)sendPushNotificationEngagedEvent:(NSString *)pushId withPayload:(NSDictionary *)payload {
#pragma unused(pushId, payload)
}

- (void)handleNotificationToCampaign:(NSString *)campaignId {
#pragma unused(campaignId)
}

- (id<SwrvePermissionsDelegate>)permissionsDelegate {
    return nil;
}

- (id<SwrveNotificationFilterDelegate>)notificationFilterDelegate {
    return nil;
}

- (NSString *)userID {
    return nil;
}

- (void)mergeWithCurrentDeviceInfo:(NSDictionary *)attributes {
    #pragma unused(attributes)
}

- (NSDictionary *)deviceInfo {
    return nil;
}

- (void)identify:(NSString *)externalUserId onSuccess:(void (^)(NSString *status, NSString *swrveUserId))onSuccess
                                              onError:(void (^)(NSInteger httpCode, NSString *errorMessage))onError {
    #pragma unused(externalUserId, onSuccess, onError)
}

- (NSString *)externalUserId {
    return @"";
}

- (double)flushRefreshDelay {
    return 0.0;
}

- (NSInteger)nextEventSequenceNumber {
    return 0;
}

- (NSString *)sessionToken {
    return nil;
}

- (void)fetchNotificationCampaigns:(NSMutableSet *)campaignIds {
#pragma unused (campaignIds)
}

- (void)setSwrveSessionDelegate:(id<SwrveSessionDelegate>)sessionDelegate {
#pragma unused (sessionDelegate)
}

- (void)removeSwrveSessionDelegate:(id<SwrveSessionDelegate>)sessionDelegate {
#pragma unused (sessionDelegate)
}

- (id<NSURLSessionDelegate>)urlSessionDelegate {
    return nil;
}

- (void)start {
}

- (void)startWithUserId:(NSString *)userId {
#pragma unused (userId)
}

- (BOOL)started {
    return false;
}

- (void)stopTracking {
}

#pragma mark Messaging

- (void)embeddedMessageWasShownToUser:(SwrveEmbeddedMessage *)message {
#pragma unused(message)
}

- (void)embeddedButtonWasPressed:(SwrveEmbeddedMessage *)message buttonName:(NSString *)button {
#pragma unused(message, button)
}

- (NSString *)personalizeEmbeddedMessageData:(SwrveEmbeddedMessage *)message withPersonalization:(NSDictionary *)personalizationProperties {
#pragma unused(message, personalizationProperties)
    return nil;
}
- (NSString *)personalizeText:(NSString *)text withPersonalization:(NSDictionary *)personalizationProperties {
#pragma unused(text, personalizationProperties)
    return nil;
}

- (NSArray *)messageCenterCampaigns {
    return @[];
}

- (NSArray *)messageCenterCampaignsWithPersonalization:(NSDictionary *)personalization {
#pragma unused(personalization)
    return @[];
}

- (SwrveCampaign *)messageCenterCampaignWithID:(NSUInteger)campaignID andPersonalization:(NSDictionary *)personalization {
#pragma unused(campaignID, personalization)
    return nil;
}

#if TARGET_OS_IOS /** exclude tvOS **/

- (NSArray <SwrveCampaign *>*)messageCenterCampaignsThatSupportOrientation:(UIInterfaceOrientation)orientation {
#pragma unused(orientation)
    return @[];
}

- (NSArray <SwrveCampaign *>*)messageCenterCampaignsThatSupportOrientation:(UIInterfaceOrientation)orientation withPersonalization:(NSDictionary *)personalization {
#pragma unused(orientation, personalization)
    return @[];
}

- (NSArray<SwrveInAppCampaign *> *)inAppMessageCenterCampaignsWith:(UIInterfaceOrientation)orientation withPersonalization:(NSDictionary *)personalization {
#pragma unused(orientation, personalization)
    return @[];
}

#endif

- (NSArray<SwrveEmbeddedMessage *> *)embeddedMessageCenterCampaigns {
    return @[];
}

- (BOOL)showMessageCenterCampaign:(SwrveCampaign *)campaign {
#pragma unused(campaign)
    return FALSE;
}

- (BOOL)showMessageCenterCampaign:(SwrveCampaign *)campaign withPersonalization:(NSDictionary *)personalization {
#pragma unused(campaign, personalization)
    return FALSE;
}

- (void)removeMessageCenterCampaign:(SwrveCampaign *)campaign {
#pragma unused(campaign)
}

- (void)removeMessageCenterCampaignWithID:(NSUInteger)campaignID {
#pragma unused(campaignID)
}

- (void)markMessageCenterCampaignAsSeen:(SwrveCampaign *)campaign {
#pragma unused(campaign)
}

- (void)markMessageCenterCampaignAsSeenWithID:(NSUInteger)campaignID {
#pragma unused(campaignID)
}

- (void)idfa:(NSString *)idfa {
#pragma unused(idfa)
}

- (void)embeddedControlMessageImpressionEvent:(SwrveEmbeddedMessage *)message {
#pragma unused(message)
}

- (void)dismissMessageWindow {
}

- (void)updateLanguage:(NSString *)language {
    #pragma unused(language)
}

#pragma mark -

@end
