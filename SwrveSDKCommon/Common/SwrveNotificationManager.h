#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

@interface SwrveNotificationManager : NSObject

#if !TARGET_OS_TV

+ (void) handleContent:(UNNotificationContent *)notificationContent
withCompletionCallback:(void (^)(UNMutableNotificationContent *content))completion __IOS_AVAILABLE(10.0) __TVOS_AVAILABLE(10.0);

+ (NSURL *)notificationResponseReceived:(NSString *)identifier withUserInfo:(NSDictionary *)userInfo;

+ (void)clearAllAuthenticatedNotifications;

#endif //!TARGET_OS_TV
@end
