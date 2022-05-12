#import "SwrveButton.h"
#import "SwrveTextImageView.h"
#import "SwrveDynamicUrlImage.h"

#if __has_include(<SwrveSDKCommon/SwrveLocalStorage.h>)

#import <SwrveSDKCommon/SwrveLocalStorage.h>

#else
#import "SwrveLocalStorage.h"
#endif

#define DEFAULT_WIDTH 100
#define DEFAULT_HEIGHT 20

@interface SwrveButton ()

@end

@implementation SwrveButton

@synthesize name;
@synthesize buttonId;
@synthesize image;
@synthesize dynamicImageUrl;
@synthesize text;
@synthesize actionString;
@synthesize center;
@synthesize size;
@synthesize campaignId;
@synthesize messageId;
@synthesize appID;
@synthesize actionType;
@synthesize accessibilityText;

static CGPoint scaled(CGPoint point, float scale) {
    return CGPointMake(point.x * scale, point.y * scale);
}

- (id)initWithDictionary:(NSDictionary *)buttonData campaignId:(long)swrveCampaignId messageId:(long)swrveMessageId appStoreURLs:(NSMutableDictionary *)appStoreURLs {
    if (self = [super init]) {

        self.campaignId = swrveCampaignId;
        self.messageId = swrveMessageId;

        self.name = [buttonData objectForKey:@"name"];
        if ([buttonData objectForKey:@"button_id"]) {
            self.buttonId = [buttonData objectForKey:@"button_id"];
        }

        NSNumber *x = [(NSDictionary *) [buttonData objectForKey:@"x"] objectForKey:@"value"];
        NSNumber *y = [(NSDictionary *) [buttonData objectForKey:@"y"] objectForKey:@"value"];
        self.center = CGPointMake(x.floatValue, y.floatValue);

        NSNumber *w = [(NSDictionary *) [buttonData objectForKey:@"w"] objectForKey:@"value"];
        NSNumber *h = [(NSDictionary *) [buttonData objectForKey:@"h"] objectForKey:@"value"];
        self.size = CGSizeMake(w.floatValue, h.floatValue);

        if ([buttonData objectForKey:@"image_up"]) {
            self.image = [(NSDictionary *) [buttonData objectForKey:@"image_up"] objectForKey:@"value"];
        } else {
            self.image = @"buttonup.png";
        }

        if ([buttonData objectForKey:@"dynamic_image_url"]) {
            self.dynamicImageUrl = [buttonData objectForKey:@"dynamic_image_url"];
        }

        NSDictionary *textDictionary = (NSDictionary *) [buttonData objectForKey:@"text"];
        if (textDictionary) {
            self.text = [textDictionary objectForKey:@"value"];
        }

        // Set up the action for the button.
        self.actionType = kSwrveActionDismiss;
        self.appID = 0;
        self.actionString = @"";

        NSString *buttonType = [(NSDictionary *) [buttonData objectForKey:@"type"] objectForKey:@"value"];
        if ([buttonType isEqualToString:@"INSTALL"]) {
            self.actionType = kSwrveActionInstall;
            self.appID = [[(NSDictionary *) [buttonData objectForKey:@"game_id"] objectForKey:@"value"] integerValue];
            self.actionString = [appStoreURLs objectForKey:[NSString stringWithFormat:@"%ld", self.appID]];
        } else if ([buttonType isEqualToString:@"CUSTOM"]) {
            self.actionType = kSwrveActionCustom;
            self.actionString = [(NSDictionary *) [buttonData objectForKey:@"action"] objectForKey:@"value"];
        } else if ([buttonType isEqualToString:@"COPY_TO_CLIPBOARD"]) {
            self.actionType = kSwrveActionClipboard;
            self.actionString = [(NSDictionary *) [buttonData objectForKey:@"action"] objectForKey:@"value"];
        } else if ([buttonType isEqualToString:@"REQUEST_CAPABILITY"]) {
            self.actionType = kSwrveActionCapability;
            self.actionString = [(NSDictionary *) [buttonData objectForKey:@"action"] objectForKey:@"value"];
        } else if ([buttonType isEqualToString:@"PAGE_LINK"]) {
            self.actionType = kSwrveActionPageLink;
            self.appID = [[(NSDictionary *) [buttonData objectForKey:@"game_id"] objectForKey:@"value"] integerValue];
            self.actionString = [(NSDictionary *) [buttonData objectForKey:@"action"] objectForKey:@"value"];
        } else {
            self.actionType = kSwrveActionDismiss;
            self.actionString = @"";
        }
        
        if ([buttonData objectForKey:@"accessibility_text"]) {
            self.accessibilityText = [buttonData objectForKey:@"accessibility_text"];
        }

    }
    return self;
}

- (UISwrveButton *)createButtonWithDelegate:(id)delegate
                                andSelector:(SEL)selector
                                   andScale:(float)scale
                                 andCenterX:(float)cx
                                 andCenterY:(float)cy
                      andPersonalizedAction:(NSString *)personalizedActionStr
                         andPersonalization:(NSString *)personalizedTextStr
                andPersonalizedUrlAssetSha1:(NSString *)personalizedUrlAssetSha1
                                 withConfig:(SwrveInAppMessageConfig *)inAppConfig
                                     qaInfo:(SwrveQAImagePersonalizationInfo *)qaInfo {

    NSString *cacheFolder = [SwrveLocalStorage swrveCacheFolder];
    NSURL *url_up = [NSURL fileURLWithPathComponents:[NSArray arrayWithObjects:cacheFolder, image, nil]];
    UIImage *up = [UIImage imageWithData:[NSData dataWithContentsOfURL:url_up]];

    if (personalizedTextStr != nil) {
        // store the current 'up' image so we can use it as a guide
        UIImage *guideImage = up;

        up = [SwrveTextImageView imageFromString:personalizedTextStr
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

    UISwrveButton *uiSwrveButton;
    if (up) {
        uiSwrveButton = [UISwrveButton buttonWithType:UIButtonTypeCustom];
#if TARGET_OS_TV
        uiSwrveButton.imageView.adjustsImageWhenAncestorFocused = YES;
#endif
        [uiSwrveButton setBackgroundImage:up forState:UIControlStateNormal];
    } else {
        uiSwrveButton = [UISwrveButton buttonWithType:UIButtonTypeRoundedRect];
    }

#if TARGET_OS_IOS /** TouchUpInside is iOS only **/
    [uiSwrveButton addTarget:delegate action:selector forControlEvents:UIControlEventTouchUpInside];
#elif TARGET_OS_TV
    // There are no touch actions in tvOS, so Primary Action Triggered is the event to run it
    [uiSwrveButton  addTarget:delegate action:selector forControlEvents:UIControlEventPrimaryActionTriggered];
#endif

    CGFloat width = DEFAULT_WIDTH;
    CGFloat height = DEFAULT_HEIGHT;
    if (up) {
        width = [up size].width;
        height = [up size].height;
    }

    CGPoint position = scaled(self.center, scale);
    [uiSwrveButton setFrame:CGRectMake(0, 0, width * scale, height * scale)];
    [uiSwrveButton setCenter:CGPointMake(position.x + cx, position.y + cy)];

    if (self.actionType == kSwrveActionClipboard || self.actionType == kSwrveActionCustom) {
        uiSwrveButton.actionString = personalizedActionStr;
    } else if (self.actionType == kSwrveActionPageLink) {
        uiSwrveButton.actionString = self.actionString; // set the pageId
    }

    if (personalizedTextStr) {
        // store the text that was displayed for testing
        uiSwrveButton.displayString = personalizedTextStr;
    }
    uiSwrveButton.buttonId = self.buttonId;
    uiSwrveButton.buttonName = self.name;

    return uiSwrveButton;
}

@end
