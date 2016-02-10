#import "UnitySwrveHelper.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

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

+(void) RegisterForPushNotifications
{
    UIApplication* app = [UIApplication sharedApplication];
#ifdef __IPHONE_8_0
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
    // Check if the new push API is not available
    if (![app respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        // Use the old API
        [app registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
    }
    else
#endif
    {
        [app registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [app registerForRemoteNotifications];
    }
#else
    // Not building with the latest XCode that contains iOS 8 definitions
    [app registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
#endif
}

@end
