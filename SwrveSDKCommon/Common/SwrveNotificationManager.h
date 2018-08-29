#if !defined(SWRVE_NO_PUSH)

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

@interface SwrveNotificationManager : NSObject

#if !TARGET_OS_TV

+ (void) handleContent:(UNNotificationContent *)notificationContent
    withCompletionCallback:(void (^)(UNMutableNotificationContent *content))completion;


/** older version of iOS handling **/
+ (NSURL *)notificationEngaged:(NSDictionary *)userInfo;

+ (NSURL *)notificationResponseReceived:(NSString *)identifier withUserInfo:(NSDictionary *)userInfo;

#endif //!TARGET_OS_TV
@end

#endif //#if !defined(SWRVE_NO_PUSH)
