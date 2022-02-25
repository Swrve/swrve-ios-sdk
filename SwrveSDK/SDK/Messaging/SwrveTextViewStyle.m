#import "SwrveTextViewStyle.h"
#import "SwrveConversationStyler.h"

@interface SwrveConversationStyler ()
+ (UIColor *)processHexColorValue:(NSString *)color;
@end

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
        
        //Conversation styler uses a different key for font size, so just at it
        NSMutableDictionary *mutableDictionary = [style mutableCopy];
        mutableDictionary[@"text_size"] = [NSNumber numberWithFloat:(float)self.fontsize];
        self.font = [SwrveConversationStyler fontFromStyle:mutableDictionary withFallback:defaultFont];
        
        NSString *foregroundColorString = [self colorString:@"font_color" fromStyle:style];
        self.foregroundColor = (foregroundColorString == nil) ? defaultForegroundColor : [SwrveConversationStyler processHexColorValue:foregroundColorString];
  
        NSString *backgroundColorString = [self colorString:@"bg_color" fromStyle:style];
        self.backgroundColor = (backgroundColorString == nil) ? defaultBackgroundColor : [SwrveConversationStyler processHexColorValue:backgroundColorString];
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

