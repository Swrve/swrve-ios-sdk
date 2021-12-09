#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SwrveTextImageView : NSObject

+ (UIImage *)imageFromString:(NSString *)string
         withBackgroundColor:(UIColor* ) background
         withForegroundColor:(UIColor *) foreground
                    withFont:(UIFont *)font
                        size:(CGSize)size;

+ (CGFloat)fitTextSize:(NSString *)text withAttributes:(NSDictionary *)attributes maxWidth:(CGFloat)maxWidth maxHeight:(CGFloat)maxHeight maxFontSize:(CGFloat)maxFontSize;

@end

NS_ASSUME_NONNULL_END
