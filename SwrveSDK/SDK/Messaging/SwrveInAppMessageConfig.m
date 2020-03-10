#import "SwrveInAppMessageConfig.h"

@implementation SwrveInAppMessageConfig

@synthesize backgroundColor;
@synthesize personalisationForegroundColor;
@synthesize personalisationBackgroundColor;
@synthesize personalisationFont;

-(id) init
{
    if ( self = [super init] ) {
        self.personalisationForegroundColor = [UIColor blackColor];
        self.personalisationBackgroundColor = [UIColor clearColor];
        self.personalisationFont = [UIFont systemFontOfSize:0];
    }
    return self;
}

@end
