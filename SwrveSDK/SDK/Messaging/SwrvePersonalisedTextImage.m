#import "SwrvePersonalisedTextImage.h"

@implementation SwrvePersonalisedTextImage

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
    paragraphStyle.alignment = NSTextAlignmentCenter;

    NSDictionary *baseAttributes = @{ NSFontAttributeName: currentFont,
                                  NSBackgroundColorAttributeName: background,
                                  NSForegroundColorAttributeName: foreground,
                                  NSParagraphStyleAttributeName:  paragraphStyle };

    NSDictionary *attributes = [SwrvePersonalisedTextImage fitTextSize:string withAttributes:baseAttributes maxWidth:(int)size.width maxHeight:(int)size.height];
    
    CGSize textBounds = [string sizeWithAttributes:attributes];
    CGRect textRect = CGRectMake(0, (size.height - textBounds.height) / 2 , size.width, size.height);

    CGRect backgroundRect = CGRectMake(0, 0, size.width, size.height);

    // start drawing an image with UIGraphics tools
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);

    // Set background of the image to match the specified background
    [background setFill];
    UIRectFill(backgroundRect);

    // Now draw the resized rect with the text onto it
    [string drawInRect:textRect withAttributes:attributes];

    // finally render a UIImage object
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();

    // cleanup
    UIGraphicsEndImageContext();

    return resultImage;
}


+ (NSDictionary *) fitTextSize:(NSString *)text withAttributes:(NSDictionary *)attributes maxWidth:(int)maxWidth maxHeight:(int) maxHeight {
    if(text == nil || maxWidth <= 0 || maxHeight <= 0) return attributes;
    
    // Retrieve the current font so we can resize against that specific styling
    UIFont *currentFont = (UIFont *)[attributes objectForKey:NSFontAttributeName];
    
    NSMutableDictionary *newAttributes = [attributes mutableCopy];
    CGSize bound = CGSizeMake(0, 0);
    float fontSize = 1.0f;
    float step = 1.0f;
    while (true) {
        bound = [text sizeWithAttributes:newAttributes];
        if(bound.width < maxWidth && bound.height < maxHeight){
            fontSize += step;
            [newAttributes setObject:[currentFont fontWithSize:fontSize] forKey:NSFontAttributeName];
        }else{
            [newAttributes setObject:[currentFont fontWithSize:fontSize - step] forKey:NSFontAttributeName];
            return newAttributes;
        }
    }
}

@end
