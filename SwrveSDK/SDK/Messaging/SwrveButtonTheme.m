#import "SwrveButtonTheme.h"

@implementation SwrveButtonTheme

@synthesize fontSize;
@synthesize fontFile;
@synthesize fontDigest;
@synthesize fontNativeStyle;
@synthesize fontPostscriptName;
@synthesize topPadding;
@synthesize rightPadding;
@synthesize bottomPadding;
@synthesize leftPadding;
@synthesize cornerRadius;
@synthesize fontColor;
@synthesize bgColor;
@synthesize borderWidth;
@synthesize borderColor;
@synthesize bgImage;
@synthesize truncate;
@synthesize pressedState;
@synthesize focusedState;
@synthesize hAlign;

- (id)initWithDictionary:(NSDictionary *)themeData {
    if (self = [super init]) {
        self.fontSize = [themeData objectForKey:@"font_size"];
        self.fontFile = [themeData objectForKey:@"font_file"];
        if ([themeData objectForKey:@"font_digest"]) {
            self.fontDigest = [themeData objectForKey:@"font_digest"];
        }
        if ([themeData objectForKey:@"font_native_style"]) {
            self.fontNativeStyle = [themeData objectForKey:@"font_native_style"];
        }
        self.fontPostscriptName = [themeData objectForKey:@"font_postscript_name"];
        NSDictionary *padding = [themeData objectForKey:@"padding"];
        self.topPadding = [padding objectForKey:@"top"];
        self.bottomPadding = [padding objectForKey:@"bottom"];
        self.rightPadding = [padding objectForKey:@"right"];
        self.leftPadding = [padding objectForKey:@"left"];
        self.cornerRadius = [themeData objectForKey:@"corner_radius"];
        self.fontColor = [themeData objectForKey:@"font_color"];
        self.fontDigest = [themeData objectForKey:@"font_digest"];
        if ([themeData objectForKey:@"bg_color"]) {
            self.bgColor = [themeData objectForKey:@"bg_color"];
        }
        if ([themeData objectForKey:@"border_width"]) {
            self.borderWidth = [themeData objectForKey:@"border_width"];
        }
        if ([themeData objectForKey:@"border_color"]) {
            self.borderColor = [themeData objectForKey:@"border_color"];
        }
        if ([themeData objectForKey:@"bg_image"] && [themeData objectForKey:@"bg_image"] != [NSNull null]) {
            self.bgImage = [(NSDictionary *) [themeData objectForKey:@"bg_image"] objectForKey:@"value"];
        }
        self.truncate = [[themeData objectForKey:@"truncate"] boolValue];
        self.pressedState = [[SwrveButtonThemeState alloc] initWithDictionary:[themeData objectForKey:@"pressed_state"]];
        if ([themeData objectForKey:@"focused_state"] && [themeData objectForKey:@"focused_state"] != [NSNull null]) {
            self.focusedState = [[SwrveButtonThemeState alloc] initWithDictionary:[themeData objectForKey:@"focused_state"]];
        }
        self.hAlign = [themeData objectForKey:@"h_align"];
    }
    return self;
}

@end
