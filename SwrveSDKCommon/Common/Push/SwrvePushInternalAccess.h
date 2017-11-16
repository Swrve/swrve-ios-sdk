#if !defined(SWRVE_NO_PUSH)
#import "SwrvePush.h"
#import "SwrveCommon.h"

@protocol SwrvePushDelegate <NSObject>

- (void) sendPushEngagedEvent:(NSString*)pushId;
- (void) deviceTokenIncoming:(NSData *)newDeviceToken;
- (void) deviceTokenUpdated:(NSString *)newDeviceToken;
- (void) remoteNotificationReceived:(NSDictionary *)notificationInfo;
- (void) deeplinkReceived:(NSURL *)url;

@end

@interface SwrvePush (SwrvePushInternalAccess)

+ (SwrvePush*) sharedInstance;
+ (SwrvePush*) sharedInstanceWithPushDelegate:(id<SwrvePushDelegate>) pushDelegate andCommonDelegate:(id<SwrveCommonDelegate>) commonDelegate;
+ (void) resetSharedInstance;

- (void) setCommonDelegate:(id<SwrveCommonDelegate>) commonDelegate;
- (void) setPushDelegate:(id<SwrvePushDelegate>) pushDelegate;
- (void) setResponseDelegate:(id<SwrvePushResponseDelegate>) responseDelegate;

- (void) registerForPushNotifications;
- (BOOL) observeSwizzling;
- (void) deswizzlePushMethods;

- (void) setPushNotificationsDeviceToken:(NSData*) newDeviceToken;
- (void) checkLaunchOptionsForPushData:(NSDictionary *) launchOptions;
- (void) pushNotificationReceived:(NSDictionary *)userInfo;
- (void) pushNotificationResponseReceived:(NSString*)identifier withUserInfo:(NSDictionary *)userInfo;
- (BOOL) didReceiveRemoteNotification:(NSDictionary *)userInfo withBackgroundCompletionHandler:(void (^)(UIBackgroundFetchResult, NSDictionary*))completionHandler;

// Called by Unity
+ (void) saveInfluencedData:(NSDictionary*)userInfo withPushId:(NSString*)pushId atDate:(NSDate*)date;
- (void) clearInfluenceDataForPushId:(NSString *)pushID;
- (void) processInfluenceData;

@end
#endif
