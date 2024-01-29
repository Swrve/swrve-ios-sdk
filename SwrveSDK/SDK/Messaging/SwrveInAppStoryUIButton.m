#import "SwrveInAppStoryUIButton.h"
#import "SwrveSDKUtils.h"

#if __has_include(<SwrveSDKCommon/SwrveUtils.h>)
#import <SwrveSDKCommon/SwrveUtils.h>
#else
#import "SwrveUtils.h"
#endif

@implementation SwrveInAppStoryUIButton

@synthesize storyDismissButton;

- (id)   initWithButton:(SwrveStoryDismissButton *)dismissButton
           dismissImage:(UIImage *)dismissImage
dismissImageHighlighted:(UIImage *)dismissImageHighlighted {
    self = [super initWithFrame:CGRectZero]; // Frame will be set by the layout engine
    if (self) {
        self.storyDismissButton = dismissButton;

        [self setImage:dismissImage forState:UIControlStateNormal];
        if (dismissImageHighlighted) {
            [self setImage:dismissImageHighlighted forState:UIControlStateHighlighted];
        }
        self.tintColor = [SwrveUtils processHexColorValue:dismissButton.color];
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.imageView.contentMode = UIViewContentModeScaleToFill;
        self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
        self.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
        self.adjustsImageWhenHighlighted = NO;
        self.isAccessibilityElement = true;
        self.accessibilityLabel = dismissButton.accessibilityText;
        self.accessibilityHint = @"Button";
    }
    return self;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    if (highlighted) {
        self.tintColor = [SwrveUtils processHexColorValue:self.storyDismissButton.pressedColor];
    } else {
        self.tintColor = [SwrveUtils processHexColorValue:self.storyDismissButton.color];
    }
}

@end
