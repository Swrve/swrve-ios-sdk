#import "DemoFramework.h"
#import "UserSettings.h"
#import "OnboardingFlow.h"

// API Demos
#import "TrackApiDemo.h"
#import "TalkApiDemo.h"
#import "GameAuthoritativeDemo.h"
#import "SwrveAuthoritativeDemo.h"

// Usecase Demos
#import "TutorialDemo.h"
#import "InAppPurchaseDemo.h"
#import "ItemPromotion.h"
#import "TransparencyDemo.h"

// Tools
#import "ResourceViewer.h"
#import "ABTestViewer.h"

// Settings
#import "SettingsView.h"

@implementation DemoFramework

static Swrve *swrveTrack;
static SwrveMessageController* swrveTalk;
static DemoResourceManager *resourceManager;

// SDK used to track usage of the Swrve Demo Framework App.  This SDK
// communicates with an internal Swrve app.  We use this to measure how often
// our customers are using this framework and what demos they are reviewing.
// You should not use this version of the SDK while experiementing with these
// demos.
static Swrve *swrveTrackInternal;

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    #pragma unused(launchOptions)
    
    // Initialize global defaults used by the app
    [UserSettings init];
    
    // Initialize sdk that points to customer game
    [DemoFramework intializeSwrveSdk];
    
    // Initialize the local resource manager.  This is used by the demos to look up values that can
    // be changed by AB tests in our dashboard.
    resourceManager = [[DemoResourceManager alloc] init];
    
    // Configure QA user id
    [DemoFramework getDemoResourceManager].userIdOverride = [UserSettings getQAUserIdIfEnabled];
    
    // Initialize an internal Swrve track SDK to measure demo usage.
    int swrveAppId = [UserSettings getSwrveAppId].intValue;
    NSString* swrveApiKey = [UserSettings getSwrveAppApiKey];
    // Take the user id override from the demo settings
    NSString* userOverride = [DemoFramework getDemoResourceManager].userIdOverride;

    SwrveConfig* config = [[SwrveConfig alloc] init];
    config.autoCollectDeviceToken = NO;
    config.pushNotificationEvents = nil;
    swrveTrackInternal = [[Swrve alloc] initWithAppID:swrveAppId apiKey:swrveApiKey userID:userOverride config:config];
    
    // Next create an instance of each demo
    DemoMenuNode *root = [DemoFramework buildRootMenuNode];
    
    // Give each demo the chance to create resources
    [DemoMenuNode enumerate:root withCallback:^(DemoMenuNode *node)
    {
        if(node.demo != nil)
        {
            [node.demo createResources:resourceManager];
        }
    }];
    
    [application setStatusBarHidden:NO];
    
    // Finally initialize the menu and other UI.
    UITabBarController *tabBarController = [DemoFramework buildTabBar:root];
    UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:tabBarController];
    navController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    navController.navigationBar.translucent = NO;
    
    tabBarController.tabBar.barStyle = UIBarStyleBlackOpaque;
    tabBarController.tabBar.translucent = NO;

    tabBarController.delegate = self;
    navController.delegate = self;
    
    // Override UI with onboarding steps if this is the first time launching the app
    if( [UserSettings isFirstTimeRunningApp] )
    {
        navController.navigationBarHidden = YES;
        [navController pushViewController:[[OnboardingFlow alloc] init] animated:NO];
    }
    
    // Show the main window
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = navController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

+(void) intializeSwrveSdk
{
    // Initialize the Swrve track SDK.  This is used by the demos to send data to our servers.
    int customerAppId = [UserSettings getAppId].intValue;
    NSString* customerApiKey = [UserSettings getAppApiKey];
    // Take the user id override from the demo settings
    NSString* userOverride = [DemoFramework getDemoResourceManager].userIdOverride;
    
    SwrveConfig* config = [[SwrveConfig alloc] init];
    config.autoCollectDeviceToken = NO;
    config.pushNotificationEvents = nil;
    
    swrveTrack = [[Swrve alloc]initWithAppID:customerAppId apiKey:customerApiKey userID:userOverride config:config];
    swrveTalk = swrveTrack.talk;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    #pragma unused(application)
    [resourceManager applyAbTestDifferencesAsync:swrveTrack];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    #pragma unused(application)
    [swrveTrack sendQueuedEvents];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    #pragma unused(application)
    [swrveTrack sendQueuedEvents];
    
    // Do not call swrve_close on application shut down.  Avoid this because
    // events are sent asynchronously and destroying the swrve object too
    // early will cause that to fail.
    //[swrveTrack shutdown];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    #pragma unused(application)
    // Normally your app would handle url navigation here and go to the correct
    // app location.  In this example we just print the url in an alert.
    
    UIAlertView *alertView;
    NSString *text = [[url host] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    alertView = [[UIAlertView alloc] initWithTitle:@"Url navigation" message:text delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    return YES;
}

/*
 * You should ask Swrve for AB test differences at the start of each session and optionally
 * during app usage.  For example, we ask for differences every time the user exits a demo
 * and goes back to the tab bar UI.
 */
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    #pragma unused(navigationController, animated)
    if( [viewController isKindOfClass: [DemoMenuViewController class]] )
    {
        [resourceManager applyAbTestDifferencesAsync:swrveTrack];
    }
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    tabBarController.title = viewController.title;
}

/*
 * Builds the main tab bar UI.  If you want to add an additional tab add it here.
 */
+ (UITabBarController *) buildTabBar:(DemoMenuNode *) root
{
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    
    DemoMenuViewController *apiViewController = [[DemoMenuViewController alloc] initWithNibName:@"Menu" bundle:nil];
    apiViewController.menuNode = [root.children objectAtIndex:0];
    apiViewController.title = @"API Demos for Engineers";
    apiViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"API" image:[UIImage imageNamed:@"Code-Image-32.png"] tag:0];
    
    DemoMenuViewController *usecaseViewController = [[DemoMenuViewController alloc] initWithNibName:@"Menu" bundle:nil];
    usecaseViewController.menuNode = [root.children objectAtIndex:1];
    usecaseViewController.title = @"Practical Examples";
    usecaseViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Usecases" image:[UIImage imageNamed:@"award.png"] tag:1];
    
    DemoMenuViewController *toolsViewController = [[DemoMenuViewController alloc] initWithNibName:@"Menu" bundle:nil];
    toolsViewController.menuNode = [root.children objectAtIndex:2];
    toolsViewController.title = @"Debugging Tools";
    toolsViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Tools" image:[UIImage imageNamed:@"settings-2.png"] tag:2];
    
    SettingsView *settingsViewController = [[SettingsView alloc] init];
    settingsViewController.title = @"Settings";
    settingsViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Settings" image:[UIImage imageNamed:@"settings-1.png"] tag:2];
    
    tabBarController.viewControllers = [NSArray arrayWithObjects:apiViewController, usecaseViewController, toolsViewController, settingsViewController, nil];
    tabBarController.title = apiViewController.title;
    
    return tabBarController;
}

/*
 * Builds the node tree of demos
 */
+ (DemoMenuNode *) buildRootMenuNode
{
    DemoMenuNode *apiDemos = [DemoMenuNode alloc];
    {
        DemoMenuNode *trackApiDemo = [DemoMenuNode alloc];
        trackApiDemo.title = @"Track in-app user behavior";
        trackApiDemo.name = @"Track API Demo";
        trackApiDemo.description = @"Shows you how to track user behavior with Swrve's event SDK.";
        trackApiDemo.demo = [[TrackApiDemo alloc] init];
        trackApiDemo.demo.title = @"Track API Demo";
        
        DemoMenuNode *talkApiDemo = [DemoMenuNode alloc];
        talkApiDemo.title = @"Deliver in-app messages to users";
        talkApiDemo.name = @"Talk API Demo";
        talkApiDemo.description = @"Shows you how to message your users with Swrve's messaging SDK.";
        talkApiDemo.demo = [[TalkApiDemo alloc] init];
        talkApiDemo.demo.title = @"Talk API Demo";
        
        DemoMenuNode *gameAuthoritativeDemo = [DemoMenuNode alloc];
        gameAuthoritativeDemo.title = @"Optimize content with AB tests";
        gameAuthoritativeDemo.name = @"AB Test Demo";
        gameAuthoritativeDemo.description = @"Shows you how to run controled experiments in your app with Swrve's AB test API";
        gameAuthoritativeDemo.demo = [[GameAuthoritativeDemo alloc] init];
        gameAuthoritativeDemo.demo.title = @"GameAuthoritativeDemo";
        
        DemoMenuNode *swrveAuthoritativeDemo = [DemoMenuNode alloc];
        swrveAuthoritativeDemo.title = @"Remotely manage content";
        swrveAuthoritativeDemo.name = @"Mini CMS Demo";
        swrveAuthoritativeDemo.description = @"Shows you how to turn Swrve into your content management system with Swrve's resource API.";
        swrveAuthoritativeDemo.demo = [[SwrveAuthoritativeDemo alloc] init];
        swrveAuthoritativeDemo.demo.title = @"SwrveAuthoritativeDemo";
        
        DemoMenuNode *transparencyDemo = [DemoMenuNode alloc];
        transparencyDemo.title = @"Show a message with a transparent background";
        transparencyDemo.name = @"Transparency Demo";
        transparencyDemo.description = @"See how to show a message with a transparent background.";
        transparencyDemo.demo = [[TransparencyDemo alloc] init];
        transparencyDemo.demo.title = @"Transparency Demo";
        
        apiDemos.title = @"API Examples";
        apiDemos.name = @"API";
        apiDemos.description = @"Simple examples that show you our API";
        apiDemos.children = [NSArray arrayWithObjects:trackApiDemo, talkApiDemo, gameAuthoritativeDemo, swrveAuthoritativeDemo, transparencyDemo, nil];
    }
    
    DemoMenuNode *usecaseDemos = [DemoMenuNode alloc];
    {
        DemoMenuNode *inAppPurchaseDemo = [DemoMenuNode alloc];
        inAppPurchaseDemo.title = @"In-app Purchase Price Sheet";
        inAppPurchaseDemo.name = @"In-app Purchase Demo";
        inAppPurchaseDemo.description = @"Maximize your revenue by testing different reward amounts.";
        inAppPurchaseDemo.demo = [[InAppPurchaseDemo alloc] init];
        inAppPurchaseDemo.demo.title = @"In App Purchase demo";
        
        DemoMenuNode *tutorialDemo = [DemoMenuNode alloc];
        tutorialDemo.title = @"Edit tutorial steps";
        tutorialDemo.name = @"Tutorial Demo";
        tutorialDemo.description = @"Improve retention by tuning the messaging and display of your tutorial steps.";
        tutorialDemo.demo = [[TutorialDemo alloc] init];
        tutorialDemo.demo.title = @"Tutorial config demo";
        
        DemoMenuNode *emptyNode = [DemoMenuNode alloc];
        emptyNode.title = @"Engagement Demos";
        emptyNode.name = @"Coming soon!";
        emptyNode.description = @"We haven't added any examples here yet but they are coming soon!";
        
        DemoMenuNode *itemPromotionDemo = [DemoMenuNode alloc];
        itemPromotionDemo.title = @"Special Item of the Day";
        itemPromotionDemo.name = @"Item Promotion Demo";
        itemPromotionDemo.description = @"See how to use Swrve Talk to promote virtual currency sales.";
        itemPromotionDemo.demo = [[ItemPromotionDemo alloc] init];
        itemPromotionDemo.demo.title = @"Item Promotion Demo";
        
        DemoMenuNode *retentionCategory = [DemoMenuNode alloc];
        retentionCategory.title = @"Retention";
        retentionCategory.name = @"Retention Examples";
        retentionCategory.description = @"Tune your users first experience to keep them coming back.";
        retentionCategory.children = [NSArray arrayWithObjects:tutorialDemo, nil];
        
        DemoMenuNode *engagementCategory = [DemoMenuNode alloc];
        engagementCategory.title = @"Engagement";
        engagementCategory.name = @"Engagement Examples";
        engagementCategory.description = @"Optimize loops in your app to get them engaged.";
        engagementCategory.children = [NSArray arrayWithObjects:emptyNode, nil];
        
        DemoMenuNode *monetizationCategory = [DemoMenuNode alloc];
        monetizationCategory.title = @"Monetization";
        monetizationCategory.name = @"Monetization Examples";
        monetizationCategory.description = @"Maximize revenue by tuning in-app monitization.";
        monetizationCategory.children = [NSArray arrayWithObjects:inAppPurchaseDemo, itemPromotionDemo, nil];
        
        usecaseDemos.title = @"Usecase Examples";
        usecaseDemos.name = @"Usecases";
        usecaseDemos.description = @"Practical examples to help you push the needle.";
        usecaseDemos.children = [NSArray arrayWithObjects:retentionCategory,
                                 monetizationCategory,
                                 engagementCategory,
                                 nil];
    }
    
    DemoMenuNode *toolDemos = [DemoMenuNode alloc];
    {
        DemoMenuNode *resourceViewer = [DemoMenuNode alloc];
        resourceViewer.title = @"View Resources in Your App";
        resourceViewer.name = @"Resource Viewer Demo";
        resourceViewer.description = @"Review the tuneable resources and their attributes in your app.";
        resourceViewer.demo = [[ResourceViewer alloc] init];
        resourceViewer.demo.title = @"Resource Viewer";
        
        DemoMenuNode *abTestViewer = [DemoMenuNode alloc];
        abTestViewer.title = @"View AB Test Diffs in Your App";
        abTestViewer.name = @"AB Test View Demo";
        abTestViewer.description = @"Review the resources and attributes in your active AB tests.";
        abTestViewer.demo = [[ABTestViewer alloc] init];
        abTestViewer.demo.title = @"AB Test Viewer";

        toolDemos.title = @"Developer Tools";
        toolDemos.name = @"Tools";
        toolDemos.description = @"Helpful tools for debugging your app.";
        toolDemos.demo = nil;
        toolDemos.children = [NSArray arrayWithObjects:resourceViewer, abTestViewer, nil];
    }
    
    DemoMenuNode *root = [DemoMenuNode alloc];
    root.children = [NSArray arrayWithObjects:apiDemos, usecaseDemos, toolDemos,nil];
    
    return root;
}

+(Swrve *) getSwrve
{
    return swrveTrack;
}

+(SwrveMessageController*) getSwrveTalk
{
    return swrveTalk;
}

+(DemoResourceManager *) getDemoResourceManager
{
    return resourceManager;
}

+(Swrve *) getSwrveInternal
{
    return swrveTrackInternal;
}

@end

int main(int argc, char *argv[])
{
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([DemoFramework class]));
    }
}
