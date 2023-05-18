#import <UIKit/UIKit.h>
#import "SwrveTextViewStyle.h"
#import "SwrveCalibration.h"

NS_ASSUME_NONNULL_BEGIN

@interface SwrveUITextView : UITextView

- (id)initWithStyle:(SwrveTextViewStyle *)style
         calbration:(SwrveCalibration *)calibration
              frame:(CGRect)frame
        renderScale:(CGFloat)scale;

@end

NS_ASSUME_NONNULL_END
