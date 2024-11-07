#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#if __has_include(<SwrveSDK/SwrveCalibration.h>)
#import <SwrveSDK/SwrveCalibration.h>
#import <SwrveSDK/SwrveButtonTheme.h>
#import "SwrveUIButton.h"
#else
#import "SwrveCalibration.h"
#import "SwrveButtonTheme.h"
#import "SwrveUIButton.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface SwrveThemedUIButton : SwrveUIButton

- (id)initWithTheme:(SwrveButtonTheme *)button
               text:(nullable NSString *)text
              frame:(CGRect)frame
        calabration:(SwrveCalibration *)calibration
        renderScale:(CGFloat)scale;

@end

NS_ASSUME_NONNULL_END
