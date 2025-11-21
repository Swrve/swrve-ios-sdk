#import <UIKit/UIKit.h>

#if __has_include(<SwrveSDK/SwrveStoryDismissButton.h>)
#import <SwrveSDK/SwrveStoryDismissButton.h>
#else
#import "SwrveStoryDismissButton.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface SwrveInAppStoryUIButton : UIButton

@property(nonatomic, retain) SwrveStoryDismissButton *storyDismissButton;

- (id)   initWithButton:(SwrveStoryDismissButton *)button
           dismissImage:(UIImage *)dismissImage
dismissImageHighlighted:(nullable UIImage *)dismissImageHighlighted;

@end

NS_ASSUME_NONNULL_END
