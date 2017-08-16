#if !defined(SWRVE_NO_PUSH)
/**
 Push Class built with the purpose of returning a correct NotificationContent object when given a class
 **/

#import <Foundation/Foundation.h>
#import "SwrveCommon.h"
#import <UserNotifications/UserNotifications.h>

@interface SwrvePushMediaHelper : NSObject

+ (UNMutableNotificationContent *) produceMediaTextFromProvidedContent:(UNNotificationContent *)notificationContent;
+ (void)downloadAttachment:(NSString *)mediaUrl withCompletedContentCallback:(void (^)(UNNotificationAttachment *attachment, NSError *error)) callback;
+ (UNNotificationCategory *) produceButtonsFromUserInfo:(NSDictionary *)userInfo;
+ (UNNotificationActionOptions) actionOptionsForKeys:(NSArray *) keys;
+ (UNNotificationCategoryOptions) categoryOptionsForKeys:(NSArray *) keys;

@end

#endif //#if !defined(SWRVE_NO_PUSH)

