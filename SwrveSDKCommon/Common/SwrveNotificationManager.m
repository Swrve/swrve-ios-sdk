#if !defined(SWRVE_NO_PUSH)

#import "SwrveCommon.h"
#import "SwrveNotificationManager.h"
#import "SwrveNotificationOptions.h"
#import "SwrveCampaignInfluence.h"
#import "SwrveNotificationConstants.h"

// Apple might call different AppDelegate callbacks that could end up calling the Swrve SDK with the same push payload.
// This would result in bad engagement reports etc. The lastProcessedPushId var is used to check that the same push id
// can't be processed in sequence.
static NSString *lastProcessedPushId = nil;

@implementation SwrveNotificationManager

#if !TARGET_OS_TV

// for unit tests
+ (void)updateLastProcessedPushId:(NSString *)pushId {
    lastProcessedPushId = pushId;
}

+ (void) handleContent:(UNNotificationContent *)notificationContent
withCompletionCallback:(void (^)(UNMutableNotificationContent *content))completion {

    __block UNMutableNotificationContent *mutableNotificationContent = [notificationContent mutableCopy];

    /** create the notification dispatch group **/
    dispatch_group_t notificationGroup = dispatch_group_create();

    /** Generate Appropriate Categories based on UserInfo **/
    UNNotificationCategory *generatedCategory = [self buttonsFromUserInfo:mutableNotificationContent.userInfo];

    if (generatedCategory) {
        // Category is generated start dispatch listener
        dispatch_group_enter(notificationGroup);

        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        /** Merge the categories defined in the app, with the dynamic ones **/
        [center getNotificationCategoriesWithCompletionHandler:^(NSSet<UNNotificationCategory *> *_Nonnull categories) {

            /** Check if mutableNotificationContent isn't set nil by mediaUrl checks first **/
            if (mutableNotificationContent != nil) {
                NSMutableSet *generatedCategories = [NSMutableSet set];
                [generatedCategories addObject:generatedCategory];
                NSSet *mergedSet = [categories setByAddingObjectsFromSet:generatedCategories];
                mutableNotificationContent.categoryIdentifier = generatedCategory.identifier;
                [center setNotificationCategories:mergedSet];
            }

            /**
               There is a delay required between setting notification categories and leaving dispatch
               the following checks for the existence of the new category twice before carrying on.
            **/
            [self verifyCategoryGenerated:generatedCategory withCompletedCallback:^(BOOL found) {
                if(found) {
                    dispatch_group_leave(notificationGroup);
                } else {
                    [self verifyCategoryGenerated:generatedCategory withCompletedCallback:^(BOOL foundCategory) {
                        #pragma unused (foundCategory)
                        // at this point, if we do not have the category, we should exit anyway
                        dispatch_group_leave(notificationGroup);
                    }];
                }
            }];
        }];
        center = nil;
    }

    NSDictionary *sw = [mutableNotificationContent.userInfo objectForKey:SwrveNotificationContentIdentifierKey];
    NSDictionary *mediaDict = [sw objectForKey:SwrveNotificationMediaKey];
    // clean up
    sw = nil;

    NSString *mediaUrl = [mediaDict objectForKey:SwrveNotificationUrlKey];
    if (mediaUrl) {
        dispatch_group_enter(notificationGroup);
        [self downloadAttachment:mediaUrl withCompletedContentCallback:^(UNNotificationAttachment *attachment, NSError *error) {

            if (attachment && error == nil) {
                // Primary image has worked
                mutableNotificationContent.attachments = [NSMutableArray arrayWithObject:attachment];
                [self mediaTextFromProvidedContent:mutableNotificationContent];
                DebugLog(@"Downloaded primary attachment successfully, returning to callback");
                dispatch_group_leave(notificationGroup);
            } else {

                if (mediaDict[SwrveNotificationFallbackUrlKey] != nil) {
                    // Download fallback image
                    [self downloadAttachment:mediaDict[SwrveNotificationFallbackUrlKey] withCompletedContentCallback:^(UNNotificationAttachment *fallbackAttachment, NSError *fallbackError) {
                        if (fallbackAttachment && fallbackError == nil) {
                            // Fallback image has worked
                            mutableNotificationContent.attachments = [NSMutableArray arrayWithObject:fallbackAttachment];
                            [self mediaTextFromProvidedContent:mutableNotificationContent];
                            DebugLog(@"Downloaded fallback attachment successfully, returning to callback");

                            // Set fallback_sd if available
                            if (mediaDict[SwrveNotificationFallbackDeeplinkKey] != nil) {
                                DebugLog(@"Fallback Deeplink detected, modifying notificationContent.userInfo");
                                NSMutableDictionary *moddedUserInfo = [mutableNotificationContent.userInfo mutableCopy];
                                [moddedUserInfo setObject:mediaDict[SwrveNotificationFallbackDeeplinkKey] forKey:SwrveNotificationDeeplinkKey];
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

                } else {
                    // There is no fallback attachment
                    DebugLog(@"Primary attachment error occured %@, Removing all attachments, ", error);
                    dispatch_group_leave(notificationGroup);
                }
            }
        }];
    }

    dispatch_group_notify(notificationGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        /** Everything is finished, return the result **/
        completion(mutableNotificationContent);
    });
}

+ (UNMutableNotificationContent *)mediaTextFromProvidedContent:(UNMutableNotificationContent *)content {
    NSDictionary *richDict = [content.userInfo objectForKey:SwrveNotificationContentIdentifierKey];
    NSDictionary *mediaDict = [richDict objectForKey:SwrveNotificationMediaKey];
    if (mediaDict) {
        if ([mediaDict objectForKey:SwrveNotificationTitleKey]) {
            content.title = [mediaDict objectForKey:SwrveNotificationTitleKey];
        }
        if ([mediaDict objectForKey:SwrveNotificationSubtitleKey]) {
            content.subtitle = [mediaDict objectForKey:SwrveNotificationSubtitleKey];
        }
        if ([mediaDict objectForKey:SwrveNotificationBodyKey]) {
            content.body = [mediaDict objectForKey:SwrveNotificationBodyKey];
        }
    }
    return content;
}

+ (UNNotificationCategory *)buttonsFromUserInfo:(NSDictionary *)userInfo {
    NSDictionary *richDict = [userInfo objectForKey:SwrveNotificationContentIdentifierKey];
    NSArray *buttons = [richDict valueForKey:SwrveNotificationButtonListKey];
    int customButtonIndex = 0;
    NSMutableArray *actions = [NSMutableArray array];
    if (buttons != nil && [buttons count] > 0) {
        for (NSDictionary *button in buttons) {
            NSString *buttonId = [NSString stringWithFormat:@"%d", customButtonIndex];
            NSString *buttonTitle = [button objectForKey:SwrveNotificationButtonTitleKey];
            NSArray *buttonActionOptions = [button objectForKey:SwrveNotificationButtonTypeKey];
            UNNotificationActionOptions actionOptions = [SwrveNotificationOptions actionOptionsForKeys:buttonActionOptions];
            UNNotificationAction *actionButton = [UNNotificationAction actionWithIdentifier:buttonId title:buttonTitle options:actionOptions];
            [actions addObject:actionButton];
            customButtonIndex++;
        }

        NSMutableArray *intentIdentifiers = [NSMutableArray array];

        NSString *categoryKey = [NSString stringWithFormat:@"swrve-%@-%@", [userInfo objectForKey:SwrveNotificationIdentifierKey], [[NSUUID UUID] UUIDString]];
        NSArray *buttonCategoryOptions = [richDict objectForKey:SwrveNotificationButtonOptionsKey];
        UNNotificationCategoryOptions categoryOptions = [SwrveNotificationOptions categoryOptionsForKeys:buttonCategoryOptions];
        UNNotificationCategory *category = [UNNotificationCategory categoryWithIdentifier:categoryKey actions:actions intentIdentifiers:intentIdentifiers options:categoryOptions];
        return category;
    } else {
        return nil;
    }
}

+ (void)verifyCategoryGenerated:(UNNotificationCategory *) generatedCategory withCompletedCallback:(void (^)(BOOL found)) callback  __IOS_AVAILABLE(10.0) __TVOS_AVAILABLE(10.0) {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center getNotificationCategoriesWithCompletionHandler:^(NSSet<UNNotificationCategory *> *_Nonnull categories) {
        BOOL found = NO;
        if ([categories containsObject:generatedCategory]) {
            found = YES;
        }

        callback(found);
    }];
 }

+ (void)downloadAttachment:(NSString *)mediaUrl withCompletedContentCallback:(void (^)(UNNotificationAttachment *attachment, NSError *error))callback {

    __block UNNotificationAttachment *attachment = nil;
    __block NSURL *attachmentURL = [NSURL URLWithString:mediaUrl];
    __weak NSURLSession *session = [NSURLSession sharedSession];

    [[session downloadTaskWithURL:attachmentURL
                completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {

                    NSInteger statusCode = 0;
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                    if ([httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
                        statusCode = httpResponse.statusCode;

                        if (statusCode != 200) {
                            DebugLog(@"Status Code was not 200 (was %ld) and produced the following error: %@", (long) statusCode, error, nil);
                            callback(nil, error);
                        }
                    }

                    if (error != nil) {
                        DebugLog(@"Media download failed with the following error: %@", error, nil);
                        callback(nil, error);
                    } else {
                        NSString *fileExt = [NSString stringWithFormat:@".%@", [[attachmentURL lastPathComponent] pathExtension]];
                        NSURL *localURL = [NSURL fileURLWithPath:[location.path stringByAppendingString:fileExt]];
                        [[NSFileManager defaultManager] moveItemAtURL:location toURL:localURL error:&error];
                        NSError *attError = nil;
                        attachment = [UNNotificationAttachment attachmentWithIdentifier:@"" URL:localURL options:nil error:&attError];

                        //clean up
                        localURL = nil;
                        fileExt = nil;

                        if (attError) {
                            DebugLog(@"Attachment creation failed with the following error: %@", attError, nil);
                            callback(nil, attError);
                        } else {
                            callback(attachment, error);
                        }
                    }
                }] resume];
}

/** older version of iOS handling **/
+ (NSURL *)notificationEngaged:(NSDictionary *)userInfo {

    if ([self canProcessEngageNotification:userInfo] == NO) {
        return nil;
    }
    NSURL *deeplinkUrl = nil;

    NSString *notificationId = [self notificationIdFromUserInfo:userInfo];

    // Engagement replaces Influence Data
    id <SwrveCommonDelegate> swrveCommon = (id <SwrveCommonDelegate>) [SwrveCommon sharedInstance];
    [SwrveCampaignInfluence removeInfluenceDataForId:notificationId fromAppGroupId:swrveCommon.appGroupIdentifier];

    // get deeplink if there is one, but pass it back up so it can be processed by calling code
    deeplinkUrl = [self deeplinkFromUserInfo:userInfo];

    // send the engagement
    [self sendEngagedEventForNotificationId:notificationId andUserInfo:userInfo];

    // check for campaign, if present try to load
    [self loadCampaignFromNotification:userInfo];

    return deeplinkUrl;
}

+ (NSURL *)notificationResponseReceived:(NSString *)identifier withUserInfo:(NSDictionary *)userInfo {

    if ([self canProcessEngageNotification:userInfo] == NO) {
        return nil;
    }
    NSURL *deeplinkUrl = nil;

    NSString *notificationId = [self notificationIdFromUserInfo:userInfo];

    // Engagement replaces Influence Data
    id <SwrveCommonDelegate> swrveCommon = (id <SwrveCommonDelegate>) [SwrveCommon sharedInstance];
    [SwrveCampaignInfluence removeInfluenceDataForId:notificationId fromAppGroupId:swrveCommon.appGroupIdentifier];

    if ([identifier isEqualToString:SwrveNotificationResponseDefaultActionKey]) {
        DebugLog(@"Performed a direct press on Swrve notification with id %@", notificationId);

        // get deeplink if there is one, but pass it back up so it can be processed by calling code
        deeplinkUrl = [self deeplinkFromUserInfo:userInfo];

        // send engaged event
        [self sendEngagedEventForNotificationId:notificationId andUserInfo:userInfo];

        // check for campaign, if present try to load
        [self loadCampaignFromNotification:userInfo];
    } else {
        NSDictionary *sw = [userInfo objectForKey:SwrveNotificationContentIdentifierKey];
        NSArray *swrvebuttons = [sw objectForKey:SwrveNotificationButtonListKey];
        if (swrvebuttons != nil && [swrvebuttons count] > 0) {
            int position = [identifier intValue];
            NSDictionary *selectedButton = [swrvebuttons objectAtIndex:(NSUInteger) position];

            // get deeplink if there is one, but pass it back up so it can be processed by calling code
            deeplinkUrl = [self deeplinkFromButton:selectedButton];

            // send button click event
            NSString *actionText = [selectedButton objectForKey:SwrveNotificationButtonTitleKey];
            NSString *campaignType = [self campaignTypeFromUserInfo:userInfo];
            NSMutableDictionary *eventPayload = [[NSMutableDictionary alloc] init];
            if ([campaignType isEqualToString:SwrveNotificationCampaignTypeGeo]) {
                if ([userInfo objectForKey:SwrveNotificationEventPayload]) {
                    NSMutableDictionary *geoPayload = [userInfo objectForKey:SwrveNotificationEventPayload];
                    eventPayload = [geoPayload mutableCopy];
                }
            }
            [self sendButtonClickEventForNotificationId:notificationId
                                        andCampaignType:campaignType
                                           andContextId:identifier
                                          andActionText:actionText
                                             andPayload:eventPayload];

            // send engaged event
            [self sendEngagedEventForNotificationId:notificationId andUserInfo:userInfo];

            // check for open campaign action, if present try to load
            [self loadCampaignFromButton:selectedButton];
        } else {
            DebugLog(@"Notification pressed with an unrecognised identifier %@", identifier);
        }
    }

    return deeplinkUrl;
}

+ (BOOL)canProcessEngageNotification:(NSDictionary *)userInfo {
    BOOL canProcess = NO;
    NSString *notificationIdentifierString = [self notificationIdFromUserInfo:userInfo];
    if (!notificationIdentifierString || [notificationIdentifierString isEqualToString:@"-1"]) {
        DebugLog(@"Got unidentified notification", nil);
    } else {
        if (lastProcessedPushId == nil || [notificationIdentifierString isEqualToString:@"0"] || ![notificationIdentifierString isEqualToString:lastProcessedPushId]) {
            canProcess = YES;
        } else {
            DebugLog(@"Got Swrve notification with id %@, ignoring as we already processed it", notificationIdentifierString);
        }
    }
    return canProcess;
}

+ (NSString *)notificationIdFromUserInfo:(NSDictionary *)userInfo {
    NSString *notificationIdString = @"-1";
    id notificationId = [userInfo objectForKey:SwrveNotificationIdentifierKey];
    if ([notificationId isKindOfClass:[NSString class]]) {
        notificationIdString = (NSString *) notificationId;
    } else if ([notificationId isKindOfClass:[NSNumber class]]) {
        notificationIdString = [((NSNumber *) notificationId) stringValue];
    }
    return notificationIdString;
}

+ (NSURL *)deeplinkFromUserInfo:(NSDictionary *)userInfo {
    NSURL *deeplinkUrl = nil;
    // deeplink _sd (and old _d)
    id deeplinkRaw = [userInfo objectForKey:SwrveNotificationDeeplinkKey];
    if (deeplinkRaw == nil || ![deeplinkRaw isKindOfClass:[NSString class]]) {
        // Retrieve old push deeplink for backwards compatibility
        deeplinkRaw = [userInfo objectForKey:SwrveNotificationDeprecatedDeeplinkKey];
    }
    if ([deeplinkRaw isKindOfClass:[NSString class]]) {
        NSString *deeplinkString = (NSString *) deeplinkRaw;
        deeplinkUrl = [self deeplinkFromUrl:deeplinkString];
    }
    return deeplinkUrl;
}

+ (NSURL *)deeplinkFromUrl:(NSString *)deeplinkString {
    NSURL *deeplinkUrl = [NSURL URLWithString:deeplinkString];
    BOOL canOpen = [[SwrveCommon sharedUIApplication] canOpenURL:deeplinkUrl];
    if (deeplinkUrl != nil && canOpen) {
        DebugLog(@"SwrveNotificationManager: Deeplink - %@ - found.  Sending to application as URL", deeplinkString);
    } else {
        DebugLog(@"SwrveNotificationManager: Could not process deeplink - %@", deeplinkString);
        deeplinkUrl = nil;
    }
    return deeplinkUrl;
}

+ (NSURL *)deeplinkFromButton:(NSDictionary *)selectedButton {
    NSURL *deeplinkUrl = nil;
    NSString *action = [selectedButton objectForKey:SwrveNotificationButtonActionKey];
    NSString *actionType = [selectedButton objectForKey:SwrveNotificationButtonActionTypeKey];
    // get the deeplink if available in Action
    if ([actionType isEqualToString:SwrveNotificationCustomButtonUrlIdentiferKey]) {
        deeplinkUrl = [self deeplinkFromUrl:action];
    }
    return deeplinkUrl;
}

+ (void)sendButtonClickEventForNotificationId:(NSString *)notificationId
                              andCampaignType:(NSString *)campaignType
                                 andContextId:(NSString *)contextId
                                andActionText:(NSString *)actionText
                                   andPayload:(NSMutableDictionary *)eventPayload {
    DebugLog(@"Selected Button:'%@' on Swrve notification with id: %@ and campaignType: %@", contextId, notificationId, campaignType);

    id <SwrveCommonDelegate> swrveCommon = (id <SwrveCommonDelegate>) [SwrveCommon sharedInstance];
    NSMutableDictionary *eventData = [[NSMutableDictionary alloc] init];
    [eventData setValue:notificationId forKey:@"id"];
    [eventData setValue:campaignType forKey:@"campaignType"];
    [eventData setValue:@"button_click" forKey:@"actionType"];
    [eventData setValue:contextId forKey:@"contextId"];
    [eventPayload setValue:actionText forKey:@"buttonText"]; // add the buttonText to the eventPayload
    [eventData setValue:eventPayload forKey:@"payload"];

    // Create generic campaign for button click
    [swrveCommon queueEvent:@"generic_campaign_event" data:eventData triggerCallback:false];
    [swrveCommon sendQueuedEvents];
}

+ (void)sendEngagedEventForNotificationId:(NSString *)notificationId andUserInfo:(NSDictionary *)userInfo {

    id <SwrveCommonDelegate> swrveCommon = (id <SwrveCommonDelegate>) [SwrveCommon sharedInstance];
    NSString *campaignType = [self campaignTypeFromUserInfo:userInfo];
    if ([campaignType isEqualToString:SwrveNotificationCampaignTypeGeo]) {

        NSMutableDictionary *eventData = [[NSMutableDictionary alloc] init];
        [eventData setValue:notificationId forKey:@"id"];
        [eventData setValue:@"geo" forKey:@"campaignType"];
        [eventData setValue:@"engaged" forKey:@"actionType"];
        if ([userInfo objectForKey:SwrveNotificationEventPayload]) {
            NSMutableDictionary *eventPayload = [userInfo objectForKey:SwrveNotificationEventPayload];
            if (eventPayload && [eventPayload count] > 0) {
                [eventData setValue:eventPayload forKey:@"payload"];
            }
        }

        [swrveCommon queueEvent:@"generic_campaign_event" data:eventData triggerCallback:false];
        [swrveCommon sendQueuedEvents];

    } else {
        [swrveCommon sendPushNotificationEngagedEvent:notificationId]; // default to regular push
    }
}

+ (NSString *)campaignTypeFromUserInfo:(NSDictionary *)userInfo {
    NSString *campaignType = SwrveNotificationCampaignTypePush; // default to push
    if ([userInfo objectForKey:SwrveNotificationCampaignTypeKey]) {
        campaignType = [userInfo objectForKey:SwrveNotificationCampaignTypeKey];
    }
    return campaignType;
}

+ (void)loadCampaignFromNotification:(NSDictionary *)userInfo {
    NSDictionary *sw = [userInfo objectForKey:SwrveNotificationContentIdentifierKey];
    NSString *swrveCampaignId = [self campaignIdFromNotificationPayload:sw];
    if (swrveCampaignId != nil) {
        [SwrveNotificationManager loadCampaign:swrveCampaignId];
    }
}

+ (NSString *)campaignIdFromNotificationPayload:(NSDictionary *)payload {
    NSString *campaignId = nil;
    if (payload && [payload objectForKey:SwrveCampaignKey]) {
        NSDictionary *campaignDict = [payload objectForKey:SwrveCampaignKey];
        if (campaignDict && [campaignDict objectForKey:@"id"]) {
            campaignId = [campaignDict objectForKey:@"id"];
        }
    }
    return campaignId;
}

+ (void)loadCampaignFromButton:(NSDictionary *)selectedButton {
    NSString *actionType = [selectedButton objectForKey:SwrveNotificationButtonActionTypeKey];
    if ([actionType isEqualToString:SwrveNotificaitonCustomButtonCampaignIdentiferKey]) {
        // in this scenario action should be the campaign id
        NSString *action = [selectedButton objectForKey:SwrveNotificationButtonActionKey];
        [SwrveNotificationManager loadCampaign:action];
    }
}

+ (void)loadCampaign:(NSString *)campaignId {
    if (campaignId == nil) {
        return;
    }
    DebugLog(@"Loading campaign %@ from notification.", campaignId);
    id <SwrveCommonDelegate> swrveCommon = (id <SwrveCommonDelegate>) [SwrveCommon sharedInstance];
    [swrveCommon handleNotificationToCampaign:campaignId];
}

#endif //!TARGET_OS_TV
@end

#endif //#if !defined(SWRVE_NO_PUSH)
