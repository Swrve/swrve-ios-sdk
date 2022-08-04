#import "SwrveMessageViewController.h"
#import "SwrveMessagePage.h"
#import "SwrveMessagePageViewController.h"
#import "SwrveMessageController.h"
#import "SwrveButton.h"
#import "SwrveMessageFocus.h"
#if __has_include(<SwrveSDKCommon/SwrveCommon.h>)
#import <SwrveSDKCommon/SwrveCommon.h>
#import <SwrveSDKCommon/SwrveLogger.h>
#else
#import "SwrveCommon.h"
#import "SwrveLogger.h"
#endif

@interface SwrveMessageController ()

@property(nonatomic, retain) UIWindow *inAppMessageWindow;
@property(nonatomic) SwrveActionType inAppMessageActionType;
@property(nonatomic, retain) NSString *inAppMessageAction;
@property(nonatomic, retain) NSString *inAppButtonPressedName;

- (void)queueMessageClickEvent:(SwrveButton *)button page:(SwrveMessagePage *)page;
- (void)messageWasShownToUser:(SwrveMessage *)message;

@end

@interface SwrveMessageViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property(nonatomic) CGSize iamWindowSize; // the current window size which is dependent on orientation
@property(nonatomic) BOOL wasShownToUserNotified;
@property(nonatomic, retain) NSMutableArray *pageViewEventsSent;
@property(nonatomic, retain) NSMutableArray *navigationEventsSent;
@property(nonatomic, retain) SwrveMessageFocus *messageFocus;
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
    NSNumber *firstPageId = [NSNumber numberWithLong:self.currentMessageFormat.firstPageId];
    [self showPage:firstPageId];

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
    CGRect screenRect = [keyWindow bounds];
    CGSize size = CGSizeMake(screenRect.size.width, screenRect.size.height);
    return size;
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

- (void)onButtonPressed:(UISwrveButton *)button pageId:(NSNumber *)pageIdPressed {

    SwrveMessagePage *page = [[self.currentMessageFormat pages] objectForKey:pageIdPressed];
    SwrveButton *swrveButton = [page.buttons objectAtIndex:(NSUInteger) button.tag];
    SwrveMessageController *messageControllerStrong = self.messageController;
    if (!messageControllerStrong || !swrveButton) {
        return;
    }

    if (swrveButton.actionType != kSwrveActionPageLink) {
        [messageControllerStrong queueMessageClickEvent:swrveButton page:page];
        messageControllerStrong.inAppButtonPressedName = swrveButton.name; // Save button name for processing later
    }

    NSString *action = button.actionString; // this may have been personalized so use button.actionString instead of swrveButton.actionString
    if (action == nil || [action isEqualToString:@""]) {
        action = swrveButton.actionString;
    }

    if (swrveButton.actionType == kSwrveActionPageLink) {
        NSNumber *pageIdToShow = @([action intValue]);
        [self queuePageNavEvent:self.currentPageId buttonId:button.buttonId pageIdToShow:pageIdToShow];
        [self showPage:pageIdToShow];
    } else {
        if (swrveButton.actionType == kSwrveActionDismiss) {
            [self queueDismissEvent:self.currentPageId buttonId:button.buttonId buttonName:button.buttonName];
        }
        // Save button type and action for processing later in the messageController
        messageControllerStrong.inAppMessageActionType = swrveButton.actionType;
        messageControllerStrong.inAppMessageAction = action;
        [self beginHideMessageAnimation];
    }
}

- (void)beginHideMessageAnimation {
    [UIView animateWithDuration:0.25
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.messageController.inAppMessageWindow.rootViewController.view.alpha = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         [SwrveLogger debug:@"Message hide animation completed:%@", @(finished)];
                         [self.messageController dismissMessageWindow];
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
    for (UIView *view in parentViewController.view.subviews) {
        [view removeFromSuperview];
    }
    // remove child controller
    for (UIViewController *controller in parentViewController.childViewControllers) {
        [controller removeFromParentViewController];
    }

    [parentViewController addChildViewController:messagePageViewController];
    [parentViewController.view addSubview:messagePageViewController.view];
    [messagePageViewController didMoveToParentViewController:parentViewController];
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

- (void)queuePageNavEvent:(NSNumber *)pageId buttonId:(NSNumber *)buttonId pageIdToShow:(NSNumber *)pageIdToShow {
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
    [self.messageFocus didUpdateFocusInContext:context];
}
#endif

@end
