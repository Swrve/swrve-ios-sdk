#import <UIKit/UIKit.h>

#if __has_include(<SwrveSDK/SwrveTextViewStyle.h>)
#import <SwrveSDK/SwrveTextViewStyle.h>
#else
#import "SwrveTextViewStyle.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@class SwrveCalibration;

@interface SwrveUITextView : UITextView

- (id)initWithStyle:(SwrveTextViewStyle *)style
         calbration:(SwrveCalibration *)calibration
              frame:(CGRect)frame
        renderScale:(CGFloat)scale;

@end

NS_ASSUME_NONNULL_END
