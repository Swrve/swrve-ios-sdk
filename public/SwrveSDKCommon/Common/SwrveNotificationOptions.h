#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

@interface SwrveNotificationOptions : NSObject

#if !TARGET_OS_TV

+ (UNNotificationCategoryOptions)categoryOptionsForKeys:(NSArray *)keys;
+ (UNNotificationActionOptions)actionOptionsForKeys:(NSArray *)key;

#endif

@end
