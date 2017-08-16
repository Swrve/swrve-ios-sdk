#import "AppDelegate.h"

@interface AppDelegate ()
@end

@implementation AppDelegate

NSString * const NotificationCategoryIdentifier  = @"com.swrve.sampleAppButtons";
NSString * const NotificationActionOneIdentifier = @"ACTION1";
NSString * const NotificationActionTwoIdentifier = @"ACTION2";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    SwrveConfig* config = [[SwrveConfig alloc] init];
    
    // Set the response delegate before swrve is intialised
    config.pushResponseDelegate = self;
    // Set the app group if you want influence to be tracked
    config.appGroupIdentifier = @"group.swrve.RichPushSample";
    
    config.pushEnabled = YES;
    
    // If running below iOS 10 as well, it is best to include a runtime conditional around category generation
    if(([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0)){
         config.notificationCategories = [self produceUNNotificationCategory];
    }else{
         config.pushCategories = [self produceUIUserNotificationCategory];
    }
    
    // FIXME: Add your App ID (instead of -1) and your API Key (instead of <API_KEY>) here.
    [Swrve sharedInstanceWithAppID:-1 apiKey:@"<API_KEY>" config:config launchOptions:launchOptions];
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Set Application badge number to 0
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

#pragma mark - notification response handling

/** SwrvePushResponseDelegate Methods **/

- (void) didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
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

/** Pre-iOS 10 Category Handling **/
- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler {
    NSLog(@"Got Pre-iOS 10 Notification with Identifier - %@", identifier);
    
    // Include this method to ensure that you still log it to Swrve
    [[Swrve sharedInstance] processNotificationResponseWithIndentifier:identifier andUserInfo:userInfo];
    
    // Include your own code in here
    if (completionHandler) {
        completionHandler();
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

- (NSSet *) produceUIUserNotificationCategory {
    
    UIMutableUserNotificationAction *fgAction;
    fgAction = [[UIMutableUserNotificationAction alloc] init];
    [fgAction setActivationMode:UIUserNotificationActivationModeForeground];
    [fgAction setTitle:@"Foreground"];
    [fgAction setIdentifier:NotificationActionOneIdentifier];
    [fgAction setDestructive:NO];
    [fgAction setAuthenticationRequired:NO];
    
    UIMutableUserNotificationAction *bgAction;
    bgAction = [[UIMutableUserNotificationAction alloc] init];
    [bgAction setActivationMode:UIUserNotificationActivationModeBackground];
    [bgAction setTitle:@"Background"];
    [bgAction setIdentifier:NotificationActionTwoIdentifier];
    [bgAction setDestructive:NO];
    [bgAction setAuthenticationRequired:NO];
    
    UIMutableUserNotificationCategory *exampleCategory;
    exampleCategory = [[UIMutableUserNotificationCategory alloc] init];
    [exampleCategory setIdentifier:NotificationCategoryIdentifier];
    [exampleCategory setActions:@[fgAction, bgAction]
                    forContext:UIUserNotificationActionContextDefault];
    return [NSSet setWithObject:exampleCategory];
}

#pragma mark -
// Other generated app delegate methods (unused in this example)
- (void)applicationWillResignActive:(UIApplication *)application { }
- (void)applicationDidEnterBackground:(UIApplication *)application { }
- (void)applicationDidBecomeActive:(UIApplication *)application { }
- (void)applicationWillTerminate:(UIApplication *)application { }

@end
