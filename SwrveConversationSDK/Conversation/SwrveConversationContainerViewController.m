#import "SwrveConversationContainerViewController.h"

@interface SwrveConversationContainerViewController ()

@property (nonatomic, retain) UIViewController* childController;
@property (nonatomic) BOOL displayedChildrenViewController;
@property (nonatomic, retain) UIColor* lightBoxColor;

@end

@implementation SwrveConversationContainerViewController

@synthesize childController;
@synthesize displayedChildrenViewController;

-(id) initWithChildViewController:(UIViewController*)child andLightboxColor:(UIColor*)lightBoxColor {
    if (self = [super init]) {
        self.childController = child;
        self.lightBoxColor = lightBoxColor;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!displayedChildrenViewController) {
        displayedChildrenViewController = YES;
        childController.view.backgroundColor = [UIColor clearColor];
        childController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [self presentViewController:childController animated:YES completion:nil];
    }
    [UIView animateWithDuration:0.5 animations:^{
        self.view.backgroundColor = self.lightBoxColor;
    } completion:NULL];
}

-(void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [super dismissViewControllerAnimated:flag completion:completion];
    [UIView animateWithDuration:0.3 animations:^{
        self.view.backgroundColor = [UIColor clearColor];
    } completion:NULL];
}

@end
