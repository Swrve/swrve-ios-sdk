#import "SwrveConversationStyler.h"
#import "SwrveConversationButton.h"
#import "SwrveCommon.h"
#import "SwrveLocalStorage.h"
#import "SwrveBaseConversation.h"
#import <CoreText/CoreText.h>

#define kSwrveKeyBg @"bg"
#define kSwrveKeyFg @"fg"
#define kSwrveKeyLb @"lb"
#define kSwrveKeyType @"type"
#define kSwrveKeyColorValue @"value"
#define kSwrveKeyBorderRadius @"border_radius"
#define kSwrveMaxBorderRadius 22.5

#define kSwrveColorTypeTransparent @"transparent"
#define kSwrveColorTypeColor @"color"

#define kSwrveDefaultColorBg @"#ffffff"   // white
#define kSwrveDefaultColorFg @"#000000"   // black
#define kSwrveDefaultColorLb @"#B3000000" // 70% alpha black

@implementation SwrveConversationStyler : NSObject

+ (void)styleView:(UIView *)uiView withStyle:(NSDictionary*)style {
    NSString *fgHexColor = [self colorFromStyle:[style objectForKey:kSwrveKeyFg] withDefault:kSwrveDefaultColorFg];
    UIColor *fgUIColor = [self convertToUIColor:fgHexColor];
    if([uiView isKindOfClass:[UITableViewCell class]] ) {
        UITableViewCell *uiTableViewCell = (UITableViewCell*)uiView;
        uiTableViewCell.textLabel.textColor = fgUIColor;
    }

    NSString *bgHexColor = [self colorFromStyle:[style objectForKey:kSwrveKeyBg] withDefault:kSwrveDefaultColorBg];
    UIColor *bgUIColor = [self convertToUIColor:bgHexColor];
    uiView.backgroundColor = bgUIColor;
}

+ (void)styleModalView:(UIView *)uiView withStyle:(NSDictionary*)style {
    if([style.allKeys containsObject:kSwrveKeyBorderRadius]){
        float border = [self convertBorderRadius:[[style objectForKey:kSwrveKeyBorderRadius] floatValue]];
        uiView.layer.cornerRadius = border;
    }
    
    NSDictionary *lightBox = [style objectForKey:kSwrveKeyLb];
    NSString *color = [self colorFromStyle:lightBox withDefault:kSwrveDefaultColorLb];
    uiView.superview.backgroundColor = [self convertToUIColor:color];
}

+ (NSString *)colorFromStyle:(NSDictionary *)dict withDefault:(NSString*) defaultColor {
    if (dict) {
        NSString *type = [dict objectForKey:kSwrveKeyType];
        if ([type isEqualToString:kSwrveColorTypeTransparent]) {
            return kSwrveColorTypeTransparent;
        } else if ([type isEqualToString:kSwrveColorTypeColor]) {
            return [dict objectForKey:kSwrveKeyColorValue];
        }
    }
    return defaultColor;
}

+ (UIColor *) convertToUIColor:(NSString*)color {
    UIColor *uiColor;
    if ([color isEqualToString:kSwrveColorTypeTransparent]) {
        uiColor = [UIColor clearColor];
    } else {
        uiColor = [self processHexColorValue:color];
    }
    return uiColor;
}

+ (UIColor *) processHexColorValue:(NSString *)color {
    NSString *colorString = [[color stringByReplacingOccurrencesOfString: @"#" withString: @""] uppercaseString];
    UIColor *returnColor;
    
    if([colorString length] == 6) {
        unsigned int hexInt = 0;
        NSScanner *scanner = [NSScanner scannerWithString:colorString];
        [scanner scanHexInt:&hexInt];
        returnColor = Swrve_UIColorFromRGB(hexInt, 1.0f);
        
    }else if([colorString length] == 8) {
        
        NSString *alphaSub = [colorString substringWithRange: NSMakeRange(0, 2)];
        NSString *colorSub = [colorString substringWithRange: NSMakeRange(2, 6)];
        
        unsigned hexComponent;
        unsigned int hexInt = 0;
        [[NSScanner scannerWithString: alphaSub] scanHexInt: &hexComponent];
        float alpha = hexComponent / 255.0f;
        
        NSScanner *scanner = [NSScanner scannerWithString:colorSub];
        [scanner scanHexInt:&hexInt];
        returnColor = Swrve_UIColorFromRGB(hexInt, alpha);
    }
    
    return returnColor;
}

+ (NSString *) convertContentToHtml:(NSString*)content withPageCSS:(NSString*)pageCSS withStyle:(NSDictionary*)style {
    [SwrveConversationStyler fontFromStyle:style withFallback:nil]; // register any custom font
    NSString *fgHexColor = [self colorFromStyle:[style objectForKey:kSwrveKeyFg] withDefault:kSwrveDefaultColorFg];
    NSString *bgHexColor = [self colorFromStyle:[style objectForKey:kSwrveKeyBg] withDefault:kSwrveDefaultColorBg];

    NSString *html = [NSString stringWithFormat:@"<html><head><style type=\"text/css\">%@ html { color: %@; } \
                          body { background-color: %@; } \
                          </style> \
                          </head> \
                          <body> \
                          %@ \
                          </body></html>", pageCSS, fgHexColor, bgHexColor, content];

    return html;
}

+ (float) convertBorderRadius:(float)borderRadiusPercentage {
    if(borderRadiusPercentage >= 100.0){
        return (float)kSwrveMaxBorderRadius;
    }else{
        float percentage = borderRadiusPercentage / 100;
        return (float)kSwrveMaxBorderRadius * percentage;
    }
}

+ (void)styleButton:(SwrveConversationUIButton *)button withStyle:(NSDictionary *)style {
    NSString *fgHexColor = [self colorFromStyle:[style objectForKey:kSwrveKeyFg] withDefault:kSwrveDefaultColorFg];
    UIColor *fgUIColor = [self convertToUIColor:fgHexColor];
    NSString *styleType = kSwrveStyleTypeSolid;
    if ([style objectForKey:kSwrveKeyType]) {
        styleType = [style objectForKey:kSwrveKeyType];
    }
    NSString *bgHexColor = [self colorFromStyle:[style objectForKey:kSwrveKeyBg] withDefault:kSwrveDefaultColorBg];
    UIColor *bgUIColor = [self convertToUIColor:bgHexColor];
    float borderRadius = [self convertBorderRadius:[[style objectForKey:kSwrveKeyBorderRadius] floatValue]];

    [button initButtonType:styleType withForegroundColor:fgUIColor withBackgroundColor:bgUIColor withBorderRadius:borderRadius];

    UIFont *fallbackFont = [UIFont boldSystemFontOfSize:[kSwrveDefaultButtonFontSize floatValue]];
    UIFont *buttonFont = [SwrveConversationStyler fontFromStyle:style withFallback:fallbackFont];
    [[button titleLabel] setFont:buttonFont];

    NSString *styleAlignment = [style objectForKey:kSwrveKeyAlignment];
    if (styleAlignment) {
        if ([styleAlignment isEqualToString:@"left"]) {
            [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
            [button setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 5.0, 0.0, 0.0)];
        } else if ([styleAlignment isEqualToString:@"center"]) {
            [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
        } else if ([styleAlignment isEqualToString:@"right"]) {
            [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
            [button setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 0.0, 5.0)];
        }
    } else {
        [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
    }

    button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [button.titleLabel setLineBreakMode:NSLineBreakByTruncatingTail];
    [button.titleLabel setNumberOfLines:1];
}

+ (UIFont *)fontFromStyle:(NSDictionary *)style withFallback:(UIFont *)fallbackUIFont {

    NSString *fontFile = [style objectForKey:kSwrveKeyFontFile];
    NSString *fontPostscriptName = [style objectForKey:kSwrveKeyFontPostscriptName];
    CGFloat fontSizePixels = [[style objectForKey:kSwrveKeyTextSize] floatValue];
    CGFloat fontSizePoints = fontSizePixels;

    UIFont *uiFont;
    if ([SwrveBaseConversation isSystemFont:style]) {
        NSString *fontNativeStyle = [style objectForKey:kSwrveKeyFontNativeStyle];
        if(fontNativeStyle && [fontNativeStyle isEqualToString:@"Normal"]) {
            uiFont = [UIFont systemFontOfSize:fontSizePoints];
        } else if(fontNativeStyle && [fontNativeStyle isEqualToString:@"Bold"]) {
            uiFont = [UIFont boldSystemFontOfSize:fontSizePoints];
        } else if(fontNativeStyle && [fontNativeStyle isEqualToString:@"Italic"]) {
            uiFont = [UIFont italicSystemFontOfSize:fontSizePoints];
        } else if(fontNativeStyle && [fontNativeStyle isEqualToString:@"BoldItalic"]) {
            if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
                UILabel * label = [[UILabel alloc] init];
                UIFontDescriptor * fontD = [label.font.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold | UIFontDescriptorTraitItalic];
                label.font = [UIFont fontWithDescriptor:fontD size:fontSizePoints];
                uiFont = label.font;
            }
        }
    } else if (fontFile == nil || (fontFile && [fontFile length] == 0)) { // will be blank for v1/v2/v3 of conversations
        uiFont = [fallbackUIFont fontWithSize:fontSizePoints];
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
                        DebugLog(@"Error registering font: %@ fontPath:%@ errorDescription:%@", fontFile, fontPath, errorDescription);
                        CFRelease(errorDescription);
                    }
                }
                CGFontRelease(cgFont);
                CGDataProviderRelease(fontDataProvider);
                if (newFontPostscsriptNameCString != nil) {
                    CFRelease(newFontPostscsriptNameCString);
                }
            } else {
                DebugLog(@"Swrve: fontFile %@ could not be loaded. Using default/fallback.", fontFile);
            }
        }
    }

    if (!uiFont) {
        uiFont = fallbackUIFont;
    }
    return uiFont;
}

+ (void) styleStarRating:(SwrveContentStarRatingView*)ratingView withStyle:(NSDictionary*)style withStarColor:(NSString*)starColorHex {
    NSString *bgHexColor = [self colorFromStyle:[style objectForKey:kSwrveKeyBg] withDefault:kSwrveDefaultColorBg];
    UIColor *bgUIColor = [self convertToUIColor:bgHexColor];
    UIColor *starColor = [self convertToUIColor:starColorHex];
    [ratingView updateWithStarColor:starColor withBackgroundColor:bgUIColor];
}

@end
