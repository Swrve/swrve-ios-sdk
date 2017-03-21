#import "SwrveEmpty.h"
#if COCOAPODS
#import <SwrveSDKCommon/SwrveCommon.h>
#else
#import "SwrveCommon.h"
#endif

// Used at runtime when the platform is not supported.
@implementation SwrveEmpty {
    SwrveResourceManager* resourceManager;
}

@synthesize config;
@synthesize appID;
@synthesize apiKey;
@synthesize userID;
@synthesize deviceInfo;
@synthesize talk;
@synthesize resourceManager;
@synthesize deviceToken;
@synthesize locationSegmentVersion;

-(id) initWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey {
    if (self = [super init]) {
        [self setup:swrveAppID apiKey:swrveAPIKey userID:nil config:nil];
    }
    return self;
}

-(id) initWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey config:(SwrveConfig*)swrveConfig {
    if (self = [super init]) {
        [self setup:swrveAppID apiKey:swrveAPIKey userID:nil config:swrveConfig];
    }
    return self;
}


-(id) initWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey launchOptions:(NSDictionary*)launchOptions {
#pragma unused(launchOptions)
    if (self = [super init]) {
        [self setup:swrveAppID apiKey:swrveAPIKey userID:nil config:nil];
    }
    return self;
}

-(id) initWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey config:(SwrveConfig*)swrveConfig launchOptions:(NSDictionary*)launchOptions {
#pragma unused(launchOptions)
    if (self = [super init]) {
        [self setup:swrveAppID apiKey:swrveAPIKey userID:nil config:swrveConfig];
    }
    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
-(id) initWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey userID:(NSString*)swrveUserID {
    if (self = [super init]) {
        [self setup:swrveAppID apiKey:swrveAPIKey userID:swrveUserID config:nil];
    }
    return self;
}

-(id) initWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey userID:(NSString*)swrveUserID config:(SwrveConfig*)swrveConfig {
    if (self = [super init]) {
        [self setup:swrveAppID apiKey:swrveAPIKey userID:swrveUserID config:swrveConfig];
    }
    return self;
}
#pragma clang diagnostic pop

-(void) setup:(int)swrveAppID apiKey:(NSString*)swrveAPIKey userID:(NSString*)swrveUserID config:(SwrveConfig*)swrveConfig {
    appID = swrveAppID;
    apiKey = swrveAPIKey;
    userID = swrveUserID;
    if (swrveConfig) {
        if (!userID) {
            userID = config.userId;
        }
    } else {
        swrveConfig = [[SwrveConfig alloc] init];
    }
    config = [[ImmutableSwrveConfig alloc] initWithSwrveConfig:swrveConfig];
    resourceManager = [[SwrveResourceManager alloc] init];
    deviceInfo = [[NSDictionary alloc] init];
    if (config.talkEnabled) {
        talk = [[SwrveMessageController alloc] initWithSwrve:nil];
    }
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

-(SwrveResourceManager*) getSwrveResourceManager {
    return resourceManager;
}

-(void) getUserResources:(SwrveUserResourcesCallback)callbackBlock {
#pragma unused(callbackBlock)
}

-(void) getUserResourcesDiff:(SwrveUserResourcesDiffCallback)callbackBlock {
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
-(void) sendPushEngagedEvent:(NSString*)pushId {
#pragma unused(pushId)
}
#endif //!defined(SWRVE_NO_PUSH)


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
-(BOOL) appInBackground {
    return NO;
}
#pragma clang diagnostic pop

- (SwrveSignatureProtectedFile *)getLocationCampaignFile {
    return nil;
}

// SwrveCommonDelegate
-(NSData*) getCampaignData:(int)category {
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

@end
