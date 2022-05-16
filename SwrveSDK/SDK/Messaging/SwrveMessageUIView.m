#import "SwrveMessageUIView.h"
#import "SwrveImage.h"
#import "SwrveMessagePage.h"
#import "SwrveTextViewStyle.h"
#import "SwrveTextView.h"
#import "SwrveButton.h"

#if __has_include(<SwrveSDKCommon/SwrveLocalStorage.h>)

#import <SwrveSDKCommon/SwrveLocalStorage.h>
#import <SwrveSDKCommon/SwrveUtils.h>
#import <SwrveSDKCommon/SwrveQA.h>
#import <SwrveSDKCommon/TextTemplating.h>
#import <SwrveSDKCommon/SwrveLogger.h>

#else
#import "SwrveLocalStorage.h"
#import "SwrveUtils.h"
#import "SwrveQA.h"
#import "SwrveQAImagePersonalizationInfo.h"
#import "TextTemplating.h"
#import "SwrveLogger.h"

#endif

@interface SwrveMessageUIView ()

@property(nonatomic, retain) SwrveMessageFormat *messageFormat;
@property(nonatomic, retain) UIViewController *controller;
@property(nonatomic, retain) NSDictionary *personalization;
@property(nonatomic, retain) SwrveInAppMessageConfig *inAppConfig;
@property(nonatomic) CGFloat centerX;
@property(nonatomic) CGFloat centerY;
@property(nonatomic) CGFloat renderScale;

@end

@implementation SwrveMessageUIView

@synthesize messageFormat;
@synthesize controller;
@synthesize personalization;
@synthesize inAppConfig;
@synthesize centerX;
@synthesize centerY;
@synthesize renderScale;

- (id)initWithMessageFormat:(SwrveMessageFormat *)format
                     pageId:(NSNumber *) pageId
                 parentSize:(CGSize)sizeParent
                 controller:(UIViewController *)delegate
            personalization:(NSDictionary *)personalizationDict
                inAppConfig:(SwrveInAppMessageConfig *)config {
    CGRect containerViewSize = CGRectMake(0, 0, sizeParent.width, sizeParent.height);
    if (self = [super initWithFrame:containerViewSize]) {

        self.messageFormat = format;
        self.controller = delegate;
        self.personalization = personalizationDict;
        self.inAppConfig = config;

        self.centerX = sizeParent.width / 2;
        self.centerY = sizeParent.height / 2;
        self.renderScale = [self renderScaleFor:format withParentSize:sizeParent];
        [self setCenter:CGPointMake(self.centerX, self.centerY)];
        [self setAlpha:1];

        // Add page images and buttons
        SwrveMessagePage *page = [format.pages objectForKey:pageId];
        [self addImages:page];
        [self addButtons:page];
    }
    return self;
}

- (CGFloat)renderScaleFor:(SwrveMessageFormat *)format withParentSize:(CGSize)sizeParent {
    // Calculate the scale needed to fit the format in the current viewport
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    [SwrveLogger debug:@"SwrveMessageUIView: MessageFormat scale :%g", format.scale];
    [SwrveLogger debug:@"SwrveMessageUIView: UI scale :%g", screenScale];
    float wscale = (float) ((sizeParent.width * screenScale) / format.size.width);
    float hscale = (float) ((sizeParent.height * screenScale) / format.size.height);
    float viewportScale = (wscale < hscale) ? wscale : hscale;
    return (format.scale / screenScale) * viewportScale; // Adjust scale, accounting for retina devices
}

- (void)addImages:(SwrveMessagePage *)page {
    for (SwrveImage *image in page.images) {
        if (image.multilineText) {
            [self addTextView:image];
        } else {
            [self addImageView:image];
        }
    }
}

- (void)addTextView:(SwrveImage *)image {

    SwrveTextViewStyle *style = [[SwrveTextViewStyle alloc] initWithDictionary:image.multilineText
                                                                   defaultFont:self.inAppConfig.personalizationFont
                                                        defaultForegroundColor:self.inAppConfig.personalizationForegroundColor
                                                        defaultBackgroundColor:self.inAppConfig.personalizationBackgroundColor];

    NSError *error;
    style.text = [TextTemplating templatedTextFromString:style.text withProperties:self.personalization andError:&error];
    if (error != nil) {
        [SwrveLogger error:@"SwrveMessageUIView:Error applying IAM text personalization: %@", error];
        return;
    }

    CGRect frame = CGRectMake(0, 0, image.size.width * self.renderScale, image.size.height * self.renderScale);
    self.messageFormat.calibration.renderScale = self.renderScale; // TODO pass the renderScale into wherever its needed instead of setting here.
    SwrveTextView *textView = [[SwrveTextView alloc] initWithStyle:style calbration:self.messageFormat.calibration frame:frame];
    textView.isAccessibilityElement = true;
    CGPoint centerPoint = CGPointMake(self.centerX + (image.center.x * self.renderScale), self.centerY + (image.center.y * self.renderScale)); // TODO repeated code??
    [textView setCenter:centerPoint];
    [self addSubview:textView];
}

- (void)addImageView:(SwrveImage *)image {
    NSString *cacheFolder = [SwrveLocalStorage swrveCacheFolder];
    NSString *personalizedTextStr = nil;
    NSString *personalizedUrlAssetSha1 = nil;
    SwrveQAImagePersonalizationInfo *imagePersonalizationQAInfo = nil;

    if (image.text) {
        NSError *error;
        personalizedTextStr = [TextTemplating templatedTextFromString:image.text withProperties:self.personalization andError:&error];
        if (error != nil) {
            [SwrveLogger error:@"%@", error];
        }
    } else if (image.dynamicImageUrl) {
        imagePersonalizationQAInfo = [[SwrveQAImagePersonalizationInfo alloc] initWithCampaign:(NSUInteger) image.campaignId
                                                                                     variantID:(NSUInteger) image.messageId
                                                                                   hasFallback:(image.file != nil)
                                                                                 unresolvedUrl:image.dynamicImageUrl];
        personalizedUrlAssetSha1 = [self resolvePersonalizedImageAsset:image.dynamicImageUrl andQAInfo:imagePersonalizationQAInfo];
    }

    UIImage *background = [image createImage:cacheFolder
                             personalization:personalizedTextStr
                    personalizedUrlAssetSha1:personalizedUrlAssetSha1
                                 inAppConfig:self.inAppConfig
                                      qaInfo:imagePersonalizationQAInfo];
    CGRect frame = CGRectMake(0, 0, background.size.width * self.renderScale, background.size.height * self.renderScale);
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
    imageView.image = background;
    
    [self addAccessibilityText:image.accessibilityText backupText:personalizedTextStr withPersonalization:self.personalization toView:imageView];

    //shows focus on tvOS
#if TARGET_OS_TV
    imageView.adjustsImageWhenAncestorFocused = YES;
#endif

    [imageView setCenter:CGPointMake(self.centerX + (image.center.x * self.renderScale), self.centerY + (image.center.y * self.renderScale))];
    [self addSubview:imageView];
}

- (void)addButtons:(SwrveMessagePage *)page {
    SEL buttonPressedSelector = NSSelectorFromString(@"onButtonPressed:");
    int buttonTag = 0;
    for (SwrveButton *button in page.buttons) {

        NSString *personalizedTextStr = nil;
        NSString *personalizedActionStr = nil;
        NSString *personalizedUrlAssetSha1 = nil;
        SwrveQAImagePersonalizationInfo *imagePersonalizationQAInfo = nil;

        if (button.text) {
            NSError *error;
            personalizedTextStr = [TextTemplating templatedTextFromString:button.text withProperties:self.personalization andError:&error];
            if (error != nil) {
                [SwrveLogger error:@"%@", error];
            }
        }

        if (button.dynamicImageUrl) {
            // set up QA Info in case it doesn't work
            imagePersonalizationQAInfo = [[SwrveQAImagePersonalizationInfo alloc] initWithCampaign:(NSUInteger) button.campaignId
                                                                                         variantID:(NSUInteger) button.messageId
                                                                                       hasFallback:(button.image != nil)
                                                                                     unresolvedUrl:button.dynamicImageUrl];

            personalizedUrlAssetSha1 = [self resolvePersonalizedImageAsset:button.dynamicImageUrl andQAInfo:imagePersonalizationQAInfo];
        }

        if (button.actionType == kSwrveActionClipboard || button.actionType == kSwrveActionCustom) {
            NSError *error;
            personalizedActionStr = [TextTemplating templatedTextFromString:button.actionString withProperties:self.personalization andError:&error];
            if (error != nil) {
                [SwrveLogger error:@"%@", error];
            }
        }

        UISwrveButton *buttonView = [button createButtonWithDelegate:self.controller
                                                         andSelector:buttonPressedSelector
                                                            andScale:(float) self.renderScale
                                                          andCenterX:(float) self.centerX
                                                          andCenterY:(float) self.centerY
                                               andPersonalizedAction:personalizedActionStr
                                                  andPersonalization:personalizedTextStr
                                         andPersonalizedUrlAssetSha1:personalizedUrlAssetSha1
                                                          withConfig:self.inAppConfig
                                                              qaInfo:imagePersonalizationQAInfo];

        [self addAccessibilityText: button.accessibilityText backupText:personalizedTextStr withPersonalization:self.personalization toView:buttonView];

        //Used by sdk systemtests
        buttonView.accessibilityIdentifier = button.name;
        buttonView.tag = buttonTag;
        [self addSubview:buttonView];
        buttonTag++;
    }
}

- (NSString *)resolvePersonalizedImageAsset:(NSString *)assetUrl andQAInfo:(SwrveQAImagePersonalizationInfo *)qaInfo {
    if (assetUrl != nil) {
        NSError *error;
        NSString *resolvedUrl = [TextTemplating templatedTextFromString:assetUrl withProperties:self.personalization andError:&error];
        if (error != nil || resolvedUrl == nil) {
            [SwrveLogger debug:@"Could not resolve personalization: %@", assetUrl];
            [qaInfo setReason:@"Could not resolve url personalization"];
            [SwrveQA assetFailedToDisplay:qaInfo];
        } else {
            NSData *data = [resolvedUrl dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
            NSString *canditateAsset = [SwrveUtils sha1:data];
            // set QAInfo in case there is a cache failure later
            [qaInfo setResolvedUrl:resolvedUrl];
            [qaInfo setAssetName:canditateAsset];
            return canditateAsset;
        }
    }
    return nil;
}

-(void)addAccessibilityText:(NSString *)accessibilityText backupText:(NSString *)backupText withPersonalization:(NSDictionary *)personalizationDict toView:(UIView *)view {
    // for images dont make them accessible, unless alt text is provided below.
    view.isAccessibilityElement = [view isKindOfClass:[UIImageView class]] ? false : true;
    if (accessibilityText != nil && ![accessibilityText isEqualToString:@""]) {
        NSError *error;
        NSString *personalizedAccessibilityText = [TextTemplating templatedTextFromString:accessibilityText withProperties:personalizationDict andError:&error];
        if (error == nil) {
            view.isAccessibilityElement = true;
            view.accessibilityLabel = personalizedAccessibilityText;
        } else {
            [SwrveLogger error:@"Adding accessibility text error: %@", error];
        }
    } else {
        if (backupText != nil && ![backupText  isEqualToString:@""]) {
            view.isAccessibilityElement = true;
            view.accessibilityLabel = backupText;
        } else {
            [SwrveLogger error:@"No text available for accesibility"];
        }
    }
    
    // disable traits as we dont want additional information read out from VO image / speech recognition
    // instead just assign simple hints as the role type: image or button
   view.accessibilityTraits = UIAccessibilityTraitNone;
    if ([view isKindOfClass:[UISwrveButton class]]) {
        view.accessibilityHint = @"Button";
    } else if ([view isKindOfClass:[UIImageView class]]) {
        view.accessibilityHint = @"Image";
    }
}
@end
