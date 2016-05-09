#import "UnitySwrveCommonMessageController.h"
#import "SwrveConversationItemViewController.h"
#import "SwrveConversationsNavigationController.h"
#import "SwrveConversationContainerViewController.h"
#import "SwrveCommon.h"

@interface UnitySwrveMessageEventHandler()

@property (nonatomic, retain) UIWindow* conversationWindow;
@end

@implementation UnitySwrveMessageEventHandler

@synthesize conversationWindow;

-(void)conversationWasShownToUser:(SwrveBaseConversation*)conversation {
    NSLog(@"conversationWasShownToUser: %@", conversation);
}

- (void) conversationClosed {
    @synchronized(self) {
        self.conversationWindow.hidden = YES;
        self.conversationWindow = nil;
    }
}

-(SwrveBaseConversation*) conversationFromString:(NSString*)conversation
{
    NSError* jsonError;
    NSDictionary *jsonDict =
        [NSJSONSerialization JSONObjectWithData:[conversation dataUsingEncoding:NSUTF8StringEncoding]
                                        options:0
                                          error:&jsonError];
    if(nil == jsonDict) {
        return nil;
    }
    return [SwrveBaseConversation fromJSON:jsonDict forController:self];
}

-(void) showConversationFromString:(NSString*)conversation
{
    [self showConversation:[self conversationFromString:conversation]];
}

-(void) showConversation:(SwrveBaseConversation*)conversation
{
    // Create a view to show the conversation
    SwrveConversationItemViewController* scivc = nil;
    UIStoryboard* storyBoard = [UIStoryboard storyboardWithName:@"SwrveConversation" bundle:[NSBundle mainBundle]];
    scivc = [storyBoard instantiateViewControllerWithIdentifier:@"SwrveConversationItemViewController"];

    self.conversationWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [scivc setConversation:conversation andMessageController:self andWindow:[self conversationWindow]];
    
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
        [self conversationWindow].rootViewController = rootController;
        [[self conversationWindow] makeKeyAndVisible];
        [rootController.view endEditing:YES];
    });
}

@end
