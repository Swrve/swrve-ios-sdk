#import "SwrveStorySettings.h"

@implementation SwrveStorySettings

@synthesize pageDuration;
@synthesize lastPageProgression;
@synthesize lastPageDismissId;
@synthesize lastPageDismissName;
@synthesize topPadding;
@synthesize rightPadding;
@synthesize leftPadding;
@synthesize barColor;
@synthesize barBgColor;
@synthesize barHeight;
@synthesize segmentGap;
@synthesize gesturesEnabled;
@synthesize dismissButton;

- (instancetype)initWithDictionary:(NSDictionary *)storySettings {
    self = [super init];
    if (self) {
        self.pageDuration = [storySettings objectForKey:@"page_duration"];
        NSString *lastPageProgressionString = [storySettings objectForKey:@"last_page_progression"];
        if ([lastPageProgressionString isEqualToString:@"dismiss"]) {
            self.lastPageProgression = kSwrveStoryLastPageProgressionDismiss;
        } else if ([lastPageProgressionString isEqualToString:@"stop"]) {
            self.lastPageProgression = kSwrveStoryLastPageProgressionStop;
        } else if ([lastPageProgressionString isEqualToString:@"loop"]) {
            self.lastPageProgression = kSwrveStoryLastPageProgressionLoop;
        }
        if ([storySettings objectForKey:@"last_page_dismiss_id"]) {
            self.lastPageDismissId = [storySettings objectForKey:@"last_page_dismiss_id"]; // only available for lastPageProgression == dismiss
        }
        if ([storySettings objectForKey:@"last_page_dismiss_name"]) {
            self.lastPageDismissName = [storySettings objectForKey:@"last_page_dismiss_name"]; // only available for lastPageProgression == dismiss
        }

        // Bottom padding is not used
        NSDictionary *padding = [storySettings objectForKey:@"padding"];
        self.topPadding = [padding objectForKey:@"top"];
        self.rightPadding = [padding objectForKey:@"right"];
        self.leftPadding = [padding objectForKey:@"left"];

        NSDictionary *progressBar = [storySettings objectForKey:@"progress_bar"];
        self.barColor = [progressBar objectForKey:@"bar_color"];
        self.barBgColor = [progressBar objectForKey:@"bg_color"];
        self.barHeight = [progressBar objectForKey:@"h"];
        self.segmentGap = [progressBar objectForKey:@"segment_gap"];

        // future proofing ability to disable gestures
        if ([storySettings objectForKey:@"gestures_enabled"]) {
            self.gesturesEnabled = [[storySettings objectForKey:@"gestures_enabled"] boolValue];
        } else {
            self.gesturesEnabled = YES;
        }

        if ([storySettings objectForKey:@"dismiss_button"]) {
            self.dismissButton = [[SwrveStoryDismissButton alloc] initWithDictionary:[storySettings objectForKey:@"dismiss_button"]];
        }
    }
    return self;
}

@end
