#import <UIKit/UIKit.h>

#if __has_include(<SwrveSDK/SwrveCalibration.h>)
#import <SwrveSDK/SwrveCalibration.h>
#import <SwrveSDK/SwrveTextViewStyle.h>
#else
#import "SwrveCalibration.h"
#import "SwrveTextViewStyle.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface SwrveUITextView : UITextView

- (id)initWithStyle:(SwrveTextViewStyle *)style
         calbration:(SwrveCalibration *)calibration
              frame:(CGRect)frame
        renderScale:(CGFloat)scale;

@end

NS_ASSUME_NONNULL_END
