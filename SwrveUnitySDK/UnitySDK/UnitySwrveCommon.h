#import "SwrveCommon.h"

// #define SWRVE_LOCATIONSDK

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
