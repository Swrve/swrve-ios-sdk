#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

@interface SwrveNotificationOptions : NSObject

#if !TARGET_OS_TV

+ (UNNotificationCategoryOptions)categoryOptionsForKeys:(NSArray *)keys __IOS_AVAILABLE(10.0) __TVOS_AVAILABLE(10.0);
+ (UNNotificationActionOptions)actionOptionsForKeys:(NSArray *)key __IOS_AVAILABLE(10.0) __TVOS_AVAILABLE(10.0);

#endif

@end
