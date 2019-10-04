#import "SwrveConversationContainerViewController.h"
#import "SwrveBaseConversation.h"
#import "SwrveConversationItemViewController.h"

@interface SwrveConversationContainerViewController ()

@property (nonatomic, retain) UIViewController* childController;
@property (nonatomic) BOOL displayedChildrenViewController;
@property (nonatomic, retain) NSDictionary *lightBoxStyle;
@property (nonatomic, retain) UIColor* lightBoxColor;
@property (nonatomic) BOOL statusBarHidden;

@end

@implementation SwrveConversationContainerViewController

@synthesize childController;
@synthesize displayedChildrenViewController;
@synthesize lightBoxStyle = _lightBoxStyle;
@synthesize lightBoxColor = _lightBoxColor;
@synthesize statusBarHidden;

-(id) initWithChildViewController:(UIViewController*)child withStatusBarHidden:(BOOL)prefeerStatusBarHidden {
    if (self = [super init]) {
        self.childController = child;
        self.statusBarHidden = prefeerStatusBarHidden;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!displayedChildrenViewController) {
        displayedChildrenViewController = YES;
        childController.view.backgroundColor = [UIColor clearColor];
        if (@available(iOS 8.0, *)) {
         childController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        }
        [self presentViewController:childController animated:YES completion:nil];
    }
}

-(void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [super dismissViewControllerAnimated:flag completion:completion];
    [UIView animateWithDuration:0.3 animations:^{
        self.view.backgroundColor = [UIColor clearColor];
    } completion:NULL];
}

#if TARGET_OS_IOS
- (BOOL)prefersStatusBarHidden {
    if (self.statusBarHidden) {
        return YES;
    } else {
        return [super prefersStatusBarHidden];
    }
}
#endif

@end
