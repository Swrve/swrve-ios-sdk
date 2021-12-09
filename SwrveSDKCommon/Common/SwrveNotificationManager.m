#import "SwrveCommon.h"
#import "SwrveNotificationManager.h"
#import "SwrveNotificationOptions.h"
#import "SwrveCampaignInfluence.h"
#import "SwrveNotificationConstants.h"
#import "SwrveLocalStorage.h"
#import "SwrveUser.h"
#import "SwrveUtils.h"

// Apple might call different AppDelegate callbacks that could end up calling the Swrve SDK with the same push payload.
// This would result in bad engagement reports etc. The lastProcessedPushId var is used to check that the same push id
// can't be processed in sequence.
static NSString *lastProcessedPushId = nil;

@interface SwrveUser ()
+ (NSString *)md5FromSource:(NSString *)source;
@end

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
    UNNotificationCategory *generatedCategory = [self categoryFromUserInfo:mutableNotificationContent.userInfo];

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
                if (categories == nil) {
                    categories = [NSMutableSet set];
                }
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
                }else{
                    [self verifyCategoryGenerated:generatedCategory withCompletedCallback:^(BOOL foundCategory) {
                        #pragma unused (foundCategory)
                        // at this point, if we do not have the category, we should exit anyway
                        dispatch_group_leave(notificationGroup);
                    }];
                }
            }];
        }];
    }
    
    NSDictionary *sw = [mutableNotificationContent.userInfo objectForKey:SwrveNotificationContentIdentifierKey];
    NSDictionary *mediaDict = [sw objectForKey:SwrveNotificationMediaKey];
    // clean up
    sw = nil;

    NSString *mediaUrl = [mediaDict objectForKey:SwrveNotificationUrlKey];
    if (mediaUrl) {
        dispatch_group_enter(notificationGroup);
        
        //check cache first
        UNNotificationAttachment  *cachedAttachment = [self attachmentFromCache:mediaUrl inCacheDir:[SwrveLocalStorage swrveCacheFolder]];
        if (cachedAttachment != nil) {
            mutableNotificationContent.attachments = [NSMutableArray arrayWithObject:cachedAttachment];
            [self mediaTextFromProvidedContent:mutableNotificationContent];
            [SwrveLogger debug:@"SwrveNotificationManager: primary attachment loaded from cache, returning to callback"];
            dispatch_group_leave(notificationGroup);
        } else {

            [self downloadAttachment:mediaUrl withCompletedContentCallback:^(UNNotificationAttachment *attachment, NSError *error) {
                
                if (error) {
                    [SwrveLogger error:@"SwrveNotificationManager: attachment failed download with the following error: %@", error, nil];
                }
                if (attachment) {
                    mutableNotificationContent.attachments = [NSMutableArray arrayWithObject:attachment];
                    [self mediaTextFromProvidedContent:mutableNotificationContent];
                    [SwrveLogger debug:@"SwrveNotificationManager: primary attachment successfully downloaded, returning to callback", nil];
                    dispatch_group_leave(notificationGroup);
                } else if (mediaDict[SwrveNotificationFallbackUrlKey] != nil) {
                    
                    //check cache first
                    UNNotificationAttachment *fallBackCachedAttachment = [self attachmentFromCache:mediaDict[SwrveNotificationFallbackUrlKey] inCacheDir:[SwrveLocalStorage swrveCacheFolder]];
                    
                    if (fallBackCachedAttachment != nil) {
                        mutableNotificationContent.attachments = [NSMutableArray arrayWithObject:fallBackCachedAttachment];
                        [self mediaTextFromProvidedContent:mutableNotificationContent];
                        [SwrveLogger debug:@"SwrveNotificationManager: fallback attachment loaded from cache, returning to callback", nil];
                        dispatch_group_leave(notificationGroup);
                    } else {
                        // Download fallback image
                        [self downloadAttachment:mediaDict[SwrveNotificationFallbackUrlKey] withCompletedContentCallback:^(UNNotificationAttachment *fallbackAttachment, NSError *fallbackError) {
                            
                            if (fallbackError) {
                                [SwrveLogger error:@"SwrveNotificationManager: fallback attachment failed download with the following error: %@", fallbackError, nil];
                            }

                            if (fallbackAttachment) {
                                // Fallback image has worked
                                mutableNotificationContent.attachments = [NSMutableArray arrayWithObject:fallbackAttachment];
                                [self mediaTextFromProvidedContent:mutableNotificationContent];
                                [SwrveLogger debug:@"SwrveNotificationManager: fallback attachment successfully downloaded, returning to callback", nil];
                                
                                // Set fallback_sd if available
                                if (mediaDict[SwrveNotificationFallbackDeeplinkKey] != nil) {
                                    [SwrveLogger debug:@"SwrveNotificationManager: fallback Deeplink detected, modifying notificationContent.userInfo", nil];
                                    NSMutableDictionary *moddedUserInfo = [mutableNotificationContent.userInfo mutableCopy];
                                    [moddedUserInfo setObject:mediaDict[SwrveNotificationFallbackDeeplinkKey] forKey:SwrveNotificationDeeplinkKey];
                                    mutableNotificationContent.userInfo = moddedUserInfo;
                                    // clean up
                                    moddedUserInfo = nil;
                                }
                                
                            } else {
                                [SwrveLogger error:@"SwrveNotificationManager: fallback attachment error occurred, removing all attachments. Error: %@", fallbackError];
                                [self setMediaDownloadFailed:mutableNotificationContent];
                            }
                            
                            // Finished async fallback download task
                            dispatch_group_leave(notificationGroup);
                        }];
                    }
                    
                } else {
                    // There is no fallback attachment
                    [SwrveLogger error:@"SwrveNotificationManager: primary attachment error occurred, removing all attachments. Error: %@", error];
                    [self setMediaDownloadFailed:mutableNotificationContent];
                    dispatch_group_leave(notificationGroup);
                }
            }];
        }
    }
    
    dispatch_group_notify(notificationGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        /** Everything is finished, return the result **/
        completion(mutableNotificationContent);
    });
}

+ (UNMutableNotificationContent *)mediaTextFromProvidedContent:(UNMutableNotificationContent *)content __IOS_AVAILABLE(10.0) __TVOS_AVAILABLE(10.0) {
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

+ (UNNotificationCategory *)categoryFromUserInfo:(NSDictionary *)userInfo __IOS_AVAILABLE(10.0) __TVOS_AVAILABLE(10.0) {
    NSDictionary *richDict = [userInfo objectForKey:SwrveNotificationContentIdentifierKey];
    NSArray *buttons = [richDict valueForKey:SwrveNotificationButtonListKey];
    NSArray *options = [richDict objectForKey:SwrveNotificationCategoryOptionsKey];
    
    if(buttons == nil && options == nil) {
        return nil;
    }
    
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
    }

    NSMutableArray *intentIdentifiers = [NSMutableArray array];
    NSString *categoryKey = [NSString stringWithFormat:@"swrve-%@-%@", [userInfo objectForKey:SwrveNotificationIdentifierKey], [[NSUUID UUID] UUIDString]];
    UNNotificationCategoryOptions categoryOptions = [SwrveNotificationOptions categoryOptionsForKeys:options];
    NSString *hiddenPlaceholder = [richDict objectForKey:SwrveNotificationHiddenPreviewTextPlaceholderKey];
    UNNotificationCategory *category;
    
    if(@available(iOS 11.0, *)) {
        if (hiddenPlaceholder != nil && [hiddenPlaceholder length] > 0) {
            category = [UNNotificationCategory categoryWithIdentifier:categoryKey actions:actions intentIdentifiers:intentIdentifiers hiddenPreviewsBodyPlaceholder:hiddenPlaceholder options:categoryOptions];
        } else {
            category = [UNNotificationCategory categoryWithIdentifier:categoryKey actions:actions intentIdentifiers:intentIdentifiers options:categoryOptions];
        }
    } else {
        category = [UNNotificationCategory categoryWithIdentifier:categoryKey actions:actions intentIdentifiers:intentIdentifiers options:categoryOptions];
    }
    
    return category;
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

+ (void)downloadAttachment:(NSString *)mediaUrl withCompletedContentCallback:(void (^)(UNNotificationAttachment *attachment, NSError *error))callback __IOS_AVAILABLE(10.0) __TVOS_AVAILABLE(10.0) {

    __block UNNotificationAttachment *attachment = nil;
    __block NSURL *attachmentURL = [NSURL URLWithString:mediaUrl];
    NSURLSession *session = nil;
    
    id <SwrveCommonDelegate> swrveCommon = (id <SwrveCommonDelegate>) [SwrveCommon sharedInstance];
    id <NSURLSessionDelegate> del = swrveCommon.urlSessionDelegate;
    if (del){
        session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                delegate:del
                                           delegateQueue:NSOperationQueue.mainQueue];
    } else {
        session = [NSURLSession sharedSession];
    }

    [[session downloadTaskWithURL:attachmentURL
                completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {

                    NSInteger statusCode = 0;
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                    if ([httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
                        statusCode = httpResponse.statusCode;
                        if (statusCode != 200) {
                            [SwrveLogger error:@"SwrveNotificationManager: Status Code was not 200 (was %ld) and produced the following error: %@", (long) statusCode, error, nil];
                            callback(nil, error);
                        }
                    }

                    if (error != nil) {
                        [SwrveLogger error:@"SwrveNotificationManager: Media download failed with the following error: %@", error, nil];
                        callback(nil, error);
                    } else {
                        NSString *fileExt = nil;

                        // By default use the extension of the URL (backwards compatibility)
                        NSString *extFromURL = [attachmentURL pathExtension];
                        if (extFromURL != nil && [extFromURL length] != 0) {
                            fileExt = [NSString stringWithFormat:@".%@", extFromURL];
                        }

                        // If there is no extension try use the MIME type
                        if (!fileExt) {
                            NSString *mimeType = [httpResponse MIMEType];
                            if (mimeType) {
                                NSString *inferredFileExtension = [SwrveNotificationManager fileExtensionFromMIMEType:mimeType];
                                if (inferredFileExtension) {
                                    fileExt = [@"." stringByAppendingString:inferredFileExtension];
                                }
                            }
                        }

                        if (fileExt) {
                            NSURL *localURL = [NSURL fileURLWithPath:[location.path stringByAppendingString:fileExt]];
                            [[NSFileManager defaultManager] moveItemAtURL:location toURL:localURL error:&error];
                            NSError *attError = nil;
                            attachment = [UNNotificationAttachment attachmentWithIdentifier:@"" URL:localURL options:nil error:&attError];

                            // Clean up
                            localURL = nil;
                            fileExt = nil;

                            if (attError) {
                                [SwrveLogger error:@"SwrveNotificationManager: Attachment creation failed with the following error: %@", attError, nil];
                                callback(nil, attError);
                            } else {
                                callback(attachment, error);
                            }
                        } else {
                            // Could not obtain extension from media path
                            NSString *errorMsg = @"SwrveNotificationManager: Could not obtain extension from media path";
                            NSError *swrveMessage = [NSError errorWithDomain:@"com.swrve" code:200
                                                           userInfo: @{NSLocalizedDescriptionKey:errorMsg}];
                            [SwrveLogger error:errorMsg, nil];
                            callback(nil, swrveMessage);
                        }
                    }
                }] resume];
}

+ (NSString *)fileExtensionFromMIMEType: (NSString *)mimeType {
    NSDictionary *mimeToFileExtension = [NSDictionary dictionaryWithObjectsAndKeys:
            @"jpeg", @"image/jpeg",
            @"bmp", @"image/bmp",
            @"jpg", @"image/jpg",
            @"png", @"image/png", // [RFC-2045], [RFC-2048]
            @"png", @"image/x-png",
            @"gif", @"image/gif",
            @"mp3", @"audio/mpeg",
            @"mp4", @"video/mp4", nil];
    return [mimeToFileExtension objectForKey:[mimeType lowercaseString]];
}

+ (UNNotificationAttachment *)attachmentFromCache:(NSString *)externalUrlString inCacheDir:(NSString *)cacheDir  API_AVAILABLE(ios(10.0)){
    UNNotificationAttachment *attachment = nil;
    NSURL *externalUrl = [NSURL URLWithString:externalUrlString];
    NSURL *attachmentURL;
    if ([externalUrl pathExtension] == nil || [[externalUrl pathExtension] length] == 0) {
        attachmentURL = [self cachedUrlWithoutFileExtension:externalUrl inCacheDir:cacheDir];
    } else {
        attachmentURL = [self cachedUrlFor:externalUrl withPathExtension:[externalUrl pathExtension] inCacheDir:cacheDir];
    }

    BOOL fileExists = attachmentURL && [[NSFileManager defaultManager] fileExistsAtPath:[attachmentURL path]];
    if (!fileExists) {
        [SwrveLogger debug:@"SwrveNotificationManager: no local cache for:%@", externalUrlString, nil];
    } else {
        //Create a copy of attachment url. The attachments are deleted when the notificaiton is shown.
        //We want to keep them on disk.
        NSError *copyError = nil;
        NSURL *tempDirUrl = [NSURL fileURLWithPath:NSTemporaryDirectory()];
        NSURL *tempAttachmentURL = [tempDirUrl URLByAppendingPathComponent:[attachmentURL lastPathComponent]];
        [[NSFileManager defaultManager] copyItemAtURL:attachmentURL toURL:tempAttachmentURL error:&copyError];
        
        if (copyError) {
            [SwrveLogger error:@"SwrveNotificationManager: attachment copy failed with the following error: %@", [copyError localizedDescription]];
        }
        
        NSError *attachmentError = nil;
        attachment = [UNNotificationAttachment attachmentWithIdentifier:@"" URL:tempAttachmentURL options:nil error:&attachmentError];
        if (attachmentError) {
            [SwrveLogger error:@"SwrveNotificationManager: attachment creation failed with the following error: %@", [attachmentError localizedDescription]];
        }
        if (attachment) {
            [SwrveLogger debug:@"SwrveNotificationManager: successfully got attachment from cache: %@", externalUrlString];
        }
    }
    return attachment;
}

// used when file extension is known
+ (NSURL *)cachedUrlFor:(NSURL *)externalUrl withPathExtension:(NSString *)pathExtension inCacheDir:(NSString *)cacheDir {

    if (pathExtension == nil || [pathExtension length] == 0) {
        return nil;
    }

    // use hash of external url for name, but preserve the file extension
    NSURL *cacheDirUrl = [NSURL URLWithString:cacheDir];
    NSString *hashedName = [SwrveUser md5FromSource:[externalUrl absoluteString]];
    hashedName = [[hashedName stringByAppendingString:@"."] stringByAppendingString:pathExtension];
    return [NSURL fileURLWithPathComponents:[NSArray arrayWithObjects:[cacheDirUrl path], hashedName, nil]];
}

// used when file extension is not known
+ (NSURL *)cachedUrlWithoutFileExtension:(NSURL *)externalUrl inCacheDir:(NSString *)cacheDir {

    // when no file extension available then iterate through files in cache and match against any file of that name
    NSURL *cacheDirUrl = [NSURL URLWithString:cacheDir];
    NSString *hashedName = [SwrveUser md5FromSource:[externalUrl absoluteString]];
    NSURL *cachedUrl = nil;
    NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtURL:cacheDirUrl
                                                          includingPropertiesForKeys:nil
                                                                             options:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles
                                                                        errorHandler:nil];
    for (NSURL *file in dirEnum) {
        if ([[file lastPathComponent] hasPrefix:hashedName] && [[file pathExtension] length] > 0) {
            cachedUrl = file;
            break;
        }
    }
    return cachedUrl;
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
        [SwrveLogger debug:@"SwrveNotificationManager: Performed a direct press on Swrve notification with id %@", notificationId];

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
            NSMutableDictionary *eventPayload = [NSMutableDictionary new];
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
            [SwrveLogger error:@"SwrveNotificationManager: Notification pressed with an unrecognised identifier %@", identifier];
        }
    }

    return deeplinkUrl;
}

+ (BOOL)canProcessEngageNotification:(NSDictionary *)userInfo {
    BOOL canProcess = NO;
    NSString *notificationIdentifierString = [self notificationIdFromUserInfo:userInfo];
    if (!notificationIdentifierString || [notificationIdentifierString isEqualToString:@"-1"]) {
        [SwrveLogger debug:@"SwrveNotificationManager: Got unidentified notification", nil];
    } else {
        if (lastProcessedPushId == nil || [notificationIdentifierString isEqualToString:@"0"] || ![notificationIdentifierString isEqualToString:lastProcessedPushId]) {
            lastProcessedPushId = notificationIdentifierString;
            canProcess = YES;
        } else {
            [SwrveLogger debug:@"SwrveNotificationManager: Got Swrve notification with id %@, ignoring as we already processed it", notificationIdentifierString];
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

+ (NSURL *)deeplinkFromUrl:(NSString *)deeplinkString NS_EXTENSION_UNAVAILABLE_IOS("") {
    NSURL *deeplinkUrl = [NSURL URLWithString:deeplinkString];
    BOOL canOpen = [[SwrveCommon sharedUIApplication] canOpenURL:deeplinkUrl];
    if (deeplinkUrl != nil && canOpen) {
        [SwrveLogger debug:@"SwrveNotificationManager: Deeplink - %@ - found.  Sending to application as URL", deeplinkString];
    } else {
        [SwrveLogger error:@"SwrveNotificationManager: Could not process deeplink - %@", deeplinkString];
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
    [SwrveLogger debug:@"SwrveNotificationManager: Selected Button:'%@' on Swrve notification with id: %@ and campaignType: %@", contextId, notificationId, campaignType];

    id <SwrveCommonDelegate> swrveCommon = (id <SwrveCommonDelegate>) [SwrveCommon sharedInstance];
    NSMutableDictionary *eventData = [NSMutableDictionary new];
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

        NSMutableDictionary *eventData = [NSMutableDictionary new];
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
            campaignId = [SwrveUtils getStringFromDic:campaignDict withKey:@"id"];
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
    [SwrveLogger debug:@"SwrveNotificationManager: Loading campaign %@ from notification.", campaignId];
    id <SwrveCommonDelegate> swrveCommon = (id <SwrveCommonDelegate>) [SwrveCommon sharedInstance];
    [swrveCommon handleNotificationToCampaign:campaignId];
}

+ (void)clearAllAuthenticatedNotifications API_AVAILABLE(ios(10.0)) {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> *_Nonnull notifications) {
        NSMutableArray *identifierArray = [SwrveNotificationManager authenticatedNotificationsFrom:notifications];
        if ([identifierArray count] > 0) {
            [center removeDeliveredNotificationsWithIdentifiers:identifierArray];
        }
    }];
}

+ (NSMutableArray *)authenticatedNotificationsFrom:(NSArray<UNNotification *> *)notifications API_AVAILABLE(ios(10.0)) {
    NSMutableArray *identifierArray = [NSMutableArray new];
    for (UNNotification* notification in notifications) {
        if (notification != nil && notification.request != nil && notification.request.content != nil && notification.request.content.userInfo != nil) {
            NSDictionary *userInfo = notification.request.content.userInfo;
            if ([userInfo objectForKey:SwrveNotificationAuthenticatedUserKey]) {
                [identifierArray addObject:notification.request.identifier];
            }
        }
    }
    return identifierArray;
}

+ (UNMutableNotificationContent *)setMediaDownloadFailed:(UNMutableNotificationContent *)mutableNotificationContent API_AVAILABLE(ios(10.0)) {
    NSMutableDictionary *moddedUserInfo = [mutableNotificationContent.userInfo mutableCopy];
    moddedUserInfo[SwrveNotificationMediaDownloadFailed] = @YES;
    mutableNotificationContent.userInfo = moddedUserInfo;
    return mutableNotificationContent;
}


#endif //!TARGET_OS_TV
@end
