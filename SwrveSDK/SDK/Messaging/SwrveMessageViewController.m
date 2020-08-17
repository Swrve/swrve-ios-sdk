#import "Swrve.h"
#import "SwrveMessageViewController.h"
#import "SwrveButton.h"

#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface SwrveMessageViewController ()

@property (nonatomic, retain) SwrveMessageFormat* current_format;
@property (nonatomic) BOOL wasShownToUserNotified;
@property (nonatomic) CGFloat viewportWidth;
@property (nonatomic) CGFloat viewportHeight;

@property (nonatomic, retain) UIFocusGuide *focusGuide1 __IOS_AVAILABLE(9.0) __TVOS_AVAILABLE(9.0);
@property (nonatomic, retain) UIFocusGuide *focusGuide2 __IOS_AVAILABLE(9.0) __TVOS_AVAILABLE(9.0);
@property (nonatomic, retain) UIButton *tvOSFocusForSelection;

@end

@implementation SwrveMessageViewController

@synthesize block;
@synthesize message;
@synthesize current_format;
@synthesize wasShownToUserNotified;
@synthesize viewportWidth;
@synthesize viewportHeight;
@synthesize prefersIAMStatusBarHidden;
@synthesize personalisationDict;
@synthesize inAppConfig;
@synthesize messageController;

@synthesize focusGuide1, focusGuide2, tvOSFocusForSelection;

- (UIWindow*)keyWindow {
    UIWindow *keyWindow = nil;
    if (@available(iOS 13, *)) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for (UIWindow *window in windows) {
            if (window.isKeyWindow) {
                keyWindow = window;
                break;
            }
        }
    } else {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        keyWindow = [[UIApplication sharedApplication] keyWindow];
        #pragma clang diagnostic pop
    }
    return keyWindow;
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    // Default viewport size to whole screen
    CGRect screenRect = [[self keyWindow] bounds];
    self.viewportWidth = screenRect.size.width;
    self.viewportHeight = screenRect.size.height;
#if TARGET_OS_TV
    UITapGestureRecognizer *playPress = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buttonSelected)];
    playPress.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypePlayPause]];
    [self.view addGestureRecognizer:playPress];
#endif
}

- (void)buttonSelected {
    [self onButtonPressed:self.tvOSFocusForSelection];
}

- (void)viewDidAppear:(BOOL)animated {

    [super viewDidAppear:animated];
    [self updateBounds];
    [self removeAllViews];
    [self displayForViewportOfSize:CGSizeMake(self.viewportWidth, self.viewportHeight)];
    [self refreshViewForPlatform];

    if (self.wasShownToUserNotified == NO) {
        [self.message wasShownToUser];
        self.wasShownToUserNotified = YES;
    }
}

-(void)updateBounds
{
    // Update the bounds to the new screen size
    [self.view setFrame:[[UIScreen mainScreen] bounds]];
    [self refreshViewForPlatform];
}

-(void)removeAllViews
{
    for (UIView *view in self.view.subviews) {
        [view removeFromSuperview];
    }
}

-(void)refreshViewForPlatform {
    // pre-iOS 9 setNeedsFocusUpdate and updateFocusIfNeeded are not supported
#if TARGET_OS_TV
    [self.view setNeedsFocusUpdate];
    [self.view updateFocusIfNeeded];
#endif
}


#if TARGET_OS_IOS /** exclude tvOS **/
-(void)addViewForOrientation:(UIInterfaceOrientation)orientation
{
    current_format = [self.message bestFormatForOrientation:orientation];
    if (!current_format) {
        // Never leave the screen without a format
        current_format = [self.message.formats objectAtIndex:0];
    }

    if (current_format) {
        // pass config for text generation
        current_format.inAppConfig = self.inAppConfig;

        DebugLog(@"Selected message format: %@", current_format.name);
        [current_format createViewToFit:self.view
                                  thatDelegatesTo:self
                                         withSize:self.view.bounds.size
                                          rotated:false
                                  personalisation:personalisationDict];
        
        // Update background color
        if (current_format.backgroundColor != nil) {
            self.view.backgroundColor = current_format.backgroundColor;
        }
    } else {
        DebugLog(@"Couldn't find a format for message: %@", message.name);
    }
}
#endif

-(IBAction)onButtonPressed:(id)sender
{
    UISwrveButton* button = sender;
    
    NSString *action = button.actionString;
    
    SwrveButton* pressed = [current_format.buttons objectAtIndex:(NSUInteger)button.tag];
    SwrveMessageController* controller = self.messageController;
    if (controller != nil) {
        [controller buttonWasPressedByUser:pressed];
    }
    
    if(action == nil || [action isEqualToString:@""]) {
        action = pressed.actionString;
    }

    self.block(pressed.actionType, action, pressed.appID);
}

#if TARGET_OS_IOS
-(BOOL)prefersStatusBarHidden
{
    if (prefersIAMStatusBarHidden) {
        return YES;
    } else {
        return [super prefersStatusBarHidden];
    }
}
#endif

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator API_AVAILABLE(ios(8.0)) {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    self.viewportWidth = size.width;
    self.viewportHeight = size.height;
    [self removeAllViews];
    [self displayForViewportOfSize:CGSizeMake(self.viewportWidth, self.viewportHeight)];
}

- (void) displayForViewportOfSize:(CGSize)size
{
    float viewportRatio = (float)(size.width/size.height);
    float closestRatio = -1;
    SwrveMessageFormat* closestFormat = nil;
    for (SwrveMessageFormat* format in self.message.formats) {
        float formatRatio = (float)(format.size.width/format.size.height);
        float diffRatio = fabsf(formatRatio - viewportRatio);
        if (closestFormat == nil || (diffRatio < closestRatio)) {
            closestFormat = format;
            closestRatio = diffRatio;
        }
    }

    current_format = closestFormat;
    current_format.inAppConfig = self.inAppConfig;
    DebugLog(@"Selected message format: %@", current_format.name);
    UIView *currentView = [current_format createViewToFit:self.view
                   thatDelegatesTo:self
                          withSize:size
                   personalisation:personalisationDict];

    [self setupFocusGuide:currentView];

    [currentView setHidden:NO];
    [currentView setUserInteractionEnabled:YES];
    [currentView setAlpha:1.0];

    // Update background color
    if (current_format.backgroundColor != nil) {
        self.view.backgroundColor = current_format.backgroundColor;
    }
}

#if TARGET_OS_IOS
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
    return YES;
}
#endif

#pragma mark - Focus
- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator __IOS_AVAILABLE(9.0) __TVOS_AVAILABLE(9.0) {
#pragma unused(coordinator)

    UIView *previouslyFocusedView = context.previouslyFocusedView;

    if (previouslyFocusedView != nil && [previouslyFocusedView isDescendantOfView:self.view]) {
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear  animations:^{
            previouslyFocusedView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        } completion:^(BOOL finished) {
#pragma unused(finished)
        }];

    }

    UIView *nextFocusedView = context.nextFocusedView;

    if (nextFocusedView != nil && [nextFocusedView isDescendantOfView:self.view]) {
        [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear  animations:^{

            CGFloat increase = (float)1.2;

            nextFocusedView.transform = CGAffineTransformMakeScale(increase, increase);
        } completion:^(BOOL finished) {
#pragma unused(finished)
        }];

        self.tvOSFocusForSelection = (UIButton *)nextFocusedView;
    }
}

- (void)setupFocusGuide:(UIView *)currentView {
    if (@available(iOS 9.0, *)) {
        self.focusGuide1 = nil;
        self.focusGuide2 = nil;
    }
    NSArray<UIButton *> *buttons = [SwrveMessageViewController buttonsInView:currentView];
    if (buttons.count != 2) { // we only want to help focus engine if there are two buttons
        return;
    }

    CGRect frame0 = buttons[0].frame;
    CGRect frame1 = buttons[1].frame;
    // only add focus guides if the buttons are strictly diagonal. otherwise the focus engine will figure it out by itself
    if ((CGRectGetMinY(frame1) > CGRectGetMaxY(frame0) || CGRectGetMaxY(frame1) < CGRectGetMinY(frame0))
         &&
         (CGRectGetMinX(frame1) > CGRectGetMaxX(frame0) || CGRectGetMaxX(frame1) < CGRectGetMinX(frame0))) {

        if (@available(iOS 10.0, *)) {
            self.focusGuide1 = [UIFocusGuide new];
            [currentView addLayoutGuide:self.focusGuide1];
            [self.focusGuide1.leftAnchor constraintEqualToAnchor:buttons[0].leftAnchor].active = YES;
            [self.focusGuide1.rightAnchor constraintEqualToAnchor:buttons[0].rightAnchor].active = YES;
            [self.focusGuide1.topAnchor constraintEqualToAnchor:buttons[1].topAnchor].active = YES;
            [self.focusGuide1.bottomAnchor constraintEqualToAnchor:buttons[1].bottomAnchor].active = YES;

            self.focusGuide2 = [UIFocusGuide new];
            [currentView addLayoutGuide:self.focusGuide2];
            [self.focusGuide2.leftAnchor constraintEqualToAnchor:buttons[1].leftAnchor].active = YES;
            [self.focusGuide2.rightAnchor constraintEqualToAnchor:buttons[1].rightAnchor].active = YES;
            [self.focusGuide2.topAnchor constraintEqualToAnchor:buttons[0].topAnchor].active = YES;
            [self.focusGuide2.bottomAnchor constraintEqualToAnchor:buttons[0].bottomAnchor].active = YES;
        } else {
            DebugLog(@"Top and bottom guide not supported, should not reach this code", nil);
        }
    }

}

- (UIButton *)nextFocusableButtonWithCurrentFocusedView:(UIView *)view {
    NSArray *allButtons = [SwrveMessageViewController buttonsInView:self.view];
    if (allButtons.count < 2) {
        return nil;
    }
    // Here we are finding the next focusable button that is then set (by the caller) as the preferred focusable view for the focusGuide.
    NSUInteger idx = [allButtons indexOfObject:view];
    if (idx == NSNotFound) {
        return nil;
    }
    // The following lines are equivalent to: return allButtons[(idx+1) % allButtons.count], i.e. we find the next button in the array, or if there are none we return the first button.
    if (idx == allButtons.count - 1) {
        return allButtons.firstObject;
    }
    return allButtons[idx + 1];
}

+ (NSArray<UIButton *> *)buttonsInView:(UIView *)view {
    NSMutableArray *result = [NSMutableArray array];
    for (UIView *subview in view.subviews) {
        [result addObjectsFromArray:[self buttonsInView:subview]];
        if ([subview isKindOfClass:[UIButton class]]) {
            [result addObject:subview];
        }
    }
    return result;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

@end
