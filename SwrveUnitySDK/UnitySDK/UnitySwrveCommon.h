#import "SwrveCommon.h"

@interface UnitySwrveCommon : NSObject<ISwrveCommon>

+(UnitySwrveCommon*) sharedInstance;
+(void) init:(char*)jsonConfig;

@end
