#if !defined(SWRVE_NO_PUSH)
#import "SwrvePush.h"
#import "SwrvePushInternalAccess.h"
#import "SwrvePushConstants.h"
#import "SwrveSwizzleHelper.h"
#import "SwrvePermissions.h"
#import "SwrvePushMediaHelper.h"

typedef void (*didRegisterForRemoteNotificationsWithDeviceTokenImplSignature)(__strong id,SEL,UIApplication *, NSData*);
typedef void (*didFailToRegisterForRemoteNotificationsWithErrorImplSignature)(__strong id,SEL,UIApplication *, NSError*);
typedef void (*didReceiveRemoteNotificationImplSignature)(__strong id,SEL,UIApplication *, NSDictionary*);
#if !TARGET_OS_TV
static id <SwrvePushDelegate> _pushDelegate = NULL;
static id <SwrveCommonDelegate> _commonDelegate = NULL;
static id <SwrvePushResponseDelegate> _responseDelegate = NULL;
static SwrvePush *pushInstance = NULL;
static bool didSwizzle = false;
static dispatch_once_t sharedInstanceToken = 0;
#endif

#pragma mark - interface

@interface SwrvePush() {
    didRegisterForRemoteNotificationsWithDeviceTokenImplSignature didRegisterForRemoteNotificationsWithDeviceTokenImpl;
    didFailToRegisterForRemoteNotificationsWithErrorImplSignature didFailToRegisterForRemoteNotificationsWithErrorImpl;
    didReceiveRemoteNotificationImplSignature didReceiveRemoteNotificationImpl;

    // Apple might call different AppDelegate callbacks that could end up calling the Swrve SDK with the same push payload.
    // This would result in bad engagement reports etc. This var is used to check that the same push id can't be processed in sequence.
    NSString* lastProcessedPushId;
}
@end

#pragma mark - implementation

@implementation SwrvePush

#if !TARGET_OS_TV
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

- (void) setResponseDelegate:(id<SwrvePushResponseDelegate>)responseDelegate {
    _responseDelegate = responseDelegate;
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
        Class appDelegateClass = [[SwrveCommon sharedUIApplication].delegate class];
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
        Class appDelegateClass = [[SwrveCommon sharedUIApplication].delegate class];
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

/** older version of iOS handling **/
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

        // Only process this push if we haven't seen it before or its a QA push
        if (lastProcessedPushId == nil || [pushId isEqualToString:@"0"] || ![pushId isEqualToString:lastProcessedPushId]) {
            lastProcessedPushId = pushId;

            // Engagement replaces Influence Data
            [self clearInfluenceDataForPushId:pushId];

            // Process deeplink _sd (and old _d)
            id pushDeeplinkRaw = [userInfo objectForKey:SwrvePushDeeplinkKey];
            if (pushDeeplinkRaw == nil || ![pushDeeplinkRaw isKindOfClass:[NSString class]]) {
                // Retrieve old push deeplink for backwards compatibility
                pushDeeplinkRaw = [userInfo objectForKey:SwrvePushDeprecatedDeeplinkKey];
            }
            if ([pushDeeplinkRaw isKindOfClass:[NSString class]]) {
                NSString* pushDeeplink = (NSString*)pushDeeplinkRaw;
                [self handlePushDeeplinkString:pushDeeplink];
            }

            [_pushDelegate sendPushEngagedEvent:pushId];
            DebugLog(@"Got Swrve notification with ID %@", pushId);
        } else {
            DebugLog(@"Got Swrve notification with ID %@, ignoring as we already processed it", pushId);
        }
    } else {
        DebugLog(@"Got unidentified notification", nil);
    }
}

- (void) pushNotificationResponseReceived:(NSString*)identifier withUserInfo:(NSDictionary *)userInfo {

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

        // Only process this push if we haven't seen it before or its a QA push
        if (lastProcessedPushId == nil || [pushId isEqualToString:@"0"] || ![pushId isEqualToString:lastProcessedPushId]) {
            lastProcessedPushId = pushId;

            // Engagement replaces Influence Data
            [self clearInfluenceDataForPushId:pushId];

            if([identifier isEqualToString:SwrvePushResponseDefaultActionKey]) {
                // if the user presses the push directly
                id pushDeeplinkRaw = [userInfo objectForKey:SwrvePushDeeplinkKey];
                if (pushDeeplinkRaw == nil || ![pushDeeplinkRaw isKindOfClass:[NSString class]]) {
                    // Retrieve old push deeplink for backwards compatibility
                    pushDeeplinkRaw = [userInfo objectForKey:SwrvePushDeprecatedDeeplinkKey];
                }
                if ([pushDeeplinkRaw isKindOfClass:[NSString class]]) {
                    NSString* pushDeeplink = (NSString*)pushDeeplinkRaw;
                    [self handlePushDeeplinkString:pushDeeplink];
                }

                [_pushDelegate sendPushEngagedEvent:pushId];
                DebugLog(@"Performed a Direct Press on Swrve notification with ID %@", pushId);

            }else{

                NSDictionary *swrveValues = [userInfo objectForKey:SwrvePushContentIdentifierKey];
                NSArray *swrvebuttons = [swrveValues objectForKey:SwrvePushButtonListKey];

                if(swrvebuttons != nil && [swrvebuttons count] > 0){
                    int position = [identifier intValue];

                    NSDictionary *selectedButton = [swrvebuttons objectAtIndex:(NSUInteger)position];
                    NSString *action = [selectedButton objectForKey:SwrvePushButtonActionKey];
                    NSString *actionType = [selectedButton objectForKey:SwrvePushButtonActionTypeKey];
                    NSString *actionText = [selectedButton objectForKey:SwrvePushButtonTitleKey];
                    // Process deeplink if available in Action
                    if([actionType isEqualToString:SwrvePushCustomButtonUrlIdentiferKey]){
                        [self handlePushDeeplinkString:action];
                    }

                    // Send button click event.
                    DebugLog(@"Selected Button:'%@' on Swrve notification with ID %@", identifier, pushId);
                    NSMutableDictionary* actionEvent = [[NSMutableDictionary alloc] init];
                    [actionEvent setValue:pushId forKey:@"id"];
                    [actionEvent setValue:@"push" forKey:@"campaignType"];
                    [actionEvent setValue:@"button_click" forKey:@"actionType"];
                    [actionEvent setValue:identifier forKey:@"contextId"];
                    NSMutableDictionary* eventPayload = [[NSMutableDictionary alloc] init];
                    [eventPayload setValue:actionText forKey:@"buttonText"];
                    [actionEvent setValue:eventPayload forKey:@"payload"];

                    // Create generic campaign for button click
                    [_commonDelegate queueEvent:@"generic_campaign_event" data:actionEvent triggerCallback:false];
                    [_commonDelegate sendQueuedEvents];

                    // Send push EngagedEvent
                    [_pushDelegate sendPushEngagedEvent:pushId];

                }else{
                    DebugLog(@"Receieved a push with an unrecognised identifier %@", identifier);
                }
            }
        } else {
           DebugLog(@"Got Swrve notification with ID %@, ignoring as we already processed it", pushId);
        }
    } else {
        DebugLog(@"Got unidentified notification", nil);
    }
}

- (BOOL)didReceiveRemoteNotification:(NSDictionary *)userInfo withBackgroundCompletionHandler:(void (^)(UIBackgroundFetchResult, NSDictionary*))completionHandler {
    // This method can also be called when the app is in the background for normal pushes
    // if the app has background remote notifications enabled
    id silentPushIdentifier = [userInfo objectForKey:SwrveSilentPushIdentifierKey];
    if (silentPushIdentifier && ![silentPushIdentifier isKindOfClass:[NSNull class]]) {
        [self silentPushReceived:userInfo withCompletionHandler:completionHandler];
        // Customer should handle the payload in the completionHandler
        return YES;
    } else {
        id pushIdentifier = [userInfo objectForKey:SwrvePushIdentifierKey];
        if (pushIdentifier && ![pushIdentifier isKindOfClass:[NSNull class]]) {
            [self pushNotificationReceived:userInfo];
            // We won't call the completionHandler and the customer should handle it themselves
            return NO;
        }
    }
    return NO;
}

- (void) handlePushDeeplinkString:(NSString*) pushDeeplink {
    NSURL* url = [NSURL URLWithString:pushDeeplink];
    BOOL canOpen = [[SwrveCommon sharedUIApplication] canOpenURL:url];
    if( url != nil && canOpen ) {
        DebugLog(@"Action - %@ - handled.  Sending to application as URL", pushDeeplink);
        [_pushDelegate deeplinkReceived:url];
    } else {
        DebugLog(@"Could not process push deeplink - %@", pushDeeplink);
    }
}


#pragma mark - Service Extension Modification (public facing)

+ (void)handleNotificationContent:(UNNotificationContent *) notificationContent withAppGroupIdentifier:(NSString *)appGroupIdentifier
     withCompletedContentCallback:(void (^)(UNMutableNotificationContent * content)) callback {

    /** Process push identifier for influenceData **/
    id pushIdentifier = notificationContent.userInfo[SwrvePushIdentifierKey];
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
            callback([notificationContent mutableCopy]);
            return;
        }

        /** Store Influenced data **/
        [SwrvePush saveInfluencedData:notificationContent.userInfo withPushId:pushId withAppGroupID:appGroupIdentifier atDate:[NSDate date]];

        DebugLog(@"Got Swrve Notification with ID %@", pushId);
    } else {

        DebugLog(@"Got unidentified notification", nil);
        callback([notificationContent mutableCopy]);
        return;
    }

    /** Check the push version number **/
    NSDictionary *sw = [notificationContent.userInfo objectForKey:SwrvePushContentIdentifierKey];
    int contentVersion = [(NSNumber*)[sw objectForKey:SwrvePushContentVersionKey] intValue];
    if(contentVersion > SwrvePushContentVersion) {
        callback([notificationContent mutableCopy]);
        return;
    }
    // clean up
    sw = nil;

    /** Set Rich Media Content **/
    [SwrvePush handleRichPushContents:notificationContent withCompletionCallback:^(UNMutableNotificationContent *content) {
        if(content){
            callback(content);
        }else{
            DebugLog(@"Push Content did not load correctly");
            callback([notificationContent mutableCopy]);
        }
    }];
}

#pragma mark - Private Methods

+ (void)handleRichPushContents:(UNNotificationContent *) notificationContent
        withCompletionCallback:(void (^)(UNMutableNotificationContent * content)) completion {

    __block UNMutableNotificationContent *mutableNotificationContent = [notificationContent mutableCopy];

    /** create the notification dispatch group **/
    dispatch_group_t notificationGroup = dispatch_group_create();

    /** Generate Appropriate Categories based on UserInfo **/
    UNNotificationCategory *generatedCategory = [SwrvePushMediaHelper produceButtonsFromUserInfo:mutableNotificationContent.userInfo];

    if (generatedCategory) {
        // Category is generated start dispatch listener
        dispatch_group_enter(notificationGroup);

        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        /** Merge the categories defined in the app, with the dynamic ones **/
        [center getNotificationCategoriesWithCompletionHandler:^(NSSet<UNNotificationCategory *> * _Nonnull categories) {

            /** Check if mutableNotificationContent isn't set nil by mediaUrl checks first **/
            if(mutableNotificationContent != nil) {
                NSMutableSet* generatedCategories = [NSMutableSet set];
                [generatedCategories addObject:generatedCategory];
                NSSet *mergedSet = [categories setByAddingObjectsFromSet:generatedCategories];
                mutableNotificationContent.categoryIdentifier = generatedCategory.identifier;
                [center setNotificationCategories:mergedSet];
            }

            dispatch_group_leave(notificationGroup);
        }];
        center = nil;
    }

    NSDictionary *sw = [mutableNotificationContent.userInfo objectForKey:SwrvePushContentIdentifierKey];
    NSDictionary *mediaDict = [sw objectForKey:SwrvePushMediaKey];
    // clean up
    sw = nil;

    NSString *mediaUrl = [mediaDict objectForKey:SwrvePushUrlKey];
    if(mediaUrl) {
        dispatch_group_enter(notificationGroup);
        [SwrvePushMediaHelper downloadAttachment:mediaUrl withCompletedContentCallback:^(UNNotificationAttachment *attachment, NSError *error) {

            if(attachment && error == nil) {
                // Primary image has worked
                mutableNotificationContent.attachments = [NSMutableArray arrayWithObject:attachment];
                [SwrvePushMediaHelper produceMediaTextFromProvidedContent:mutableNotificationContent];
                DebugLog(@"Downloaded primary attachment successfully, returning to callback");
                dispatch_group_leave(notificationGroup);
            } else {

                if(mediaDict[SwrvePushFallbackUrlKey] != nil) {
                    // Download fallback image
                    [SwrvePushMediaHelper downloadAttachment:mediaDict[SwrvePushFallbackUrlKey] withCompletedContentCallback:^(UNNotificationAttachment *fallbackAttachment, NSError *fallbackError) {
                        if(fallbackAttachment && fallbackError == nil) {
                            // Fallback image has worked
                            mutableNotificationContent.attachments = [NSMutableArray arrayWithObject:fallbackAttachment];
                            [SwrvePushMediaHelper produceMediaTextFromProvidedContent:mutableNotificationContent];
                            DebugLog(@"Downloaded fallback attachment successfully, returning to callback");

                            // Set fallback_sd if available
                            if(mediaDict[SwrvePushFallbackDeeplinkKey] != nil) {
                                DebugLog(@"Fallback Deeplink detected, modifying notificationContent.userInfo");
                                NSMutableDictionary *moddedUserInfo = [mutableNotificationContent.userInfo mutableCopy];
                                [moddedUserInfo setObject:mediaDict[SwrvePushFallbackDeeplinkKey] forKey:SwrvePushDeeplinkKey];
                                mutableNotificationContent.userInfo = moddedUserInfo;
                                // clean up
                                moddedUserInfo = nil;
                            }

                        } else {
                            DebugLog(@"Fallback attachment error occurred: %@ Removing all attachments", fallbackError);
                        }

                        // Finished async fallback download task
                        dispatch_group_leave(notificationGroup);
                    }];

                }else{
                    // There is no fallback attachment
                    DebugLog(@"Primary attachment error occured %@, Removing all attachments, ", error);
                    dispatch_group_leave(notificationGroup);
                }
            }
        }];
    }

    dispatch_group_notify(notificationGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
        /** Everything is finished, return the result **/
        completion(mutableNotificationContent);
    });
}

#pragma mark - UNUserNotificationCenterDelegate Functions

- (void) userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
#pragma unused(center)

    if(_responseDelegate){
        if ([_responseDelegate respondsToSelector:@selector(willPresentNotification:withCompletionHandler:)]) {
            [_responseDelegate willPresentNotification:notification withCompletionHandler:completionHandler];
        }else{
            // if there is no willPresentNotification implemented as part of the delegate
            if(completionHandler) {
                completionHandler(UNNotificationPresentationOptionNone);
            }
        }
    }else{
        if(completionHandler) {
            completionHandler(UNNotificationPresentationOptionNone);
        }
    }
}

#ifdef __IPHONE_11_0
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler {
#else
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)())completionHandler {
#endif
#pragma unused(center)

    [self pushNotificationResponseReceived:response.actionIdentifier withUserInfo:response.notification.request.content.userInfo];

    if(_responseDelegate){
        if ([_responseDelegate respondsToSelector:@selector(didReceiveNotificationResponse:withCompletionHandler:)]) {
            [_responseDelegate didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
            
        }else{
            // if there is no didReceiveNotificationResponse implemented as part of the delegate
            if(completionHandler) {
                completionHandler();
            }
        }
    }else{
        if (completionHandler) {
            completionHandler();
        }
    }
}


#pragma mark - silent push

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

        // Only process this push if we haven't seen it before or its a QA push
        if (lastProcessedPushId == nil || [pushId isEqualToString:@"0"]  || ![pushId isEqualToString:lastProcessedPushId]) {
            lastProcessedPushId = pushId;

            [SwrvePush saveInfluencedData:userInfo withPushId:pushId atDate:[self getNow]];

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

            DebugLog(@"Got Swrve silent notification with ID %@", pushId);
        } else {
            DebugLog(@"Got Swrve notification with ID %@, ignoring as we already processed it", pushId);
        }
    } else {
        DebugLog(@"Got unidentified notification", nil);
    }
}

+ (void) saveInfluencedData:(NSDictionary*)userInfo withPushId:(NSString*)pushId atDate:(NSDate*)date {
    [SwrvePush saveInfluencedData:userInfo withPushId:pushId withAppGroupID:nil atDate:date];
}

+ (void) saveInfluencedData:(NSDictionary*)userInfo withPushId:(NSString*)pushId withAppGroupID:(NSString *)appGroupID atDate:(NSDate*)date {
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
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        if(appGroupID) {
            // if there is an appGroupID then check there instead
            defaults = [[NSUserDefaults alloc] initWithSuiteName:appGroupID];
        }

        [defaults synchronize];

        NSMutableDictionary* influencedData = [[defaults dictionaryForKey:SwrveInfluenceDataKey] mutableCopy];

        // if nothing is there. create a new one
        if (influencedData == nil) {
            influencedData = [[NSMutableDictionary alloc] init];
        }

        // set pushId passed in
        [influencedData setValue:[NSNumber numberWithLong:maxWindowTimeSeconds] forKey:pushId];

        // set influenced data to either the appGroup or the NSUserDefaults of the main app
        [defaults setObject:influencedData forKey:SwrveInfluenceDataKey];
        [defaults synchronize];

    }
}

- (void) processInfluenceData {

    NSDictionary *influencedData;
    NSDictionary* mainAppInfluence = [[NSUserDefaults standardUserDefaults] dictionaryForKey:SwrveInfluenceDataKey];
    NSDictionary* serviceExtensionInfluence = nil;

    if(_commonDelegate != nil && _commonDelegate.appGroupIdentifier != nil){
        serviceExtensionInfluence = [[[NSUserDefaults alloc] initWithSuiteName:_commonDelegate.appGroupIdentifier] dictionaryForKey:SwrveInfluenceDataKey];
    }

    if(mainAppInfluence != nil) {
        influencedData = mainAppInfluence;

    }else if(serviceExtensionInfluence != nil) {
        influencedData = serviceExtensionInfluence;

    }

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

                        [_commonDelegate queueEvent:@"generic_campaign_event" data:influencedEvent triggerCallback:false];
                    } else {
                        DebugLog(@"Could not find a shared instance to send the silent push influence data");
                    }
                }
            }
        }

        [[NSUserDefaults standardUserDefaults] removeObjectForKey:SwrveInfluenceDataKey];
        [[[NSUserDefaults alloc] initWithSuiteName:_commonDelegate.appGroupIdentifier] removeObjectForKey:SwrveInfluenceDataKey];
    }
}

- (NSDate*)getNow {
    return [NSDate date];
}

- (void) clearInfluenceDataForPushId:(NSString *)pushID {

    NSMutableDictionary *coreAppInfluenceData = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:SwrveInfluenceDataKey] mutableCopy];
    NSMutableDictionary *appGroupInfluenceData = [[[[NSUserDefaults alloc] initWithSuiteName:_commonDelegate.appGroupIdentifier] dictionaryForKey:SwrveInfluenceDataKey] mutableCopy];

    if([coreAppInfluenceData objectForKey:pushID]) {
        [coreAppInfluenceData removeObjectForKey:pushID];
        [[NSUserDefaults standardUserDefaults] setValue:coreAppInfluenceData forKey:SwrveInfluenceDataKey];
    }

    if([appGroupInfluenceData objectForKey:pushID]) {
        [appGroupInfluenceData removeObjectForKey:pushID];
        [[[NSUserDefaults alloc] initWithSuiteName:_commonDelegate.appGroupIdentifier] setValue:appGroupInfluenceData forKey:SwrveInfluenceDataKey];
    }
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
            id target = [SwrveCommon sharedUIApplication].delegate;
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
            id target = [SwrveCommon sharedUIApplication].delegate;
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
            id target = [SwrveCommon sharedUIApplication].delegate;
            pushInstance->didReceiveRemoteNotificationImpl(target, @selector(application:didReceiveRemoteNotification:), application, userInfo);
        }
    }
}

#endif //!TARGET_OS_TV
@end

#endif
