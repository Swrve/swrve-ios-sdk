#import <Foundation/Foundation.h>

#if __has_include(<SwrveSDK/SwrveProtocol.h>)
#import <SwrveSDK/SwrveProtocol.h>
#else
#import "SwrveProtocol.h"
#endif

#if __has_include(<SwrveSDKCommon/SwrveCommon.h>)
#import <SwrveSDKCommon/SwrveCommon.h>
#else
#import "SwrveCommon.h"
#endif

// Used at runtime when the SDK is not supported
@interface SwrveEmpty : NSObject<Swrve>

@end
