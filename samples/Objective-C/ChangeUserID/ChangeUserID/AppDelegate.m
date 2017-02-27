#import "AppDelegate.h"
#import "SwrveIdentityUtils.h"

@interface AppDelegate ()
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//  Override point for customization after application launch.
//  Configure SwrveConfig as normal.  The most common steps include setting the
//  Swrve stack you'll send data to and enabling push notifications.
    SwrveConfig* config = [[SwrveConfig alloc] init];
    config.pushEnabled = YES;

//  You need to disable method Swizzling for this solution to work
    config.autoCollectDeviceToken = NO;
    
//  Set the user_id to the last known user
//  If it is the first session set it to nil which will initialize an empty SDK
    NSString* userID = [[NSUserDefaults standardUserDefaults] stringForKey:@"userID"];
    if (!userID) {
        userID = nil;
    }
    
//  Initialize the identity utility.  See documentation in SwrveIdentityUtils to
//  learn about what this utility does
    self.identityUtils = [[SwrveIdentityUtils alloc] init];

//  ----------------------------------------
//  |ENTER YOUR OWN APP_ID AND API KEY HERE |
//  ----------------------------------------
    int appID = 0;
    NSString * apiKey = @"your_api_key_here";
    
    
    [self.identityUtils createSDKInstance:appID apiKey:apiKey config:config userID:userID launchOptions:launchOptions];
    
    return YES;
}


//  Needed to disable Method Swizzling. This is sends the device token to Swrve
//  to allow Push Notifications
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    if ([Swrve sharedInstance].talk != nil) {
        [[Swrve sharedInstance].talk setDeviceToken:deviceToken];
    }
}
//  Needed to disable Method Swizzling. This is used to send the push engaged
//  event to Swrve for tracking campaign metrics
-(void) application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [[Swrve sharedInstance].talk pushNotificationReceived:userInfo];
}


@end

