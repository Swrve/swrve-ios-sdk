#import "SwrveProtocol.h"
#import "SwrveConfig.h"

#if __has_include(<SwrveSDKCommon/SwrveCommon.h>)

#import <SwrveSDKCommon/SwrveSignatureProtectedFile.h>
#import <SwrveSDKCommon/SwrveCommon.h>

#else
#import "SwrveSignatureProtectedFile.h"
#import "SwrveCommon.h"
#endif

#if !defined(SWRVE_NO_PUSH) && TARGET_OS_IOS
#if __has_include(<SwrveSDKCommon/SwrvePush.h>)

#import <SwrveSDKCommon/SwrvePush.h>

#else
#import "SwrvePush.h"
#endif /** has_include **/

/*! Swrve SDK main class. */
@interface Swrve : NSObject <Swrve, SwrveSignatureErrorDelegate, SwrvePushDelegate>
#else
@interface Swrve : NSObject<Swrve, SwrveSignatureErrorDelegate>
#endif /* !defined(SWRVE_NO_PUSH)*/

@end
