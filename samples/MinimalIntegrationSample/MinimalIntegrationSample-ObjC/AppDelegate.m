#import "AppDelegate.h"
#import "SwrveSDK.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    SwrveConfig *config = [SwrveConfig new];
    // To use the EU stack, include this in your config.
    // config.Stack = SWRVE_STACK_EU;
    
    //FIXME: Replace <app_id> and "<api_key>" with your app ID and API key.
#if DEBUG
    [SwrveSDK sharedInstanceWithAppID:-1 apiKey:@"<sandbox_api_key>" config:config];
#else
    [SwrveSDK sharedInstanceWithAppID:-1 apiKey:@"<production_api_key>" config:config];
#endif
    
    return YES;
}

@end
