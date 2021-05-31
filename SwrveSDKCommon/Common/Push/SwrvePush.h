#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>
#import "SwrveCommon.h"

NS_ASSUME_NONNULL_BEGIN
extern NSString *const SwrveContentVersionKey;

@protocol SwrvePushDelegate <NSObject>

- (void)deviceTokenIncoming:(NSData *)newDeviceToken;
- (void)deviceTokenUpdated:(NSString *)newDeviceToken;
- (void)deeplinkReceived:(NSURL *)url;

@end

@protocol SwrvePushResponseDelegate <NSObject>
#if !TARGET_OS_TV
@optional
- (void)didReceiveNotificationResponse:(UNNotificationResponse *)response
                 withCompletionHandler:(void (^)(void))completionHandler __IOS_AVAILABLE(10.0);

- (void)willPresentNotification:(UNNotification *)notification
          withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler __IOS_AVAILABLE(10.0);

#endif
@end

@interface SwrvePush : NSObject <UNUserNotificationCenterDelegate>
#if !TARGET_OS_TV
#pragma mark - Static Methods
/** Rich Push Management **/

/*! Processes APNs Notification that comes in from a Service Extension
 *  and adds all the additional campaign content.
 *  App Group Identifier is used for storing influence so it can be tracked by Swrve in the Main App.
 */
+ (void)handleNotificationContent:(UNNotificationContent *)notificationContent
           withAppGroupIdentifier:(nullable NSString *)appGroupIdentifier
     withCompletedContentCallback:(void (^)(UNMutableNotificationContent *content))callback __IOS_AVAILABLE(10.0) __TVOS_AVAILABLE(10.0);

#endif
@end

NS_ASSUME_NONNULL_END
