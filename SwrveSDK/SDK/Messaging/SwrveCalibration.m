#import "SwrveCalibration.h"

@implementation SwrveCalibration

@synthesize renderScale;
@synthesize calibrationWidth;
@synthesize calibrationHeight;
@synthesize calibrationFontSize;
@synthesize calibrationText;

- (instancetype)initWithDictionary:(NSDictionary *)calibration {
    self = [super init];
    if (self) {
        self.calibrationWidth = (CGFloat)[[calibration objectForKey:@"width"] doubleValue];
        self.calibrationHeight = (CGFloat)[[calibration objectForKey:@"height"] doubleValue];
        self.calibrationFontSize = (CGFloat)[[calibration objectForKey:@"base_font_size"] doubleValue];
        self.calibrationText = [calibration objectForKey:@"text"];
    }
    return self;
}

@end
