#import "AppDelegate.h"
#import  "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

@synthesize window;
@synthesize swizzleDeviceToken;
@synthesize swizzleError;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // A default window set frame to avoid use of storyboard
    ViewController *vc = [[ViewController alloc] init];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
#pragma unused(application)
    self.swizzleDeviceToken = deviceToken; // Needed to test metthod Swizzleing
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
#pragma unused(application)
    self.swizzleError = error; //// Needed to test metthod Swizzleing
}

@end
