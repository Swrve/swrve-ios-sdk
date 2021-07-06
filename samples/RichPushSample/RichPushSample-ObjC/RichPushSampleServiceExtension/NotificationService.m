#import "NotificationService.h"
#import <SwrveSDKCommon/SwrvePush.h>

@interface NotificationService ()

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    self.contentHandler = contentHandler;
    [SwrvePush handleNotificationContent:[request content] withAppGroupIdentifier:@"group.swrve.RichPushSample" withCompletedContentCallback:^(UNMutableNotificationContent * content) {
        self.bestAttemptContent = content;
        self.contentHandler(self.bestAttemptContent);
    }];

}

- (void)serviceExtensionTimeWillExpire {
    self.contentHandler(self.bestAttemptContent);
}

@end
