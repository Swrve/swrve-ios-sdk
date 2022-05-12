#if __has_include(<SwrveSDKCommon/SwrveLogger.h>)
#import <SwrveSDKCommon/SwrveLogger.h>
#else
#import "SwrveLogger.h"
#endif

#import "SwrveMessageFocus.h"

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
    }

    UIView *nextFocusedView = context.nextFocusedView;
    if (nextFocusedView != nil && [nextFocusedView isDescendantOfView:self.rootView]) {
        [self scaleView:nextFocusedView scale:(float) 1.2];
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

@end
