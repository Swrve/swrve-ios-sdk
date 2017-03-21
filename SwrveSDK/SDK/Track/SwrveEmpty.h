#import <Foundation/Foundation.h>
#import "SwrveProtocol.h"

#if COCOAPODS
#import <SwrveSDKCommon/SwrveCommon.h>
#else
#import "SwrveCommon.h"
#endif

// Used at runtime when the SDK is not supported
@interface SwrveEmpty : NSObject<Swrve, SwrveCommonDelegate>

@property (atomic) int locationSegmentVersion;

@end
