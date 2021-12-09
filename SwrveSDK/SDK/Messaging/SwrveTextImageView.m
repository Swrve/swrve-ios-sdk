#define SWRVE_MIN(a,b)    ((a) < (b) ? (a) : (b))
#import "SwrveTextImageView.h"

@implementation SwrveTextImageView

CGFloat const TEST_FONT_SIZE = 200.0f;

+ (UIImage *)imageFromString:(NSString *)string
         withBackgroundColor:(UIColor* ) background
         withForegroundColor:(UIColor *) foreground
                    withFont:(UIFont *)font
                        size:(CGSize)size
{
    if (CGSizeEqualToSize(CGSizeZero, size)) {
        // if size is 0,0 just give an empty object back and avoid CG errors
        return [UIImage new];
    }
    
    UIFont *currentFont = font;
    if (currentFont == nil) {
        // to prevent any exceptions with the font types
        currentFont = [UIFont systemFontOfSize:0];
    }
    
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByClipping;
    paragraphStyle.alignment = NSTextAlignmentLeft;
  
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    
    //the font size will be scaled below
    [attributes setObject:[currentFont fontWithSize:TEST_FONT_SIZE] forKey:NSFontAttributeName];
    [attributes setObject:background forKey:NSBackgroundColorAttributeName];
    [attributes setObject:foreground forKey:NSForegroundColorAttributeName];
    [attributes setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
    
    CGFloat scaledFontSize = [SwrveTextImageView fitTextSize:string withAttributes:attributes maxWidth:size.width maxHeight:size.height maxFontSize:TEST_FONT_SIZE];
    
    // set the font size to the correct scaled value
    [attributes setObject:[currentFont fontWithSize:scaledFontSize] forKey:NSFontAttributeName];

    CGRect backgroundRect = CGRectMake(0, 0, size.width, size.height);
    
    CGRect textRect = [string boundingRectWithSize:size options:NSStringDrawingUsesDeviceMetrics attributes:attributes context:nil];
    
    // Align vertically
    textRect.origin.y = textRect.origin.y + (textRect.size.height + size.height) / 2.0f;
    textRect.origin.x = ((size.width - textRect.size.width) / 2.0f) - textRect.origin.x;

    // Start drawing an image with UIGraphics tools
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);

    // Set background of the image to match the specified background
    [background setFill];
    UIRectFill(backgroundRect);

    // Now draw the resized rect with the text onto it
    [string drawWithRect:textRect options:NSStringDrawingUsesDeviceMetrics attributes:attributes context:nil];

    // Finally render a UIImage object
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();

    // Cleanup
    UIGraphicsEndImageContext();

    return resultImage;
}

+ (CGFloat)fitTextSize:(NSString *)text withAttributes:(NSDictionary *)attributes maxWidth:(CGFloat)maxWidth maxHeight:(CGFloat)maxHeight maxFontSize:(CGFloat)maxFontSize {
    if (text == nil || maxWidth <= 0 || maxHeight <= 0) return 0;

    CGSize maxSize = CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX);
    CGRect bound = [text boundingRectWithSize:maxSize options:NSStringDrawingUsesDeviceMetrics attributes:attributes context:nil];
    double scalex = maxFontSize / (bound.size.width + fabs(bound.origin.x));
    double scaley = maxFontSize / (bound.size.height + fabs(bound.origin.y));
    CGFloat fontSize = (CGFloat)floor(SWRVE_MIN(scalex * maxWidth, scaley * maxHeight));
    return fontSize;
}

@end
