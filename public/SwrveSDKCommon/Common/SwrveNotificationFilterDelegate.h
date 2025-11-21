#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

@protocol SwrveNotificationFilterDelegate <NSObject>
#if !TARGET_OS_TV
@optional

/**
 * Use this delegate in SwrveConfig to edit or filter authenticated push notifications.
 * \param notification The authenticated push notification
 * \param payload The userInfo dictionary used to construct the push notification. Additional payload values can be found here
 * \return The notification to be disaplyed, return nil to prevent or suppress the notification
 */
- (UNMutableNotificationContent *)filterNotification:(UNMutableNotificationContent *) notification withPayload:(NSDictionary *)payload;
#endif
@end
