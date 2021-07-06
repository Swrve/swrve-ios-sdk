#import "AppDelegate.h"
#import <SwrveSDK/SwrveSDK.h>
#import <SwrveSDKCommon/SwrvePush.h>

@interface AppDelegate () <SwrvePushResponseDelegate>
@end

@implementation AppDelegate

NSString * const NotificationCategoryIdentifier  = @"com.swrve.sampleAppButtons";
NSString * const NotificationActionOneIdentifier = @"ACTION1";
NSString * const NotificationActionTwoIdentifier = @"ACTION2";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    SwrveConfig *config = [SwrveConfig new];

    // Set the response delegate before swrve is intialised
    config.pushResponseDelegate = self;
    // Set the app group if you want influence to be tracked
    config.appGroupIdentifier = @"group.swrve.RichPushSample";

    config.pushEnabled = YES;
    config.notificationCategories = [self produceUNNotificationCategory];

    // FIXME: Add your App ID (instead of -1) and your API Key (instead of <API_KEY>) here.
    [SwrveSDK sharedInstanceWithAppID:-1 apiKey:@"<API_KEY>" config:config];
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Set Application badge number to 0
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

#pragma mark - notification response handling

/** SwrvePushResponseDelegate Methods **/

- (void) didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    NSLog(@"Got iOS 10 Notification with Identifier - %@", response.actionIdentifier);

    // Include your own code in here
    if(completionHandler) {
        completionHandler();
    }
}

- (void) willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {

    // Include your own code in here
    if(completionHandler) {
        completionHandler(UNNotificationPresentationOptionNone);
    }
}

#pragma mark - example category generation

- (NSSet *) produceUNNotificationCategory {

    UNNotificationAction *fgAction = [UNNotificationAction actionWithIdentifier:NotificationActionOneIdentifier
                                                                          title:@"Foreground"
                                                                        options:UNNotificationActionOptionForeground];
    UNNotificationAction *bgAction = [UNNotificationAction actionWithIdentifier:NotificationActionTwoIdentifier
                                                                          title:@"Background"
                                                                        options:UNNotificationActionOptionNone];

    NSArray *notificationActions = @[fgAction, bgAction];

    UNNotificationCategory *exampleCategory = [UNNotificationCategory categoryWithIdentifier:
                                              NotificationCategoryIdentifier
                                                                                    actions:notificationActions
                                                                          intentIdentifiers:@[]
                                                                                    options:UNNotificationCategoryOptionNone];
    return [NSSet setWithObject:exampleCategory];
}

#pragma mark -
// Other generated app delegate methods (unused in this example)
- (void)applicationWillResignActive:(UIApplication *)application { }
- (void)applicationDidEnterBackground:(UIApplication *)application { }
- (void)applicationDidBecomeActive:(UIApplication *)application { }
- (void)applicationWillTerminate:(UIApplication *)application { }

@end
