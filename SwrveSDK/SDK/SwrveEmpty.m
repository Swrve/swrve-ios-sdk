#import "SwrveEmpty.h"
#import "SwrveMessageController+Private.h"
#if __has_include(<SwrveSDKCommon/SwrveCommon.h>)
#import <SwrveSDKCommon/SwrveCommon.h>
#else
#import "SwrveCommon.h"
#endif

@interface SwrveEmpty() <SwrveCommonDelegate>
@end

// Used at runtime when the platform is not supported.
@implementation SwrveEmpty {
    SwrveResourceManager* resourceManager;
}

@synthesize config;
@synthesize appID;
@synthesize apiKey;
@synthesize userID;
@synthesize deviceInfo;
@synthesize messaging;
@synthesize resourceManager;
@synthesize deviceToken;
@synthesize locationSegmentVersion;

-(id) initWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey {
    if (self = [super init]) {
        [self setup:swrveAppID apiKey:swrveAPIKey config:nil];
    }
    return self;
}

-(id) initWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey config:(SwrveConfig*)swrveConfig {
    if (self = [super init]) {
        [self setup:swrveAppID apiKey:swrveAPIKey config:swrveConfig];
    }
    return self;
}


-(id) initWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey launchOptions:(NSDictionary*)launchOptions {
#pragma unused(launchOptions)
    if (self = [super init]) {
        [self setup:swrveAppID apiKey:swrveAPIKey config:nil];
    }
    return self;
}

-(id) initWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey config:(SwrveConfig*)swrveConfig launchOptions:(NSDictionary*)launchOptions {
#pragma unused(launchOptions)
    if (self = [super init]) {
        [self setup:swrveAppID apiKey:swrveAPIKey config:swrveConfig];
    }
    return self;
}

-(void) setup:(int)swrveAppID apiKey:(NSString*)swrveAPIKey config:(SwrveConfig*)swrveConfig {
    appID = swrveAppID;
    apiKey = swrveAPIKey;
    if (swrveConfig == nil) {
        swrveConfig = [[SwrveConfig alloc] init];
    }
    config = [[ImmutableSwrveConfig alloc] initWithMutableConfig:swrveConfig];
    resourceManager = [[SwrveResourceManager alloc] init];
    deviceInfo = [[NSDictionary alloc] init];

    messaging = [[SwrveMessageController alloc] initWithSwrve:nil];

    [SwrveCommon addSharedInstance:self];
}

-(NSString*) swrveSDKVersion {
    return @SWRVE_SDK_VERSION;
}

-(int) purchaseItem:(NSString*)itemName currency:(NSString*)itemCurrency cost:(int)itemCost quantity:(int)itemQuantity {
#pragma unused(itemName, itemCurrency, itemCost, itemQuantity)
    return SWRVE_SUCCESS;
}

-(int) iap:(SKPaymentTransaction*) transaction product:(SKProduct*) product {
#pragma unused(transaction, product)
    return SWRVE_SUCCESS;
}

-(int) iap:(SKPaymentTransaction*) transaction product:(SKProduct*) product rewards:(SwrveIAPRewards*)rewards {
#pragma unused(transaction, product, rewards)
    return SWRVE_SUCCESS;
}

-(int) unvalidatedIap:(SwrveIAPRewards*)rewards localCost:(double)localCost localCurrency:(NSString*)localCurrency productId:(NSString*)productId productIdQuantity:(int)productIdQuantity
{
#pragma unused(rewards, localCost, localCurrency, productId, productIdQuantity)
    return SWRVE_SUCCESS;
}

-(int) event:(NSString*)eventName {
#pragma unused(eventName)
    return SWRVE_SUCCESS;
}

-(int) event:(NSString*)eventName payload:(NSDictionary*)eventPayload {
#pragma unused(eventName, eventPayload)
    return SWRVE_SUCCESS;
}

-(int) currencyGiven:(NSString*)givenCurrency givenAmount:(double)givenAmount {
#pragma unused(givenCurrency, givenAmount)
    return SWRVE_SUCCESS;
}

-(int) userUpdate:(NSDictionary*)attributes {
#pragma unused(attributes)
    return SWRVE_SUCCESS;
}

- (int) userUpdate:(NSString *)name withDate:(NSDate *) date {
#pragma unused(name, date)
    return SWRVE_SUCCESS;
}

-(void) refreshCampaignsAndResources {
}

-(SwrveResourceManager*) resourceManager {
    return self->resourceManager;
}

-(void) userResources:(SwrveUserResourcesCallback)callbackBlock {
#pragma unused(callbackBlock)
}

-(void) userResourcesDiff:(SwrveUserResourcesDiffCallback)callbackBlock {
#pragma unused(callbackBlock)
}

-(void) sendQueuedEvents {
}

-(void) saveEventsToDisk {
}

-(void) setEventQueuedCallback:(SwrveEventQueuedCallback)callbackBlock {
#pragma unused(callbackBlock)
}

-(int) eventWithNoCallback:(NSString*)eventName payload:(NSDictionary*)eventPayload {
#pragma unused(eventName, eventPayload)
    return SWRVE_SUCCESS;
}

-(void) shutdown {
}


#if !defined(SWRVE_NO_PUSH)
- (void) setDeviceToken:(NSData*)deviceToken
{
#pragma unused(deviceToken)
}

- (void) processNotificationResponse:(UNNotificationResponse *)response {
#pragma unused(response)
}

- (void) processNotificationResponseWithIdentifier:(NSString *)identifier andUserInfo:(NSDictionary *)userInfo {
#pragma unused(identifier)
#pragma unused(userInfo)
}

- (NSString*) deviceToken
{
    return nil;
}

- (void) pushNotificationReceived:(NSDictionary*)userInfo
{
#pragma unused(userInfo)
}

- (BOOL)didReceiveRemoteNotification:(NSDictionary *)userInfo withBackgroundCompletionHandler:(void (^)(UIBackgroundFetchResult, NSDictionary*))completionHandler
{
#pragma unused(userInfo, completionHandler)
    return NO;
}

-(void) sendPushEngagedEvent:(NSString*)pushId {
#pragma unused(pushId)
}



#endif //!defined(SWRVE_NO_PUSH)

// SwrveCommonDelegate
-(NSData*) campaignData:(int)category {
#pragma unused(category)
    return nil;
}

-(int) eventInternal:(NSString*)eventName payload:(NSDictionary*)eventPayload triggerCallback:(bool)triggerCallback {
#pragma unused(eventName, eventPayload, triggerCallback)
    return SWRVE_SUCCESS;
}

-(BOOL) processPermissionRequest:(NSString*)action {
#pragma unused(action)
    return NO;
}

- (void) queueEvent:(NSString*)eventType data:(NSMutableDictionary*)eventData triggerCallback:(bool)triggerCallback {
#pragma unused(eventType, eventData, triggerCallback)
}

-(NSString*) appVersion {
    return config.appVersion;
}

-(NSSet*) pushCategories {
    return nil;
}

-(NSSet*) notificationCategories{
    return nil;
}

-(NSString*) appGroupIdentifier {
    return nil;
}

@end
