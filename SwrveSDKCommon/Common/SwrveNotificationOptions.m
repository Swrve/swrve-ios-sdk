#import "SwrveNotificationOptions.h"
#import "SwrveNotificationConstants.h"

@implementation SwrveNotificationOptions

#if !TARGET_OS_TV

+ (UNNotificationCategoryOptions)categoryOptionsForKeys:(NSArray *)keys {// API_AVAILABLE(ios(10.0)){
    UNNotificationCategoryOptions options = UNNotificationCategoryOptionNone;
    if (keys == nil || [keys count] < 1) {
        options = UNNotificationCategoryOptionNone;
    } else {
        for (NSString *key in keys) {
            options |= [self categoryOptionForKey:key];
        }
    }
    return options;
}

+ (UNNotificationCategoryOptions)categoryOptionForKey:(NSString *)key __IOS_AVAILABLE(10.0) __TVOS_AVAILABLE(10.0) {

    if ([key isEqualToString:SwrveNotificationCategoryTypeOptionsCustomDismissKey]) {
        return UNNotificationCategoryOptionCustomDismissAction;
    }

    if ([key isEqualToString:SwrveNotificationCategoryTypeOptionsCarPlayKey]) {
        return UNNotificationCategoryOptionAllowInCarPlay;
    }
    
    if(@available(iOS 11.0,*)){
        if([key isEqualToString:SwrveNotificationCategoryTypeOptionsHiddenShowTitleKey]) {
            return UNNotificationCategoryOptionHiddenPreviewsShowTitle;
        }
        
        if([key isEqualToString:SwrveNotificationCategoryTypeOptionsHiddenShowSubtitleKey]) {
            return UNNotificationCategoryOptionHiddenPreviewsShowSubtitle;
        }
    }
    
    return UNNotificationCategoryOptionNone;
}

+ (UNNotificationActionOptions)actionOptionsForKeys:(NSArray *)keys {// API_AVAILABLE(ios(10.0)){
    UNNotificationActionOptions options = UNNotificationActionOptionNone;
    if (keys == nil || [keys count] < 1) {
        options = UNNotificationActionOptionNone;
    } else {
        for (NSString *key in keys) {
            options |= [self actionOptionForKey:key];
        }
    }
    return options;
}

+ (UNNotificationActionOptions)actionOptionForKey:(NSString *)key __IOS_AVAILABLE(10.0) __TVOS_AVAILABLE(10.0) {

    if ([key isEqualToString:SwrveNotificationActionTypeForegroundKey]) {
        return UNNotificationActionOptionForeground;
    }

    if ([key isEqualToString:SwrveNotificationActionTypeDestructiveKey]) {
        return UNNotificationActionOptionDestructive;
    }

    if ([key isEqualToString:SwrveNotificationActionTypeAuthorisationKey]) {
        return UNNotificationActionOptionAuthenticationRequired;
    }

    return UNNotificationActionOptionNone;
}

#endif

@end
