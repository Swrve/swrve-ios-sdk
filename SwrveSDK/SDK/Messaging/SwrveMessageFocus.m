#import "SwrveMessageFocus.h"
#import "SwrveThemedUIButton.h"

#if __has_include(<SwrveSDKCommon/SwrveLogger.h>)
#import <SwrveSDKCommon/SwrveLogger.h>
#import <SwrveSDKCommon/SwrveUtils.h>
#else
#import "SwrveLogger.h"
#import "SwrveUtils.h"
#endif

@interface SwrveThemedUIButton (Internal)

@property(atomic, retain) SwrveButtonTheme *theme;

@end

@interface SwrveMessageFocus ()

@property(nonatomic, retain) UIView *rootView;

@end

@implementation SwrveMessageFocus

@synthesize rootView;

- (id)initWithView:(UIView *)rootUiView {
    if ((self = [super init])) {
        self.rootView = rootUiView;
    }
    return self;
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context {

    UIView *previouslyFocusedView = context.previouslyFocusedView;
    if (previouslyFocusedView != nil && [previouslyFocusedView isDescendantOfView:self.rootView]) {
        [self scaleView:previouslyFocusedView scale:(float) 1.0];
        [self applyFocusOnThemedUIButton:previouslyFocusedView gainFocus:false];
    }


    UIView *nextFocusedView = context.nextFocusedView;
    if (nextFocusedView != nil && [nextFocusedView isDescendantOfView:self.rootView]) {
        [self scaleView:nextFocusedView scale:(float) 1.2];
        [self applyFocusOnThemedUIButton:nextFocusedView gainFocus:true];
    }
}

// Increase/decrease the size of the view to indicate the view is in or out of focus
- (void)scaleView:(UIView *)view scale:(CGFloat)scale {
    [UIView animateWithDuration:0.1
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         view.transform = CGAffineTransformMakeScale(scale, scale);
                     }
                     completion:^(BOOL finished) {
                         [SwrveLogger debug:@"Finished focus animation:%@ scale:%.1f", finished ? @"Success" : @"Failure", scale];
                     }];
}

- (void)applyFocusOnThemedUIButton:(UIView *)view gainFocus:(bool)gainFocus {

    if (![view isKindOfClass:[SwrveThemedUIButton class]]) {
        return;
    }
    SwrveThemedUIButton *themedUIButton = (SwrveThemedUIButton *) view;
    if (gainFocus) {
        if (themedUIButton.theme.focusedState.bgColor) {
            themedUIButton.backgroundColor = [SwrveUtils processHexColorValue:themedUIButton.theme.focusedState.bgColor];
        }
        if (themedUIButton.theme.focusedState.borderColor) {
            UIColor *borderColor = [SwrveUtils processHexColorValue:themedUIButton.theme.focusedState.borderColor];
            themedUIButton.layer.borderColor = [borderColor CGColor];
        }
    } else {
        if (themedUIButton.theme.bgColor) {
            themedUIButton.backgroundColor = [SwrveUtils processHexColorValue:themedUIButton.theme.bgColor];
        }
        if (themedUIButton.theme.borderColor) {
            UIColor *borderColor = [SwrveUtils processHexColorValue:themedUIButton.theme.borderColor];
            themedUIButton.layer.borderColor = [borderColor CGColor];
        }
    }
}

@end
