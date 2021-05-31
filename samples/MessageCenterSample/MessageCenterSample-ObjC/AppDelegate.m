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
    
    // The Swrve SDK creates new UIWindows to display content to avoid
    // creating issues for games etc. However, this means that the controllers
    // do not get their callbacks called.
    // We set this class as the delegate to listen to these events and notify any views interested.
    config.inAppMessageConfig.showMessageDelegate = self;
    
    //FIXME: Add your App ID (instead of -1) and your API Key (instead of <API_KEY>) here.
    [SwrveSDK sharedInstanceWithAppID:-1 apiKey:@"<API_KEY>" config:config];
    return YES;
}

- (void) messageWillBeHidden:(UIViewController*) viewController {
    // An in-app message or conversation will be hidden.
    // Notify the table view that the state of a campaign might have changed.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SwrveMessageWillBeHidden" object:self];
}


@end
