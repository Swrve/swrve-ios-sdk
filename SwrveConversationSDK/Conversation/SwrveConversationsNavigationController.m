#import "SwrveConversationsNavigationController.h"

@interface SwrveConversationsNavigationController ()

@end

@implementation SwrveConversationsNavigationController

-(id) initWithRootViewController:(UIViewController *)rootViewController {
    self = [super initWithRootViewController:rootViewController];
    return self;
}

#if TARGET_OS_IOS
- (BOOL)shouldAutorotate {
    return YES;
}
#endif

#if defined(__IPHONE_9_0)
#else
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
#pragma unused(interfaceOrientation)
    return YES;
}
#endif

@end
