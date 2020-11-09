#if !defined(SWRVE_NO_PUSH)

#import "SwrvePush.h"
#import "SwrveSwizzleHelper.h"
#import "SwrveCampaignInfluence.h"
#import "SwrveNotificationManager.h"
#import "SwrveNotificationConstants.h"
#import "SwrvePermissions.h"
#import "SwrveLocalStorage.h"
#import "SwrveCampaignDelivery.h"
#import "SwrveQA.h"

typedef void (*didRegisterForRemoteNotificationsWithDeviceTokenImplSignature)(__strong id, SEL, UIApplication *, NSData *);

typedef void (*didFailToRegisterForRemoteNotificationsWithErrorImplSignature)(__strong id, SEL, UIApplication *, NSError *);

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

- (void)registerForPushNotifications:(BOOL)provisional {
    [SwrvePermissions requestPushNotifications:_commonDelegate provisional:provisional];
}

- (void)setPushNotificationsDeviceToken:(NSData *)newDeviceToken {
    NSCAssert(newDeviceToken, @"The device token cannot be null", nil);
    NSString *newTokenString = [self deviceTokenString:newDeviceToken];
    [_pushDelegate deviceTokenUpdated:newTokenString];
}

- (NSString *)deviceTokenString:(NSData *)deviceTokenData {
    const unsigned char *bytes = (const unsigned char *)deviceTokenData.bytes;
    NSMutableString *deviceTokenString = [NSMutableString string];
    for (NSUInteger i = 0; i < [deviceTokenData length]; i++) {
        [deviceTokenString appendFormat:@"%02.2hhX", bytes[i]];
    }
    return [[deviceTokenString copy] lowercaseString];
}

#pragma mark - Swizzling Handlers

- (BOOL)observeSwizzling {

    if (!didSwizzle) {
        Class appDelegateClass = [[SwrveCommon sharedUIApplication].delegate class];
        SEL didRegisterSelector = @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
        SEL didFailSelector = @selector(application:didFailToRegisterForRemoteNotificationsWithError:);

        // Cast to actual method signature
        didRegisterForRemoteNotificationsWithDeviceTokenImpl = (didRegisterForRemoteNotificationsWithDeviceTokenImplSignature) [SwrveSwizzleHelper swizzleMethod:didRegisterSelector inClass:appDelegateClass withImplementationIn:self];
        didFailToRegisterForRemoteNotificationsWithErrorImpl = (didFailToRegisterForRemoteNotificationsWithErrorImplSignature) [SwrveSwizzleHelper swizzleMethod:didFailSelector inClass:appDelegateClass withImplementationIn:self];

        didSwizzle = true;
    } else {
        didRegisterForRemoteNotificationsWithDeviceTokenImpl = NULL;
        didFailToRegisterForRemoteNotificationsWithErrorImpl = NULL;
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

        didSwizzle = false;
    }
}

- (BOOL)didReceiveRemoteNotification:(NSDictionary *)userInfo withBackgroundCompletionHandler:(void (^)(UIBackgroundFetchResult, NSDictionary *))completionHandler API_AVAILABLE(ios(7.0)) {
    return [self didReceiveRemoteNotification:userInfo withBackgroundCompletionHandler:completionHandler withLocalUserId:[SwrveLocalStorage swrveUserId]];
}

- (BOOL)didReceiveRemoteNotification:(NSDictionary *)userInfo withBackgroundCompletionHandler:(void (^)(UIBackgroundFetchResult, NSDictionary *))completionHandler withLocalUserId:(NSString *) localUserId API_AVAILABLE(ios(7.0)) {
    NSString *appGroupIdentifier = nil;
    if (_commonDelegate != NULL) {
        appGroupIdentifier = _commonDelegate.appGroupIdentifier;
    }
    id silentPushIdentifier = [userInfo objectForKey:SwrveSilentPushIdentifierKey];
    if (silentPushIdentifier && ![silentPushIdentifier isKindOfClass:[NSNull class]]) {
        [SwrveCampaignDelivery sendPushDelivery:userInfo withAppGroupID:appGroupIdentifier];
        return [self handleSilentPushNotification:userInfo withCompletionHandler:completionHandler];
    } else {
        id pushIdentifier = [userInfo objectForKey:SwrveNotificationIdentifierKey];
        NSString *authenticatedPush = userInfo[SwrveNotificationAuthenticatedUserKey];
        if (pushIdentifier && ![pushIdentifier isKindOfClass:[NSNull class]] &&
                authenticatedPush && ![authenticatedPush isKindOfClass:[NSNull class]]) {
            [SwrveCampaignDelivery sendPushDelivery:userInfo withAppGroupID:appGroupIdentifier];
            return [self handleAuthenticatedPushNotification:userInfo withCompletionHandler:completionHandler withLocalUserId:localUserId];
        }
    }
    // We are not dealing with this push, so we return NO.
    return NO;
}

- (BOOL)handleAuthenticatedPushNotification:(NSDictionary *)userInfo withCompletionHandler:(void (^)(UIBackgroundFetchResult, NSDictionary *)) completionHandler {
    return [self handleAuthenticatedPushNotification:userInfo withCompletionHandler:completionHandler withLocalUserId:[SwrveLocalStorage swrveUserId]];
}

- (BOOL)handleAuthenticatedPushNotification:(NSDictionary *)userInfo withCompletionHandler:(void (^)(UIBackgroundFetchResult, NSDictionary *)) completionHandler withLocalUserId:(NSString *) localUserId API_AVAILABLE(ios(7.0)) {
    id pushIdentifier = [userInfo objectForKey:SwrveNotificationIdentifierKey];
    if (pushIdentifier && ![pushIdentifier isKindOfClass:[NSNull class]]) {

        NSString *targetedUserId = userInfo[SwrveNotificationAuthenticatedUserKey];
        if (![targetedUserId isEqualToString:localUserId]) {
            DebugLog(@"Could not handle authenticated notification.", nil);
            return NO;
        }

        if (@available(iOS 10.0, *)) {
            //for authenticated push we need to set the title, subtitle and body from the "_sw" dictionary
            //as these values are removed by the backend from the "aps" dictionary to support silent push.
            UNMutableNotificationContent *notification = [[UNMutableNotificationContent alloc] init];
            notification.userInfo = userInfo;
           
            NSDictionary *richDict = [userInfo objectForKey:SwrveNotificationContentIdentifierKey];
            NSDictionary *mediaDict = [richDict objectForKey:SwrveNotificationMediaKey];
            if (mediaDict) {
                if ([mediaDict objectForKey:SwrveNotificationTitleKey]) {
                    notification.title = [mediaDict objectForKey:SwrveNotificationTitleKey];
                }
                if ([mediaDict objectForKey:SwrveNotificationSubtitleKey]) {
                    notification.subtitle = [mediaDict objectForKey:SwrveNotificationSubtitleKey];
                }
                if ([mediaDict objectForKey:SwrveNotificationBodyKey]) {
                    notification.body = [mediaDict objectForKey:SwrveNotificationBodyKey];
                }
            }

            NSString *appGroupIdentifier = nil;
            if (_commonDelegate != NULL) {
                appGroupIdentifier = _commonDelegate.appGroupIdentifier;
            }

            [SwrvePush handleNotificationContent:notification withAppGroupIdentifier:appGroupIdentifier
                    withCompletedContentCallback:^(UNMutableNotificationContent *content) {
                        
                        //if media url was present and failed to download, we wont show the push
                        if ([content.userInfo[SwrveNotificationMediaDownloadFailed] boolValue]) {
                            DebugLog(@"Media download failed, authenticated push does not support fallback text", nil);
                            if (completionHandler != nil) {
                                completionHandler(UIBackgroundFetchResultFailed, nil);
                            }
                            return;
                        }

                        NSString *requestIdentifier = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                                                     dateStyle:NSDateFormatterShortStyle
                                                                                     timeStyle:NSDateFormatterFullStyle];
                        requestIdentifier = [requestIdentifier stringByAppendingString:[NSString stringWithFormat:@" Id: %@", pushIdentifier]];

                        UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.5 repeats:NO];
                        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:requestIdentifier
                                                                                              content:content
                                                                                              trigger:trigger];

                        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError *_Nullable error) {
                            if (error == nil) {
                                DebugLog(@"Authenticated notification completed correctly", nil);
                            } else {
                                DebugLog(@"Authenticated Notification error %@", error);
                            }
                            if (completionHandler != nil) {
                                completionHandler(UIBackgroundFetchResultNewData, nil);
                            }
                        }];
                    }];
            return YES;
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
    [SwrveCampaignDelivery sendPushDelivery:notificationContent.userInfo withAppGroupID:appGroupIdentifier];

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
            DebugLog(@"Push Content did not load correctly", nil);
            callback([notificationContent mutableCopy]);
        }
    }];
}

#pragma mark - UNUserNotificationCenterDelegate Functions

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler __IOS_AVAILABLE(10.0) __TVOS_AVAILABLE(10.0) {
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

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler __IOS_AVAILABLE(10.0) __TVOS_AVAILABLE(10.0) {
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

- (BOOL)handleSilentPushNotification:(NSDictionary *)userInfo withCompletionHandler:(void (^)(UIBackgroundFetchResult, NSDictionary *)) completionHandler API_AVAILABLE(ios(7.0)) {
    id pushIdentifier = [userInfo objectForKey:SwrveSilentPushIdentifierKey];
    if (pushIdentifier && ![pushIdentifier isKindOfClass:[NSNull class]]) {
        NSString *pushId = @"-1";
        if ([pushIdentifier isKindOfClass:[NSString class]]) {
            pushId = (NSString *) pushIdentifier;
        } else if ([pushIdentifier isKindOfClass:[NSNumber class]]) {
            pushId = [((NSNumber *) pushIdentifier) stringValue];
        } else {
            DebugLog(@"Unknown Swrve notification ID class for _sp attribute", nil);
            return NO;
        }

        // Only process this push if we haven't seen it before or its a QA push
        if (lastProcessedPushId == nil || [pushId isEqualToString:@"0"] || ![pushId isEqualToString:lastProcessedPushId]) {
            lastProcessedPushId = pushId;

            // Silent push does not require an app group Id so pass nil as a param.
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
            return YES;
        } else {
            DebugLog(@"Got Swrve notification with ID %@, ignoring as we already processed it", pushId);
            return NO;
        }
    } else {
        DebugLog(@"Got unidentified notification", nil);
        return NO;
    }
}

- (void)processInfluenceData {
    [SwrveCampaignInfluence processInfluenceDataWithDate:[self getNow]];
}

- (void)saveConfigForPushDelivery {
    if (_commonDelegate == NULL) {
        DebugLog(@"Error: Could not storage SwrveCampaignDelivery necesarry info to trigger this event later", nil);
    }

    [SwrveCampaignDelivery saveConfigForPushDeliveryWithUserId:_commonDelegate.userID
                                            WithEventServerUrl:_commonDelegate.eventsServer
                                                  WithDeviceId:_commonDelegate.deviceUUID
                                              WithSessionToken:_commonDelegate.sessionToken
                                                WithAppVersion:_commonDelegate.appVersion
                                                 ForAppGroupID:_commonDelegate.appGroupIdentifier
                                                      isQAUser:[[SwrveQA sharedInstance] isQALogging]];
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

#endif //!TARGET_OS_TV
@end

#endif
