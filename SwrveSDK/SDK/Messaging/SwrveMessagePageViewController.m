#import "SwrveMessagePageViewController.h"
#import "Swrve.h"
#import "SwrveButton.h"
#import "SwrveMessageController.h"
#import "SwrveMessageUIView.h"

@interface SwrveMessageController ()
@property (nonatomic, retain) UIWindow *inAppMessageWindow;
@end

@implementation SwrveMessagePageViewController

@synthesize messageFormat;
@synthesize pageId;
@synthesize personalization;
@synthesize size;
@synthesize messageController;

- (id)initWithMessageController:(SwrveMessageController *)swrveMessageController
                         format:(SwrveMessageFormat *) swrveMessageFormat
                personalization:(NSDictionary *)personalizationDict
                         pageId:(NSNumber *)currentPageId
                           size:(CGSize)sizeParent {

    self = [super init];
    if (self) {
        self.messageController = swrveMessageController;
        self.messageFormat = swrveMessageFormat;
        self.personalization = personalizationDict;
        self.pageId = currentPageId;
        self.size = sizeParent;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self updateBounds];
    [self displaySwrveMessage];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    SwrveMessageViewController *messageViewController = (SwrveMessageViewController*)self.messageController.inAppMessageWindow.rootViewController;
    messageViewController.currentPageId = self.pageId;
    [messageViewController queuePageViewEvent:self.pageId];
}

- (void)updateBounds {
    [self.view setFrame:[[UIScreen mainScreen] bounds]]; // Update the bounds to the new screen size
}

- (void)removeAllSubViews {
    for (UIView *view in self.view.subviews) {
        [view removeFromSuperview];
    }
}

- (IBAction)onButtonPressed:(id)sender {
    UISwrveButton *button = sender;
    SwrveMessageViewController *messageViewController = (SwrveMessageViewController *) self.parentViewController;
    [messageViewController onButtonPressed:button pageId:self.pageId];
}

#if TARGET_OS_IOS
- (BOOL)prefersStatusBarHidden {
    if (self.messageController.inAppMessageConfig.prefersStatusBarHidden) {
        return YES;
    } else {
        return [super prefersStatusBarHidden];
    }
}
#endif

- (void)displaySwrveMessage {

    [self removeAllSubViews];

    SwrveMessageUIView *swrveMessageUIView = [[SwrveMessageUIView alloc] initWithMessageFormat:self.messageFormat
                                                                                        pageId:self.pageId
                                                                                    parentSize:self.size
                                                                                    controller:self
                                                                               personalization:self.personalization
                                                                                   inAppConfig:self.messageController.inAppMessageConfig];
    [self.view addSubview:swrveMessageUIView];

#if TARGET_OS_TV
    UITapGestureRecognizer *menuPress = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tvSelectorMenuButtonPressed)];
    menuPress.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypeMenu]];
    [self.view addGestureRecognizer:menuPress];
#endif
}

- (void)tvSelectorMenuButtonPressed {
    SwrveMessageController *controller = self.messageController;
    [controller dismissMessageWindow];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

@end
