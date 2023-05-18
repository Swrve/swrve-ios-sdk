#import "SwrveCalibration.h"

NS_ASSUME_NONNULL_BEGIN

@interface SwrveTextUtils : NSObject

+ (CGFloat)scaleFont:(UIFont *)font
         calibration:(SwrveCalibration *)calibration
       swrveFontSize:(CGFloat)fontSize
         renderScale:(CGFloat)renderScale;

+ (CGFloat)fitTextSize:(NSString *)text
        withAttributes:(NSDictionary *)attributes
              maxWidth:(CGFloat)maxWidth
             maxHeight:(CGFloat)maxHeight
           maxFontSize:(CGFloat)maxFontSize;

+ (UIFont *)fontFromFile:(NSString *)fontFile
          postscriptName:(NSString *)fontPostscriptName
                    size:(CGFloat)fontSizePoints
                   style:(NSString *)fontNativeStyle
            withFallback:(UIFont *)fallbackUIFont;

+ (BOOL)isSystemFont:(NSString *)fontFile;

@end

NS_ASSUME_NONNULL_END
