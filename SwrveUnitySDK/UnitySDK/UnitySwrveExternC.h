#import "UnitySwrveHelper.h"
#import "UnitySwrveCommon.h"
#import "UnitySwrveCommonMessageController.h"
#import "SwrvePlotDelegate.h"

extern "C"
{
    char* _swrveiOSGetLanguage()
    {
        return [UnitySwrveHelper GetLanguage];
    }
    
    char* _swrveiOSGetTimeZone()
    {
        return [UnitySwrveHelper GetTimeZone];
    }
    
    char * _swrveiOSGetAppVersion()
    {
        return [UnitySwrveHelper GetAppVersion];
    }
    
    char* _swrveiOSUUID()
    {
        return [UnitySwrveHelper GetUUID];
    }
    
    char* _swrveiOSCarrierName()
    {
        return [UnitySwrveHelper GetCarrierName];
    }
    
    char* _swrveiOSCarrierIsoCountryCode()
    {
        return [UnitySwrveHelper GetCarrierIsoCountryCode];
    }
    
    char* _swrveiOSCarrierCode()
    {
        return [UnitySwrveHelper GetCarrierCode];
    }
    
    char* _swrveiOSLocaleCountry()
    {
        return [UnitySwrveHelper GetLocaleCountry];
    }
    
//    char* _swrveIDFA()
//    {
//        return swrveCStringCopy(UnityAdvertisingIdentifier());
//    }
    
    char* _swrveiOSIDFV()
    {
        return [UnitySwrveHelper GetIDFV];
    }
    
    void _swrveiOSRegisterForPushNotifications()
    {
        return [UnitySwrveHelper RegisterForPushNotifications];
    }
    
    void _swrveiOSInitNative(char* jsonConfig)
    {
        [UnitySwrveCommon init:jsonConfig];
    }
    
    const char* _swrveiOSGetConversationResult()
    {
        return [UnitySwrveHelper NSStringCopy:@"[]"];
    }
    
    void _swrveiOSShowConversation(char* conversation)
    {
        [[UnitySwrveCommonMessageController alloc] showConversationFromString:[UnitySwrveHelper CStringToNSString:conversation]];
    }
    
    void _swrveiOSStartPlot()
    {
        [[SwrvePlotDelegate sharedInstance] startPlot];
    }
}

/*
 
 
+(char*) _swrveIDFA
{
    return [UnitySwrveHelper swrveCStringCopy:UnityAdvertisingIdentifier()];
}
 
@interface UnityAppControllerSub : UnityAppController {
}
@end

@implementation UnityAppControllerSub

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [SwrvePlotDelegate sharedInstance].launchOptions = launchOptions;
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo
{
    UIApplicationState swrveState = [application applicationState];
    BOOL swrveInBackground = (swrveState == UIApplicationStateInactive || swrveState == UIApplicationStateBackground);
    if (!swrveInBackground) {
        NSMutableDictionary* mutableUserInfo = [userInfo mutableCopy];
        [mutableUserInfo setValue:@"YES" forKey:@"_swrveForeground"];
        userInfo = mutableUserInfo;
    }
}

#if !UNITY_TVOS
- (void)application:(UIApplication*)application didReceiveLocalNotification:(UILocalNotification*)notification
{
    [[SwrvePlotDelegate sharedInstance] didReceiveLocalNotification:notification];
}
#endif

@end
IMPL_APP_CONTROLLER_SUBCLASS(UnityAppControllerSub);
*/
