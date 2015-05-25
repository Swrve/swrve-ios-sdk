#import "SwrveConversationStyler.h"
#import "SwrveSetup.h"

#define kSwrveKeyBg @"bg"
#define kSwrveKeyFg @"fg"
#define kSwrveKeyType @"type"
#define kSwrveKeyValue @"value"

#define kSwrveTypeTransparent @"transparent"
#define kSwrveTypeColor @"color"
#define kSwrveTypeSolid @"solid"
#define kSwrveTypeOutline @"outline"

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

+ (NSString *) convertContentToHtml:(NSString*)content withStyle:(NSDictionary*)style{
    NSString *fontFam = @"Helvetica";
    NSString *fgHexColor = [self colorFromStyle:[style objectForKey:kSwrveKeyFg] withDefault:kSwrveDefaultColorFg];
    NSString *bgHexColor = [self colorFromStyle:[style objectForKey:kSwrveKeyBg] withDefault:kSwrveDefaultColorBg];

    NSString *html = [NSString stringWithFormat:@"<html><head><style type=\"text/css\">html h1 {font-family:\"%@\"; font-weight:bold; font-size:22px; color:%@} \
                          body {font-family:\"%@\";background-color: %@;} \
                          </style> \
                          </head> \
                          <body> \
                          %@ \
                          </body></html>", fontFam, fgHexColor, fontFam, bgHexColor, content];
    
    return html;
}

+(void) styleButton:(UIButton *)button withStyle:(NSDictionary*)style {
    NSString *fgHexColor = [self colorFromStyle:[style objectForKey:kSwrveKeyFg] withDefault:kSwrveDefaultColorFg];
    UIColor *fgUIColor = [self convertToUIColor:fgHexColor];

    [button setTitleColor:fgUIColor forState:UIControlStateNormal];
    [button setTitleColor:fgUIColor forState:UIControlStateHighlighted];
    [button setTitleColor:fgUIColor forState:UIControlStateSelected];

    NSString *styleType = kSwrveTypeSolid;
    if([style objectForKey:kSwrveKeyType]) {
        styleType = [style objectForKey:kSwrveKeyType];
    }
    NSString *bgHexColor = [self colorFromStyle:[style objectForKey:kSwrveKeyBg] withDefault:kSwrveDefaultColorBg];
    UIColor *bgUIColor = [self convertToUIColor:bgHexColor];

    if ([styleType isEqualToString:kSwrveTypeSolid]) {
        [button setBackgroundColor:bgUIColor];
    } else if ([styleType isEqualToString:kSwrveTypeOutline]) {
        [[button layer] setBorderWidth:1.5f];
        [[button layer] setBorderColor:fgUIColor.CGColor];
        [button setBackgroundColor:bgUIColor];
    }
}

@end
