#import "SwrveImage.h"
#import "SwrvePersonalisedTextImage.h"

@implementation SwrveImage

@synthesize file;
@synthesize text;
@synthesize center;

- (UIImage*)createImage:(NSString *)cacheFolder
        personalisation:(NSString*)personalisedTextStr
            inAppConfig:(SwrveInAppMessageConfig *)inAppConfig {

    NSURL* bgurl = [NSURL fileURLWithPathComponents:[NSArray arrayWithObjects:cacheFolder, self.file, nil]];
    UIImage* image = [UIImage imageWithData:[NSData dataWithContentsOfURL:bgurl]];
    
    if (personalisedTextStr != nil) {
        // store the current image so we can use it as a guide
        UIImage *guideImage = image;
        
        image = [SwrvePersonalisedTextImage imageFromString:personalisedTextStr
                withBackgroundColor:inAppConfig.personalisationBackgroundColor
                withForegroundColor:inAppConfig.personalisationForegroundColor
                       withFont:inAppConfig.personalisationFont
                               size:guideImage.size];
    }
    
    return image;
}

@end
