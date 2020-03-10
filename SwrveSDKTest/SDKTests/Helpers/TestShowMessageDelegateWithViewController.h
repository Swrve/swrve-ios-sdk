#import <XCTest/XCTest.h>

#import "SwrveMessage.h"
#import "SwrveMessageController.h"
#import "SwrveMessageViewController.h"

@interface TestShowMessageDelegateWithViewController : NSObject<SwrveMessageDelegate>

@property UIViewController* viewControllerUsed;
@property UIViewController* viewControllerDismissed;
@property SwrveMessageController* controller;
@property SwrveMessage* messageShown;
@property XCTestExpectation* messageShownExpectation;
@property XCTestExpectation* messageHiddenExpectation;

- (id) initWithExpectations:(XCTestExpectation*) messageShown messageHiddenExpectation:(XCTestExpectation*)messageHidden;
- (void) messageWillBeShown:(UIViewController *) viewController;
- (void) beginHideMessageAnimation:(SwrveMessageViewController*) viewController;
- (void) messageWillBeHidden:(UIViewController *)viewController;
@end

