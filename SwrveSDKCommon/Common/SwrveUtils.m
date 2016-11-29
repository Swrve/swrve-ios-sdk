#import "SwrveUtils.h"

@implementation SwrveUtils

+ (CGFloat)convertPixelsToPoints:(CGFloat)pixels {
    CGFloat pointsPerInch = 72.0;
    CGFloat scale = 1.0;
    CGFloat pixelsPerInch;
    UIUserInterfaceIdiom uiUserInterfaceIdiom = UI_USER_INTERFACE_IDIOM();
    if (uiUserInterfaceIdiom == UIUserInterfaceIdiomPad) {
        pixelsPerInch = 132 * scale;
    } else if (uiUserInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        pixelsPerInch = 163 * scale;
    } else {
        pixelsPerInch = 160 * scale;
    }
    CGFloat points = pixels * pointsPerInch / pixelsPerInch;
    return points;
}

@end
