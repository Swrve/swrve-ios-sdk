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


// Rotation for iOS < 6
#if defined(__IPHONE_9_0)
#else
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
#pragma unused(interfaceOrientation)
    return YES;
}
#endif

@end
