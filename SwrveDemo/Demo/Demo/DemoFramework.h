#import "Menu.h"

/*
 * Main entry point for demos.
 */
@interface DemoFramework : UIResponder <UIApplicationDelegate, UINavigationControllerDelegate, UITabBarControllerDelegate>{
}

/*
 * Initializes the Swrve Track and Talk SDKs using the api key and app id
 * stored in the user settings.
 */
+(void) intializeSwrveSdk;

/*
 * A global object you can use to send event data to Swrve.
 */
+(Swrve *) getSwrve;

/*
 * A global object you can use to show messages to your users.
 */
+(SwrveMessageController*) getSwrveTalk;

/*
 * A global object that manages resources that can be overriden by Swrve AB tests.
 */
+(DemoResourceManager *) getDemoResourceManager;

/*
 * A global object used to track behavior in the Demo Framework.  Do not use.
 */
+(Swrve *) getSwrveInternal;

@end
