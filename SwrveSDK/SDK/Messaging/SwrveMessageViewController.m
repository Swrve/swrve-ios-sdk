#import "SwrveMessageViewController.h"
#import "SwrveMessagePage.h"
#import "SwrveMessagePageViewController.h"
#import "SwrveMessageController.h"
#import "SwrveButton.h"
#import "SwrveMessageFocus.h"
#import "SwrveInAppStoryView.h"
#import "SwrveSDKUtils.h"
#import "SwrveInAppStoryUIButton.h"

#if __has_include(<SwrveSDKCommon/SwrveCommon.h>)
#import <SwrveSDKCommon/SwrveCommon.h>
#import <SwrveSDKCommon/SwrveLogger.h>
#import <SwrveSDKCommon/SwrveUtils.h>
#else
#import "SwrveCommon.h"
#import "SwrveLogger.h"
#import "SwrveUtils.h"
#endif

@interface SwrveMessageController ()

@property(nonatomic, retain) UIWindow *inAppMessageWindow;
@property(nonatomic) SwrveActionType inAppMessageActionType;
@property(nonatomic, retain) NSString *inAppMessageAction;
@property(nonatomic, retain) NSString *inAppButtonPressedName;
@property(nonatomic, retain) NSString *inAppButtonPressedText;

- (void)queueMessageClickEvent:(SwrveButton *)button page:(SwrveMessagePage *)page;
- (void)messageWasShownToUser:(SwrveMessage *)message;

@end

@interface SwrveMessageViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate, SwrveInAppStorySegmentDelegate>

@property(nonatomic) CGSize iamWindowSize; // the current window size which is dependent on orientation
@property(nonatomic) BOOL wasShownToUserNotified;
@property(nonatomic, retain) NSMutableArray *pageViewEventsSent;
@property(nonatomic, retain) NSMutableArray *navigationEventsSent;
@property(nonatomic, retain) SwrveMessageFocus *messageFocus;
@property(nonatomic) SwrveInAppStoryView *storyView;
@property(nonatomic) SwrveInAppStoryUIButton *storyDismissButton;
@end

@implementation SwrveMessageViewController

@synthesize messageController;
@synthesize message;
@synthesize personalization;
@synthesize currentMessageFormat;
@synthesize currentPageId;
@synthesize iamWindowSize;
@synthesize wasShownToUserNotified;
@synthesize pageViewEventsSent;
@synthesize navigationEventsSent;
@synthesize messageFocus;
@synthesize storyView;
@synthesize storyDismissButton;

- (id)initWithMessageController:(SwrveMessageController *)swrveMessageController
                        message:(SwrveMessage *)swrveMessage
                personalization:(NSDictionary *)personalizationDict {

#if TARGET_OS_TV
    self = [super init];
#else
    self = [super initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                    navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                  options:nil];
#endif

    if (self) {
        self.messageController = swrveMessageController;
        self.message = swrveMessage;
        self.personalization = personalizationDict;
        self.pageViewEventsSent = [NSMutableArray array];
        self.navigationEventsSent = [NSMutableArray array];
#if TARGET_OS_IOS
        self.dataSource = self; // this is required for swiping capability
#endif
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.iamWindowSize = [self windowSize];
    [self updateCurrentMessageFormat];
    NSNumber *firstPageId = self.currentMessageFormat.pagesOrdered[0];
    [self showPage:firstPageId];
    [self startStoryViewSegment:firstPageId];

    self.view.frame = self.view.bounds;
    self.messageFocus = [[SwrveMessageFocus alloc] initWithView:self.view];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.wasShownToUserNotified == NO) {
        [self.messageController messageWasShownToUser:self.message];
        self.wasShownToUserNotified = YES;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator API_AVAILABLE(ios(8.0)) {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    self.iamWindowSize = size;
    [self updateCurrentMessageFormat];
    [self showPage:self.currentPageId];
    [self redrawStoryView];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(SwrveMessagePageViewController *)viewController {
    SwrveMessagePage *page = [self.currentMessageFormat.pages objectForKey:viewController.pageId];
    if (page.swipeBackward == -1 || self.currentMessageFormat.pages.count == 1) {
        return nil;
    }
    NSNumber *pageIdToShow = [NSNumber numberWithLong:page.swipeBackward];
    return [self messagePageViewController:pageIdToShow];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(SwrveMessagePageViewController *)viewController {
    SwrveMessagePage *page = [self.currentMessageFormat.pages objectForKey:viewController.pageId];
    if (page.swipeForward == -1 || self.currentMessageFormat.pages.count == 1) {
        return nil;
    }
    NSNumber *pageIdToShow = [NSNumber numberWithLong:page.swipeForward];
    return [self messagePageViewController:pageIdToShow];
}

- (void)updateCurrentMessageFormat {
    float viewportRatio = (float) (self.iamWindowSize.width / self.iamWindowSize.height);
    float closestRatio = -1;
    SwrveMessageFormat *closestFormat = nil;
    for (SwrveMessageFormat *format in self.message.formats) {
        float formatRatio = (float) (format.size.width / format.size.height);
        float diffRatio = fabsf(formatRatio - viewportRatio);
        if (closestFormat == nil || (diffRatio < closestRatio)) {
            closestFormat = format;
            closestRatio = diffRatio;
        }
    }
    [SwrveLogger debug:@"Selected message format: %@", closestFormat.name];
    self.currentMessageFormat = closestFormat;

    [self setControllerBackgroundColor]; // A Format can contain a background color so set it after getting the Format
}

- (CGSize)windowSize NS_EXTENSION_UNAVAILABLE_IOS("") {
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
    CGSize screenSize = [keyWindow bounds].size;
    // if campaign is launched before window is visible, there is strong possibility of screenSize to be zero
    if (screenSize.width == 0.0 || screenSize.height == 0) {
        screenSize = [UIScreen mainScreen].bounds.size;
    }
    return screenSize;
}

- (SwrveMessagePageViewController *)messagePageViewController:(NSNumber *)pageIdToShow {
    SwrveMessagePageViewController *messageViewController = [[SwrveMessagePageViewController alloc]
            initWithMessageController:self.messageController
                               format:self.currentMessageFormat
                      personalization:self.personalization
                               pageId:pageIdToShow
                                 size:self.iamWindowSize];
    return messageViewController;
}

- (void)onButtonPressed:(SwrveUIButton *)button pageId:(NSNumber *)pageIdPressed {

    SwrveMessagePage *page = [[self.currentMessageFormat pages] objectForKey:pageIdPressed];
    SwrveButton *swrveButton = [page.buttons objectAtIndex:(NSUInteger) button.tag];
    SwrveMessageController *messageControllerStrong = self.messageController;
    if (!messageControllerStrong || !swrveButton) {
        return;
    }

    if (swrveButton.actionType != kSwrveActionPageLink) {
        [messageControllerStrong queueMessageClickEvent:swrveButton page:page];
        messageControllerStrong.inAppButtonPressedName = swrveButton.name; // Save button name for processing later
        messageControllerStrong.inAppButtonPressedText = button.displayString;
    }

    NSString *action = button.actionString; // this may have been personalized so use button.actionString instead of swrveButton.actionString
    if (action == nil || [action isEqualToString:@""]) {
        action = swrveButton.actionString;
    }

    if (swrveButton.actionType == kSwrveActionPageLink) {
        NSNumber *pageIdToShow = @([action intValue]);
        [self queuePageNavEvent:self.currentPageId buttonId:button.buttonId pageIdToShow:pageIdToShow buttonName:button.buttonName];
        [self showPage:pageIdToShow];
        [self startStoryViewSegment:pageIdToShow];
        [self queueDataCaptureEventsForButton:swrveButton personalization:self.personalization];
    } else {
        if (swrveButton.actionType == kSwrveActionDismiss) {
            [self queueDismissEvent:self.currentPageId buttonId:button.buttonId buttonName:button.buttonName];
        }
        if (self.storyView != nil) {
            [self.storyView stop];
        }
        // Save button type and action for processing later in the messageController
        messageControllerStrong.inAppMessageActionType = swrveButton.actionType;
        messageControllerStrong.inAppMessageAction = action;
        [self beginHideMessageAnimationWithCompletionHandler:^{
            [self queueDataCaptureEventsForButton:swrveButton personalization:self.personalization];
        }];
    }
}

- (void)queueDataCaptureEventsForButton:(SwrveButton *)swrveButton personalization:(NSDictionary *)personalizationDic {
    if (swrveButton.events != nil) {
        [self queueButtonEvents:swrveButton.events personalization:self.personalization];
    }
    
    if (swrveButton.userUpdates != nil) {
        [self queueButtonUserUpdates:swrveButton.userUpdates personalization:self.personalization];
    }
}

- (void)beginHideMessageAnimationWithCompletionHandler:(void (^)(void))completionHandler {
    [UIView animateWithDuration:0.25
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.messageController.inAppMessageWindow.rootViewController.view.alpha = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         [SwrveLogger debug:@"Message hide animation completed:%@", @(finished)];
                         [self.messageController dismissMessageWindow];
                         if (completionHandler) {
                             completionHandler();
                         }
                     }];
}

- (void)showPage:(NSNumber *)pageIdToShow {
    SwrveMessagePageViewController *messagePageViewController = [self messagePageViewController:pageIdToShow];
#if TARGET_OS_TV
    [SwrveMessageViewController showTvOSController:messagePageViewController inParentController:self];
#else
    [SwrveMessageViewController showIOSController:messagePageViewController inPageController:self pageId:pageIdToShow];
#endif
}

+ (void)showIOSController:(SwrveMessagePageViewController *)messagePageViewController inPageController:(UIPageViewController *)pageViewController pageId:(NSNumber *)pageId {
    [pageViewController setViewControllers:@[messagePageViewController]
                                 direction:UIPageViewControllerNavigationDirectionForward
                                  animated:NO
                                completion:nil];
    SwrveMessagePage *page = [messagePageViewController.messageFormat.pages objectForKey:pageId];
    if (messagePageViewController.messageFormat.pages.count == 1 || (page.swipeBackward == -1 && page.swipeForward == -1)) {
        [SwrveMessageViewController disableSwipe:pageViewController.view];
    }
}

+ (void)showTvOSController:(SwrveMessagePageViewController *)messagePageViewController inParentController:(UIViewController *)parentViewController {
    // remove subviews
    UIView *storyView;
    UIView *storyButton;
    for (UIView *view in parentViewController.view.subviews) {
        if ([view isKindOfClass:[SwrveInAppStoryView class]]) {
            storyView = view;
        } else if ([view isKindOfClass:[SwrveInAppStoryUIButton class]]) {
            storyButton = view;
        } else {
            [view removeFromSuperview];
        }
    }
    // remove child controller
    for (UIViewController *controller in parentViewController.childViewControllers) {
        [controller removeFromParentViewController];
    }

    [parentViewController addChildViewController:messagePageViewController];
    [parentViewController.view addSubview:messagePageViewController.view];
    [parentViewController.view addSubview:storyView];
    [parentViewController.view addSubview:storyButton];
    [messagePageViewController didMoveToParentViewController:parentViewController];
}

- (void)redrawStoryView {
    if (!self.storyView) {
        return;
    }
    [self.storyView stop];
    [self.storyView removeFromSuperview];
    self.storyView = nil;
    if (self.storyDismissButton) {
        [self.storyDismissButton removeFromSuperview];
        self.storyDismissButton = nil;
    }
    [self startStoryViewSegment:self.currentPageId];
}

- (void)startStoryViewSegment:(NSNumber *)pageIdToShow {
    if (self.currentMessageFormat.storySettings == nil) {
        return; // No story settings so do nothing
    }
    if (self.storyView == nil) {
        [self initStoryView];
    }
    int segmentIndex = (int) [self.currentMessageFormat.pagesOrdered indexOfObject:pageIdToShow];
    [self.storyView startSegmentAtIndex:segmentIndex];
}

- (void)initStoryView {
    NSUInteger numberOfPages = [self.currentMessageFormat pages].count;
    CGFloat renderScale = [SwrveSDKUtils renderScaleFor:self.currentMessageFormat withParentSize:self.iamWindowSize];
    CGRect storyViewFrame = [self storyViewFrame:renderScale];
    NSArray *pageDurations = [self pageDurations];
    self.storyView = [[SwrveInAppStoryView alloc] initWithFrame:storyViewFrame
                                                       delegate:self
                                                  storySettings:self.currentMessageFormat.storySettings
                                               numberOfSegments:(int) numberOfPages
                                                    renderScale:renderScale
                                                  pageDurations:pageDurations];
    [self.view addSubview:self.storyView];
    [self storyViewPosition:renderScale];
    [self addDismissButton:renderScale];

#if TARGET_OS_IOS
    if (self.currentMessageFormat.storySettings.gesturesEnabled) {
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        tapGestureRecognizer.numberOfTapsRequired = 1;
        [self.view addGestureRecognizer:tapGestureRecognizer];
    }
#endif
}

- (CGRect)storyViewFrame:(CGFloat)renderScale {
    SwrveStorySettings *storySettings = self.currentMessageFormat.storySettings;
    CGFloat leftPadding = storySettings.leftPadding.floatValue * renderScale;
    CGFloat rightPadding = storySettings.rightPadding.floatValue * renderScale;
    CGFloat width = self.iamWindowSize.width - leftPadding - rightPadding;
    CGFloat height = storySettings.barHeight.floatValue * renderScale;
    return CGRectMake(0, 0, width, height);
}

- (NSArray *)pageDurations {
    NSMutableArray *pageDurations = [NSMutableArray new];
    for (NSNumber *pageId in self.currentMessageFormat.pagesOrdered) {
        SwrveMessagePage *page = [self.currentMessageFormat.pages objectForKey:pageId];
        if(page.pageDuration) {
            [pageDurations addObject:page.pageDuration];
        }
    }
    return [NSArray arrayWithArray:pageDurations];
}

- (void)storyViewPosition:(CGFloat)renderScale {
    SwrveStorySettings *storySettings = self.currentMessageFormat.storySettings;
    CGFloat topPadding = storySettings.topPadding.floatValue * renderScale;
    CGFloat leftPadding = storySettings.leftPadding.floatValue * renderScale;
    CGFloat rightPadding = storySettings.rightPadding.floatValue * renderScale;
    self.storyView.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 11.0, tvOS 11.0, *)) {
        [NSLayoutConstraint activateConstraints:@[
                [self.storyView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:topPadding],
                [self.storyView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:leftPadding],
                [self.storyView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-rightPadding]
        ]];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [NSLayoutConstraint activateConstraints:@[
                [self.storyView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor constant:topPadding],
                [self.storyView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:leftPadding],
                [self.storyView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-rightPadding]
        ]];
#pragma clang diagnostic pop
    }
}

- (void)addDismissButton:(CGFloat)renderScale {
    SwrveStorySettings *storySettings = self.currentMessageFormat.storySettings;
    if (storySettings.dismissButton == nil) {
        return;
    }

    UIImage *dismissImage = nil;
    UIImage *dismissImageHighlighted = nil;
    SwrveMessageController *messageControllerStrong = self.messageController;
    if (messageControllerStrong) {
        dismissImage = messageControllerStrong.inAppMessageConfig.storyDismissButton;
        dismissImageHighlighted = messageControllerStrong.inAppMessageConfig.storyDismissButtonHighlighted;
    }
    if (dismissImage == nil) {
        dismissImage = [SwrveSDKUtils iamStoryDismissImage]; // use custom image if available and fallback to default
    }
    if (dismissImage == nil) {
        return;
    }

    self.storyDismissButton = [[SwrveInAppStoryUIButton alloc] initWithButton:storySettings.dismissButton
                                                                 dismissImage:dismissImage
                                                      dismissImageHighlighted:dismissImageHighlighted];
    [self.view addSubview:self.storyDismissButton];

    CGFloat topPadding = storySettings.topPadding.floatValue * renderScale;
    CGFloat height = storySettings.barHeight.floatValue * renderScale;
    CGFloat marginTop = storySettings.dismissButton.marginTop.floatValue * renderScale;
    CGFloat topAnchorConstant = topPadding + height + marginTop;
    CGFloat size = storySettings.dismissButton.size.floatValue * renderScale;
    if (@available(iOS 11.0, tvOS 11.0, *)) {
        [NSLayoutConstraint activateConstraints:@[
                [self.storyDismissButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:topAnchorConstant],
                [self.storyDismissButton.rightAnchor constraintEqualToAnchor:self.storyView.rightAnchor],
                [self.storyDismissButton.widthAnchor constraintEqualToConstant:size],
                [self.storyDismissButton.heightAnchor constraintEqualToConstant:size]
        ]];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [NSLayoutConstraint activateConstraints:@[
                [self.storyDismissButton.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor constant:topAnchorConstant],
                [self.storyDismissButton.rightAnchor constraintEqualToAnchor:self.storyView.rightAnchor],
                [self.storyDismissButton.widthAnchor constraintEqualToConstant:size],
                [self.storyDismissButton.heightAnchor constraintEqualToConstant:size]
        ]];
#pragma clang diagnostic pop
    }

    SEL buttonPressedSelector = NSSelectorFromString(@"onDismissButtonPressed:");
#if TARGET_OS_IOS /** TouchUpInside is iOS only **/
    [self.storyDismissButton  addTarget:self action:buttonPressedSelector forControlEvents:UIControlEventTouchUpInside];
#elif TARGET_OS_TV
    // There are no touch actions in tvOS, so Primary Action Triggered is the event to run it
    [self.storyDismissButton  addTarget:self action:buttonPressedSelector forControlEvents:UIControlEventPrimaryActionTriggered];
#endif
}

- (IBAction)onDismissButtonPressed:(id)sender {
    NSNumber *buttonId = self.currentMessageFormat.storySettings.dismissButton.buttonId;
    NSString *buttonName = self.currentMessageFormat.storySettings.dismissButton.name;
    [self queueDismissEvent:self.currentPageId buttonId:buttonId buttonName:buttonName];
    SwrveMessageController *messageControllerStrong = self.messageController;
    if (messageControllerStrong) {
        // Save info for processing later in the messageController
        messageControllerStrong.inAppMessageActionType = kSwrveActionDismiss;
        messageControllerStrong.inAppMessageAction = @"";
        messageControllerStrong.inAppButtonPressedName = buttonName;
        messageControllerStrong.inAppButtonPressedText = @"";
        [self beginHideMessageAnimationWithCompletionHandler:nil];
    }
    
    if (self.storyView != nil) {
        [self.storyView stop];
    }
}

// Not used in tvOS
- (void)handleTap:(UITapGestureRecognizer *)tap {
    CGPoint tapLocation = [tap locationInView:self.view];
    CGFloat halfScreenWidth = CGRectGetWidth(self.view.bounds) / 2.0;
    NSUInteger indexToShow;
    if (tapLocation.x < halfScreenWidth) {
        indexToShow = ((NSUInteger) self.storyView.currentIndex) - 1;
    } else {
        indexToShow = ((NSUInteger) self.storyView.currentIndex) + 1;
    }
    if (indexToShow >= 0 && indexToShow < self.currentMessageFormat.pagesOrdered.count) {
        NSNumber *pageIdToShow = self.currentMessageFormat.pagesOrdered[indexToShow];
        [self showPage:pageIdToShow];
        [self startStoryViewSegment:pageIdToShow];
    }
}

// SwrveInAppStorySegmentDelegate
- (void)segmentFinishedAtIndex:(NSUInteger)segmentIndex {
    if (segmentIndex < self.currentMessageFormat.pagesOrdered.count - 1) {
        NSNumber *pageIdToShow = self.currentMessageFormat.pagesOrdered[segmentIndex + 1];
        [self showPage:pageIdToShow];
    } else {
        [self handleLastPageProgression:self.currentMessageFormat.storySettings.lastPageProgression];
    }
}

- (void)handleLastPageProgression:(LastPageProgression)lastPageProgression {
    if (lastPageProgression == kSwrveStoryLastPageProgressionDismiss) {
        [SwrveLogger debug:@"Last page progression is dismiss, so dismissing", nil];

        NSNumber *buttonId = self.currentMessageFormat.storySettings.lastPageDismissId;
        NSString *buttonName = self.currentMessageFormat.storySettings.lastPageDismissName;
        [self queueDismissEvent:self.currentPageId buttonId:buttonId buttonName:buttonName];

        SwrveMessageController *messageControllerStrong = self.messageController;
        if (messageControllerStrong) {
            // Save info for processing later in the messageController, but without inAppButtonPressedName/inAppButtonPressedText
            messageControllerStrong.inAppMessageActionType = kSwrveActionDismiss;
            messageControllerStrong.inAppMessageAction = @"";
            [self beginHideMessageAnimationWithCompletionHandler:nil];
        }
    } else if (lastPageProgression == kSwrveStoryLastPageProgressionLoop) {
        [SwrveLogger debug:@"Last page progression is loop, so restarting the story", nil];
        NSNumber *firstPageId = self.currentMessageFormat.pagesOrdered[0];
        [self showPage:firstPageId];
        [self.storyView startSegmentAtIndex:0];
    } else if (lastPageProgression == kSwrveStoryLastPageProgressionStop) {
        [SwrveLogger debug:@"Last page progression is stop, so remain on last page", nil];
    }
}

- (void)setControllerBackgroundColor {
    if (self.currentMessageFormat.backgroundColor != nil) {
        self.view.backgroundColor = self.currentMessageFormat.backgroundColor;
    } else {
        self.view.backgroundColor = self.messageController.inAppMessageConfig.backgroundColor;
    }
}

+ (void)disableSwipe:(UIView *)controllerRootView {
    for (UIView *view in controllerRootView.subviews) {
        if ([view isKindOfClass:[UIScrollView class]]) {
            UIScrollView *scrollView = (UIScrollView *) view;
            scrollView.bounces = NO;
            scrollView.scrollEnabled = NO;
            break;
        }
    }
}

- (void)queuePageViewEvent:(NSNumber *)pageId {
    if ([self.pageViewEventsSent containsObject:pageId]) {
        [SwrveLogger debug:@"Page view event for page_id %@ already sent", pageId];
        return;
    }

    id <SwrveCommonDelegate> swrveCommon = (id <SwrveCommonDelegate>) [SwrveCommon sharedInstance];
    NSMutableDictionary *eventData = [NSMutableDictionary new];
    [eventData setValue:@"iam" forKey:@"campaignType"];
    [eventData setValue:@"page_view" forKey:@"actionType"];
    [eventData setValue:self.message.messageID forKey:@"id"];
    [eventData setValue:pageId forKey:@"contextId"];

    NSMutableDictionary *eventPayload = [NSMutableDictionary new];
    SwrveMessagePage *page = [self.currentMessageFormat.pages objectForKey:pageId];
    if(page.pageName && page.pageName.length > 0) {
        [eventPayload setValue:page.pageName forKey:@"pageName"];
    }
    [eventData setValue:eventPayload forKey:@"payload"];

    [swrveCommon queueEvent:@"generic_campaign_event" data:eventData triggerCallback:false];
    [self.pageViewEventsSent addObject:pageId];
}

- (void)queuePageNavEvent:(NSNumber *)pageId buttonId:(NSNumber *)buttonId pageIdToShow:(NSNumber *)pageIdToShow buttonName:(NSString *)buttonName {
    if ([self.navigationEventsSent containsObject:buttonId]) {
        [SwrveLogger debug:@"Navigation event for button_id %@ already sent", buttonId];
        return;
    }

    id <SwrveCommonDelegate> swrveCommon = (id <SwrveCommonDelegate>) [SwrveCommon sharedInstance];
    NSMutableDictionary *eventData = [NSMutableDictionary new];
    [eventData setValue:@"iam" forKey:@"campaignType"];
    [eventData setValue:@"navigation" forKey:@"actionType"];
    [eventData setValue:self.message.messageID forKey:@"id"];
    [eventData setValue:pageId forKey:@"contextId"];

    NSMutableDictionary *eventPayload = [NSMutableDictionary new];
    SwrveMessagePage *page = [self.currentMessageFormat.pages objectForKey:pageId];
    if(page.pageName && page.pageName.length > 0) {
        [eventPayload setValue:page.pageName forKey:@"pageName"];
    }
    if(pageIdToShow && [pageIdToShow integerValue] > 0) {
        [eventPayload setValue:pageIdToShow forKey:@"to"];
    }
    if(buttonId && [buttonId integerValue] > 0) {
        [eventPayload setValue:buttonId forKey:@"buttonId"];
    }
    if(buttonName && [buttonName length] > 0) {
        [eventPayload setValue:buttonName forKey:@"buttonName"];
    }
    [eventData setValue:eventPayload forKey:@"payload"];

    [swrveCommon queueEvent:@"generic_campaign_event" data:eventData triggerCallback:false];
    [self.navigationEventsSent addObject:buttonId];
}

- (void)queueDismissEvent:(NSNumber *)pageId buttonId:(NSNumber *)buttonId buttonName:(NSString *)buttonName {
    id <SwrveCommonDelegate> swrveCommon = (id <SwrveCommonDelegate>) [SwrveCommon sharedInstance];
    NSMutableDictionary *eventData = [NSMutableDictionary new];
    [eventData setValue:@"iam" forKey:@"campaignType"];
    [eventData setValue:@"dismiss" forKey:@"actionType"];
    [eventData setValue:self.message.messageID forKey:@"id"];
    [eventData setValue:pageId forKey:@"contextId"];

    NSMutableDictionary *eventPayload = [NSMutableDictionary new];
    SwrveMessagePage *page = [self.currentMessageFormat.pages objectForKey:pageId];
    if(page.pageName && page.pageName.length > 0) {
        [eventPayload setValue:page.pageName forKey:@"pageName"];
    }
    if(buttonName && [buttonName length] > 0) {
        [eventPayload setValue:buttonName forKey:@"buttonName"];
    }
    if(buttonId && [buttonId integerValue] > 0) {
        [eventPayload setValue:buttonId forKey:@"buttonId"];
    }
    [eventData setValue:eventPayload forKey:@"payload"];

    [swrveCommon queueEvent:@"generic_campaign_event" data:eventData triggerCallback:false];
}

#if TARGET_OS_TV

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator __IOS_AVAILABLE(9.0) __TVOS_AVAILABLE(9.0) {

    [self.messageFocus applyFocusOnSwrveButton:context];

    id <SwrveInAppMessageFocusDelegate> delegate = self.messageController.inAppMessageConfig.inAppMessageFocusDelegate;
    if (delegate != nil && [delegate respondsToSelector:@selector(didUpdateFocusInContext:withAnimationCoordinator:parentView:)]) {
        [delegate didUpdateFocusInContext:context withAnimationCoordinator:coordinator parentView:self.view];
    } else {
        [self.messageFocus applyDefaultFocusInContext:context];
    }
}
#endif

- (void)addPayload:(NSMutableDictionary *)newPayload fromPayloadValues:(NSDictionary *)payload personalization:(NSDictionary *)personalizationDic {
    NSString *key = [payload objectForKey:@"key"];
    NSString *value = [payload objectForKey:@"value"];
    NSString *personlizedValue = [self.messageController personalizeText:value withPersonalization:personalizationDic];
    if (key != nil && personlizedValue != nil) {
        [newPayload setObject:personlizedValue forKey:key];
    }
}

- (void)queueButtonEvents:(NSArray *)events personalization:(NSDictionary *)personalizationDic {
    id <SwrveCommonDelegate> swrveCommon = (id <SwrveCommonDelegate>) [SwrveCommon sharedInstance];
    for (NSDictionary *event in events) {
        NSString *name = [event objectForKey:@"name"];
        NSArray *payloadArray = [event objectForKey:@"payload"];
        if (payloadArray != nil && [payloadArray count] > 0) {
            NSMutableDictionary *eventPayload = [NSMutableDictionary new];
            for (NSDictionary *payload in payloadArray) {
                [self addPayload:eventPayload fromPayloadValues:payload personalization:personalizationDic];
            }
            if ([eventPayload count] > 0) {
                NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
                [data setValue:NullableNSString(name) forKey:@"name"];
                [data setValue:eventPayload forKey:@"payload"];
                [swrveCommon queueEvent:@"event" data:data triggerCallback:true];
            }
        } else {
            NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
            [data setValue:NullableNSString(name) forKey:@"name"];
            [data setValue:@{} forKey:@"payload"];
            [swrveCommon queueEvent:@"event" data:data triggerCallback:true];
        }
    }
}

- (void)queueButtonUserUpdates:(NSArray *)userUpdates personalization:(NSDictionary *)personalizationDic {
    NSMutableDictionary *userPayload = [NSMutableDictionary new];
    for (NSDictionary *payload in userUpdates) {
        [self addPayload:userPayload fromPayloadValues:payload personalization:personalizationDic];
    }
    if ([userPayload count] > 0) {
        id <SwrveCommonDelegate> swrveCommon = (id <SwrveCommonDelegate>) [SwrveCommon sharedInstance];
        [swrveCommon userUpdate:userPayload];
    }
}

@end
