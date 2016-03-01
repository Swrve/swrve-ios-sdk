#import "SwrveCommon.h"

static id<ISwrveCommon> _iSwrveCommon = NULL;

@interface SwrveCommon ()

@end

@implementation SwrveCommon

+(void) setSwrveCommon:(id<ISwrveCommon>)swrveCommon
{
    _iSwrveCommon = swrveCommon;
}

+(id<ISwrveCommon>) getSwrveCommon
{
    return _iSwrveCommon;
}

@end
