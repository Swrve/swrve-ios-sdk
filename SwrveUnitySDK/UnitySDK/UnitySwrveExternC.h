#import "UnitySwrveHelper.h"
#import "UnitySwrveCommon.h"
#import "UnitySwrveCommonMessageController.h"
#import "SwrveBaseConversation.h"

#ifdef __cplusplus
extern "C"
{
#endif
    
    int _swrveiOSConversationVersion()
    {
        return CONVERSATION_VERSION;
    }
    
    char* _swrveiOSGetLanguage()
    {
        return [UnitySwrveHelper GetLanguage];
    }
    
    char* _swrveiOSGetTimeZone()
    {
        return [UnitySwrveHelper GetTimeZone];
    }
    
    char* _swrveiOSGetAppVersion()
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
    
    char* _swrveiOSIDFV()
    {
        return [UnitySwrveHelper GetIDFV];
    }
    
    char* _swrveiOSIDFA()
    {
        return [UnitySwrveHelper GetIDFA];
    }
    
    void _swrveiOSRegisterForPushNotifications(char* jsonCategorySet)
    {
        return [UnitySwrveHelper RegisterForPushNotifications:[UnitySwrveHelper CStringToNSString:jsonCategorySet]];
    }
    
    void _swrveiOSInitNative(char* jsonConfig)
    {
        [UnitySwrveCommonDelegate init:jsonConfig];
    }
    
    void _swrveiOSShowConversation(char* conversation)
    {
        [[UnitySwrveMessageEventHandler alloc] showConversationFromString:[UnitySwrveHelper CStringToNSString:conversation]];
    }
    
    void _swrveiOSStartPlot()
    {
        [[UnitySwrveCommonDelegate sharedInstance] initLocation];
    }

#ifdef __cplusplus
}
#endif
