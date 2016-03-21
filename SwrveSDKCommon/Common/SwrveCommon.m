#import "SwrveCommon.h"

static id<SwrveCommonDelegate> _iSwrveCommon = NULL;

@implementation SwrveCommon

+(void) setSwrveCommon:(id<SwrveCommonDelegate>)swrveCommon
{
    _iSwrveCommon = swrveCommon;
}

+(id<SwrveCommonDelegate>) getSwrveCommon
{
    return _iSwrveCommon;
}

@end
