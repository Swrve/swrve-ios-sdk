#import <UIKit/UIKit.h>
#import "SwrveTextViewStyle.h"
#import "SwrveCalibration.h"

NS_ASSUME_NONNULL_BEGIN

@interface SwrveTextView : UITextView

- (id)initWithStyle:(SwrveTextViewStyle *)style calbration:(SwrveCalibration *)calibration frame:(CGRect)frame;

@end

NS_ASSUME_NONNULL_END
