#import "SwrveCommon.h"

static id<SwrveCommonDelegate> _iSwrveCommon = NULL;

@implementation SwrveCommon

+(void) addSharedInstance:(id<SwrveCommonDelegate>)swrveCommon
{
    _iSwrveCommon = swrveCommon;
}

+(id<SwrveCommonDelegate>) sharedInstance
{
    return _iSwrveCommon;
}

@end
