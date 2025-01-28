
#import "SwrveTestHelper.h"
#import <SwrveSDK/SwrveSDK-Swift.h>

@interface SwrveNotificationManager()
+ (void)updateLastProcessedPushId:(NSString *)pushId;
@end

@interface Swrve()
@property(atomic) NSURL *eventFilename;
@property(atomic) NSMutableArray *eventBuffer;
- (void)processNotificationResponseWithIdentifier:(NSString *)identifier andUserInfo:(NSDictionary *)userInfo notificationRequestId:(NSString *)notificationRequestId;
- (NSString *)signatureKey;
@end

