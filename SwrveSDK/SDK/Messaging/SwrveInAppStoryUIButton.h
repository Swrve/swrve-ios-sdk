#import <UIKit/UIKit.h>

#import "SwrveStoryDismissButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface SwrveInAppStoryUIButton : UIButton

@property(nonatomic, retain) SwrveStoryDismissButton *storyDismissButton;

- (id)   initWithButton:(SwrveStoryDismissButton *)button
           dismissImage:(UIImage *)dismissImage
dismissImageHighlighted:(UIImage *)dismissImageHighlighted;

@end

NS_ASSUME_NONNULL_END
