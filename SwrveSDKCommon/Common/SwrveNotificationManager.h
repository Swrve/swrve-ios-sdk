#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

@interface SwrveNotificationManager : NSObject

#if !TARGET_OS_TV

+ (void) handleContent:(UNNotificationContent *)notificationContent
withCompletionCallback:(void (^)(UNMutableNotificationContent *content))completion;

+ (NSURL *)notificationResponseReceived:(NSString *)identifier withUserInfo:(NSDictionary *)userInfo notificationRequestId:(NSString *)notificationRequestId;

+ (void)clearAllAuthenticatedNotifications;

#endif //!TARGET_OS_TV
@end
