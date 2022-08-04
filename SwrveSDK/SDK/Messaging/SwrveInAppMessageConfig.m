#import "SwrveInAppMessageConfig.h"

@implementation SwrveInAppMessageConfig

@synthesize backgroundColor;
@synthesize prefersStatusBarHidden;
@synthesize personalizationForegroundColor;
@synthesize personalizationBackgroundColor;
@synthesize personalizationFont;
@synthesize customButtonCallback;
@synthesize dismissButtonCallback;
@synthesize clipboardButtonCallback;
@synthesize personalizationCallback;
@synthesize inAppCapabilitiesDelegate;

- (id)init {
    if (self = [super init]) {
        prefersStatusBarHidden = YES;
        self.personalizationForegroundColor = [UIColor blackColor];
        self.personalizationBackgroundColor = [UIColor clearColor];
        self.personalizationFont = [UIFont systemFontOfSize:0];
    }
    return self;
}

@end
