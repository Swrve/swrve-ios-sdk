#import <CoreText/CoreText.h>
#import "SwrveSDKUtils.h"

#if __has_include(<SwrveSDKCommon/SwrveLocalStorage.h>)
#import <SwrveSDKCommon/SwrveLocalStorage.h>
#import <SwrveSDKCommon/SwrveLogger.h>
#import <SwrveSDKCommon/SwrveUtils.h>
#else
#import "SwrveLocalStorage.h"
#import "SwrveLogger.h"
#import "SwrveUtils.h"
#endif

#import "Swrve.h"
#import "SwrveButtonActions.h"
#if __has_include(<SwrveSDK/SwrveSDK-Swift.h>)
#import <SwrveSDK/SwrveSDK-Swift.h>
#elif __has_include("SwrveSDK-Swift.h")
#import "SwrveSDK-Swift.h"
#endif

#define SWRVE_MIN(a, b)    ((a) < (b) ? (a) : (b))

// A screen replaces the stored one only if its area is larger by this much. A new size changes the content request, so the content is downloaded in full again: not worth doing for a negligible gain
static const double SWRVE_LARGEST_SCREEN_MIN_GROWTH = 1.02;

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
    // Scale the format until it touches the nearest pair of the parent's edges
    CGFloat wscale = sizeParent.width / format.size.width;
    CGFloat hscale = sizeParent.height / format.size.height;
    return format.scale * MIN(wscale, hscale);
}

// The screen a window is on, from its scene rather than [UIScreen mainScreen], which is deprecated in iOS 26 and on a device with more than one screen, 
// such as the iPhone Duo, can describe a different one. A window without a scene (one not shown yet) gets the screen of the app's first scene.
+ (UIScreen *)screenForWindow:(UIWindow *)window NS_EXTENSION_UNAVAILABLE_IOS("") {
    if (@available(iOS 13.0, tvOS 13.0, *)) {
        UIWindowScene *scene = window.windowScene;
        if (scene == nil) {
            for (UIScene *connected in [[UIApplication sharedApplication] connectedScenes]) {
                if ([connected isKindOfClass:[UIWindowScene class]]) {
                    scene = (UIWindowScene *)connected;
                    break;
                }
            }
        }
        if (scene != nil) {
            return scene.screen;
        }
    }
    return window.screen ?: [UIScreen mainScreen]; // before iOS 13, an app has a single screen
}

+ (void)updateLargestScreenFromConnectedScenes NS_EXTENSION_UNAVAILABLE_IOS("") {
    if (![NSThread isMainThread]) {
        // Scenes can only be read on the main thread: this request reports what's stored, later ones the update
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateLargestScreenFromConnectedScenes];
        });
        return;
    }
    if (@available(iOS 13.0, tvOS 13.0, *)) {
        for (UIScene *scene in [[UIApplication sharedApplication] connectedScenes]) {
            [self updateLargestScreenWithScene:scene];
        }
    }
}

+ (void)updateLargestScreenWithScene:(UIScene *)scene {
    if (![scene isKindOfClass:[UIWindowScene class]] || ![scene.session.role isEqualToString:UIWindowSceneSessionRoleApplication]) {
        return;
    }
    UIScreen *screen = ((UIWindowScene *)scene).screen;
    CGFloat scale = screen.scale;
    [self updateLargestScreenWithSize:CGSizeMake(screen.bounds.size.width * scale, screen.bounds.size.height * scale) scale:scale];
}

+ (BOOL)updateLargestScreenWithSize:(CGSize)size scale:(CGFloat)scale {
    int width = (int)MIN(size.width, size.height);
    int height = (int)MAX(size.width, size.height);
    if (width <= 0 || scale <= 0) {
        return NO;
    }
    NSDictionary *largest = [self storedLargestScreen];
    if (largest != nil) {
        double largestArea = [largest[@"width"] doubleValue] * [largest[@"height"] doubleValue];
        if ((double)width * height < largestArea * SWRVE_LARGEST_SCREEN_MIN_GROWTH) {
            return NO;
        }
    }
    [SwrveLocalStorage saveLargestScreen:@{@"width": @(width), @"height": @(height), @"scale": @(scale)}];
    [SwrveLogger debug:@"Swrve largest screen is now %dx%d (scale %.2f)", width, height, scale];
    return YES;
}

// The stored largest screen, or nil if there isn't a usable one
+ (nullable NSDictionary *)storedLargestScreen {
    NSDictionary *largest = [SwrveLocalStorage largestScreen];
    for (NSString *key in @[@"width", @"height", @"scale"]) {
        id value = largest[key];
        if (![value isKindOfClass:[NSNumber class]] || [value doubleValue] <= 0) {
            return nil;
        }
    }
    return largest;
}

+ (CGSize)largestScreenSize {
    NSDictionary *largest = [self storedLargestScreen];
    if (largest == nil) {
        return [SwrveUtils deviceScreenBounds].size;
    }
    return CGSizeMake([largest[@"width"] intValue], [largest[@"height"] intValue]);
}

+ (float)largestScreenDpi {
    NSDictionary *largest = [self storedLargestScreen];
    if (largest == nil) {
        return [SwrveUtils estimate_dpi];
    }
    return [SwrveUtils estimateDpiForScale:[largest[@"scale"] floatValue]];
}

// Note:
// - in app story dismiss image is rendered using a svg graphic shipped in the SwrveSDK bundle
// - svg graphics are not completely backwards compatible and may render slightly differently below iOS 13
// - when adding svg to xcassets make sure to preserve vector data, render as template and use single scale
+ (nullable UIImage * )iamStoryDismissImage {
    NSBundle *swrveSDKBundle = [SwrveSDKUtils swrveSDKBundle];
    NSString *dismissImageSVGName = @"swrve_x.svg";
    UIImage *dismissImage = [UIImage imageNamed:dismissImageSVGName inBundle:swrveSDKBundle compatibleWithTraitCollection:nil];
    if (!dismissImage) {
        [SwrveLogger error:@"Dismiss asset image missing from in-app story", nil];
    }
    return dismissImage;
}

+ (NSBundle *)swrveSDKBundle {
    NSBundle *mainBundle = [NSBundle bundleForClass:[SwrveSDKUtils class]];
           
    // cocoapods uses SwrveSDK.bundle , see resources_bundle in podspec
    NSURL *bundleURL = [[mainBundle resourceURL] URLByAppendingPathComponent:@"SwrveSDK.bundle"];
    NSBundle *frameworkBundle = [NSBundle bundleWithURL:bundleURL];
           
    if (frameworkBundle != nil) {
        return frameworkBundle;
    }
    
    // SPM references static framework, location is: Frameworks/SwrveSDK.framework.
    bundleURL = [[mainBundle resourceURL] URLByAppendingPathComponent:@"Frameworks/SwrveSDK.framework"];
    frameworkBundle = [NSBundle bundleWithURL:bundleURL];
           
    if (frameworkBundle != nil) {
        return frameworkBundle;
    }
    
#ifdef SWIFTPM_MODULE_BUNDLE
    mainBundle = SWIFTPM_MODULE_BUNDLE;
#endif
    
    // if its nil, try standard bundle location for class
    return mainBundle;
}

@end
