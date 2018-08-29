#if !defined(SWRVE_NO_PUSH)

#import "SwrvePush.h"
#import "SwrveSwizzleHelper.h"
#import "SwrvePermissions.h"
#import "SwrveCampaignInfluence.h"
#import "SwrveNotificationManager.h"
#import "SwrveNotificationConstants.h"

typedef void (*didRegisterForRemoteNotificationsWithDeviceTokenImplSignature)(__strong id, SEL, UIApplication *, NSData *);
typedef void (*didFailToRegisterForRemoteNotificationsWithErrorImplSignature)(__strong id, SEL, UIApplication *, NSError *);
typedef void (*didReceiveRemoteNotificationImplSignature)(__strong id, SEL, UIApplication *, NSDictionary *);

#if !TARGET_OS_TV
static id <SwrvePushDelegate> _pushDelegate = NULL;
static id <SwrveCommonDelegate> _commonDelegate = NULL;
static id <SwrvePushResponseDelegate> _responseDelegate = NULL;
static SwrvePush *pushInstance = NULL;
static bool didSwizzle = false;
static dispatch_once_t sharedInstanceToken = 0;
NSString *const SwrveSilentPushIdentifierKey = @"_sp";
NSString *const SwrveSilentPushPayloadKey = @"_s.SilentPayload";
int const SwrveContentVersion = 1;
NSString *const SwrveContentVersionKey = @"version";
#endif

#pragma mark - interface

@interface SwrvePush () {
    didRegisterForRemoteNotificationsWithDeviceTokenImplSignature didRegisterForRemoteNotificationsWithDeviceTokenImpl;
    didFailToRegisterForRemoteNotificationsWithErrorImplSignature didFailToRegisterForRemoteNotificationsWithErrorImpl;
    didReceiveRemoteNotificationImplSignature didReceiveRemoteNotificationImpl;

    // Apple might call different AppDelegate callbacks that could end up calling the Swrve SDK with the same push payload.
    // This would result in bad engagement reports etc. This var is used to check that the same push id can't be processed in sequence.
    NSString *lastProcessedPushId;
}
@end

#pragma mark - implementation

@implementation SwrvePush

#if !TARGET_OS_TV

+ (SwrvePush *)sharedInstance {
    @synchronized (self) {
        dispatch_once(&sharedInstanceToken, ^{
            pushInstance = [[SwrvePush alloc] init];
        });
        return pushInstance;
    }
}

+ (SwrvePush *)sharedInstanceWithPushDelegate:(id <SwrvePushDelegate>)pushDelegate
                            andCommonDelegate:(id <SwrveCommonDelegate>)commonDelegate {
    @synchronized (self) {
        dispatch_once(&sharedInstanceToken, ^{
            pushInstance = [[SwrvePush alloc] init];
            _pushDelegate = pushDelegate;
            _commonDelegate = commonDelegate;
        });
        return pushInstance;
    }
}

+ (void)resetSharedInstance {
    @synchronized (self) {
        [pushInstance deswizzlePushMethods];
        sharedInstanceToken = 0;
        pushInstance = nil;
        _pushDelegate = nil;
    }
}

#pragma mark - Instances and Delegates

- (void)setPushDelegate:(id <SwrvePushDelegate>)pushDelegate {
    _pushDelegate = pushDelegate;
}

- (void)setCommonDelegate:(id <SwrveCommonDelegate>)commonDelegate {
    _commonDelegate = commonDelegate;
}

- (void)setResponseDelegate:(id <SwrvePushResponseDelegate>)responseDelegate {
    _responseDelegate = responseDelegate;
}


#pragma mark - Registration and Startup Functions

- (void)registerForPushNotifications {
    [SwrvePermissions requestPushNotifications:_commonDelegate withCallback:NO];
}

- (void)setPushNotificationsDeviceToken:(NSData *)newDeviceToken {
    NSCAssert(newDeviceToken, @"The device token cannot be null", nil);
    NSString *newTokenString = [[[newDeviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""];
    [_pushDelegate deviceTokenUpdated:newTokenString];
}

- (void)checkLaunchOptionsForPushData:(NSDictionary *)launchOptions {
    NSDictionary *remoteNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotification) {
        [_pushDelegate remoteNotificationReceived:remoteNotification];
    }
}

#pragma mark - Swizzling Handlers

- (BOOL)observeSwizzling {

    if (!didSwizzle) {
        Class appDelegateClass = [[SwrveCommon sharedUIApplication].delegate class];
        SEL didRegisterSelector = @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
        SEL didFailSelector = @selector(application:didFailToRegisterForRemoteNotificationsWithError:);
        SEL didReceiveSelector = @selector(application:didReceiveRemoteNotification:);

        // Cast to actual method signature
        didRegisterForRemoteNotificationsWithDeviceTokenImpl = (didRegisterForRemoteNotificationsWithDeviceTokenImplSignature) [SwrveSwizzleHelper swizzleMethod:didRegisterSelector inClass:appDelegateClass withImplementationIn:self];
        didFailToRegisterForRemoteNotificationsWithErrorImpl = (didFailToRegisterForRemoteNotificationsWithErrorImplSignature) [SwrveSwizzleHelper swizzleMethod:didFailSelector inClass:appDelegateClass withImplementationIn:self];
        didReceiveRemoteNotificationImpl = (didReceiveRemoteNotificationImplSignature) [SwrveSwizzleHelper swizzleMethod:didReceiveSelector inClass:appDelegateClass withImplementationIn:self];

        didSwizzle = true;
    } else {
        didRegisterForRemoteNotificationsWithDeviceTokenImpl = NULL;
        didFailToRegisterForRemoteNotificationsWithErrorImpl = NULL;
        didReceiveRemoteNotificationImpl = NULL;
    }

    return didSwizzle;
}

- (void)deswizzlePushMethods {

    if (didSwizzle) {
        Class appDelegateClass = [[SwrveCommon sharedUIApplication].delegate class];
        SEL didRegister = @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
        [SwrveSwizzleHelper deswizzleMethod:didRegister inClass:appDelegateClass originalImplementation:(IMP) didRegisterForRemoteNotificationsWithDeviceTokenImpl];
        didRegisterForRemoteNotificationsWithDeviceTokenImpl = NULL;

        SEL didFail = @selector(application:didFailToRegisterForRemoteNotificationsWithError:);
        [SwrveSwizzleHelper deswizzleMethod:didFail inClass:appDelegateClass originalImplementation:(IMP) didFailToRegisterForRemoteNotificationsWithErrorImpl];
        didFailToRegisterForRemoteNotificationsWithErrorImpl = NULL;

        SEL didReceive = @selector(application:didReceiveRemoteNotification:);
        [SwrveSwizzleHelper deswizzleMethod:didReceive inClass:appDelegateClass originalImplementation:(IMP) didReceiveRemoteNotificationImpl];
        didReceiveRemoteNotificationImpl = NULL;

        didSwizzle = false;
    }
}

- (BOOL)didReceiveRemoteNotification:(NSDictionary *)userInfo withBackgroundCompletionHandler:(void (^)(UIBackgroundFetchResult, NSDictionary *))completionHandler {
    // This method can also be called when the app is in the background for normal pushes
    // if the app has background remote notifications enabled
    id silentPushIdentifier = [userInfo objectForKey:SwrveSilentPushIdentifierKey];
    if (silentPushIdentifier && ![silentPushIdentifier isKindOfClass:[NSNull class]]) {
        [self silentPushReceived:userInfo withCompletionHandler:completionHandler];
        // Customer should handle the payload in the completionHandler
        return YES;
    } else {
        id pushIdentifier = [userInfo objectForKey:SwrveNotificationIdentifierKey];
        if (pushIdentifier && ![pushIdentifier isKindOfClass:[NSNull class]]) {
            NSURL *deeplinkUrl = [SwrveNotificationManager notificationEngaged:userInfo];
            if (deeplinkUrl) {
                [_pushDelegate deeplinkReceived:deeplinkUrl];
            }
            // We won't call the completionHandler and the customer should handle it themselves
            return NO;
        }
    }
    return NO;
}

#pragma mark - Service Extension Modification (public facing)

+ (void)handleNotificationContent:(UNNotificationContent *)notificationContent
           withAppGroupIdentifier:(NSString *)appGroupIdentifier
     withCompletedContentCallback:(void (^)(UNMutableNotificationContent *content))callback {

    /** Check the push version number **/
    NSDictionary *sw = [notificationContent.userInfo objectForKey:SwrveNotificationContentIdentifierKey];
    int contentVersion = [(NSNumber *) [sw objectForKey:SwrveContentVersionKey] intValue];
    sw = nil; // set pointer to nil so the OS can clean it up. This is done because Service Extensions have a low memory ceiling
    if (contentVersion > SwrveContentVersion) {
        DebugLog(@"Could not process notification because version is incompatible", nil);
        callback([notificationContent mutableCopy]);
        return;
    }

    /** Process push identifier for influenceData **/
    id pushIdentifier = notificationContent.userInfo[SwrveNotificationIdentifierKey];
    if (pushIdentifier && ![pushIdentifier isKindOfClass:[NSNull class]]) {
        NSString *pushId = @"-1";
        if ([pushIdentifier isKindOfClass:[NSString class]]) {
            pushId = (NSString *) pushIdentifier;
        } else if ([pushIdentifier isKindOfClass:[NSNumber class]]) {
            pushId = [((NSNumber *) pushIdentifier) stringValue];
        } else {
            DebugLog(@"Unknown Swrve notification ID class for _p attribute", nil);
            callback([notificationContent mutableCopy]);
            return;
        }
        DebugLog(@"Got Swrve Notification with id:%@", pushId);
        [SwrveCampaignInfluence saveInfluencedData:notificationContent.userInfo withId:pushId withAppGroupID:appGroupIdentifier atDate:[NSDate date]];
    } else {
        DebugLog(@"Got unidentified notification", nil);
        callback([notificationContent mutableCopy]);
        return;
    }

    /** Set Rich Media Content **/
    [SwrveNotificationManager handleContent:notificationContent withCompletionCallback:^(UNMutableNotificationContent *content) {
        if (content) {
            callback(content);
        } else {
            DebugLog(@"Push Content did not load correctly");
            callback([notificationContent mutableCopy]);
        }
    }];
}

#pragma mark - UNUserNotificationCenterDelegate Functions

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
#pragma unused(center)

    if (_responseDelegate) {
        if ([_responseDelegate respondsToSelector:@selector(willPresentNotification:withCompletionHandler:)]) {
            [_responseDelegate willPresentNotification:notification withCompletionHandler:completionHandler];
        } else {
            // if there is no willPresentNotification implemented as part of the delegate
            if (completionHandler) {
                completionHandler(UNNotificationPresentationOptionNone);
            }
        }
    } else {
        if (completionHandler) {
            completionHandler(UNNotificationPresentationOptionNone);
        }
    }
}

#ifdef __IPHONE_11_0

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
#else
    - (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)())completionHandler {
#endif
#pragma unused(center)

    NSURL *deeplinkUrl = [SwrveNotificationManager notificationResponseReceived:response.actionIdentifier withUserInfo:response.notification.request.content.userInfo];
    if (deeplinkUrl) {
        [_pushDelegate deeplinkReceived:deeplinkUrl];
    }

    if (_responseDelegate) {
        if ([_responseDelegate respondsToSelector:@selector(didReceiveNotificationResponse:withCompletionHandler:)]) {
            [_responseDelegate didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
        } else {
            // if there is no didReceiveNotificationResponse implemented as part of the delegate
            if (completionHandler) {
                completionHandler();
            }
        }
    } else {
        if (completionHandler) {
            completionHandler();
        }
    }
}

#pragma mark - silent push

- (void)silentPushReceived:(NSDictionary *)userInfo withCompletionHandler:(void (^)(UIBackgroundFetchResult, NSDictionary *))completionHandler {
    id pushIdentifier = [userInfo objectForKey:SwrveSilentPushIdentifierKey];
    if (pushIdentifier && ![pushIdentifier isKindOfClass:[NSNull class]]) {
        NSString *pushId = @"-1";
        if ([pushIdentifier isKindOfClass:[NSString class]]) {
            pushId = (NSString *) pushIdentifier;
        } else if ([pushIdentifier isKindOfClass:[NSNumber class]]) {
            pushId = [((NSNumber *) pushIdentifier) stringValue];
        } else {
            DebugLog(@"Unknown Swrve notification ID class for _sp attribute", nil);
            return;
        }

        // Only process this push if we haven't seen it before or its a QA push
        if (lastProcessedPushId == nil || [pushId isEqualToString:@"0"] || ![pushId isEqualToString:lastProcessedPushId]) {
            lastProcessedPushId = pushId;

            [SwrveCampaignInfluence saveInfluencedData:userInfo withId:pushId withAppGroupID:nil atDate:[self getNow]];

            if (completionHandler != nil) {
                // The SDK currently does no fetch operation on its own but will in future releases

                // Obtain the silent push payload and call the customers code
                @try {
                    id silentPayloadRaw = [userInfo objectForKey:SwrveSilentPushPayloadKey];
                    if (silentPayloadRaw != nil && [silentPayloadRaw isKindOfClass:[NSDictionary class]]) {
                        completionHandler(UIBackgroundFetchResultNoData, (NSDictionary *) silentPayloadRaw);
                    } else {
                        completionHandler(UIBackgroundFetchResultNoData, nil);
                    }
                } @catch (NSException *exception) {
                    DebugLog(@"Could not execute the silent push listener: %@", exception.reason);
                }
            }
            DebugLog(@"Got Swrve silent notification with ID %@", pushId);
        } else {
            DebugLog(@"Got Swrve notification with ID %@, ignoring as we already processed it", pushId);
        }
    } else {
        DebugLog(@"Got unidentified notification", nil);
    }
}

- (void)processInfluenceData {
    [SwrveCampaignInfluence processInfluenceDataWithDate:[self getNow]];
}

- (NSDate *)getNow {
    return [NSDate date];
}

#pragma mark - UIApplication Functions

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    if (_commonDelegate == NULL) {
        DebugLog(@"Error: Auto device token collection only works if you are using the Swrve instance singleton.", nil);
    } else {
        if (_pushDelegate) {
            [_pushDelegate deviceTokenIncoming:newDeviceToken];
        }
        if (pushInstance->didRegisterForRemoteNotificationsWithDeviceTokenImpl != NULL) {
            id target = [SwrveCommon sharedUIApplication].delegate;
            pushInstance->didRegisterForRemoteNotificationsWithDeviceTokenImpl(target, @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:), application, newDeviceToken);
        }
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {

    if (_commonDelegate == NULL) {
        DebugLog(@"Error: Auto device token collection only works if you are using the Swrve instance singleton.", nil);
    } else {
        DebugLog(@"Could not auto collected device token.", nil);

        if (pushInstance->didFailToRegisterForRemoteNotificationsWithErrorImpl != NULL) {
            id target = [SwrveCommon sharedUIApplication].delegate;
            pushInstance->didFailToRegisterForRemoteNotificationsWithErrorImpl(target, @selector(application:didFailToRegisterForRemoteNotificationsWithError:), application, error);
        }
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {

    if (_commonDelegate == NULL) {
        DebugLog(@"Error: Push notification can only be automatically reported if you are using the Swrve instance singleton.", nil);
    } else {
        if (_pushDelegate) {
            [_pushDelegate remoteNotificationReceived:userInfo];
        }
        if (pushInstance->didReceiveRemoteNotificationImpl != NULL) {
            id target = [SwrveCommon sharedUIApplication].delegate;
            pushInstance->didReceiveRemoteNotificationImpl(target, @selector(application:didReceiveRemoteNotification:), application, userInfo);
        }
    }
}

#endif //!TARGET_OS_TV
@end

#endif
