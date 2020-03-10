#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SwrvePersonalisedTextImage : NSObject

+ (UIImage *)imageFromString:(NSString *)string
         withBackgroundColor:(UIColor* ) background
         withForegroundColor:(UIColor *) foreground
                    withFont:(UIFont *)font
                        size:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
