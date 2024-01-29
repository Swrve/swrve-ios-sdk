#import <CoreText/CoreText.h>
#import "SwrveSDKUtils.h"

#if __has_include(<SwrveSDKCommon/SwrveLocalStorage.h>)
#import <SwrveSDKCommon/SwrveLocalStorage.h>
#import <SwrveSDKCommon/SwrveLogger.h>
#else
#import "SwrveLocalStorage.h"
#import "SwrveLogger.h"
#endif

#define SWRVE_MIN(a, b)    ((a) < (b) ? (a) : (b))

@implementation SwrveSDKUtils

+ (CGFloat)scaleFont:(UIFont *)font calibration:(SwrveCalibration *)calibration swrveFontSize:(CGFloat)fontSize renderScale:(CGFloat)renderScale {
    CGFloat calibrationWidth = calibration.calibrationWidth * renderScale;
    CGFloat calibrationHeight = calibration.calibrationHeight * renderScale;

    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByClipping;
    paragraphStyle.alignment = NSTextAlignmentLeft;
    CGFloat maxFontSize = 200.0f;
    NSDictionary *baseAttributes = @{
            NSFontAttributeName: [font fontWithSize:maxFontSize],
            NSParagraphStyleAttributeName: paragraphStyle
    };

    CGFloat osSizeForTemplate = [SwrveSDKUtils fitTextSize:calibration.calibrationText
                                         withAttributes:baseAttributes
                                               maxWidth:calibrationWidth
                                              maxHeight:calibrationHeight
                                            maxFontSize:maxFontSize];

    CGFloat scaledFont = (fontSize / calibration.calibrationFontSize) * osSizeForTemplate;
    return scaledFont;
}

+ (CGFloat)fitTextSize:(NSString *)text
        withAttributes:(NSDictionary *)attributes
              maxWidth:(CGFloat)maxWidth
             maxHeight:(CGFloat)maxHeight
           maxFontSize:(CGFloat)maxFontSize {

    if (text == nil || maxWidth <= 0 || maxHeight <= 0) {
        return 0;
    }

    CGSize maxSize = CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX);
    CGRect bound = [text boundingRectWithSize:maxSize options:NSStringDrawingUsesDeviceMetrics attributes:attributes context:nil];
    double scaleX = maxFontSize / (bound.size.width + fabs(bound.origin.x));
    double scaleY = maxFontSize / (bound.size.height + fabs(bound.origin.y));
    CGFloat fontSize = (CGFloat) floor(SWRVE_MIN(scaleX * maxWidth, scaleY * maxHeight));
    return fontSize;
}

// Similar method in SwrveConversationStyler
+ (UIFont *)fontFromFile:(NSString *)fontFile
          postscriptName:(NSString *)fontPostscriptName
                    size:(CGFloat)fontSizePoints
                   style:(NSString *)fontNativeStyle
            withFallback:(UIFont *)fallbackFont {

    UIFont *uiFont;
    if ([SwrveSDKUtils isSystemFont:fontFile]) {
        if(fontNativeStyle && [fontNativeStyle isEqualToString:@"Normal"]) {
            uiFont = [UIFont systemFontOfSize:fontSizePoints];
        } else if(fontNativeStyle && [fontNativeStyle isEqualToString:@"Bold"]) {
            uiFont = [UIFont boldSystemFontOfSize:fontSizePoints];
        } else if(fontNativeStyle && [fontNativeStyle isEqualToString:@"Italic"]) {
            uiFont = [UIFont italicSystemFontOfSize:fontSizePoints];
        } else if(fontNativeStyle && [fontNativeStyle isEqualToString:@"BoldItalic"]) {
            UILabel *label = [UILabel new];
            UIFontDescriptor * fontD = [label.font.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold | UIFontDescriptorTraitItalic];
            label.font = [UIFont fontWithDescriptor:fontD size:fontSizePoints];
            uiFont = label.font;
        }
    } else {
        if(fontPostscriptName && [fontPostscriptName length] > 0) {
            uiFont = [UIFont fontWithName:fontPostscriptName size:fontSizePoints]; // try loading the font. It could already be registered.
        }
        if (!uiFont) {
            NSString *cacheFolder = [SwrveLocalStorage swrveCacheFolder];
            NSString *fontPath = [cacheFolder stringByAppendingPathComponent:fontFile];
            BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:fontPath];
            if (fileExists) {
                NSURL *url = [NSURL fileURLWithPath:fontPath];
                CGDataProviderRef fontDataProvider = CGDataProviderCreateWithURL((__bridge CFURLRef) url);
                CGFontRef cgFont = CGFontCreateWithDataProvider(fontDataProvider);
                CFStringRef newFontPostscsriptNameCString = CGFontCopyPostScriptName(cgFont);
                NSString *newFontPostscriptName = (__bridge NSString *) newFontPostscsriptNameCString;
                if(newFontPostscriptName) {
                    uiFont = [UIFont fontWithName:newFontPostscriptName size:fontSizePoints]; // check again if already registered
                }
                if (uiFont == NULL) {
                    CFErrorRef cfError;
                    if (CTFontManagerRegisterGraphicsFont(cgFont, &cfError)) {
                        if (newFontPostscriptName != nil) {
                            uiFont = [UIFont fontWithName:newFontPostscriptName size:fontSizePoints];
                        }
                    } else {
                        CFStringRef errorDescription = CFErrorCopyDescription(cfError);
                        [SwrveLogger error:@"Error registering font: %@ fontPath:%@ errorDescription:%@", fontFile, fontPath, errorDescription];
                        CFRelease(errorDescription);
                    }
                }
                CGFontRelease(cgFont);
                CGDataProviderRelease(fontDataProvider);
                if (newFontPostscsriptNameCString != nil) {
                    CFRelease(newFontPostscsriptNameCString);
                }
            } else {
                [SwrveLogger error:@"Swrve: fontFile %@ could not be loaded. Using default/fallback.", fontFile];
            }
        }
    }

    if (!uiFont) {
        uiFont = fallbackFont;
    }
    return uiFont;
}

+ (BOOL)isSystemFont:(NSString *)fontFile {
    BOOL isSystemFont = NO;
    if (fontFile && [fontFile isEqualToString:@"_system_font_"]) {
        isSystemFont = YES;
    }
    return isSystemFont;
}

+ (CGFloat)renderScaleFor:(SwrveMessageFormat *)format withParentSize:(CGSize)sizeParent {
    // Calculate the scale needed to fit the format in the current viewport
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    float wscale = (float) ((sizeParent.width * screenScale) / format.size.width);
    float hscale = (float) ((sizeParent.height * screenScale) / format.size.height);
    float viewportScale = (wscale < hscale) ? wscale : hscale;
    return (format.scale / screenScale) * viewportScale; // Adjust scale, accounting for retina devices
}

// Note:
// - in app story dismiss image is rendered using a svg graphic shipped in the SwrveSDK bundle
// - svg graphics are not completely backwards compatible and may render slightly differently below iOS 13
// - when adding svg to xcassets make sure to preserve vector data, render as template and use single scale
+ (UIImage *)iamStoryDismissImage {
    NSBundle *swrveSDKBundle = [SwrveSDKUtils swrveSDKBundle];
    NSString *dismissImageSVGName = @"swrve_x.svg";
    UIImage *dismissImage = [UIImage imageNamed:dismissImageSVGName inBundle:swrveSDKBundle compatibleWithTraitCollection:nil];
    if (!dismissImage) {
        [SwrveLogger error:@"Dismiss asset image missing from in-app story", nil];
    }
    return dismissImage;
}

+ (NSBundle *)swrveSDKBundle {
#ifdef SWIFTPM_MODULE_BUNDLE
    return SWIFTPM_MODULE_BUNDLE;
#else
    NSBundle *mainBundle = [NSBundle bundleForClass:[SwrveSDKUtils class]];
    NSURL *bundleURL = [[mainBundle resourceURL] URLByAppendingPathComponent:@"SwrveSDK.bundle"];
    NSBundle *frameworkBundle = [NSBundle bundleWithURL:bundleURL];
    // if its nil, try standard bundle location for class
    if (frameworkBundle != nil) {
        return frameworkBundle;
    }
    return mainBundle;
#endif
}

@end
