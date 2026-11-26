#if __has_include(<SwrveSDK/SwrveMessageFormat.h>)
#import <SwrveSDK/SwrveMessageFormat.h>
#else
#import "SwrveMessageFormat.h"
#endif

@class SwrveCalibration;

NS_ASSUME_NONNULL_BEGIN

@interface SwrveSDKUtils : NSObject

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

+ (CGFloat)renderScaleFor:(SwrveMessageFormat *)format withParentSize:(CGSize)sizeParent;

+ (UIScreen *)screenForWindow:(nullable UIWindow *)window;

+ (void)updateLargestScreenFromConnectedScenes;
+ (void)updateLargestScreenWithScene:(UIScene *)scene API_AVAILABLE(ios(13.0), tvos(13.0));
+ (BOOL)updateLargestScreenWithSize:(CGSize)size scale:(CGFloat)scale;
+ (CGSize)largestScreenSize;
+ (float)largestScreenDpi;

+ (nullable UIImage *)iamStoryDismissImage;

@end

NS_ASSUME_NONNULL_END
