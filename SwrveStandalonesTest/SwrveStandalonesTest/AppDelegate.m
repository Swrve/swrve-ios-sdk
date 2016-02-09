#import "AppDelegate.h"
#import "SwrveCommon.h"
#import "SwrvePlotDelegate.h"
#import "SwrveCommonMessageController.h"
#import "SwrveCommonConversation.h"
#import "SwrveConversationItemViewController.h"
#import "SwrveConversationsNavigationController.h"
#import "SwrveConversationContainerViewController.h"

@interface DemoSwrveCommon : NSObject<ISwrveCommon>
@end

@implementation DemoSwrveCommon
-(NSData*) getCampaignData:(int)category {
    if(SWRVE_CAMPAIGN_LOCATION == category) {
        return [@"{\"1\":{\"version\":1,\"message\":{\"id\":1,\"body\":\"Swrve Dublin office ENTER. This should open deeplink to ios Data tab swrve://deeplink/data\",\"payload\":\"{\\\"_sd\\\":\\\"swrve://deeplink/data\\\"}\"}},\"2\":{\"version\":1,\"message\":{\"id\":2,\"body\":\"Dom Swrve Dublin office EXIT.\",\"payload\":\"{}\"}},\"12\":{\"version\":1,\"message\":{\"id\":12,\"body\":\"Dom campaign brookwood Exit\\nLabel is: ${geofence.label}\",\"payload\":\"{}\"}},\"13\":{\"version\":1,\"message\":{\"id\":13,\"body\":\"Dundalk enter\",\"payload\":\"{}\"}},\"14\":{\"version\":1,\"message\":{\"id\":14,\"body\":\"Dundalk exit\",\"payload\":\"{}\"}},\"21\":{\"version\":1,\"message\":{\"id\":21,\"body\":\"Dom Fairview Enter\",\"payload\":\"{}\"}},\"43\":{\"version\":1,\"message\":{\"id\":39,\"body\":\"Swrve Dublin Phoenix Park Enter\",\"payload\":\"{}\"}},\"176\":{\"version\":1,\"message\":{\"id\":155,\"body\":\"Dom Bull Island Exit. Label is: ${geofence.label}\",\"payload\":\"{}\"}},\"177\":{\"version\":1,\"message\":{\"id\":156,\"body\":\"Dom campaign brookwood Enter. Label:${geofence.label}\",\"payload\":\"{}\"}}}" dataUsingEncoding:NSUTF8StringEncoding];
    }
    return nil;
}

-(BOOL) processPermissionRequest:(NSString*)action { return TRUE; }
-(void) sendQueuedEvents { }
-(int) eventInternal:(NSString*)eventName payload:(NSDictionary*)eventPayload triggerCallback:(bool)triggerCallback { return SWRVE_SUCCESS; }
-(int) userUpdate:(NSDictionary*)attributes { return SWRVE_SUCCESS; }
-(void) setLocationVersion:(NSString *)version { }
@end

@interface DemoSwrveCommonMessageController : NSObject<SwrveCommonMessageController>
@end

@implementation DemoSwrveCommonMessageController
-(void)conversationWasShownToUser:(SwrveCommonConversation*)conversation {
    NSLog(@"conversationWasShownToUser: %@", conversation);
}
- (void) conversationClosed {
    NSLog(@"conversationClosed");
}

-(void) showConversationFromString:(NSString*)_conversation
{
    NSError* jsonError;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[_conversation dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&jsonError];
    
    SwrveCommonConversation* conversation = [SwrveCommonConversation fromJSON:jsonDict forController:self];
    
    [self showConversation:conversation];

}

-(void) showConversation:(SwrveCommonConversation*)conversation
{
    // Create a view to show the conversation
    SwrveConversationItemViewController* scivc = nil;
    @try {
        UIStoryboard* storyBoard = [UIStoryboard storyboardWithName:@"SwrveConversation" bundle:[NSBundle mainBundle]];
        scivc = [storyBoard instantiateViewControllerWithIdentifier:@"SwrveConversationItemViewController"];
    }
    @catch (NSException *exception) {
        DebugLog(@"Unable to load Conversation Item View Controller. %@", exception);
        return;
    }
    
    UIWindow* conversationWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [scivc setConversation:conversation andMessageController:self andWindow:conversationWindow];
    
    // Create a navigation controller in which to push the conversation, and choose iPad presentation style
    SwrveConversationsNavigationController *svnc = [[SwrveConversationsNavigationController alloc] initWithRootViewController:scivc];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        svnc.modalPresentationStyle = UIModalPresentationFormSheet;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wselector"
    // Attach cancel button to the conversation navigation options
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:scivc action:@selector(cancelButtonTapped:)];
#pragma clang diagnostic pop
    scivc.navigationItem.leftBarButtonItem = cancelButton;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        SwrveConversationContainerViewController* rootController = [[SwrveConversationContainerViewController alloc] initWithChildViewController:svnc];
        conversationWindow.rootViewController = rootController;
        [conversationWindow makeKeyAndVisible];
        [rootController.view endEditing:YES];
    });
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSURL* location = [[NSBundle mainBundle] URLForResource:@"campaign" withExtension:@"json"];
    
    NSData* content = [NSData dataWithContentsOfURL: location];
    
    DemoSwrveCommonMessageController* controller = [DemoSwrveCommonMessageController alloc];
    [controller showConversationFromString:[NSString stringWithUTF8String:[content bytes]]];
    
    return YES;
}

-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    //Pass the notification to the Plot library to pre process the notification.
    //Don't handle the notifications yourself in this method, because this method isn't always called when a notification is opened.
    [Plot handleNotification:notification];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
