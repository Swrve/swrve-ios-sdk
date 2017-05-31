/**
 Main Push Class for SwrveSDK. Also used by Unity on iOS builds
 **/

#if !defined(SWRVE_NO_PUSH)

#import <Foundation/Foundation.h>
#import "SwrveCommon.h"

@protocol SwrvePushDelegate <NSObject>

- (void) sendPushEngagedEvent:(NSString*)pushId;
- (void) deviceTokenIncoming:(NSData *)newDeviceToken;
- (void) deviceTokenUpdated:(NSString *)newDeviceToken;
- (void) remoteNotificationReceived:(NSDictionary *)notificationInfo;

@end

@interface SwrvePush : NSObject

+ (SwrvePush*) sharedInstance;
+ (SwrvePush*) sharedInstanceWithPushDelegate:(id<SwrvePushDelegate>) pushDelegate andCommonDelegate:(id<SwrveCommonDelegate>) commonDelegate;
+ (void) resetSharedInstance;

- (void) setCommonDelegate:(id<SwrveCommonDelegate>) commonDelegate;
- (void) setPushDelegate:(id<SwrvePushDelegate>) pushDelegate;

- (void) registerForPushNotifications;
- (BOOL) observeSwizzling;
- (void) deswizzlePushMethods;

- (void) setPushNotificationsDeviceToken:(NSData*) newDeviceToken;
- (void) checkLaunchOptionsForPushData:(NSDictionary *) launchOptions;
- (void) pushNotificationReceived:(NSDictionary *)userInfo;
- (void) silentPushReceived:(NSDictionary*)userInfo withCompletionHandler:(void (^)(UIBackgroundFetchResult, NSDictionary*))completionHandler;

// Called by Unity
+ (void) saveInfluencedData:(NSDictionary*)userInfo withPushId:(NSString*)pushId atDate:(NSDate*)date;

- (void) processInfluenceData;

@end

#endif

