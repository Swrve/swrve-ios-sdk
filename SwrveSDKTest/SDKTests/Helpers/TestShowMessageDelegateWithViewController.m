#import "TestShowMessageDelegateWithViewController.h"
#import "SwrveMessageViewController.h"

@implementation TestShowMessageDelegateWithViewController

- (id) initWithExpectations:(XCTestExpectation*) messageShown messageHiddenExpectation:(XCTestExpectation*)messageHidden {
    self = [super init];
    if (self) {
        self.messageShownExpectation = messageShown;
        self.messageHiddenExpectation = messageHidden;
    }
    return self;
}

- (void) messageWillBeShown:(UIViewController*) viewController {
    [self setViewControllerUsed:viewController];
    if ([viewController isKindOfClass:[SwrveMessageViewController class]]) {
        SwrveMessageViewController* mvc = (SwrveMessageViewController*)viewController;
        [self setMessageShown:[mvc message]];
    }
    if (self.messageShownExpectation) {
        [self.messageShownExpectation fulfill];
    }
}

- (void) beginHideMessageAnimation:(SwrveMessageViewController*) viewController {
    [[self controller] dismissMessageWindow];
    [self setMessageShown:[viewController message]];
}

- (void) messageWillBeHidden:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[SwrveMessageViewController class]]) {
        SwrveMessageViewController* mvc = (SwrveMessageViewController*)viewController;
        [self setMessageShown:[mvc message]];
    }
    [self setViewControllerDismissed:viewController];
    if (self.messageHiddenExpectation) {
        [self.messageHiddenExpectation fulfill];
    }
}

@end

