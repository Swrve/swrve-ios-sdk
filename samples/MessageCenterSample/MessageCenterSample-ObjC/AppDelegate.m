#import "AppDelegate.h"
#import "SwrveSDK.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    SwrveConfig *config = [SwrveConfig new];
    config.resourcesUpdatedCallback = ^() {
        // New campaigns are available
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SwrveUserResourcesUpdated" object:self];
    };

    //FIXME: Add your App ID (instead of -1) and your API Key (instead of <API_KEY>) here.
    [SwrveSDK sharedInstanceWithAppID:-1 apiKey:@"<API_KEY>" config:config];
    return YES;
}

@end
