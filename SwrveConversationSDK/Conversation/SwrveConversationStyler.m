#import "SwrveConversationStyler.h"
#import "SwrveConversationButton.h"
#import "SwrveSetup.h"
@import CoreText;

#define kSwrveKeyBg @"bg"
#define kSwrveKeyFg @"fg"
#define kSwrveKeyLb @"lb"
#define kSwrveKeyType @"type"
#define kSwrveKeyValue @"value"
#define kSwrveKeyBorderRadius @"border_radius"
#define kSwrveMaxBorderRadius 22.5

#define kSwrveTypeTransparent @"transparent"
#define kSwrveTypeColor @"color"

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
        if ([type isEqualToString:kSwrveTypeTransparent]) {
            return kSwrveTypeTransparent;
        } else if ([type isEqualToString:kSwrveTypeColor]) {
            return [dict objectForKey:kSwrveKeyValue];
        }
    }
    return defaultColor;
}


+ (UIColor *) convertToUIColor:(NSString*)color {
    UIColor *uiColor;
    if ([color isEqualToString:kSwrveTypeTransparent]) {
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
    
    NSString *newCSS = [NSString stringWithFormat:@"%@ %@",pageCSS, [self applyDownloadedFontToHTML:@"SourceSansPro-Black"]];

    NSString *html = [NSString stringWithFormat:@"<html><head><style type=\"text/css\">%@ html { color: %@; } \
                          body { background-color: %@; } \
                          </style> \
                          </head> \
                          <body> \
                          %@ \
                          </body></html>", newCSS, fgHexColor, bgHexColor, content];
    
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

+ (void) styleButton:(SwrveConversationUIButton*)button withStyle:(NSDictionary*)style {
    NSString *fgHexColor = [self colorFromStyle:[style objectForKey:kSwrveKeyFg] withDefault:kSwrveDefaultColorFg];
    UIColor *fgUIColor = [self convertToUIColor:fgHexColor];
    NSString *styleType = kSwrveTypeSolid;
    if([style objectForKey:kSwrveKeyType]) {
        styleType = [style objectForKey:kSwrveKeyType];
    }
    NSString *bgHexColor = [self colorFromStyle:[style objectForKey:kSwrveKeyBg] withDefault:kSwrveDefaultColorBg];
    UIColor *bgUIColor = [self convertToUIColor:bgHexColor];
    float borderRadius = [self convertBorderRadius:[[style objectForKey:kSwrveKeyBorderRadius] floatValue]];
    
    [button initButtonType:styleType withForegroundColor:fgUIColor withBackgroundColor:bgUIColor withBorderRadius:borderRadius];
    
    NSMutableAttributedString *atttext=[[NSMutableAttributedString alloc] initWithString:button.titleLabel.text];
    
    NSRange attRange = NSMakeRange(0, button.titleLabel.text.length);

    //font
    UIFont *downloaded = [self applyDownloadedFont:@"SourceSansPro-Black" withSize:[UIFont buttonFontSize]];

    if(downloaded){
        [atttext addAttribute:NSFontAttributeName value:downloaded range:attRange];
    }

    //color
    [atttext addAttribute:NSForegroundColorAttributeName value:fgUIColor range:attRange];

//    //kern (letter spacing)
//    [atttext addAttribute:NSKernAttributeName value:@(1.4) range:attRange];
//
//    //strikethrough
//    [atttext addAttribute:NSStrikethroughStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:attRange];
//
//    //strikethrough color
//    [atttext addAttribute:NSStrikethroughColorAttributeName value:[UIColor greenColor] range:attRange];
//
//    //underline
//    [atttext addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:attRange];
//
//    //underline color
//    [atttext addAttribute:NSUnderlineColorAttributeName value:[UIColor redColor] range:attRange];
    
    button.titleLabel.attributedText = atttext;
}

+ (NSString *) applyDownloadedFontToHTML:(NSString *) fontName {
    
    NSString *cache = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString* fontPath = [cache stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.otf", fontName]];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:fontPath];
    if(fileExists){
        NSLog(@"\n %@.otf found at:%@ \n", fontName, fontPath);
        
        NSData *inData = [[NSFileManager defaultManager] contentsAtPath:fontPath];
        CFErrorRef error;
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)inData);
        CGFontRef font = CGFontCreateWithDataProvider(provider);
        if (! CTFontManagerRegisterGraphicsFont(font, &error)) {
            CFStringRef errorDescription = CFErrorCopyDescription(error);
            NSLog(@"Failed to load font: %@", errorDescription);
            CFRelease(errorDescription);
        }
        CFRelease(font);
        CFRelease(provider);
        
        return [NSString stringWithFormat:@" @font-face{ font-family:'%@'; src: url('%@')} body { font-family: %@; } ",fontName, fontPath, fontName];
    }
    
    //since there's no fonts to load
    return @"";
}

+ (UIFont *) applyDownloadedFont:(NSString *) fontName withSize:(CGFloat) size {
    NSString *cache = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString* fontPath = [cache stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.otf", fontName]];
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:fontPath];
    if(fileExists){
        NSLog(@"\n %@.otf found at:%@ \n", fontName, fontPath);
        
        NSData *inData = [[NSFileManager defaultManager] contentsAtPath:fontPath];
        CFErrorRef error;
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)inData);
        CGFontRef font = CGFontCreateWithDataProvider(provider);
        if (! CTFontManagerRegisterGraphicsFont(font, &error)) {
            CFStringRef errorDescription = CFErrorCopyDescription(error);
            NSLog(@"Failed to load font: %@", errorDescription);
            CFRelease(errorDescription);
        }
        CFRelease(font);
        CFRelease(provider);
        
        return  [UIFont fontWithName:fontName size:size];
    }
    
    //if there's no font
    return nil;
}

+ (void) styleStarRating:(SwrveContentStarRatingView*)ratingView withStyle:(NSDictionary*)style withStarColor:(NSString*)starColorHex {

    NSString *styleType = kSwrveTypeSolid;
    if([style objectForKey:kSwrveKeyType]) {
        styleType = [style objectForKey:kSwrveKeyType];
    }
    NSString *bgHexColor = [self colorFromStyle:[style objectForKey:kSwrveKeyBg] withDefault:kSwrveDefaultColorBg];
    UIColor *bgUIColor = [self convertToUIColor:bgHexColor];
    UIColor *starColor = [self convertToUIColor:starColorHex];
    
    [ratingView updateWithStarColor:starColor withBackgroundColor:bgUIColor];
}

@end
