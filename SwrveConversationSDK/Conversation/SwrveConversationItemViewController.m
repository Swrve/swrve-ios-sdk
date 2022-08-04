#import "SwrveBaseConversation.h"
#import "SwrveConversationAtom.h"
#import "SwrveConversationButton.h"
#import "SwrveConversationEvents.h"
#import "SwrveConversationItemViewController.h"
#import "SwrveConversationPane.h"
#import "SwrveInputMultiValue.h"
#import "SwrveContentImage.h"
#if __has_include(<SwrveSDKCommon/SwrveCommon.h>)
#import <SwrveSDKCommon/SwrveCommon.h>
#else
#import "SwrveCommon.h"
#endif
#import "SwrveConversationStyler.h"
#import "SwrveConversationsNavigationController.h"
#import "SwrveConversationContainerViewController.h"
#import "SwrveConversationResourceManagement.h"

@interface SwrveConversationItemViewController() {
    NSUInteger numViewsReady;
    CGFloat keyboardOffset;
#if TARGET_OS_IOS /** exclude tvOS **/
    UIDeviceOrientation currentOrientation;
#endif
    SwrveBaseConversation *conversation;
    id<SwrveMessageEventHandler> controller;
}

@property (nonatomic) BOOL wasShownToUserNotified;

@end

@implementation SwrveConversationItemViewController

@synthesize fullScreenBackgroundImageView;
@synthesize contentTableView;
@synthesize buttonsView;
@synthesize cancelButtonView;
@synthesize conversationPane = _conversationPane;
@synthesize conversation;
@synthesize wasShownToUserNotified;
@synthesize contentHeight;

+ (SwrveConversationItemViewController *)initConversation {

    SwrveConversationItemViewController *itemViewController = [SwrveConversationItemViewController new];

    // -- Background Image
    itemViewController.fullScreenBackgroundImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    [itemViewController.view addSubview:itemViewController.fullScreenBackgroundImageView];

    // -- Atoms table
    UITableView *tableview = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableview.delegate = itemViewController;
    tableview.dataSource = itemViewController;
    itemViewController.contentTableView = tableview;
    [itemViewController.view addSubview:itemViewController.contentTableView];

    // -- Atoms buttons view
    UIView *buttonView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, itemViewController.view.frame.size.width, 0)];
    itemViewController.buttonsView = buttonView;
    [itemViewController.view addSubview:itemViewController.buttonsView];

    // -- Cancel button
    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectZero]; // will set with constraints in viewWillAppear
    [cancelButton addTarget:itemViewController action:@selector(cancelButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setImage:[SwrveConversationResourceManagement imageWithName:@"close_button"] forState:UIControlStateNormal];
    itemViewController.cancelButtonView = cancelButton;
    [itemViewController.view addSubview:itemViewController.cancelButtonView];

    return itemViewController;
}

+ (SwrveConversationItemViewController *)initFromStoryboard {
     // This function exists as a Unity SDK bridge since it still uses this specific name. delete when not longer used by Unity.
    return [self initConversation];
}

+ (bool)showConversation:(SwrveBaseConversation *)conversation
    withItemController:(SwrveConversationItemViewController *)conversationItemViewController
        withEventHandler:(id<SwrveMessageEventHandler>) eventHandler
                inWindow:(UIWindow *)conversationWindow
     withMessageDelegate:(id)messageDelegate {
    return [SwrveConversationItemViewController showConversation:conversation withItemController:conversationItemViewController withEventHandler:eventHandler inWindow:conversationWindow withStatusBarHidden:NO];
}

+ (bool)showConversation:(SwrveBaseConversation *)conversation
    withItemController:(SwrveConversationItemViewController *)conversationItemViewController
        withEventHandler:(id<SwrveMessageEventHandler>) eventHandler
                inWindow:(UIWindow *)conversationWindow
     withStatusBarHidden:(BOOL)preferStatusBarHidden {
    
#if TARGET_OS_IOS /** exclude tvOS **/

    if (!conversation || conversationItemViewController == nil || conversationWindow == nil) {
        [SwrveLogger error:@"Unable to showConversation.", nil];
        return false;
    }

    if ([SwrveConversationItemViewController hasUnknownContentAtoms:conversation]) {
        [SwrveLogger error:@"Unable to showConversation. Conversation %i contains unknown atoms", [conversation.conversationID intValue]];
        return false;
    }

    [conversationItemViewController setConversation:conversation andMessageController:eventHandler];

    // Create a navigation controller in which to push the conversation, and choose iPad presentation style
    SwrveConversationsNavigationController *svnc = [[SwrveConversationsNavigationController alloc] initWithRootViewController:conversationItemViewController];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wselector"
    // Attach cancel button to the conversation navigation options
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:conversationItemViewController
                                                                                  action:@selector(cancelButtonTapped:)];
#pragma clang diagnostic pop
    conversationItemViewController.navigationItem.leftBarButtonItem = cancelButton;

    dispatch_async(dispatch_get_main_queue(), ^{
        SwrveConversationContainerViewController* rootController = [[SwrveConversationContainerViewController alloc] initWithChildViewController:svnc withStatusBarHidden:preferStatusBarHidden];
        conversationWindow.rootViewController = rootController;
        conversationWindow.windowLevel = UIWindowLevelAlert + 1;
        [conversationWindow makeKeyAndVisible];
        [conversationWindow.rootViewController.view endEditing:YES];
    });

    return true;
    
#elif TARGET_OS_TV
    [SwrveLogger error:@"Conversations are not supported on tvOS.", nil];
    return false;
#endif
}

+ (bool)hasUnknownContentAtoms:(SwrveBaseConversation *)conversation {
    bool hasUnknownContentAtoms = false;
    for (SwrveConversationPane *page in conversation.pages) {

        for (SwrveContentItem *contentItem in page.content) {
            if ([[contentItem type] isEqualToString:kSwrveContentUnknown]) {
                hasUnknownContentAtoms = true;
                break;
            }
        }
        if(hasUnknownContentAtoms) {
            break;
        }
    }

    return hasUnknownContentAtoms;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.wasShownToUserNotified == NO) {
        [self.conversation wasShownToUser];
        self.wasShownToUserNotified = YES;
    }
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (@available(iOS 9.0, *)) {

        // - background image constraints
        self.fullScreenBackgroundImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.fullScreenBackgroundImageView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
        [self.fullScreenBackgroundImageView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;
        [self.fullScreenBackgroundImageView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
        [self.fullScreenBackgroundImageView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;

        self.buttonsView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.buttonsView.heightAnchor constraintEqualToConstant:65.0f].active = YES;

        self.contentTableView.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.cancelButtonView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.cancelButtonView.widthAnchor constraintEqualToConstant:40.0f].active = YES;
        [self.cancelButtonView.heightAnchor constraintEqualToConstant:40.0f].active = YES;
        
#if TARGET_OS_IOS /** exclude tvOS **/
        if (@available(iOS 11, *)) {
            [self.buttonsView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor].active = YES;
            [self.buttonsView.rightAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.rightAnchor constant: -5].active = YES;
            [self.buttonsView.leftAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leftAnchor constant:5].active = YES;
            
            [self.contentTableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor].active = YES;
            [self.contentTableView.rightAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.rightAnchor].active = YES;
            [self.contentTableView.leftAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leftAnchor].active = YES;
            [self.contentTableView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-65].active = YES;
            
            [self.cancelButtonView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor].active = YES;
            [self.cancelButtonView.rightAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.rightAnchor].active = YES;
        } else {
            [self.buttonsView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
            [self.buttonsView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant: -5].active = YES;
            [self.buttonsView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:5].active = YES;
            
            [self.contentTableView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
            [self.contentTableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;
            [self.contentTableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
            [self.contentTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-65].active = YES;
            
            [self.cancelButtonView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
            [self.cancelButtonView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;
        }
#endif
    } else {
        // This section is build for iOS 10.0 and above
    }

    // Subscribe to internal notifications and orientation changes
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(viewReady:)
                                                 name:kSwrveNotificationViewReady
                                               object:nil];
#if TARGET_OS_IOS /** exclude tvOS **/
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
#endif

    self.navigationController.navigationBarHidden = YES;
    self.view.hidden = YES;
    [self updateUI];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    for(SwrveConversationAtom *atom in self.conversationPane.content) {
        [atom viewDidDisappear];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    // Unsubscribe from internal notifications and orientation changes
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kSwrveNotificationViewReady
                                                  object:nil];
#if TARGET_OS_IOS /** exclude tvOS **/
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
#endif

    // Cleanup views for all panes
    for(SwrveConversationPane* page in self.conversation.pages) {
        for(SwrveConversationAtom* contentItem in page.content) {
            [contentItem removeView];
        }
        for(SwrveConversationAtom* contentItem in page.controls) {
            [contentItem removeView];
        }
    }
}

#pragma mark ViewDidLoad

- (void)viewDidLoad {
    [super viewDidLoad];

    if (@available(iOS 7.0, *)) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
        self.navigationController.navigationBar.translucent = NO;
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self resizeUIView:self.view.superview.bounds.size];
}

-(void)resizeUIView:(CGSize)size {
    if (size.width > SWRVE_CONVERSATION_MAX_WIDTH) {
        float centerx = ((float)size.width - SWRVE_CONVERSATION_MAX_WIDTH)/2.0f;
        CGRect newFrame = CGRectMake(centerx, SWRVE_CONVERSATION_MODAL_MARGIN, SWRVE_CONVERSATION_MAX_WIDTH, size.height - (SWRVE_CONVERSATION_MODAL_MARGIN*2));
        
        float maxControlsHeight = (float)buttonsView.frame.size.height;
        float modalHeight = (contentHeight + maxControlsHeight);
        if (modalHeight < (size.height - SWRVE_CONVERSATION_MODAL_MARGIN)) {
            newFrame.size.height = modalHeight;
            newFrame.origin.y = (size.height / 2) - (newFrame.size.height / 2);
        }

        self.view.frame = newFrame;
        // Apply styles from conversationPane
        [SwrveConversationStyler styleModalView:self.view withStyle:self.conversationPane.pageStyle];
        self.view.layer.masksToBounds = YES;

    } else {
        CGRect newFrame = CGRectMake(0, 0, size.width, size.height);
        self.view.frame = newFrame;
        // Hide border
        self.view.layer.borderWidth = 0;
        self.view.layer.cornerRadius = 0.0f;
    }

    for (SwrveConversationAtom *atom in self.conversationPane.content) {
        // Layout with the frame of the root UIView
        [atom parentViewChangedSize:self.view.frame.size];
    }
}

-(SwrveConversationPane *)conversationPane {
    return _conversationPane;
}

-(void) setConversationPane:(SwrveConversationPane *)conversationPane {
    _conversationPane = conversationPane;
    numViewsReady = 0;
    [SwrveConversationEvents impression:conversation onPage:_conversationPane.tag];
    // Apply styles from conversationPane
    [SwrveConversationStyler styleModalView:self.view withStyle:conversationPane.pageStyle];
}

-(CGFloat) buttonHorizontalPadding {
    return 6.0;
}

-(void) performActions:(SwrveConversationButton *)control {
    [self performActions:control withConversationPaneTag:self.conversationPane.tag];
}

-(void) performActions:(SwrveConversationButton *)control withConversationPaneTag:(NSString *)conversationPaneTag NS_EXTENSION_UNAVAILABLE_IOS("") {
    NSDictionary *actions = control.actions;
    SwrveConversationActionType actionType = SwrveVisitURLActionType;
    id param;

    if (actions == nil) {
        return;
    }

    for (NSString *key in [actions allKeys]) {
        if ([key isEqualToString:@"visit"]) {
            actionType = SwrveVisitURLActionType;
            NSDictionary *visitDict = [actions objectForKey:@"visit"];
            param = [visitDict objectForKey:@"url"];
        } else if ([key isEqualToString:@"deeplink"]) {
            actionType = SwrveDeeplinkActionType;
            NSDictionary *deeplinkDict = [actions objectForKey:@"deeplink"];
            param = [deeplinkDict objectForKey:@"url"];
        } else if ([key isEqualToString:@"call"]) {
            actionType = SwrveCallNumberActionType;
            param = [actions objectForKey:@"call"];
        } else if ([key isEqualToString:@"permission_request"]) {
            actionType = SwrvePermissionRequestActionType;
            NSDictionary *permissionDict = [actions objectForKey:@"permission_request"];
            param = [permissionDict objectForKey:@"permission"];
        } else {
            [SwrveConversationEvents error:conversation onPage:conversationPaneTag withControl:control.tag];
        }
    }

    switch (actionType) {
        case SwrveCallNumberActionType: {
            [SwrveConversationEvents callNumber:conversation onPage:conversationPaneTag withControl:control.tag];
            NSURL *callUrl = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", param]];
            if (@available(iOS 10.0, *)) {
                [[UIApplication sharedApplication] openURL:callUrl options:@{} completionHandler:^(BOOL success) {
                    [SwrveLogger debug:@"Opening url [%@] successfully: %d", callUrl, success];
                }];
            } else {
                [SwrveLogger error:@"Could not open url, not supported (should not reach this code)", nil];
            }
            break;
        }
        case SwrveVisitURLActionType: {
            if (!param) {
                [SwrveConversationEvents error:conversation onPage:conversationPaneTag withControl:control.tag];
                return;
            }

            NSURL *target = [NSURL URLWithString:param];
            if (![target scheme]) {
                target = [NSURL URLWithString:[@"http://" stringByAppendingString:param]];
            }

            if (target == nil || ![[UIApplication sharedApplication] canOpenURL:target]) {
                // The URL scheme could be an app URL scheme, but there is a chance that
                // the user doesn't have the app installed, which leads to confusing behaviour
                // Notify the user that the app isn't available and then just return.
                [SwrveConversationEvents error:conversation onPage:conversationPaneTag withControl:control.tag];
                [SwrveLogger error:@"Could not open the Conversation URL: %@", param, nil];
            } else {
                [SwrveConversationEvents linkVisit:conversation onPage:conversationPaneTag withControl:control.tag];
                if (@available(iOS 10.0, *)) {
                    [[UIApplication sharedApplication] openURL:target options:@{} completionHandler:^(BOOL success) {
                        [SwrveLogger debug:@"Opening url [%@] successfully: %d", target, success];
                    }];
                } else {
                    [SwrveLogger error:@"Could not open url, not supported (should not reach this code)", nil];
                }
            }
            break;
        }
        case SwrvePermissionRequestActionType: {
            // Ask for the configured permission
            if(![[SwrveCommon sharedInstance] processPermissionRequest:param]) {
                [SwrveLogger error:@"Unknown permission request %@", param, nil];
            } else {
                [SwrveConversationEvents permissionRequest:conversation onPage:conversationPaneTag withControl:control.tag];
            }
            break;
        }
        case SwrveDeeplinkActionType: {
            if (!param) {
                [SwrveConversationEvents error:conversation onPage:conversationPaneTag withControl:control.tag];
                return;
            }
            NSURL *target = [NSURL URLWithString:param];
            [SwrveConversationEvents deeplinkVisit:conversation onPage:conversationPaneTag withControl:control.tag];
            if (@available(iOS 10.0, *)) {
                [[UIApplication sharedApplication] openURL:target options:@{} completionHandler:^(BOOL success) {
                    [SwrveLogger debug:@"Opening url [%@] successfully: %d", target, success];
                }];
            } else {
                [SwrveLogger error:@"Could not open deeplink, not supported (should not reach this code)", nil];
            }
        }
        default:
            break;
    }
}

- (IBAction)cancelButtonTapped:(id)sender {
#pragma unused(sender)
    [SwrveConversationEvents cancel:conversation onPage:self.conversationPane.tag];
    // Send queued user input events
    [SwrveConversationEvents gatherAndSendUserInputs:self.conversationPane forConversation:conversation];
    [self dismiss];
}

-(void) buttonTapped:(id)sender {
    SwrveConversationButton *control = [self mapButtonToControl:(UIButton*)sender];
    [self transitionWithControl:control];
}

-(SwrveConversationButton*)mapButtonToControl:(UIButton*)button {
    // The sender is tagged with its index in the list of controls in the
    // conversation pane. Use this to lift the tag associated with the control
    // to populate the finished conversation event.
    NSUInteger tag = (NSUInteger)button.tag;
    return self.conversationPane.controls[(NSUInteger)tag];
}

-(BOOL)transitionWithControl:(SwrveConversationButton *)control {
    // Things that are 'running' need to be 'stopped'
    // Bit of a band-aid for videos continuing to play in the background for now.
    [self stopAtoms];

    // Issue events for data from the user
    [SwrveConversationEvents gatherAndSendUserInputs:self.conversationPane forConversation:conversation];

    // Move onto the next page in the conversation - fetch the next Convseration pane
    if ([control endsConversation]) {
        [SwrveConversationEvents done:conversation onPage:self.conversationPane.tag withControl:control.tag];
        dispatch_async(dispatch_get_main_queue(), ^ {
            [self dismiss];
        });
    } else {
        SwrveConversationPane *nextPage = [conversation pageForTag:control.target];
        [SwrveConversationEvents pageTransition:conversation fromPage:self.conversationPane.tag toPage:nextPage.tag withControl:control.tag];

        self.conversationPane = nextPage;
        dispatch_async(dispatch_get_main_queue(), ^ {
            [self updateUI];
        });
    }

    [self runControlActions:control onPage:self.conversationPane.tag];
    return YES;
}

-(void)stopAtoms {
    for(SwrveConversationAtom *atom in self.conversationPane.content) {
        [atom stop];
    }
}

-(void)dismiss {
    // Stop videos etc
    [self stopAtoms];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        @synchronized(self->controller) {
            // Delay for .01ms to account for killing the conversation stuff (iOS6)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (u_int64_t)0.01 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self->controller conversationClosed];
            });
        }
    }];
}

-(void)runControlActions:(SwrveConversationButton*)control onPage:(NSString *)tag{
    if (control.actions != nil) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            [self performActions:control withConversationPaneTag:tag];
        });
    }
}

-(void) viewReady:(NSNotification *)notification {
#pragma unused (notification)
    numViewsReady++;
    if (numViewsReady == self.conversationPane.content.count) {
        float newContentHeight = 0;
        for (SwrveConversationAtom *atom in self.conversationPane.content) {

            if ([atom.type isEqualToString:kSwrveInputMultiValue]) {
                SwrveInputMultiValue *multValue = (SwrveInputMultiValue *)atom;
                // Measure all rows including the description (+1) if needed
                int rows = (int)[multValue numberOfRowsNeeded];
                for (int i = 0; i < rows; i++) {
                    newContentHeight += (float)[multValue heightForRow:(uint)i inTableView:self.contentTableView];
                }

            } else if ([atom.type isEqualToString:kSwrveContentTypeImage]) {
                SwrveContentImage *imageAtom = (SwrveContentImage *)atom;
                newContentHeight += (float)imageAtom.view.frame.size.height;

            } else {
                newContentHeight += (float)atom.view.frame.size.height;
            }
        }

        contentHeight = newContentHeight;

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.contentTableView reloadData];
            [self viewWillLayoutSubviews];
            self.view.hidden = NO;
        });
    }
}

-(void) updateUI {
    self.navigationItem.title = self.conversationPane.title;
    [SwrveConversationStyler styleView:fullScreenBackgroundImageView withStyle:self.conversationPane.pageStyle];
    self.contentTableView.backgroundColor = [UIColor clearColor];

    // In the case where a pane is scrolled, then the user moves on to the next
    // pane, that second pane will display as scrolled too, unless we reset the
    // tableview to the top of the content stack.
    [self.contentTableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
#if TARGET_OS_IOS /** exclude tvOS **/
    self.contentTableView.separatorColor = [UIColor clearColor];
#endif
    
    // When all atoms are loaded, it will trigger a measurement of height (contentHeight)
    NSArray *contentToAdd = self.conversationPane.content;
    for (SwrveConversationAtom *atom in contentToAdd) {

        // Ensure there are no Checkmarks selected initially
        if ([atom.type isEqualToString:kSwrveInputMultiValue]) {
            SwrveInputMultiValue *vgInputMultiValue = (SwrveInputMultiValue *)atom;
            vgInputMultiValue.selectedIndex = -1;
        }

        [atom loadViewWithContainerView:self.view];
    }
    
    // Remove current buttons
    for (UIView *view in buttonsView.subviews) {
        [view removeFromSuperview];
    }

    NSArray *buttons = self.conversationPane.controls;
    // Buttons need to fit into width - 2*button padding
    // When there are n buttons, there are n-1 gaps between them
    // So, the buttons each take up (width-(n+1)*gapwidth)/numbuttons
    CGFloat buttonWidth = (buttonsView.frame.size.width-(buttons.count+1)*[self buttonHorizontalPadding])/buttons.count;
    CGFloat xOffset = [self buttonHorizontalPadding];
    for (NSUInteger i = 0; i < buttons.count; i++) {
        SwrveConversationButton *button = [buttons objectAtIndex:i];
        UIButton *buttonUIView = (UIButton*)button.view;
        buttonUIView.frame = CGRectMake(xOffset, 10, buttonWidth, 45.0);
        buttonUIView.tag = (NSInteger)i;
        [buttonUIView addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [SwrveConversationStyler styleButton:(SwrveConversationUIButton *)buttonUIView withStyle:button.style];
        [buttonsView addSubview:buttonUIView];
        xOffset += buttonWidth + [self buttonHorizontalPadding];
    }
}

#pragma mark - Rotation

#if TARGET_OS_IOS
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}
#endif

-(void)setConversation:(SwrveBaseConversation*)conv andMessageController:(id<SwrveMessageEventHandler>)ctrl
{
    conversation = conv;
    controller = ctrl;
    // The conversation is starting now, so issue a starting event
    SwrveConversationPane *firstPage = [conversation pageAtIndex:0];
    [SwrveConversationEvents started:conversation onStartPage:firstPage.tag];
    // Assigment will issue an impression event
    self.conversationPane = firstPage;
}

// Tapping the content view outside the context of any
// interactive input views requests the current first
// responder to relinquish its status. Gesture recognizer
// is then removed.
- (void)contentViewTapped:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded)     {
        for(SwrveConversationAtom *atom in self.conversationPane.content) {
            if([atom isKindOfClass:[SwrveInputItem class]]) {
                if([(SwrveInputItem *)atom isFirstResponder]) {
                    [(SwrveInputItem *)atom resignFirstResponder];
                    [self.contentTableView removeGestureRecognizer:sender];
                    return;
                }
            }
        }
    }
}

-(NSIndexPath *) indexPathForAtom:(SwrveConversationAtom *)atom {
    for(NSUInteger i = 0; i < self.conversationPane.content.count; i++) {
        if(atom == [self.conversationPane.content objectAtIndex:i]) {
            return [NSIndexPath indexPathForRow:0 inSection:(NSInteger)i];
        }
    }
    return nil;
}

-(UIView*) findTopView {
    // This navigates up to the Application. Different stuff for
    // phones and iPads though.
    UIView *v = self.view;
    while (v.superview) {
        v = v.superview;
    }
    return v;
}

#pragma mark TableViewDelegate Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#pragma unused (tableView)
    SwrveConversationAtom *atom = [self.conversationPane.content objectAtIndex:(NSUInteger)section];
    return (NSInteger)[atom numberOfRowsNeeded];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger objectIndex = [self objectIndexFromIndexPath:indexPath]; // HACK
    SwrveConversationAtom *atom = [self.conversationPane.content objectAtIndex:objectIndex];
    return [atom cellForRow:(NSUInteger)indexPath.row inTableView:tableView];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#pragma unused (tableView)
    // Each item is a "section"
    return (NSInteger)self.conversationPane.content.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
#pragma unused (tableView)
    NSUInteger objectIndex = [self objectIndexFromIndexPath:indexPath];
    SwrveConversationAtom *atom = [self.conversationPane.content objectAtIndex:objectIndex];
    return [atom heightForRow:(NSUInteger)indexPath.row inTableView:tableView];
}

- (NSUInteger) objectIndexFromIndexPath:(NSIndexPath *)indexPath {
    NSUInteger checkedIndexPath = (NSUInteger)indexPath.section;
    NSUInteger paneCount = [self.conversationPane.content count];
    if(checkedIndexPath >= paneCount) {
        checkedIndexPath = paneCount - 1;
    }
    return checkedIndexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    SwrveConversationAtom *atom = [self.conversationPane.content objectAtIndex:(NSUInteger)indexPath.section];
    if([atom.type isEqualToString:kSwrveInputMultiValue]) {
        SwrveInputMultiValue *vgInputMultiValue = (SwrveInputMultiValue *)atom;
        vgInputMultiValue.selectedIndex = indexPath.row;
        // Redraw the section, as we may have switched another off
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:(NSUInteger)indexPath.section];
        [tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

@end
