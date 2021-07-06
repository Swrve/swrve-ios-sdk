#import "SwrveButton.h"
#import "SwrvePersonalizedTextImage.h"
#import "SwrveDynamicUrlImage.h"
#if __has_include(<SwrveSDKCommon/SwrveLocalStorage.h>)
#import <SwrveSDKCommon/SwrveLocalStorage.h>
#else
#import "SwrveLocalStorage.h"
#endif

#define DEFAULT_WIDTH 100
#define DEFAULT_HEIGHT 20

@interface SwrveButton()

@end

@implementation SwrveButton

@synthesize name;
@synthesize image;
@synthesize dynamicImageUrl;
@synthesize text;
@synthesize actionString;
@synthesize message;
@synthesize center;
@synthesize size;
@synthesize messageID;
@synthesize appID;
@synthesize actionType;

static CGPoint scaled(CGPoint point, float scale)
{
    return CGPointMake(point.x * scale, point.y * scale);
}

-(id)init
{
    self = [super init];
    self.name         = NULL;
    self.image        = @"buttonup.png";
    self.dynamicImageUrl = NULL;
    self.text         = NULL;
    self.actionString = @"";
    self.appID       = 0;
    self.actionType   = kSwrveActionDismiss;
    self.center   = CGPointMake(100, 100);
    self.size     = CGSizeMake(0, 0);
    return self;
}

- (UISwrveButton*)createButtonWithDelegate:(id)delegate
                               andSelector:(SEL)selector
                                  andScale:(float)scale
                                andCenterX:(float)cx
                                andCenterY:(float)cy
                     andPersonalizedAction:(NSString*)personalizedActionStr
                        andPersonalization:(NSString*)personalizedTextStr
               andPersonalizedUrlAssetSha1:(NSString*)personalizedUrlAssetSha1
                                withConfig:(SwrveInAppMessageConfig*)inAppConfig
                                    qaInfo:(SwrveQAImagePersonalizationInfo*)qaInfo
{

    NSString *cacheFolder = [SwrveLocalStorage swrveCacheFolder];
    NSURL* url_up = [NSURL fileURLWithPathComponents:[NSArray arrayWithObjects:cacheFolder, image, nil]];
    UIImage* up   = [UIImage imageWithData:[NSData dataWithContentsOfURL:url_up]];
    
    if (personalizedTextStr != nil) {
        // store the current 'up' image so we can use it as a guide
        UIImage *guideImage = up;

        up = [SwrvePersonalizedTextImage imageFromString:personalizedTextStr
                withBackgroundColor:inAppConfig.personalizationBackgroundColor
                withForegroundColor:inAppConfig.personalizationForegroundColor
                       withFont:inAppConfig.personalizationFont
                               size:guideImage.size];
        
    } else if (personalizedUrlAssetSha1 != nil) {
        UIImage *dynamicImage = [SwrveDynamicUrlImage dynamicImageToContainer:personalizedUrlAssetSha1
                                                                  cacheFolder:cacheFolder
                                                                         size:self.size
                                                                        qaInfo:qaInfo];
        if (dynamicImage != nil) {
            up = dynamicImage;
        }
    }
        
    UISwrveButton* result;
    if (up) {
        result = [UISwrveButton buttonWithType:UIButtonTypeCustom];

#if TARGET_OS_TV
        result.imageView.adjustsImageWhenAncestorFocused = YES;
#endif
        [result setBackgroundImage:up forState:UIControlStateNormal];
    }
    else {
        result = [UISwrveButton buttonWithType:UIButtonTypeRoundedRect];
    }

#if TARGET_OS_IOS /** TouchUpInside is iOS only **/
    [result  addTarget:delegate action:selector forControlEvents:UIControlEventTouchUpInside];
#elif TARGET_OS_TV
    // There are no touch actions in tvOS, so Primary Action Triggered is the event to run it
    [result  addTarget:delegate action:selector forControlEvents:UIControlEventPrimaryActionTriggered];
#endif

    CGFloat width  = DEFAULT_WIDTH;
    CGFloat height = DEFAULT_HEIGHT;

    if (up) {
        width  = [up size].width;
        height = [up size].height;
    }

    CGPoint position = scaled(self.center, scale);
    [result setFrame:CGRectMake(0, 0, width * scale, height * scale)];
    [result setCenter: CGPointMake(position.x + cx, position.y + cy)];
    
    if (self.actionType == kSwrveActionClipboard || self.actionType == kSwrveActionCustom) {
        result.actionString = personalizedActionStr;
    }
    
    if (personalizedTextStr) {
        // store the text that was displayed for testing
        result.displayString = personalizedTextStr;
    }

    return result;
}


@end
