#if !defined(SWRVE_NO_PUSH)

#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

@interface SwrveNotificationOptions : NSObject

#if !TARGET_OS_TV

+ (UNNotificationCategoryOptions)categoryOptionsForKeys:(NSArray *)keys;
+ (UNNotificationActionOptions)actionOptionsForKeys:(NSArray *)keys;

#endif

@end

#endif //#if !defined(SWRVE_NO_PUSH)
