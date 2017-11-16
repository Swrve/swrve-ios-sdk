#if !defined(SWRVE_NO_PUSH)
#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>
#import "SwrveCommon.h"

@protocol SwrvePushResponseDelegate <NSObject>

@optional
- (void)didReceiveNotificationResponse:(UNNotificationResponse *)response
                 withCompletionHandler:(void(^)(void))completionHandler __IOS_AVAILABLE(10.0);

- (void) willPresentNotification:(UNNotification *)notification
           withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler __IOS_AVAILABLE(10.0);

@end

@interface SwrvePush : NSObject <UNUserNotificationCenterDelegate>

#pragma mark - Static Methods
/** Rich Push Management **/


/*! Processes APNs Notification that comes in from a Service Extension
 *  and adds all the additional campaign content.
 *  App Group Intentifier is used for storing influence so it can be tracked by Swrve in the Main App.
 */
+ (void)handleNotificationContent:(UNNotificationContent *) notificationContent withAppGroupIdentifier:(NSString *)appGroupIdentifier
     withCompletedContentCallback:(void (^)(UNMutableNotificationContent * content))callback;

@end
#endif //!defined(SWRVE_NO_PUSH)
