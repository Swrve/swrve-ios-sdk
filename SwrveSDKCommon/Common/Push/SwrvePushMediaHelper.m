#if !defined(SWRVE_NO_PUSH)
#import "SwrvePushMediaHelper.h"
#import "SwrvePushConstants.h"

@implementation SwrvePushMediaHelper


+ (UNMutableNotificationContent *) produceMediaTextFromProvidedContent:(UNMutableNotificationContent *)content {
    
    NSDictionary *richDict = [content.userInfo objectForKey:SwrvePushContentIdentifierKey];
    NSDictionary *mediaDict = [richDict objectForKey:SwrvePushMediaKey];
    
    if(mediaDict){
        if([mediaDict objectForKey:SwrvePushTitleKey]){
            content.title = [mediaDict objectForKey:SwrvePushTitleKey];
        }
        
        if([mediaDict objectForKey:SwrvePushSubtitleKey]){
            content.subtitle = [mediaDict objectForKey:SwrvePushSubtitleKey];
        }
        
        if([mediaDict objectForKey:SwrvePushBodyKey]){
            content.body = [mediaDict objectForKey:SwrvePushBodyKey];
        }
    }
    
    return content;
}

+ (void)downloadAttachment:(NSString *)mediaUrl withCompletedContentCallback:(void (^)(UNNotificationAttachment *attachment, NSError *error)) callback {
    
    __block UNNotificationAttachment *attachment = nil;
    __block NSURL *attachmentURL = [NSURL URLWithString:mediaUrl];
    __weak NSURLSession *session = [NSURLSession sharedSession];
    
    [[session downloadTaskWithURL:attachmentURL
                completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                    
                    NSInteger statusCode = 0;
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    if ([httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
                        statusCode = httpResponse.statusCode;
                        
                        if(statusCode != 200){
                            DebugLog(@"Status Code was not 200 (was %ld) and produced the following error: %@", (long)statusCode, error, nil);
                            callback(nil, error);
                        }
                    }
                    
                    if (error != nil) {
                        DebugLog(@"Media download failed with the following error: %@",error, nil);
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
                            DebugLog(@"Attachment creation failed with the following error: %@",attError, nil);
                            callback(nil, attError);
                        }else{
                            callback(attachment, error);
                        }
                    }
                }] resume];
}

+ (UNNotificationCategory *) produceButtonsFromUserInfo:(NSDictionary *)userInfo {
    
    NSDictionary *richDict = [userInfo objectForKey:SwrvePushContentIdentifierKey];
    NSArray *buttons = [richDict valueForKey:SwrvePushButtonListKey];
    
    int customButtonIndex = 0;
    NSMutableArray *actions = [NSMutableArray array];
    
    if(buttons != nil && [buttons count] > 0){
        for(NSDictionary *button in buttons){
            NSString *buttonId = [NSString stringWithFormat:@"%d", customButtonIndex];
            NSString *buttonTitle = [button objectForKey:SwrvePushButtonTitleKey];
            NSArray *buttonOptions = [button objectForKey:SwrvePushButtonTypeKey];
            
            UNNotificationAction* actionButton = [UNNotificationAction actionWithIdentifier:buttonId title:buttonTitle options:[self actionOptionsForKeys:buttonOptions]];
            [actions addObject:actionButton];
            NSLog(@"Added Action: %@", actionButton);
            customButtonIndex++;
        }
        
        NSMutableArray *intentIdentifiers = [NSMutableArray array];
    
        NSString *categoryKey = [NSString stringWithFormat:@"swrve-%@-%@", [userInfo objectForKey:SwrvePushIdentifierKey], [[NSUUID UUID] UUIDString]];
        UNNotificationCategory* category = [UNNotificationCategory categoryWithIdentifier:categoryKey actions:actions intentIdentifiers:intentIdentifiers options:[self categoryOptionsForKeys:[richDict objectForKey:SwrvePushButtonOptionsKey]]];
        return category;
    } else{
        return nil;
    }
}

+ (UNNotificationActionOptions) actionOptionsForKeys:(NSArray *) keys {
    
    if(keys == nil || [keys count] < 1){
        return UNNotificationActionOptionNone;
    }else{
        UNNotificationActionOptions result = UNNotificationActionOptionNone;
        for(NSString *key in keys){
            result |= [self actionOptionForKey:key];
        }
        return result;
    }
    return UNNotificationActionOptionNone;
}

+ (UNNotificationCategoryOptions) categoryOptionsForKeys:(NSArray *) keys {
    
    if(keys == nil || [keys count] < 1){
        return UNNotificationCategoryOptionNone;
    }else{
        UNNotificationCategoryOptions result = UNNotificationCategoryOptionNone;
        for(NSString *key in keys){
            result |= [self categoryOptionForKey:key];
        }
        
        return result;
    }
    return UNNotificationCategoryOptionNone;
}

+ (UNNotificationCategoryOptions) categoryOptionForKey:(NSString *) key {
    
    if([key isEqualToString:SwrvePushCategoryTypeOptionsCustomDismissKey]){
        return UNNotificationCategoryOptionCustomDismissAction;
    }
    
    if([key isEqualToString:SwrvePushCategoryTypeOptionsCarPlayKey]){
        return UNNotificationCategoryOptionAllowInCarPlay;
    }
    
    return UNNotificationCategoryOptionNone;
}

+ (UNNotificationActionOptions) actionOptionForKey:(NSString *) key {
    
    if([key isEqualToString:SwrvePushActionTypeForegroundKey]){
        return UNNotificationActionOptionForeground;
    }
    
    if([key isEqualToString:SwrvePushActionTypeDestructiveKey]){
        return UNNotificationActionOptionDestructive;
    }
    
    if([key isEqualToString:SwrvePushActionTypeAuthorisationKey]){
        return UNNotificationActionOptionAuthenticationRequired;
    }
    
    return UNNotificationActionOptionNone;
}

@end
#endif //#if !defined(SWRVE_NO_PUSH)
