#import "SwrveStoryDismissButton.h"

@implementation SwrveStoryDismissButton

@synthesize buttonId;
@synthesize name;
@synthesize color;
@synthesize pressedColor;
@synthesize focusedColor;
@synthesize size;
@synthesize marginTop;
@synthesize accessibilityText;

- (instancetype)initWithDictionary:(NSDictionary *)storySettings {
    self = [super init];
    if (self) {
        self.buttonId = [storySettings objectForKey:@"id"];
        self.name = [storySettings objectForKey:@"name"];
        self.color = [storySettings objectForKey:@"color"];
        self.pressedColor = [storySettings objectForKey:@"pressed_color"];
        self.focusedColor = [storySettings objectForKey:@"focused_color"];
        self.size = [storySettings objectForKey:@"size"];
        self.marginTop = [storySettings objectForKey:@"margin_top"];
        self.accessibilityText = [storySettings objectForKey:@"accessibility_text"];
    }
    return self;
}

@end
