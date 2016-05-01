#import "SwrveConversationsNavigationController.h"

@interface SwrveConversationsNavigationController ()

@end

@implementation SwrveConversationsNavigationController

-(id) initWithRootViewController:(UIViewController *)rootViewController {
    self = [super initWithRootViewController:rootViewController];
    return self;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    /*[UIView animateWithDuration:1 animations:^{
     self.view.backgroundColor = [UIColor clearColor];
     } completion:NULL];*/
}

@end
