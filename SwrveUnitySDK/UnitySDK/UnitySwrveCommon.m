#import "UnitySwrveCommon.h"

static UnitySwrveCommon *_swrveSharedUnity = NULL;
static dispatch_once_t sharedInstanceToken = 0;

@implementation UnitySwrveCommon

+(UnitySwrveCommon*) sharedInstance
{
    dispatch_once(&sharedInstanceToken, ^{
        _swrveSharedUnity = [UnitySwrveCommon alloc];
    });
    return _swrveSharedUnity;
}

+(void) init:(char*)jsonConfig {
    [UnitySwrveCommon sharedInstance];
}

-(NSData*) getCampaignData:(int)category {
    if(SWRVE_CAMPAIGN_LOCATION == category) {
        return [@"{\"1\":{\"version\":1,\"message\":{\"id\":1,\"body\":\"Swrve Dublin office ENTER. This should open deeplink to ios Data tab swrve://deeplink/data\",\"payload\":\"{\\\"_sd\\\":\\\"swrve://deeplink/data\\\"}\"}},\"2\":{\"version\":1,\"message\":{\"id\":2,\"body\":\"Dom Swrve Dublin office EXIT.\",\"payload\":\"{}\"}},\"12\":{\"version\":1,\"message\":{\"id\":12,\"body\":\"Dom campaign brookwood Exit\\nLabel is: ${geofence.label}\",\"payload\":\"{}\"}},\"13\":{\"version\":1,\"message\":{\"id\":13,\"body\":\"Dundalk enter\",\"payload\":\"{}\"}},\"14\":{\"version\":1,\"message\":{\"id\":14,\"body\":\"Dundalk exit\",\"payload\":\"{}\"}},\"21\":{\"version\":1,\"message\":{\"id\":21,\"body\":\"Dom Fairview Enter\",\"payload\":\"{}\"}},\"43\":{\"version\":1,\"message\":{\"id\":39,\"body\":\"Swrve Dublin Phoenix Park Enter\",\"payload\":\"{}\"}},\"176\":{\"version\":1,\"message\":{\"id\":155,\"body\":\"Dom Bull Island Exit. Label is: ${geofence.label}\",\"payload\":\"{}\"}},\"177\":{\"version\":1,\"message\":{\"id\":156,\"body\":\"Dom campaign brookwood Enter. Label:${geofence.label}\",\"payload\":\"{}\"}}}" dataUsingEncoding:NSUTF8StringEncoding];
    }
    return nil;
}

-(BOOL) processPermissionRequest:(NSString*)action { return TRUE; }
-(void) sendQueuedEvents { }
-(int) eventInternal:(NSString*)eventName payload:(NSDictionary*)eventPayload triggerCallback:(bool)triggerCallback { return SWRVE_SUCCESS; }
-(int) userUpdate:(NSDictionary*)attributes { return SWRVE_SUCCESS; }
-(void) setLocationVersion:(NSString *)version { }

@end
