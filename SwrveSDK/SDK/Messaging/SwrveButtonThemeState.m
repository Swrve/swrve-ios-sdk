#import "SwrveButtonThemeState.h"

@implementation SwrveButtonThemeState

@synthesize fontColor;
@synthesize bgColor;
@synthesize borderColor;
@synthesize bgImage;

- (id)initWithDictionary:(NSDictionary *)themeState {
    if (self = [super init]) {
        if ([themeState objectForKey:@"font_color"]) {
            self.fontColor = [themeState objectForKey:@"font_color"];
        }
        if ([themeState objectForKey:@"bg_color"]) {
            self.bgColor = [themeState objectForKey:@"bg_color"];
        }
        if ([themeState objectForKey:@"border_color"]) {
            self.borderColor = [themeState objectForKey:@"border_color"];
        }
        if ([themeState objectForKey:@"bg_image"] && [themeState objectForKey:@"bg_image"] != [NSNull null]) {
            self.bgImage = [(NSDictionary *) [themeState objectForKey:@"bg_image"] objectForKey:@"value"];
        }
    }
    return self;
}

@end
