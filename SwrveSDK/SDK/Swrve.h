#import "SwrveProtocol.h"

#if __has_include(<SwrveSDKCommon/SwrveCommon.h>)

#import <SwrveSDKCommon/SwrveSignatureProtectedFile.h>
#import <SwrveSDKCommon/SwrveCommon.h>
#import <SwrveSDKCommon/SwrveAssetsManager.h>
#else
#import "SwrveSignatureProtectedFile.h"
#import "SwrveCommon.h"
#import "SwrveAssetsManager.h"
#endif


#if TARGET_OS_IOS
#if __has_include(<SwrveSDKCommon/SwrvePush.h>)

#import <SwrveSDKCommon/SwrvePush.h>

#else
#import "SwrvePush.h"
#endif /** has_include **/


/*! Swrve SDK main class. */
@interface Swrve : NSObject <Swrve, SwrveSignatureErrorDelegate, SwrvePushDelegate>
#else
@interface Swrve : NSObject<Swrve, SwrveSignatureErrorDelegate>
#endif //TARGET_OS_IOS

@end

//TODO: This definition should move to SwrveInAppMessageConfig file after complete migration

/*! A block that will be called when an event triggers an in-app message with personalization
 * \param eventPayload the payload associated with the message
 * \returns NSDictionary of key / value strings used for personalising the IAM
 */
typedef NSDictionary *(^SwrveMessagePersonalizationCallback)(NSDictionary *eventPayload);
