#if !__has_feature(objc_arc)
#error ConverserSDK must be built with ARC.
// You can turn on ARC for only ConverserSDK files by adding -fobjc-arc to the build phase for each of its files.
#endif

#import "SwrveConversation.h"
#import "SwrveConversationItemViewController.h"
#import "SwrveConversationResource.h"
#import "SwrveConversationResponse.h"
#import "SwrveConversationResponseItem.h"
#import "SwrveConversationPane.h"
#import "SwrveConversationAtom.h"
#import "SwrveConversationButton.h"
#import "SwrveInputItem.h"
#import "SwrveInputMultiValue.h"
#import "SwrveInputMultiValueLong.h"
#import "SwrveSimpleChoiceTableViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>
#import "SwrveSetup.h"
#import "Swrve.h"
#import "SwrveConversationEvents.h"

#define kVerticalPadding 10.0

static NSString *singleButtonImageName = @"bottom_button_green";
static NSString *firstButtonImageName  = @"bottom_button_red";
static NSString *lastButtonImageName   = @"bottom_button_green";
static NSString *otherButtonImageName  = @"bottom_button_blue";

static NSString *singleButtonImageNameIOS7 = @"bottom_button_green_ios7";
static NSString *firstButtonImageNameIOS7  = @"bottom_button_red_ios7";
static NSString *lastButtonImageNameIOS7   = @"bottom_button_green_ios7";
static NSString *otherButtonImageNameIOS7  = @"bottom_button_blue_ios7";

@interface SwrveConversationItemViewController() {
    NSUInteger numViewsReady;
    CGFloat keyboardOffset;
    BOOL conversationEndedWithAction;
    NSIndexPath *updatePath;
    UIDeviceOrientation currentOrientation;
    UITapGestureRecognizer *localRecognizer;
    SwrveConversation *conversation;
}

@property (strong, nonatomic) SwrveConversationPane *conversationPane;

@end

typedef enum {
    SwrveButtonColorRed,
    SwrveButtonColorGreen,
    SwrveButtonColorBlue
} SwrveButtonColor;

typedef enum {
    SwrveButtonColorStyleOutline,
    SwrveButtonColorStyleSolid
} SwrveButtonColorStyle;

@implementation SwrveConversationItemViewController

@synthesize fullScreenBackgroundImageView;
@synthesize backgroundImageView;
@synthesize buttonsBackgroundImageView;
@synthesize contentTableView;
@synthesize buttonsView;
@synthesize conversationPane = _conversationPane;

-(void) viewWillAppear:(BOOL)animated {
#pragma unused (animated)
    if (updatePath) {
        NSArray *arr = [NSArray arrayWithObject:updatePath];
        [self.contentTableView reloadRowsAtIndexPaths:arr withRowAnimation:UITableViewRowAnimationNone];
        updatePath = nil;
    }
    
    [self showConversation];
}

-(SwrveConversationPane *)conversationPane {
    return _conversationPane;
}

-(void) setConversationPane:(SwrveConversationPane *)conversationPane {
    _conversationPane = conversationPane;
    numViewsReady = 0;
}

-(CGFloat) buttonHorizontalPadding {
    return 6.0;
}

-(CGFloat) verticalPadding {
    return kVerticalPadding;
}

-(void) performActions:(SwrveConversationButton *)control {
    NSDictionary *actions = control.actions;
    SwrveConversationActionType actionType;
    id param;
    
    if (actions == nil) {
        return;
    }
    
    for (NSString *key in [actions allKeys]) {
        if ([key isEqualToString:@"visit"]) {
            actionType = SwrveVisitURLActionType;
            NSDictionary *visitDict = [actions objectForKey:@"visit"];
            param = [visitDict objectForKey:@"url"];
        } else {
            if ([key isEqualToString:@"call"]) {
                actionType = SwrveCallNumberActionType;
                param = [actions objectForKey:@"call"];
            } else {
                [SwrveConversationEvents error:conversation onPage:self.conversationPane.tag withControl:control.tag];
            }
        }
    }
    
    switch (actionType) {
        case SwrveCallNumberActionType: {
            conversationEndedWithAction = YES;
            [SwrveConversationEvents callNumber:conversation onPage:self.conversationPane.tag withControl:control.tag];
            [SwrveConversationEvents finished:conversation onPage:self.conversationPane.tag withControl:control.tag];
            NSURL *callUrl = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", param]];
            NSLog(@"calling number: %@", callUrl.absoluteString);
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

            BOOL isAppScheme = YES;
            if (([@"http" caseInsensitiveCompare:[target scheme]] == NSOrderedSame) ||
                ([@"https" caseInsensitiveCompare:[target scheme]] == NSOrderedSame)) {
                isAppScheme = NO;
            }
            conversationEndedWithAction = YES;

            if (![[UIApplication sharedApplication] canOpenURL:target]) {
                // The URL scheme could be an app URL scheme, but there is a chance that
                // the user doesn't have the app installed, which leads to confusing behaviour
                // Notify the user that the app isn't available and then just return.
                [SwrveConversationEvents error:conversation onPage:self.conversationPane.tag withControl:control.tag];
                NSString *msg = [NSString stringWithFormat:NSLocalizedStringFromTable(@"NO_APP", @"Converser", @"You will need to install an app to visit %@"), [target absoluteString]];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"CANNOT_OPEN_URL", @"Converser", @"Cannot open URL")
                                                                message:msg
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedStringFromTable(@"DONE", @"Converser", @"Done")
                                                      otherButtonTitles:nil];
                [alert show];
            } else {
                [SwrveConversationEvents linkVisit:conversation onPage:self.conversationPane.tag withControl:control.tag];
                [SwrveConversationEvents finished:conversation onPage:self.conversationPane.tag withControl:control.tag];
                [[UIApplication sharedApplication] openURL:target];
            }
            break;
        }
        default:
            break;
    }    
}

- (IBAction)cancelButtonTapped:(id)sender {
#pragma unused(sender)
    [SwrveConversationEvents cancelled:conversation onPage:self.conversationPane.tag];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
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

-(void)transitionWithControl:(SwrveConversationButton *)control {
    // Check to see if all required inputs have had data applied and pop up an
    // alert to the user if this is not the case.
    //
    NSMutableArray *incompleteRequiredInputs = [[NSMutableArray alloc] init];
    NSMutableArray *invalidInputs = [[NSMutableArray alloc] init];
    NSError *invalidInputError = nil;
    
    for(SwrveConversationAtom *atom in self.conversationPane.content) {
        if([atom isKindOfClass:[SwrveInputItem class]]) {
            SwrveInputItem *item = (SwrveInputItem*)atom;
            
            if ([item isComplete]) {
                if (![item isValid:&invalidInputError]) {
                    [item highlight];
                    [invalidInputs addObject:item];
                }
            } else {
                if (![item isOptional]) {
                    [item highlight];
                    [incompleteRequiredInputs addObject:item];
                }
            }
        }
    }
    
    if ([incompleteRequiredInputs count] > 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"ERROR", @"Converser", @"Error")
                                                        message:NSLocalizedStringFromTable(@"FILL_ALL", @"Converser", @"Please fill all required fields.")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedStringFromTable(@"DONE", @"Converser", @"Done")
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    if ([invalidInputs count] > 0 ) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"ERROR", @"Converser", @"Error")
                                                        message:NSLocalizedStringFromTable(@"VALID_EMAIL", @"Converser", @"Please supply a valid email address.")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedStringFromTable(@"DONE", @"Converser", @"Done")
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    // Things that are 'running' need to be 'stopped'
    // Bit of a band-aid for videos continuing to play
    // in the background for now.
    for(SwrveConversationAtom *atom in self.conversationPane.content) {
        [atom stop];
    }
    
    
    // Move onto the next page in the conversation - fetch the next Convseration pane
    if ([control endsConversation]) {
        [SwrveConversationEvents finished:conversation onPage:self.conversationPane.tag withControl:control.tag];
        dispatch_async(dispatch_get_main_queue(), ^ {
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
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
}

-(void)runControlActions:(SwrveConversationButton*)control {
    if (control.actions != nil) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            [self performActions:control];
        });
    }
}

-(void) updateButtonStyle:(UIButton *)button withColor:(SwrveButtonColor)color andStyle:(SwrveButtonColorStyle)style {
    NSString *imageToUse, *imageToUseForTapped;
    NSString *ext = @"", *styleId = @"", *colorId = @"";
    UIColor *titleColor;
    
    if (color == SwrveButtonColorRed) {
        colorId = @"_red";
        titleColor = Swrve_UIColorFromRGB(Swrve_COLOR_RED);
    } else if (color == SwrveButtonColorGreen) {
        colorId = @"_green";
        titleColor = Swrve_UIColorFromRGB(Swrve_COLOR_GREEN);
    } else {
        colorId = @"_blue";
        titleColor = Swrve_UIColorFromRGB(Swrve_COLOR_LIGHT_BLUE);
    }
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        ext = @"_ios7";
        if (style == SwrveButtonColorStyleSolid) {
            styleId = @"_solid";
            [button setTitleColor:Swrve_UIColorFromRGB(Swrve_COLOR_WHITE) forState:UIControlStateNormal];
            [button setTitleColor:Swrve_UIColorFromRGB(Swrve_COLOR_WHITE) forState:UIControlStateHighlighted];
            [button setTitleColor:Swrve_UIColorFromRGB(Swrve_COLOR_WHITE) forState:UIControlStateSelected];
        } else {
            [button setTitleColor:titleColor forState:UIControlStateNormal];
            [button setTitleColor:titleColor forState:UIControlStateHighlighted];
            [button setTitleColor:titleColor forState:UIControlStateSelected];
        }
    }
    
    imageToUse = [NSString stringWithFormat:@"bottom_button%@%@%@", styleId, colorId, ext];

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        imageToUseForTapped = imageToUse;
    } else {
        imageToUseForTapped = [NSString stringWithFormat:@"bottom_button%@%@%@_tapped", styleId, colorId, ext];
    }
    
    UIImage *image, *stretchedImage;
    UIImage *tappedImage, *stretchedTappedImage;

    // Load the images from the resources
    image = [SwrveConversationResource imageFromBundleNamed:imageToUse];
    tappedImage = [SwrveConversationResource imageFromBundleNamed:imageToUseForTapped];

    // Make stretchable images from them 
    stretchedImage = [image stretchableImageWithLeftCapWidth:5.0 topCapHeight:5.0];
    stretchedTappedImage = [tappedImage stretchableImageWithLeftCapWidth:5.0 topCapHeight:5.0];
    [button setBackgroundImage:stretchedImage forState:UIControlStateNormal];
    [button setBackgroundImage:stretchedTappedImage forState:UIControlStateHighlighted];
}

-(void) styleButton:(UIButton *)button atIndex:(NSUInteger)index withCount:(NSUInteger) count {
    SwrveButtonColorStyle currentStyle;
    
    currentStyle = SwrveButtonColorStyleSolid;

    // TODO: another option is currentStyle = SwrveButtonColorStyleOutline;
    
    // If the page has only one button, it's going to be green
    if(count == 1) {
        [self updateButtonStyle:button withColor:SwrveButtonColorGreen andStyle:currentStyle];
    } else {
        // If there is more than one button, the leftmost button is
        // always red.
        if (index == 0) {
            [self updateButtonStyle:button withColor:SwrveButtonColorRed andStyle:currentStyle];
        } else {
            // If there is more than one button, the rightmost button is
            // always green, and the middle button, if any, is blue.
            if (index == count - 1) {
                [self updateButtonStyle:button withColor:SwrveButtonColorGreen andStyle:currentStyle];
            } else {
                [self updateButtonStyle:button withColor:SwrveButtonColorBlue andStyle:currentStyle];
            }
        }
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
    // Style the table based on iOS version
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        self.contentTableView.backgroundColor = [UIColor clearColor];
        
        // The table view should be -10 on each side and centred in the
        // width of its containing view (so that it will behave correctly
        // on iPad modal.
        //
        self.contentTableView.frame =
            CGRectMake(10, self.contentTableView.frame.origin.y,
                       self.view.frame.size.width - 20, self.contentTableView.frame.size.height);
        [self.contentTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    } else {
        self.contentTableView.backgroundColor = [UIColor whiteColor];
        self.contentTableView.frame = CGRectMake(0, 0, self.contentTableView.frame.size.width, self.contentTableView.frame.size.height);
        [self.contentTableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    }
    
    
    // In the case where a pane is scrolled, then the user moves on to the next
    // pane, that second pane will display as scrolled too, unless we reset the
    // tableview to the top of the content stack.
    [self.contentTableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    // TODO: check the above for iOS 8 / autolayout use
    // may need to use setContentOffset instead
    
    // Only called once the conversation has been retrieved
    for(UIView *view in buttonsView.subviews) {
        if (![view isKindOfClass:[UIImageView class]]) {
            [view removeFromSuperview];
        }
    }
    NSArray *contentToAdd = self.conversationPane.content;
    
    for (SwrveConversationAtom *atom in contentToAdd) {
        [atom loadView];
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
        UIView *v = button.view;
        v.frame = CGRectMake(xOffset, 18, buttonWidth, 45.0);
        v.tag = (NSInteger)i;
        v.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [(UIButton *)v addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self styleButton:(UIButton *)v atIndex:i withCount:buttons.count];
        [buttonsView addSubview:v];
        xOffset += buttonWidth + [self buttonHorizontalPadding];
    }
}

#pragma mark - Rotation

// Rotation for iOS < 6
-(NSUInteger) supportedInterfaceOrientations {
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

#pragma mark - Inits

-(id)initWithConversation:(SwrveConversation*)conv {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self = [super initWithNibName:@"SwrveConversationItemViewController_iPad" bundle:nil];
    } else {
        self = [super initWithNibName:@"SwrveConversationItemViewController_iPhone" bundle:nil];
    }
    
    if (self) {
        conversation = conv;
    }
    return self;
}

// Show conversation - take the current page number (defaults to 0)
// Pull the conversation page at current page number from the SwrveConversation
// Convert the page into a Conversation Pane
// Set the current conversation pane and update the UI
// TODO: this is good forstarting the conversation, or hitting a page, not
// for navigation, so a refactor would be good.
-(void) showConversation {
    if (conversation) {
        if (!self.conversationPane) {
            // No current conversation pane means that conversation is starting
            self.conversationPane = [conversation pageAtIndex:0];
            [SwrveConversationEvents started:conversation onPage:self.conversationPane.tag];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateUI];
        });
    }
}

// Tapping the content view outside the context of any
// interactive input views requests the current first
// responder to relinquish its status. Gesture recognizer
// is then removed. 
//
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

-(CGFloat)offsetForAtom:(SwrveConversationAtom*)atom withKeyboardSize:(CGSize)kbdSize {
    CGPoint p2, p3;
    CGFloat offset = 0.0;

    UIView *v = [self findTopView];
    NSIndexPath *indexPath = [self indexPathForAtom:atom];
    CGRect  screenRect = [[UIScreen mainScreen] bounds];
    CGPoint originInSuperView = [v convertPoint:CGPointZero fromView:self.view];
    CGRect  rectInTableView = [self.contentTableView rectForRowAtIndexPath:indexPath];
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        switch (orientation) {
            case UIInterfaceOrientationPortraitUpsideDown:
                p2 = CGPointMake(originInSuperView.x, originInSuperView.y - rectInTableView.origin.y);
                p3 = CGPointMake(originInSuperView.x, p2.y - rectInTableView.size.height);
                offset = kbdSize.height - p3.y;
                break;
            case UIInterfaceOrientationPortrait:
            case UIInterfaceOrientationUnknown:
                p2 = CGPointMake(originInSuperView.x, originInSuperView.y + rectInTableView.origin.y);
                p3 = CGPointMake(originInSuperView.x, p2.y + rectInTableView.size.height);
                offset = p3.y - (screenRect.size.height - kbdSize.height);
                break;
            case UIInterfaceOrientationLandscapeLeft:
                p2 = CGPointMake(originInSuperView.x + rectInTableView.origin.y, originInSuperView.y);
                p3 = CGPointMake(p2.x + rectInTableView.size.height, originInSuperView.y);
                offset = p3.x - (screenRect.size.width - kbdSize.width);
                break;
            case UIInterfaceOrientationLandscapeRight:
                p2 = CGPointMake(originInSuperView.x - rectInTableView.origin.y, originInSuperView.y);
                p3 = CGPointMake(p2.x - rectInTableView.size.height, originInSuperView.y);
                offset = kbdSize.width - p3.x;
                break;
        }
    }
    
    return (offset > 0.0) ? offset : 0.0;
}

-(CGSize) keyboardSize:(NSDictionary*)userinfo {
    NSValue *value = [userinfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect;
    [value getValue:&keyboardRect];
    return keyboardRect.size;
}

// On the iPad, the atom is scrolled up a bit. On the iPhone, the atom
// is brought to the top of the visible content to make it as accessible
// as possible given the limited space available.
//
-(void)nudgeAtom:(SwrveConversationAtom*)atom fromKeyboard:(NSDictionary*)userinfo {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        CGFloat scrollDiff = [self offsetForAtom:atom withKeyboardSize:[self keyboardSize:userinfo]];
        if (scrollDiff > 0) {
            [UIView animateWithDuration:0.3 animations:^ {
                self.contentTableView.contentOffset = CGPointMake(self.contentTableView.contentOffset.x, self.contentTableView.contentOffset.y + scrollDiff);
            }];
            keyboardOffset = scrollDiff;
        }
    } else {
        CGSize keyboardSize = [self keyboardSize:userinfo];
        
        UIEdgeInsets contentInsets;
        if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
            contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardSize.height), 0.0);
        } else {
            contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardSize.width), 0.0);
        }
        
        self.contentTableView.contentInset = contentInsets;
        self.contentTableView.scrollIndicatorInsets = contentInsets;
        [self.contentTableView scrollToRowAtIndexPath:[self indexPathForAtom:atom] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

-(void)nudgeAtomBack:(NSNumber*)animRate {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (keyboardOffset != 0) {
            CGFloat tmpval = keyboardOffset;
            keyboardOffset = 0.0;
            [UIView animateWithDuration:animRate.floatValue animations:^ {
                self.contentTableView.contentOffset = CGPointMake(self.contentTableView.contentOffset.x, self.contentTableView.contentOffset.y - tmpval);
            }];
        }
    } else {
        [UIView animateWithDuration:animRate.floatValue animations:^ {
            self.contentTableView.contentInset = UIEdgeInsetsZero;
            self.contentTableView.scrollIndicatorInsets = UIEdgeInsetsZero;
        }];
    }
}

-(void) keyboardWillShow:(NSNotification *)notification {
    for(SwrveConversationAtom *atom in self.conversationPane.content) {
        if([atom isKindOfClass:[SwrveInputItem class]]) {
            if([(SwrveInputItem *)atom isFirstResponder]) {
                [self nudgeAtom:atom fromKeyboard:notification.userInfo];
            }
        }
    }

    // When there's a keyboard on-screen, then apply a recognizer to this content
    // view so we can detect when a tap takes place outside the keyboard area.
    // A tap of this nature means that the user is done typing.
    //
    if (localRecognizer == nil) {
        localRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(contentViewTapped:)];
        localRecognizer.numberOfTapsRequired = 1;
    }
    [self.contentTableView addGestureRecognizer:localRecognizer];
    
}

-(void) keyboardWillHide:(NSNotification *)notification {
    // Two ways to get to here - the user has pressed the Done
    // accessory button on the kbd, or a text input has resigned
    // first responder. If it's the latter, the local gesture
    // recognizer added by keyboardWillShow will be removed
    // already, but if Done is pressed it will not have been
    // removed, so we need to do it here.
    [self.contentTableView removeGestureRecognizer:localRecognizer];
    [self nudgeAtomBack:notification.userInfo[UIKeyboardAnimationDurationUserInfoKey]];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        UIImage *bgImgFullScreen = [SwrveConversationResource imageFromBundleNamed:@"layer_0_background"];
        fullScreenBackgroundImageView.image = bgImgFullScreen;
        //1
        UIImage *bgImg = [SwrveConversationResource backgroundImage];
        backgroundImageView.image = bgImg;
        //
        UIImage *buttonBgImg = [SwrveConversationResource imageFromBundleNamed:@"bottom_button_background"];
        buttonsBackgroundImageView.image = buttonBgImg;
    } else {
        fullScreenBackgroundImageView.image = nil;
        backgroundImageView.image = nil;
        buttonsBackgroundImageView.image = nil;
        buttonsView.backgroundColor = [UIColor clearColor];
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
        self.navigationController.navigationBar.translucent = NO;
        UIImage *buttonBgImg = [SwrveConversationResource imageFromBundleNamed:@"bottom_button_background_ios7"];
        buttonsBackgroundImageView.image = buttonBgImg;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(viewReady:)
                                                 name:kSwrveNotificationViewReady
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
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
                                                  object:UIKeyboardDidShowNotification];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
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
    SwrveConversationAtom *atom = [self.conversationPane.content objectAtIndex:(NSUInteger)indexPath.section];
    return [atom cellForRow:(NSUInteger)indexPath.row inTableView:tableView];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#pragma unused (tableView)
    // Each item is a "section"
    return (NSInteger)self.conversationPane.content.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
#pragma unused (tableView)
    SwrveConversationAtom *atom = [self.conversationPane.content objectAtIndex:(NSUInteger)indexPath.section];
    return [atom heightForRow:(NSUInteger)indexPath.row];
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    SwrveConversationAtom *atom = [self.conversationPane.content objectAtIndex:(NSUInteger)indexPath.section];
    // Now...how to handle this.
    if([atom.type isEqualToString:kSwrveInputMultiValue]) {
        SwrveInputMultiValue *vgInputMultiValue = (SwrveInputMultiValue *)atom;
        vgInputMultiValue.selectedIndex = indexPath.row;
        // Redraw the section, as we may have switched another off
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:(NSUInteger)indexPath.section];
        [tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
    } else if([atom.type isEqualToString:kSwrveInputMultiValueLong]) {
        SwrveSimpleChoiceTableViewController *simpleVC = [[SwrveSimpleChoiceTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        simpleVC.choiceValues = [(SwrveInputMultiValueLong *)atom choicesForRow:(NSUInteger)indexPath.row];
        [self.navigationController pushViewController:simpleVC animated:YES];
        // Also note that this row may need an update
        updatePath = indexPath;
    }
}

@end
