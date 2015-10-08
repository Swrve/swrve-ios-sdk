#import "SwrveConversationContainerViewController.h"

@interface SwrveConversationContainerViewController ()

@property (nonatomic, retain) UIViewController* childController;
@property (nonatomic) BOOL displayedChildrenViewController;

@end

@implementation SwrveConversationContainerViewController

@synthesize childController;
@synthesize displayedChildrenViewController;

-(id) initWithChildViewController:(UIViewController*)child {
    if (self = [super init]) {
        self.childController = child;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!displayedChildrenViewController) {
        displayedChildrenViewController = YES;
        [self presentViewController:childController animated:YES completion:nil];
    }
}

@end
