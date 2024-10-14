#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>
#import "SwrveButtonTheme.h"
#import "SwrveUIButton.h"
#import "SwrveCalibration.h"

NS_ASSUME_NONNULL_BEGIN

@interface SwrveThemedUIButton : SwrveUIButton

- (id)initWithTheme:(SwrveButtonTheme *)button
               text:(nullable NSString *)text
              frame:(CGRect)frame
        calabration:(SwrveCalibration *)calibration
        renderScale:(CGFloat)scale;

@end

NS_ASSUME_NONNULL_END
