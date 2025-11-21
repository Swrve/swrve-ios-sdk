#import "SwrveTextViewStyle.h"
#import "SwrveSDKUtils.h"

#if __has_include(<SwrveSDKCommon/SwrveUtils.h>)
#import <SwrveSDKCommon/SwrveUtils.h>
#else
#import "SwrveUtils.h"
#endif

@implementation SwrveTextViewStyle

@synthesize fontsize;
@synthesize text;
@synthesize textAlignment;
@synthesize scrollable;
@synthesize font;
@synthesize foregroundColor;
@synthesize backgroundColor;
@synthesize font_postscript_name;
@synthesize font_native_style;
@synthesize font_file;
@synthesize font_digest;
@synthesize padding;
@synthesize line_height;
@synthesize topPadding;
@synthesize rightPadding;
@synthesize bottomPadding;
@synthesize leftPadding;

- (instancetype)initWithDictionary:(NSDictionary *)style
                       defaultFont:(UIFont *)defaultFont
            defaultForegroundColor:(UIColor *)defaultForegroundColor
            defaultBackgroundColor:(UIColor *)defaultBackgroundColor {
    self = [super init];
    if (self) {
        self.text = [style objectForKey:@"value"];
        self.fontsize = [[style objectForKey:@"font_size"] floatValue];
        self.scrollable = [[style objectForKey:@"scrollable"] boolValue];
        self.textAlignment = [self textAlignmentFromString:[style objectForKey:@"h_align"]];
        self.font_postscript_name = [style objectForKey:@"font_postscript_name"];
        self.font_native_style = [style objectForKey:@"font_native_style"];
        self.font_file = [style objectForKey:@"font_file"];
        self.font_digest = [style objectForKey:@"font_digest"];
        self.line_height = [[style objectForKey:@"line_height"] floatValue];
        self.padding = [style objectForKey:@"padding"];
        self.topPadding = [self padding:@"top" fromStyle:style];
        self.rightPadding = [self padding:@"right" fromStyle:style];
        self.bottomPadding = [self padding:@"bottom" fromStyle:style];
        self.leftPadding = [self padding:@"left" fromStyle:style];

        self.font = [SwrveSDKUtils fontFromFile:self.font_file
                                  postscriptName:self.font_postscript_name
                                            size:self.fontsize
                                           style:self.font_native_style
                                    withFallback:defaultFont];

        NSString *foregroundColorString = [self colorString:@"font_color" fromStyle:style];
        self.foregroundColor = (foregroundColorString == nil) ? defaultForegroundColor : [SwrveUtils processHexColorValue:foregroundColorString];
  
        NSString *backgroundColorString = [self colorString:@"bg_color" fromStyle:style];
        self.backgroundColor = (backgroundColorString == nil) ? defaultBackgroundColor : [SwrveUtils processHexColorValue:backgroundColorString];
    }
    return self;
}

- (NSTextAlignment)textAlignmentFromString:(NSString *)textAlignmentString {
    if ([textAlignmentString isEqualToString:@"CENTER"]) {
        return NSTextAlignmentCenter;
    } else if ([textAlignmentString isEqualToString:@"RIGHT"]) {
        return NSTextAlignmentRight;
    } else {
        return NSTextAlignmentLeft;
    }
}

- (NSString *)colorString:(NSString *)key fromStyle:(NSDictionary *)style {
    NSString *colorString = [style objectForKey:key];
    return (colorString == nil) ? nil : colorString;
}

- (int)padding:(NSString *)key fromStyle:(NSDictionary *)style  {
    NSNumber *value = [self.padding objectForKey:key];
    return (value == nil) ? 0 : [value intValue];
}

@end

