#import "SwrveImage.h"
#import "SwrvePersonalizedTextImage.h"
#import "SwrveDynamicUrlImage.h"

@implementation SwrveImage

@synthesize file;
@synthesize dynamicImageUrl;
@synthesize text;
@synthesize center;
@synthesize size;
@synthesize message;

- (UIImage*)createImage:(NSString *)cacheFolder
        personalization:(NSString *)personalizedTextStr
personalizedUrlAssetSha1:(NSString *)personalizedUrlAssetSha1
            inAppConfig:(SwrveInAppMessageConfig *)inAppConfig
                 qaInfo:(SwrveQAImagePersonalizationInfo *)qaInfo {

    NSURL* bgurl = [NSURL fileURLWithPathComponents:[NSArray arrayWithObjects:cacheFolder, self.file, nil]];
    UIImage* image = [UIImage imageWithData:[NSData dataWithContentsOfURL:bgurl]];
    
    if (personalizedTextStr != nil) {
        // store the current image so we can use it as a guide
        UIImage *guideImage = image;
        
        image = [SwrvePersonalizedTextImage imageFromString:personalizedTextStr
                                        withBackgroundColor:inAppConfig.personalizationBackgroundColor
                                        withForegroundColor:inAppConfig.personalizationForegroundColor
                                                   withFont:inAppConfig.personalizationFont
                                                       size:guideImage.size];
        
    } else if(personalizedUrlAssetSha1 != nil) {
        UIImage *dynamicImage = [SwrveDynamicUrlImage dynamicImageToContainer:personalizedUrlAssetSha1
                                                                  cacheFolder:cacheFolder size:self.size
                                                                       qaInfo:qaInfo];
        if (dynamicImage != nil){
            image = dynamicImage;
        }
    }
    
    return image;
}

@end
