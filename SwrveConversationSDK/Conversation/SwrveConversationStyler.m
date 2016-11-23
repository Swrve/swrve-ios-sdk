#import "SwrveConversationStyler.h"
#import "SwrveConversationButton.h"
#import "SwrveCommon.h"
#import <CoreText/CoreText.h>
#import <CoreText/CTFontManager.h>

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

    NSString *fontName = [style objectForKey:kSwrveKeyFontFile];
    NSNumber *fontSize = [style objectForKey:kSwrveKeyTextSize];

    UIFont *uiFont;
    if (fontName && [fontName length] == 0) { // will be blank for system font and for v1/v2/v3 of conversations
        uiFont = [fallbackUIFont fontWithSize:[fontSize floatValue]];
    } else {
        uiFont = [UIFont fontWithName:fontName size:[fontSize floatValue]];
        if (!uiFont) {
            NSString *cache = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
            NSString *fontPath = [cache stringByAppendingPathComponent:fontName];
            BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:fontPath];
            if (fileExists) {
                NSURL *url = [NSURL fileURLWithPath:fontPath];
                CGDataProviderRef fontDataProvider = CGDataProviderCreateWithURL((__bridge CFURLRef) url);
                CGFontRef cgFont = CGFontCreateWithDataProvider(fontDataProvider);
                NSString *newFontName = (__bridge NSString *) CGFontCopyPostScriptName(cgFont);
                if(newFontName) {
                    uiFont = [UIFont fontWithName:newFontName size:[fontSize floatValue]]; // check again if already registered
                }
                if (uiFont == NULL) {
                    CGDataProviderRelease(fontDataProvider);
                    CFErrorRef cfError;
                    BOOL success = CTFontManagerRegisterGraphicsFont(cgFont, &cfError);
                    CGFontRelease(cgFont);
                    if (success) {
                        uiFont = [UIFont fontWithName:newFontName size:[fontSize floatValue]];
                    } else {
                        DebugLog(@"Error registering font: %@ fontPath:%@", fontName, fontPath);
                    }
                }
            } else {
                DebugLog(@"Swrve: font %@ could not be loaded.Using default/fallback.", fontName);
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
