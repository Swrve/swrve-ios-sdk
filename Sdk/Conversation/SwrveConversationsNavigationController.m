#import "SwrveConversationsNavigationController.h"
#import "SwrveConversationResource.h"
#import "SwrveSetup.h"

@interface SwrveConversationsNavigationController ()

@end

@implementation SwrveConversationsNavigationController

@synthesize landscapeEnabled;
@synthesize movieRotationHandling;

-(id) initWithRootViewController:(UIViewController *)rootViewController {
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        self.landscapeEnabled = YES;
    }
    return self;
}

// Rotation for iOS 6
- (BOOL)shouldAutorotate {
    return landscapeEnabled;
}

// Rotation for iOS 6
- (NSUInteger)supportedInterfaceOrientations {
    if (landscapeEnabled) {
        // On iOS 6+, you would use the shorthand UIInterfaceOrientationMaskAll
        // here, but it won't compile for iOS 5.1, so must be primitive about it
        return (1 << UIInterfaceOrientationPortrait) | (1 << UIInterfaceOrientationLandscapeLeft) | (1 << UIInterfaceOrientationLandscapeRight) | (1 << UIInterfaceOrientationPortraitUpsideDown);
    } else {
        // On iOS 6+, you would use the shorthand UIInterfaceOrientationMaskPortrait
        // here, but it won't compile for iOS 5.1, so must be primitive about it
        return (1 << UIInterfaceOrientationPortrait);
    }
}

@end
