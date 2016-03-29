#if !__has_feature(objc_arc)
#error ConverserSDK must be built with ARC.
// You can turn on ARC for only ConverserSDK files by adding -fobjc-arc to the build phase for each of its files.
#endif

#import "SwrveBaseConversation.h"
#import "SwrveMessageEventHandler.h"
#import "SwrveConversationAtom.h"
#import "SwrveConversationButton.h"
#import "SwrveConversationEvents.h"
#import "SwrveConversationItemViewController.h"
#import "SwrveConversationPane.h"
#import "SwrveInputMultiValue.h"
#import "SwrveSetup.h"
#import "SwrveConversationEvents.h"
#import "SwrveCommon.h"
#import "SwrveConversationStyler.h"
#import "SwrveConversationUIButton.h"

@interface SwrveConversationItemViewController() {
    NSUInteger numViewsReady;
    CGFloat keyboardOffset;
    UIDeviceOrientation currentOrientation;
    UITapGestureRecognizer *localRecognizer;
    SwrveBaseConversation *conversation;
    id<SwrveMessageEventHandler> controller;
    UIWindow* window;
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
    self.navigationController.navigationBarHidden = YES;
    [self updateUI];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    for(SwrveConversationAtom *atom in self.conversationPane.content) {
        [atom viewDidDisappear];
    }
}

-(SwrveConversationPane *)conversationPane {
    return _conversationPane;
}

-(void) setConversationPane:(SwrveConversationPane *)conversationPane {
    _conversationPane = conversationPane;
    numViewsReady = 0;
    [SwrveConversationEvents impression:conversation onPage:_conversationPane.tag];
}

-(CGFloat) buttonHorizontalPadding {
    return 6.0;
}

-(void) performActions:(SwrveConversationButton *)control {
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
            [SwrveConversationEvents error:conversation onPage:self.conversationPane.tag withControl:control.tag];
        }
    }
    
    switch (actionType) {
        case SwrveCallNumberActionType: {
            [SwrveConversationEvents callNumber:conversation onPage:self.conversationPane.tag withControl:control.tag];
            NSURL *callUrl = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", param]];
            [[UIApplication sharedApplication] openURL:callUrl];
            break;
        }
        case SwrveVisitURLActionType: {
            if (!param) {
                [SwrveConversationEvents error:conversation onPage:self.conversationPane.tag withControl:control.tag];
                return;
            }
            
            NSURL *target = [NSURL URLWithString:param];
            if (![target scheme]) {
                target = [NSURL URLWithString:[@"http://" stringByAppendingString:param]];
            }

            if (![[UIApplication sharedApplication] canOpenURL:target]) {
                // The URL scheme could be an app URL scheme, but there is a chance that
                // the user doesn't have the app installed, which leads to confusing behaviour
                // Notify the user that the app isn't available and then just return.
                
                [SwrveConversationEvents error:conversation onPage:self.conversationPane.tag withControl:control.tag];
                
                
                
                DebugLog(@"Could not open the Conversation URL: %@", param, nil);
            } else {
                [SwrveConversationEvents linkVisit:conversation onPage:self.conversationPane.tag withControl:control.tag];
                [[UIApplication sharedApplication] openURL:target];
            }
            break;
        }
        case SwrvePermissionRequestActionType: {
            // Ask for the configured permission
            if(![[SwrveCommon sharedInstance] processPermissionRequest:param]) {
                DebugLog(@"Unkown permission request %@", param, nil);
            } else {
                [SwrveConversationEvents permissionRequest:conversation onPage:self.conversationPane.tag withControl:control.tag];
            }
            break;
        }
        case SwrveDeeplinkActionType: {
            if (!param) {
                [SwrveConversationEvents error:conversation onPage:self.conversationPane.tag withControl:control.tag];
                return;
            }
            NSURL *target = [NSURL URLWithString:param];
            [SwrveConversationEvents deeplinkVisit:conversation onPage:self.conversationPane.tag withControl:control.tag];
            [[UIApplication sharedApplication] openURL:target];
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

    [self runControlActions:control];
    return YES;
}

-(void)stopAtoms {
    for(SwrveConversationAtom *atom in self.conversationPane.content) {
        [atom stop];
    }
}

-(void)dismiss {
    [self stopAtoms];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        @synchronized(self->controller) {
            [self->controller conversationClosed];
        }
    }];
}

-(void)runControlActions:(SwrveConversationButton*)control {
    if (control.actions != nil) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            [self performActions:control];
        });
    }
}

-(void) viewReady:(NSNotification *)notification {
#pragma unused (notification)
    numViewsReady++;
    if(numViewsReady == self.conversationPane.content.count) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.contentTableView reloadData];
        });
    }
}

-(void) updateUI {
    [SwrveConversationStyler styleView:fullScreenBackgroundImageView withStyle:self.conversationPane.pageStyle];
    self.contentTableView.backgroundColor = [UIColor clearColor];
    
    // In the case where a pane is scrolled, then the user moves on to the next
    // pane, that second pane will display as scrolled too, unless we reset the
    // tableview to the top of the content stack.
    [self.contentTableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    self.contentTableView.separatorColor = [UIColor clearColor];
    
    // Only called once the conversation has been retrieved
    for (UIView *view in buttonsView.subviews) {
        if (![view isKindOfClass:[UIImageView class]]) {
            [view removeFromSuperview];
        }
    }

    NSArray *contentToAdd = self.conversationPane.content;
    for (SwrveConversationAtom *atom in contentToAdd) {
        [atom loadViewWithContainerView:self.view];
    }
    
    self.navigationItem.title = self.conversationPane.title;
    NSArray *buttons = self.conversationPane.controls;

    // Buttons need to fit into width - 2*button padding
    // When there are n buttons, there are n-1 gaps between them
    // So, the buttons each take up (width-(n+1)*gapwidth)/numbuttons
    CGFloat buttonWidth = (buttonsView.frame.size.width-(buttons.count+1)*[self buttonHorizontalPadding])/buttons.count;
    CGFloat xOffset = [self buttonHorizontalPadding];
    for(NSUInteger i = 0; i < buttons.count; i++) {
        SwrveConversationButton *button = [buttons objectAtIndex:i];
        UIButton *buttonUIView = (UIButton*)button.view;
        buttonUIView.frame = CGRectMake(xOffset, 10, buttonWidth, 45.0);
        buttonUIView.tag = (NSInteger)i;
        buttonUIView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [buttonUIView.titleLabel setLineBreakMode:NSLineBreakByTruncatingTail];
        [buttonUIView.titleLabel setNumberOfLines:1];
        [buttonUIView addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [SwrveConversationStyler styleButton:(SwrveConversationUIButton *)buttonUIView withStyle:button.style];
        [buttonsView addSubview:buttonUIView];
        xOffset += buttonWidth + [self buttonHorizontalPadding];
    }
}

#pragma mark - Rotation

// Rotation for iOS < 6
#if defined(__IPHONE_9_0)
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
#else
-(NSUInteger) supportedInterfaceOrientations {
#endif //defined(__IPHONE_9_0)
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    } else {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
}

// Orientation Detection
- (void)deviceOrientationDidChange:(NSNotification *)notification {
#pragma unused (notification)
    // Obtaining the current device orientation
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    // Ignoring specific orientations or if hasn't actually changed
    if (orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationUnknown || currentOrientation == orientation) {
        return;
    }
    currentOrientation = orientation;
    // Tell everyone who needs to know that orientation has changed, individual items will react to this and change shape
    [[NSNotificationCenter defaultCenter] postNotificationName:kSwrveNotifyOrientationChange object:nil];
}

-(void)setConversation:(SwrveBaseConversation*)conv andMessageController:(id<SwrveMessageEventHandler>)ctrl andWindow:(UIWindow*)win
{
    conversation = conv;
    controller = ctrl;
    window = win;
    // The conversation is starting now, so issue a starting event
    SwrveConversationPane *firstPage = [conversation pageAtIndex:0];
    [SwrveConversationEvents started:conversation onStartPage:firstPage.tag]; // Issues a start event
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

- (void)viewDidLoad {
    [super viewDidLoad];

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    }
    self.navigationController.navigationBar.translucent = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(viewReady:)
                                                 name:kSwrveNotificationViewReady
                                               object:nil];

    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object: nil];
}

-(void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kSwrveNotificationViewReady
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceOrientationDidChangeNotification
                                                  object:nil];
}

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

#if defined(__IPHONE_8_0)
- (BOOL)prefersStatusBarHidden
{
    return NO;
}
    
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    for(SwrveConversationAtom *atom in self.conversationPane.content) {
        [atom viewWillTransitionToSize:size];
    }
}
#endif //defined(__IPHONE_8_0)

@end
