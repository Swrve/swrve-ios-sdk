#import "SwrveConversationsNavigationController.h"

@interface SwrveConversationsNavigationController ()

@end

@implementation SwrveConversationsNavigationController

-(id) initWithRootViewController:(UIViewController *)rootViewController {
    self = [super initWithRootViewController:rootViewController];
    return self;
}

- (BOOL)shouldAutorotate {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // This does not work if conversation is of type UIModalPresentationFormSheet
        return YES;
    } else {
        return NO;
    }
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return [self.topViewController preferredInterfaceOrientationForPresentation];
    } else {
        return UIInterfaceOrientationPortrait;
    }
}

@end
