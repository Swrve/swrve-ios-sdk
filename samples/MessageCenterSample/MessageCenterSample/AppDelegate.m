#import "AppDelegate.h"
#import "Swrve.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    SwrveConfig* config = [[SwrveConfig alloc] init];
    config.resourcesUpdatedCallback = ^() {
        // New campaigns are available
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SwrveUserResourcesUpdated" object:self];
    };
    [Swrve sharedInstanceWithAppID:YOUR_APP_ID apiKey:@"YOUR_API_KEY" config:config launchOptions:launchOptions];
    return YES;
}

@end
