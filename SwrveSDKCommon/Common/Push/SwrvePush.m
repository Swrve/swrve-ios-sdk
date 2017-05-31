#if !defined(SWRVE_NO_PUSH)
#import "SwrvePush.h"
#import "SwrvePushConstants.h"
#import "SwrveSwizzleHelper.h"
#import "SwrvePermissions.h"

typedef void (*didRegisterForRemoteNotificationsWithDeviceTokenImplSignature)(__strong id,SEL,UIApplication *, NSData*);
typedef void (*didFailToRegisterForRemoteNotificationsWithErrorImplSignature)(__strong id,SEL,UIApplication *, NSError*);
typedef void (*didReceiveRemoteNotificationImplSignature)(__strong id,SEL,UIApplication *, NSDictionary*);

static id <SwrvePushDelegate> _pushDelegate = NULL;
static id <SwrveCommonDelegate> _commonDelegate = NULL;
static SwrvePush *pushInstance = NULL;
static bool didSwizzle = false;
static dispatch_once_t sharedInstanceToken = 0;

#pragma mark - interface

@interface SwrvePush() {
    NSString* lastProcessedPushId;
    didRegisterForRemoteNotificationsWithDeviceTokenImplSignature didRegisterForRemoteNotificationsWithDeviceTokenImpl;
    didFailToRegisterForRemoteNotificationsWithErrorImplSignature didFailToRegisterForRemoteNotificationsWithErrorImpl;
    didReceiveRemoteNotificationImplSignature didReceiveRemoteNotificationImpl;
}
@end

#pragma mark - implementation

@implementation SwrvePush

+ (SwrvePush*) sharedInstance {
    @synchronized(self) {
        dispatch_once(&sharedInstanceToken, ^{
            pushInstance = [[SwrvePush alloc] init];
        });
        return pushInstance;
    }
}

+ (SwrvePush*) sharedInstanceWithPushDelegate:(id<SwrvePushDelegate>) pushDelegate andCommonDelegate:(id<SwrveCommonDelegate>) commonDelegate {
    @synchronized(self) {
        dispatch_once(&sharedInstanceToken, ^{
            pushInstance = [[SwrvePush alloc] init];
            _pushDelegate = pushDelegate;
            _commonDelegate = commonDelegate;
        });
        return pushInstance;
    }
}

+ (void) resetSharedInstance {
    @synchronized(self) {
        [pushInstance deswizzlePushMethods];
        sharedInstanceToken = 0;
        pushInstance = nil;
        _pushDelegate = nil;
    }
}

#pragma mark - Instances and Delegates

- (void) setPushDelegate:(id<SwrvePushDelegate>)pushDelegate {
    _pushDelegate = pushDelegate;
}


- (void) setCommonDelegate:(id<SwrveCommonDelegate>)commonDelegate {
    _commonDelegate = commonDelegate;
}

#pragma mark - Registration and Startup Functions

- (void) registerForPushNotifications {
    [SwrvePermissions requestPushNotifications:_commonDelegate withCallback:NO];
}

- (void) setPushNotificationsDeviceToken:(NSData*) newDeviceToken {
    NSCAssert(newDeviceToken, @"The device token cannot be null", nil);
    NSString* newTokenString = [[[newDeviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""];
    [_pushDelegate deviceTokenUpdated:newTokenString];
}

- (void) checkLaunchOptionsForPushData:(NSDictionary *) launchOptions {
    NSDictionary * remoteNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotification) {
        [_pushDelegate remoteNotificationReceived:remoteNotification];
    }
}

#pragma mark - Swizzling Handlers

- (BOOL) observeSwizzling {

    if(!didSwizzle){
        Class appDelegateClass = [[UIApplication sharedApplication].delegate class];

        SEL didRegisterSelector = @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
        SEL didFailSelector = @selector(application:didFailToRegisterForRemoteNotificationsWithError:);
        SEL didReceiveSelector = @selector(application:didReceiveRemoteNotification:);

        // Cast to actual method signature
        didRegisterForRemoteNotificationsWithDeviceTokenImpl = (didRegisterForRemoteNotificationsWithDeviceTokenImplSignature)[SwrveSwizzleHelper swizzleMethod:didRegisterSelector inClass:appDelegateClass withImplementationIn:self];
        didFailToRegisterForRemoteNotificationsWithErrorImpl = (didFailToRegisterForRemoteNotificationsWithErrorImplSignature)[SwrveSwizzleHelper swizzleMethod:didFailSelector inClass:appDelegateClass withImplementationIn:self];
        didReceiveRemoteNotificationImpl = (didReceiveRemoteNotificationImplSignature)[SwrveSwizzleHelper swizzleMethod:didReceiveSelector inClass:appDelegateClass withImplementationIn:self];

        didSwizzle = true;
    } else {
        didRegisterForRemoteNotificationsWithDeviceTokenImpl = NULL;
        didFailToRegisterForRemoteNotificationsWithErrorImpl = NULL;
        didReceiveRemoteNotificationImpl = NULL;
    }

    return didSwizzle;
}

- (void) deswizzlePushMethods {

    if(didSwizzle) {
        Class appDelegateClass = [[UIApplication sharedApplication].delegate class];

        SEL didRegister = @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
        [SwrveSwizzleHelper deswizzleMethod:didRegister inClass:appDelegateClass originalImplementation:(IMP)didRegisterForRemoteNotificationsWithDeviceTokenImpl];
        didRegisterForRemoteNotificationsWithDeviceTokenImpl = NULL;

        SEL didFail = @selector(application:didFailToRegisterForRemoteNotificationsWithError:);
        [SwrveSwizzleHelper deswizzleMethod:didFail inClass:appDelegateClass originalImplementation:(IMP)didFailToRegisterForRemoteNotificationsWithErrorImpl];
        didFailToRegisterForRemoteNotificationsWithErrorImpl = NULL;

        SEL didReceive = @selector(application:didReceiveRemoteNotification:);
        [SwrveSwizzleHelper deswizzleMethod:didReceive inClass:appDelegateClass originalImplementation:(IMP)didReceiveRemoteNotificationImpl];
        didReceiveRemoteNotificationImpl = NULL;

        didSwizzle = false;
    }
}

#pragma mark - Event Handling

- (void) pushNotificationReceived:(NSDictionary *)userInfo {

    // Try to get the identifier (_p)
    id pushIdentifier = [userInfo objectForKey:SwrvePushIdentifierKey];
    if (pushIdentifier && ![pushIdentifier isKindOfClass:[NSNull class]]) {
        NSString* pushId = @"-1";
        if ([pushIdentifier isKindOfClass:[NSString class]]) {
            pushId = (NSString*)pushIdentifier;
        }
        else if ([pushIdentifier isKindOfClass:[NSNumber class]]) {
            pushId = [((NSNumber*)pushIdentifier) stringValue];
        }
        else {
            DebugLog(@"Unknown Swrve notification ID class for _p attribute", nil);
            return;
        }

        // Only process this push if we haven't seen it before
        if (lastProcessedPushId == nil || ![pushId isEqualToString:lastProcessedPushId]) {
            lastProcessedPushId = pushId;

            // Process deeplink _sd (and old _d)
            id pushDeeplinkRaw = [userInfo objectForKey:SwrvePushDeeplinkKey];
            if (pushDeeplinkRaw == nil || ![pushDeeplinkRaw isKindOfClass:[NSString class]]) {
                // Retrieve old push deeplink for backwards compatibility
                pushDeeplinkRaw = [userInfo objectForKey:SwrvePushDeprecatedDeeplinkKey];
            }
            if ([pushDeeplinkRaw isKindOfClass:[NSString class]]) {
                NSString* pushDeeplink = (NSString*)pushDeeplinkRaw;
                NSURL* url = [NSURL URLWithString:pushDeeplink];
                BOOL canOpen = [[UIApplication sharedApplication] canOpenURL:url];
                if( url != nil && canOpen ) {
                    DebugLog(@"Action - %@ - handled.  Sending to application as URL", pushDeeplink);
                    [[UIApplication sharedApplication] openURL:url];

                } else {
                    DebugLog(@"Could not process push deeplink - %@", pushDeeplink);
                }
            }

            [_pushDelegate sendPushEngagedEvent:pushId];
            DebugLog(@"Got Swrve notification with ID %@", pushId);
        } else {
            DebugLog(@"Got Swrve notification with ID %@ but it was already processed", pushId);
        }
    } else {
        DebugLog(@"Got unidentified notification", nil);
    }
}

- (void) silentPushReceived:(NSDictionary*)userInfo withCompletionHandler:(void (^)(UIBackgroundFetchResult, NSDictionary*))completionHandler {
    id pushIdentifier = [userInfo objectForKey:SwrveSilentPushIdentifierKey];
    if (pushIdentifier && ![pushIdentifier isKindOfClass:[NSNull class]]) {
        NSString* pushId = @"-1";
        if ([pushIdentifier isKindOfClass:[NSString class]]) {
            pushId = (NSString*)pushIdentifier;
        }
        else if ([pushIdentifier isKindOfClass:[NSNumber class]]) {
            pushId = [((NSNumber*)pushIdentifier) stringValue];
        }
        else {
            DebugLog(@"Unknown Swrve notification ID class for _sp attribute", nil);
            return;
        }
        [SwrvePush saveInfluencedData:userInfo withPushId:pushId atDate:[self getNow]];

        DebugLog(@"Got Swrve silent notification with ID %@", pushId);
    } else {
        DebugLog(@"Got unidentified notification", nil);
    }

    if (completionHandler != nil) {
        // The SDK currently does no fetch operation on its own but will in future releases

        // Obtain the silent push payload and call the customers code
        @try {
            id silentPayloadRaw = [userInfo objectForKey:SwrveSilentPushPayloadKey];
            if (silentPayloadRaw != nil && [silentPayloadRaw isKindOfClass:[NSDictionary class]]) {
                completionHandler(UIBackgroundFetchResultNoData, (NSDictionary*)silentPayloadRaw);
            } else {
                completionHandler(UIBackgroundFetchResultNoData, nil);
            }
        } @catch (NSException* exception) {
            DebugLog(@"Could not execute the silent push listener: %@", exception.reason);
        }
    }
}

+ (void) saveInfluencedData:(NSDictionary*)userInfo withPushId:(NSString*)pushId atDate:(NSDate*)date {
    // Check if the push requires influence tracking
    id influencedWindowMinsRaw = [userInfo objectForKey:SwrveInfluencedWindowMinsKey];
    if (influencedWindowMinsRaw && ![influencedWindowMinsRaw isKindOfClass:[NSNull class]]) {
        int influenceWindowMins = 720;
        if ([influencedWindowMinsRaw isKindOfClass:[NSString class]]) {
            influenceWindowMins = [influencedWindowMinsRaw intValue];
        }
        else if ([influencedWindowMinsRaw isKindOfClass:[NSNumber class]]) {
            influenceWindowMins = [((NSNumber*)influencedWindowMinsRaw) intValue];
        }

        long maxWindowTimeSeconds = (long)[[date dateByAddingTimeInterval:influenceWindowMins*60] timeIntervalSince1970];
        // Save influence data
        NSMutableDictionary* influencedData = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:SwrveInfluenceDataKey] mutableCopy];
        if (influencedData == nil) {
            influencedData = [[NSMutableDictionary alloc] init];
        }

        [influencedData setValue:[NSNumber numberWithLong:maxWindowTimeSeconds] forKey:pushId];
        [[NSUserDefaults standardUserDefaults] setObject:influencedData forKey:SwrveInfluenceDataKey];
    }
}

- (void) processInfluenceData {
    NSDictionary* influencedData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:SwrveInfluenceDataKey];
    if (influencedData != nil) {
        double nowSeconds = [[self getNow] timeIntervalSince1970];
        for (NSString* trackingId in influencedData) {
            id maxInfluenceWindow = [influencedData objectForKey:trackingId];
            if ([maxInfluenceWindow isKindOfClass:[NSNumber class]]) {
                long maxWindowTimeSeconds = [(NSNumber*)maxInfluenceWindow longValue];

                if (maxWindowTimeSeconds > 0 && maxWindowTimeSeconds >= nowSeconds) {
                    // Send an influenced event for this tracking id
                    if (_commonDelegate != nil) {
                        NSInteger trackingIdLong = [trackingId integerValue];
                        NSMutableDictionary* influencedEvent = [[NSMutableDictionary alloc] init];
                        [influencedEvent setValue:[NSNumber numberWithLong:trackingIdLong] forKey:@"id"];
                        [influencedEvent setValue:@"push" forKey:@"campaignType"];
                        [influencedEvent setValue:@"influenced" forKey:@"actionType"];
                        NSMutableDictionary* eventPayload = [[NSMutableDictionary alloc] init];
                        [eventPayload setValue:[NSString stringWithFormat:@"%i", (int)((maxWindowTimeSeconds - nowSeconds)/60)] forKey:@"delta"];
                        [influencedEvent setValue:eventPayload forKey:@"payload"];

                        [_commonDelegate queueEvent:@"generic_campaign_event" data:influencedEvent triggerCallback:NO];
                    } else {
                        DebugLog(@"Could not find a shared instance to send the silent push influence data");
                    }
                }
            }
        }
        // Clear influence data
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:SwrveInfluenceDataKey];
    }
}

- (NSDate*)getNow
{
    return [NSDate date];
}

#pragma mark - UIApplication Functions

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    if( _commonDelegate == NULL) {
        DebugLog(@"Error: Auto device token collection only works if you are using the Swrve instance singleton.", nil);
    } else {

        if(_pushDelegate){
            [_pushDelegate deviceTokenIncoming:newDeviceToken];
        }

        if(pushInstance->didRegisterForRemoteNotificationsWithDeviceTokenImpl != NULL) {
            id target = [UIApplication sharedApplication].delegate;
            pushInstance->didRegisterForRemoteNotificationsWithDeviceTokenImpl(target, @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:), application, newDeviceToken);
        }
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {

    if( _commonDelegate == NULL) {
        DebugLog(@"Error: Auto device token collection only works if you are using the Swrve instance singleton.", nil);
    } else {
        DebugLog(@"Could not auto collected device token.", nil);

        if( pushInstance->didFailToRegisterForRemoteNotificationsWithErrorImpl != NULL ) {
            id target = [UIApplication sharedApplication].delegate;
            pushInstance->didFailToRegisterForRemoteNotificationsWithErrorImpl(target, @selector(application:didFailToRegisterForRemoteNotificationsWithError:), application, error);
        }
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {

    if( _commonDelegate == NULL) {
        DebugLog(@"Error: Push notification can only be automatically reported if you are using the Swrve instance singleton.", nil);
    } else {

        if(_pushDelegate) {
            [_pushDelegate remoteNotificationReceived:userInfo];
        }

        if( pushInstance->didReceiveRemoteNotificationImpl != NULL ) {
            id target = [UIApplication sharedApplication].delegate;
            pushInstance->didReceiveRemoteNotificationImpl(target, @selector(application:didReceiveRemoteNotification:), application, userInfo);
        }
    }
}

@end

#endif
