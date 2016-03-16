#import "SwrveConversationStyler.h"
#import "SwrveConversationButton.h"
#import "SwrveSetup.h"

#define kSwrveKeyBg @"bg"
#define kSwrveKeyFg @"fg"
#define kSwrveKeyType @"type"
#define kSwrveKeyValue @"value"
#define kSwrveKeyBorderRadius @"border_radius"
#define kSwrveMaxBorderRadius 22.5

#define kSwrveTypeTransparent @"transparent"
#define kSwrveTypeColor @"color"

#define kSwrveDefaultColorBg @"#ffffff"
#define kSwrveDefaultColorFg @"#000000"

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
        unsigned int hexInt = 0;
        NSScanner *scanner = [NSScanner scannerWithString:color];
        [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"#"]];
        [scanner scanHexInt:&hexInt];
        uiColor = Swrve_UIColorFromRGB(hexInt);
    }
    return uiColor;
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
