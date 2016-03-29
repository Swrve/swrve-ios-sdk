#import "SwrveCommon.h"

// #define SWRVE_LOCATIONSDK
void UnitySendMessage(const char* obj, const char* method, const char* msg);

#ifdef SWRVE_LOCATIONSDK
#import "SwrvePlot.h"
@interface UnitySwrveCommonDelegate : NSObject<SwrveCommonDelegate, PlotDelegate>
#else
@interface UnitySwrveCommonDelegate : NSObject<SwrveCommonDelegate>
#endif

+(UnitySwrveCommonDelegate*) sharedInstance;
+(void) init:(char*)jsonConfig;

-(void) initLocation;

@end
