#import "UnitySwrveHelper.h"
#import "UnitySwrveCommon.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#ifndef SWRVE_NO_IDFA
#import <AdSupport/ASIdentifierManager.h>
#endif

@implementation UnitySwrveHelper

+(char*) CStringCopy:(const char*)string
{
    if (string == NULL)
        return NULL;
    
    char* res = (char*)malloc(strlen(string) + 1);
    strcpy(res, string);
    return res;
}

+(char*) NSStringCopy:(NSString*)string
{
    if([string length] == 0)
        return NULL;
    return [UnitySwrveHelper CStringCopy:[string UTF8String]];
}

+(NSString*) CStringToNSString:(char*)string
{
    if(string == NULL)
        return NULL;
    
    return [NSString stringWithUTF8String: string];
}

+(char*) GetLanguage
{
    NSString *preferredLang = [[NSLocale preferredLanguages] objectAtIndex:0];
    return [UnitySwrveHelper NSStringCopy:preferredLang];
}

+(char*) GetTimeZone
{
    NSTimeZone* tz = [NSTimeZone localTimeZone];
    NSString* timezone_name = [tz name];
    return [UnitySwrveHelper NSStringCopy:timezone_name];
}

+(char*) GetAppVersion
{
    NSString* appVersion = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
    if (!appVersion || [appVersion length] == 0) {
        appVersion = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"];
    }
    if (!appVersion || [appVersion length] == 0) {
        appVersion = @"";
    }
    return [UnitySwrveHelper NSStringCopy:appVersion];
}

+(char*) GetUUID
{
    NSString* swrveUUID = [[NSUUID UUID] UUIDString];
    return [UnitySwrveHelper NSStringCopy:swrveUUID];
}

+(char*) GetCarrierName
{
    Class telephonyClass = NSClassFromString(@"CTTelephonyNetworkInfo");
    if (telephonyClass) {
        id netinfo = [[telephonyClass alloc] init]; // CTTelephonyNetworkInfo
        id carrierInfo = [netinfo subscriberCellularProvider]; // CTCarrier
        if (carrierInfo != nil) {
            return [UnitySwrveHelper NSStringCopy:[carrierInfo carrierName]];
        }
    }
    return NULL;
}

+(char*) GetCarrierIsoCountryCode
{
    Class telephonyClass = NSClassFromString(@"CTTelephonyNetworkInfo");
    if (telephonyClass) {
        id netinfo = [[telephonyClass alloc] init]; // CTTelephonyNetworkInfo
        id carrierInfo = [netinfo subscriberCellularProvider]; // CTCarrier
        if (carrierInfo != nil) {
            return [UnitySwrveHelper NSStringCopy:[carrierInfo isoCountryCode]];
        }
    }
    return NULL;
}

+(char*) GetCarrierCode
{
    Class telephonyClass = NSClassFromString(@"CTTelephonyNetworkInfo");
    if (telephonyClass) {
        id netinfo = [[telephonyClass alloc] init]; // CTTelephonyNetworkInfo
        id carrierInfo = [netinfo subscriberCellularProvider]; // CTCarrier
        if (carrierInfo != nil) {
            NSString* mobileCountryCode = [carrierInfo mobileCountryCode];
            NSString* mobileNetworkCode = [carrierInfo mobileNetworkCode];
            if (mobileCountryCode != nil && mobileNetworkCode != nil) {
                NSMutableString* carrierCode = [[NSMutableString alloc] initWithString:mobileCountryCode];
                [carrierCode appendString:mobileNetworkCode];
                return [UnitySwrveHelper NSStringCopy:carrierCode];
            }
        }
    }
    return NULL;
}

+(char*) GetLocaleCountry
{
    NSString* localeCountry = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
    return [UnitySwrveHelper NSStringCopy:localeCountry];
}

+(char*) GetIDFV
{
    NSString *idfv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    return [UnitySwrveHelper NSStringCopy:idfv];
}

+(char*) GetIDFA
{
#ifndef SWRVE_NO_IDFA
    if([[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled])
    {
        NSString *idfa = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
        return [UnitySwrveHelper NSStringCopy:idfa];
    }
#endif
    return NULL;
}

#ifdef __IPHONE_8_0
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
+(NSSet*) categorySetFromJson:(NSString*)jsonString
{
    NSMutableSet* categorySet = nil;
    
    NSError* error = nil;
    NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    id jsonObj = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error: &error];
    if(nil == error)
    {
        for (NSDictionary* categoryDict in jsonObj)
        {
            UIMutableUserNotificationCategory *category =
                [[UIMutableUserNotificationCategory alloc] init];
            
            NSDictionary* contextActionsDict = (NSDictionary*)[categoryDict valueForKey:@"contextActions"];
            for(NSString* key in contextActionsDict)
            {
                NSMutableArray* actions = [[NSMutableArray alloc] init];
                for(NSDictionary* actionDict in [contextActionsDict objectForKey:key])
                {
                    UIMutableUserNotificationAction *action =
                        [[UIMutableUserNotificationAction alloc] init];
                    
                    action.identifier = [actionDict valueForKey:@"identifier"];
                    action.title = [actionDict valueForKey:@"title"];
                    action.activationMode = (0 == [[actionDict valueForKey:@"activationMode"] intValue] ?
                                             UIUserNotificationActivationModeForeground :
                                             UIUserNotificationActivationModeBackground);
                    
#ifdef __IPHONE_9_0
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_9_0
                    
                    UIUserNotificationActionBehavior behaviour = (0 == [[actionDict valueForKey:@"behaviour"] intValue] ?
                                                                  UIUserNotificationActionBehaviorDefault :
                                                                  UIUserNotificationActionBehaviorTextInput);
                    action.behavior = behaviour;
#endif
#endif //defined(__IPHONE_9_0)
                    
                    action.destructive = [[actionDict valueForKey:@"destructive"] boolValue];
                    action.authenticationRequired = [[actionDict valueForKey:@"authenticationRequired"] boolValue];
                    
                    [actions addObject:action];
                }
                
                if(0 == [actions count])
                {
                    continue;
                }
                
                UIUserNotificationActionContext context = (0 == [key intValue] ?
                                                           UIUserNotificationActionContextDefault :
                                                           UIUserNotificationActionContextMinimal);
                category.identifier = [categoryDict valueForKey:@"identifier"];
                [category setActions:actions forContext:context];
            }
            
            if(nil == categorySet)
            {
                categorySet = [[NSMutableSet alloc] init];
            }
            [categorySet addObject:category];
        }
    }
    
    return categorySet;
}
#endif
#endif //defined(__IPHONE_8_0)


+(void) RegisterForPushNotifications:(NSString*)jsonCategorySet
{
    UIApplication* appDelegate = [UIApplication sharedApplication];
    NSSet* pushCategories = nil;
#ifdef __IPHONE_8_0
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
    // Check if the new push API is not available
    if (![appDelegate respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        // Does not have iOS8 APIs
    }
    else
#endif
    {
        pushCategories = [self categorySetFromJson:jsonCategorySet];
        // NSLog(@"pushCategories: %@", pushCategories);
    }
#endif //defined(__IPHONE_8_0)
    
#if defined(__IPHONE_8_0)
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
    // Check if the new push API is not available
    if (![appDelegate respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        // Use the old API
        [appDelegate registerForRemoteNotificationTypes:(UIUserNotificationTypeSound |
                                                         UIUserNotificationTypeAlert |
                                                         UIUserNotificationTypeBadge)];
    }
    else
#endif
    //__IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0
    {        
        UIUserNotificationType notifType = (UIUserNotificationTypeSound |
                                            UIUserNotificationTypeAlert |
                                            UIUserNotificationTypeBadge);
        // NSLog(@"\n\nregisterFornNotifications:\n\n%lu\n\n%@\n", (unsigned long)notifType, pushCategories);
        [appDelegate registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:notifType
                                                                                        categories:pushCategories]];
        [appDelegate registerForRemoteNotifications];
    }
#else
    
    // Not building with the latest XCode that contains iOS 8 definitions
    [appDelegate registerForRemoteNotificationTypes:(UIUserNotificationTypeSound |
                                                     UIUserNotificationTypeAlert |
                                                     UIUserNotificationTypeBadge)];
#endif //defined(__IPHONE_8_0)
}

+(void) InitPlot
{
    [[UnitySwrveCommonDelegate sharedInstance] initLocation];
}

@end
