#import "SwrvePush.h"
#import "SwrveSwizzleHelper.h"
#import "SwrveCampaignInfluence.h"
#import "SwrveNotificationManager.h"
#import "SwrveNotificationConstants.h"
#import "SwrvePermissions.h"
#import "SwrveLocalStorage.h"
#import "SwrveCampaignDelivery.h"
#import "SwrveQA.h"
#import "SwrveSEConfig.h"
#import "SwrveUtils.h"

typedef void (*didRegisterForRemoteNotificationsWithDeviceTokenImplSignature)(__strong id, SEL, UIApplication *, NSData *);

typedef void (*didFailToRegisterForRemoteNotificationsWithErrorImplSignature)(__strong id, SEL, UIApplication *, NSError *);

#if !TARGET_OS_TV
static id <SwrvePushDelegate> _pushDelegate = NULL;
static id <SwrveCommonDelegate> _commonDelegate = NULL;
static id <SwrvePushResponseDelegate> _responseDelegate = NULL;
static SwrvePush *pushInstance = NULL;
static bool didSwizzle = false;
static dispatch_once_t sharedInstanceToken = 0;
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

NSString *appGroupIdentifier;

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

- (BOOL)observeSwizzling NS_EXTENSION_UNAVAILABLE_IOS("") {

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

- (void)deswizzlePushMethods NS_EXTENSION_UNAVAILABLE_IOS("") {

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
    if (_commonDelegate != NULL) {
        appGroupIdentifier = _commonDelegate.appGroupIdentifier;
    }

    NSString *silentPushId = [SwrvePush pushIdFromNotificationContent:userInfo andPushIdKey:SwrveNotificationSilentPushIdentifierKey];
    if (silentPushId) {
        return [self handleSilentPushNotification:userInfo withCompletionHandler:completionHandler];
    } else {
        NSString *pushId = [SwrvePush pushIdFromNotificationContent:userInfo andPushIdKey:SwrveNotificationIdentifierKey];
        if (pushId && [SwrveUtils isAuthenticatedPush:userInfo]) {
            return [self handleAuthenticatedPushNotification:userInfo
                                             withLocalUserId:localUserId
                                       withCompletionHandler:completionHandler];
        } else {
            [SwrveLogger debug:@"Swrve not processing didReceiveRemoteNotification.", nil];
        }
    }
    return NO;
}

- (BOOL)handleAuthenticatedPushNotification:(NSDictionary *)userInfo
                            withLocalUserId:(NSString *)localUserId
                      withCompletionHandler:(void (^)(UIBackgroundFetchResult, NSDictionary *))completionHandler API_AVAILABLE(ios(7.0)) {

    [self sendPushDelivery:userInfo];

    if (![SwrvePush isValidNotificationContent:userInfo]) {
        return NO;
    } else if ([SwrveUtils isDifferentUserForAuthenticatedPush:userInfo userId:localUserId]) {
        [SwrveLogger error:@"Swrve could not handle authenticated notification.", nil];
        return NO;
    } else if ([SwrveSEConfig isTrackingStateStopped:appGroupIdentifier]) {
        [SwrveLogger error:@"Swrve could not handle authenticated notification as sdk tracking is stopped.", nil];
        return NO;
    }

    if (@available(iOS 10.0, *)) {
        //for authenticated push we need to set the title, subtitle and body from the "_sw" dictionary
        //as these values are removed by the backend from the "aps" dictionary to support silent push.
        UNMutableNotificationContent *notificationContent = [[UNMutableNotificationContent alloc] init];
        notificationContent.userInfo = userInfo;

        NSDictionary *richDict = [userInfo objectForKey:SwrveNotificationContentIdentifierKey];
        NSDictionary *mediaDict = [richDict objectForKey:SwrveNotificationMediaKey];
        if (mediaDict) {
            if ([mediaDict objectForKey:SwrveNotificationTitleKey]) {
                notificationContent.title = [mediaDict objectForKey:SwrveNotificationTitleKey];
            }
            if ([mediaDict objectForKey:SwrveNotificationSubtitleKey]) {
                notificationContent.subtitle = [mediaDict objectForKey:SwrveNotificationSubtitleKey];
            }
            if ([mediaDict objectForKey:SwrveNotificationBodyKey]) {
                notificationContent.body = [mediaDict objectForKey:SwrveNotificationBodyKey];
            }
        }

        NSString *pushId = [SwrvePush pushIdFromNotificationContent:userInfo andPushIdKey:SwrveNotificationIdentifierKey]; // pushId already validated in isValidNotificationContent
        [SwrveCampaignInfluence saveInfluencedData:notificationContent.userInfo
                                            withId:pushId
                                    withAppGroupID:appGroupIdentifier
                                            atDate:[NSDate date]];
        
        __block UIBackgroundTaskIdentifier handleContentTask = UIBackgroundTaskInvalid;
        __block NSString *taskName = [NSString stringWithFormat:@"handleContent %@",pushId];
        handleContentTask = [SwrveUtils startBackgroundTaskCommon:handleContentTask withName:taskName];
        [SwrveNotificationManager handleContent:notificationContent withCompletionCallback:^(UNMutableNotificationContent *content) {\

            //if media url was present and failed to download, we wont show the push
            if ([content.userInfo[SwrveNotificationMediaDownloadFailed] boolValue]) {
                [SwrveLogger error:@"Media download failed, authenticated push does not support fallback text", nil];
                if (completionHandler != nil) {
                    completionHandler(UIBackgroundFetchResultFailed, nil);
                }
                [SwrveUtils stopBackgroundTaskCommon:handleContentTask withName:taskName];
                return;
            }

            NSString *requestIdentifier = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                                         dateStyle:NSDateFormatterShortStyle
                                                                         timeStyle:NSDateFormatterFullStyle];
            requestIdentifier = [requestIdentifier stringByAppendingString:[NSString stringWithFormat:@" Id: %@", pushId]];

            UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.5 repeats:NO];
            UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:requestIdentifier
                                                                                  content:content
                                                                                  trigger:trigger];

            [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError *_Nullable error) {
                if (error == nil) {
                    [SwrveLogger debug:@"Authenticated notification completed correctly", nil];
                } else {
                    [SwrveLogger error:@"Authenticated Notification error %@", error];
                }
                if (completionHandler != nil) {
                    completionHandler(UIBackgroundFetchResultNewData, nil);
                }
                [SwrveUtils stopBackgroundTaskCommon:handleContentTask withName:taskName];
            }];
        }];

        return YES;
    }

    return NO;
}

+ (BOOL)isValidNotificationContent:(NSDictionary *)userInfo {
    BOOL isValidNotificationContent = YES;
    
    //Check if rich push and version is ok, (note plain text (non-rich) pushes do not contain _sw dict)
    NSDictionary *sw = [userInfo objectForKey:SwrveNotificationContentIdentifierKey];
    if (sw != nil) {
        int contentVersion = [(NSNumber *) [sw objectForKey:SwrveContentVersionKey] intValue];
        if (contentVersion > SwrveContentVersion) {
            [SwrveLogger error:@"Could not process notification because version is incompatible version.", nil];
            isValidNotificationContent = NO;
        }
    }
    
    //Check that its a Swrve push
    //Note, even though auth pushes are sent silently they will contain _p and not _sp
    id pushIdentifier = userInfo[SwrveNotificationIdentifierKey];
    if (!pushIdentifier) {
        [SwrveLogger debug:@"Got unidentified notification", nil];
        isValidNotificationContent = NO;
    } else if (![pushIdentifier isKindOfClass:[NSString class]] && ![pushIdentifier isKindOfClass:[NSNumber class]]) {
        [SwrveLogger error:@"Unknown Swrve notification ID class for _p attribute", nil];
        isValidNotificationContent = NO;
    }
        
    return isValidNotificationContent;
}

// handles both regular and silent push (SwrveNotificationIdentifierKey and SwrveNotificationSilentPushIdentifierKey)
+ (NSString *)pushIdFromNotificationContent:(NSDictionary *)userInfo andPushIdKey:(NSString *)pushIdKey {
    NSString *pushId = @"";
    id pushIdentifier = userInfo[pushIdKey];
    if (pushIdentifier && ![pushIdentifier isKindOfClass:[NSNull class]]) {
        if ([pushIdentifier isKindOfClass:[NSString class]]) {
            pushId = (NSString *) pushIdentifier;
        } else if ([pushIdentifier isKindOfClass:[NSNumber class]]) {
            pushId = [((NSNumber *) pushIdentifier) stringValue];
        }
    }
    return [pushId length] == 0 ? nil : pushId;
}

- (void)sendPushDelivery:(NSDictionary *)userInfo {
    SwrveCampaignDelivery *campaignDelivery = [[SwrveCampaignDelivery alloc] initAppGroupId:appGroupIdentifier];
    [campaignDelivery sendPushDelivery:userInfo];
}

#pragma mark - Service Extension Modification (public facing)

+ (void)handleNotificationContent:(UNNotificationContent *)notificationContent
           withAppGroupIdentifier:(NSString *)appGroupIdentifier
     withCompletedContentCallback:(void (^)(UNMutableNotificationContent *content))callback {

    if(![SwrvePush isValidNotificationContent:notificationContent.userInfo]) {
        callback([notificationContent mutableCopy]);
        return;
    }
    if (_commonDelegate != NULL) {
        appGroupIdentifier = _commonDelegate.appGroupIdentifier;
    }

    SwrveCampaignDelivery *campaignDelivery = [[SwrveCampaignDelivery alloc] initAppGroupId:appGroupIdentifier];
    [campaignDelivery sendPushDelivery:notificationContent.userInfo];

    NSString *pushId = [SwrvePush pushIdFromNotificationContent:notificationContent.userInfo andPushIdKey:SwrveNotificationIdentifierKey]; // pushId already validated in isValidNotificationContent
    [SwrveCampaignInfluence saveInfluencedData:notificationContent.userInfo
                                        withId:pushId
                                withAppGroupID:appGroupIdentifier
                                        atDate:[NSDate date]];

    [SwrveNotificationManager handleContent:notificationContent withCompletionCallback:^(UNMutableNotificationContent *content) {
        if (content) {
            callback(content);
        } else {
            [SwrveLogger error:@"Push Content did not load correctly", nil];
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

- (BOOL)handleSilentPushNotification:(NSDictionary *)userInfo withCompletionHandler:(void (^)(UIBackgroundFetchResult, NSDictionary *))completionHandler API_AVAILABLE(ios(7.0)) {

    [self sendPushDelivery:userInfo];

    NSString *pushId = [SwrvePush pushIdFromNotificationContent:userInfo andPushIdKey:SwrveNotificationSilentPushIdentifierKey];
    if (!pushId) {
        [SwrveLogger debug:@"Got unidentified silent push", nil];
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
                id silentPayloadRaw = [userInfo objectForKey:SwrveNotificationSilentPushPayloadKey];
                if (silentPayloadRaw != nil && [silentPayloadRaw isKindOfClass:[NSDictionary class]]) {
                    completionHandler(UIBackgroundFetchResultNoData, (NSDictionary *) silentPayloadRaw);
                } else {
                    completionHandler(UIBackgroundFetchResultNoData, nil);
                }
            } @catch (NSException *exception) {
                [SwrveLogger error:@"Could not execute the silent push listener: %@", exception.reason];
            }
        }
        [SwrveLogger debug:@"Got Swrve silent notification with ID %@", pushId];
        return YES;
    } else {
        [SwrveLogger warning:@"Got Swrve notification with ID %@, ignoring as we already processed it", pushId];
        return NO;
    }
}

- (void)processInfluenceData {
    [SwrveCampaignInfluence processInfluenceDataWithDate:[self getNow]];
}

- (void)saveConfigForPushDelivery {
    if (_commonDelegate == NULL) {
        [SwrveLogger error:@"Error: Could not store SwrveCampaignDelivery necessary info to trigger this event later", nil];
    }

    [SwrveSEConfig saveAppGroupId:_commonDelegate.appGroupIdentifier
                           userId:_commonDelegate.userID
                   eventServerUrl:_commonDelegate.eventsServer
                         deviceId:_commonDelegate.deviceUUID
                     sessionToken:_commonDelegate.sessionToken
                       appVersion:_commonDelegate.appVersion
                         isQAUser:[[SwrveQA sharedInstance] isQALogging]];
}

- (NSDate *)getNow {
    return [NSDate date];
}

#pragma mark - UIApplication Functions

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken NS_EXTENSION_UNAVAILABLE_IOS("") {
    if (_commonDelegate == NULL) {
        [SwrveLogger error:@"Error: Auto device token collection only works if you are using the Swrve instance singleton.", nil];
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

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error NS_EXTENSION_UNAVAILABLE_IOS("") {

    if (_commonDelegate == NULL) {
        [SwrveLogger error:@"Error: Auto device token collection only works if you are using the Swrve instance singleton.", nil];
    } else {
        [SwrveLogger debug:@"Could not auto collected device token.", nil];

        if (pushInstance->didFailToRegisterForRemoteNotificationsWithErrorImpl != NULL) {
            id target = [SwrveCommon sharedUIApplication].delegate;
            pushInstance->didFailToRegisterForRemoteNotificationsWithErrorImpl(target, @selector(application:didFailToRegisterForRemoteNotificationsWithError:), application, error);
        }
    }
}

#endif //!TARGET_OS_TV
@end
