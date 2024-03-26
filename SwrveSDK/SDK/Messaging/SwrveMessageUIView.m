#import "SwrveMessageUIView.h"
#import "SwrveImage.h"
#import "SwrveMessagePage.h"
#import "SwrveTextViewStyle.h"
#import "SwrveUITextView.h"
#import "SwrveButton.h"
#import "SwrveTextImageView.h"
#import "SwrveThemedUIButton.h"
#import "SwrveSDKUtils.h"
#import "SwrveMessageViewController.h"

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

#if __has_include(<SDWebImage/SDAnimatedImageView.h>)
#import <SDWebImage/SDAnimatedImageView.h>
#import <SDWebImage/UIButton+WebCache.h>
#else
#import "SDAnimatedImageView.h"
#import "UIButton+WebCache.h"
#endif

#define SWRVEMIN(a, b)    ((a) < (b) ? (a) : (b))
#define DEFAULT_WIDTH 100
#define DEFAULT_HEIGHT 20
#define SWRVEMIN(a, b)    ((a) < (b) ? (a) : (b))

@interface SwrveMessageImageInfo : NSObject
@property(atomic, retain) UIImage *image;
@property(atomic, retain) NSURL *fileImageURL;
@property(atomic) BOOL isGif;
@property(atomic) BOOL isFallback;
@end

@implementation SwrveMessageImageInfo
@synthesize image;
@synthesize fileImageURL;
@synthesize isGif;
@synthesize isFallback;
@end

@interface SwrveMessageUIView ()

@property(nonatomic) SwrveMessageFormat *messageFormat;
@property(nonatomic) NSNumber *pageId;
@property(nonatomic, weak) UIViewController *controller;
@property(nonatomic) NSDictionary *personalization;
@property(nonatomic) SwrveInAppMessageConfig *inAppConfig;
@property(nonatomic) CGFloat centerX;
@property(nonatomic) CGFloat centerY;
@property(nonatomic) CGFloat renderScale;
@end

@implementation SwrveMessageUIView

@synthesize messageFormat;
@synthesize pageId;
@synthesize controller;
@synthesize personalization;
@synthesize inAppConfig;
@synthesize centerX;
@synthesize centerY;
@synthesize renderScale;

static CGPoint scaled(CGPoint point, float scale) {
    return CGPointMake(point.x * scale, point.y * scale);
}

- (id)initWithMessageFormat:(SwrveMessageFormat *)format
                     pageId:(NSNumber *)pageIdToShow
                 parentSize:(CGSize)sizeParent
                 controller:(UIViewController *)delegate
            personalization:(NSDictionary *)personalizationDict
                inAppConfig:(SwrveInAppMessageConfig *)config {
    CGRect containerViewSize = CGRectMake(0, 0, sizeParent.width, sizeParent.height);
    if (self = [super initWithFrame:containerViewSize]) {

        self.messageFormat = format;
        self.pageId = pageIdToShow;
        self.controller = delegate;
        self.personalization = personalizationDict;
        self.inAppConfig = config;

        self.centerX = sizeParent.width / 2;
        self.centerY = sizeParent.height / 2;
        self.renderScale = [SwrveSDKUtils renderScaleFor:format withParentSize:sizeParent];
        [self setCenter:CGPointMake(self.centerX, self.centerY)];
        [self setAlpha:1];

        NSArray *pageElements = [self pageElements];
        int buttonTag = 0;
        for (id obj in pageElements) {
            if ([obj isKindOfClass:[SwrveButton class]]) {
                [self addButton:(SwrveButton *) obj buttonTag:buttonTag];
                buttonTag++;
            } else if ([obj isKindOfClass:[SwrveImage class]]) {
                [self addImage:(SwrveImage *) obj];
            }
        }
    }
    return self;
}

- (NSArray *)pageElements {
    // Combine page elements together (images and buttons)
    // Images must be added before buttons to preserve the order of the elements for backwards compatibility
    // If iam_z_index is set then it will be sorted by the iam_z_index
    SwrveMessagePage *page = [self.messageFormat.pages objectForKey:self.pageId];
    NSArray *pageElements = [page.images arrayByAddingObjectsFromArray:page.buttons];
    pageElements = [pageElements sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSInteger order1 = [obj1 iamZIndex];
        NSInteger order2 = [obj2 iamZIndex];
        if (order1 < order2) {
            return NSOrderedAscending;
        } else if (order1 > order2) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
    return pageElements;
}

- (void)addImage:(SwrveImage *)image {
    if (image.multilineText) {
        [self addTextView:image];
    } else {
        [self addImageView:image];
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

    CGRect frame = [self frameWithDynamicScale:1.0f width:image.size.width height:image.size.height];
    SwrveUITextView *textView = [[SwrveUITextView alloc] initWithStyle:style
                                                            calbration:self.messageFormat.calibration
                                                                 frame:frame
                                                           renderScale:self.renderScale];
    textView.isAccessibilityElement = true;
    [self setPosition:textView center:image.center];
    [self addSubview:textView];
}

- (void)addImageView:(SwrveImage *)swrveImage {
    NSString *textStr = nil;
    NSString *urlAssetSha1 = nil;
    if (swrveImage.text) {
        NSError *error;
        textStr = [TextTemplating templatedTextFromString:swrveImage.text withProperties:self.personalization andError:&error];
        if (error != nil) {
            [SwrveLogger error:@"%@", error];
        }
    } else if (swrveImage.dynamicImageUrl) {
        SwrveQAImagePersonalizationInfo *imagePersonalizationQAInfo = [[SwrveQAImagePersonalizationInfo alloc]
                initWithCampaign:(NSUInteger) swrveImage.campaignId
                       variantID:(NSUInteger) swrveImage.messageId
                     hasFallback:(swrveImage.file != nil)
                   unresolvedUrl:swrveImage.dynamicImageUrl];
        urlAssetSha1 = [self resolveUrlImageAssetToSha1:swrveImage.dynamicImageUrl andQAInfo:imagePersonalizationQAInfo];
    }

    UIImage *background = nil;
    SwrveMessageImageInfo *imageInfo = nil;
    CGFloat dynamicScale = 1.0;
    if (textStr != nil) {
        background = [self createTextUIImage:swrveImage.file text:textStr];
    } else if (urlAssetSha1 != nil) {
        imageInfo = [self createDynamicUrlUIImage:urlAssetSha1 fallback:swrveImage.file];
        background = imageInfo.image;
        dynamicScale = [self scaleForDynamicImage:background width:swrveImage.size.width height:swrveImage.size.height];
    } else {
        imageInfo = [self createUIImage:swrveImage.file];
        background = imageInfo.image;
    }

    CGRect frame = [self frameWithDynamicScale:dynamicScale width:background.size.width height:background.size.height];
    UIImageView *imageView = nil;
    if(imageInfo && imageInfo.isGif) {
        imageView = [[SDAnimatedImageView alloc] initWithFrame:frame];
    } else {
        imageView = [[UIImageView alloc] initWithFrame:frame];
    }
    imageView.image = background;
    [self setPosition:imageView center:swrveImage.center];

    [self addAccessibilityText:swrveImage.accessibilityText backupText:textStr withPersonalization:self.personalization toView:imageView];

    imageView.userInteractionEnabled = YES; // this is required to not allow touches to be passed through to the view beneath it

    [self addSubview:imageView];
}

- (UIImage *)createTextUIImage:(NSString *)guideAssetName text:(NSString *)textStr {
    NSString *cacheFolder = [SwrveLocalStorage swrveCacheFolder];
    NSURL *guideImageUrl = [NSURL fileURLWithPathComponents:[NSArray arrayWithObjects:cacheFolder, guideAssetName, nil]];
    UIImage *guideImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:guideImageUrl]];
    UIImage *image = [SwrveTextImageView imageFromString:textStr
                                     withBackgroundColor:self.inAppConfig.personalizationBackgroundColor
                                     withForegroundColor:self.inAppConfig.personalizationForegroundColor
                                                withFont:self.inAppConfig.personalizationFont
                                                    size:guideImage.size];
    return image;
}

- (SwrveMessageImageInfo *)createDynamicUrlUIImage:(NSString *)assetSha1 fallback:(NSString *)fallback {
    SwrveMessageImageInfo *imageInfo = [self createUIImage:assetSha1];
    if (imageInfo.image == nil) {
        imageInfo = [self createUIImage:fallback]; // use fallback
        imageInfo.isFallback = YES;
    }
    return imageInfo;
}

- (SwrveMessageImageInfo *)createUIImage:(NSString *)assetName {
    SwrveMessageImageInfo *imageInfo = [SwrveMessageImageInfo new];
    NSURL *fileImageURL = [self fileImageURL:assetName];
    NSData *fileImageData = [NSData dataWithContentsOfURL:fileImageURL];
    if ([[fileImageURL path] hasSuffix:@".gif"]) {
        imageInfo.image = [SDAnimatedImage imageWithData:fileImageData]; // create SDAnimatedImage for gif's
        imageInfo.isGif = YES;
    } else {
        imageInfo.image = [UIImage imageWithData:fileImageData];
        imageInfo.isGif = NO;
    }
    imageInfo.fileImageURL = fileImageURL;
    return imageInfo;
}

- (NSURL *)fileImageURL:(NSString *)assetName {
    NSString *cacheFolder = [SwrveLocalStorage swrveCacheFolder];
    NSString *assetNameGif = [assetName stringByAppendingString:@".gif"];
    NSString *target = [cacheFolder stringByAppendingPathComponent:assetNameGif];
    if (![[NSFileManager defaultManager] fileExistsAtPath:target]) {
        // the file type is not gif so use just the assetName without any extension
        target = [cacheFolder stringByAppendingPathComponent:assetName];
    }
    return [NSURL fileURLWithPath:target];
}

- (CGFloat)scaleForDynamicImage:(UIImage *)image width:(CGFloat)width height:(CGFloat)height {
    CGFloat scale = 1.0;
    if (image != nil) {
        CGFloat widthRatio = width / image.size.width;
        CGFloat heightRatio = height / image.size.height;
        scale = SWRVEMIN(widthRatio, heightRatio);
    }
    return scale;
}

- (void)addButton:(SwrveButton *)swrveButton buttonTag:(int)buttonTag {
    NSString *textStr = nil;
    NSString *actionStr = nil;
    NSString *urlAssetSha1 = nil;
    if (swrveButton.text) {
        NSError *error;
        textStr = [TextTemplating templatedTextFromString:swrveButton.text withProperties:self.personalization andError:&error];
        if (error != nil) {
            [SwrveLogger error:@"%@", error];
        }
    }

    if (swrveButton.dynamicImageUrl) {
        // set up QA Info in case it doesn't work
        SwrveQAImagePersonalizationInfo *imagePersonalizationQAInfo = [[SwrveQAImagePersonalizationInfo alloc] initWithCampaign:(NSUInteger) swrveButton.campaignId
                                                                                     variantID:(NSUInteger) swrveButton.messageId
                                                                                   hasFallback:(swrveButton.image != nil)
                                                                                 unresolvedUrl:swrveButton.dynamicImageUrl];
        urlAssetSha1 = [self resolveUrlImageAssetToSha1:swrveButton.dynamicImageUrl andQAInfo:imagePersonalizationQAInfo];
    }

    if (swrveButton.actionType == kSwrveActionClipboard || swrveButton.actionType == kSwrveActionCustom) {
        NSError *error;
        actionStr = [TextTemplating templatedTextFromString:swrveButton.actionString withProperties:self.personalization andError:&error];
        if (error != nil) {
            [SwrveLogger error:@"%@", error];
        }
    }

    SwrveUIButton *buttonView = nil;
    if (swrveButton.theme) {
        CGRect frame = [self frameWithDynamicScale:1.0 width:swrveButton.size.width height:swrveButton.size.height];
        buttonView = [[SwrveThemedUIButton alloc] initWithTheme:swrveButton.theme
                                                           text:textStr
                                                          frame:frame
                                                    calabration:self.messageFormat.calibration
                                                    renderScale:self.renderScale];

        // set position
        [self setPosition:buttonView center:swrveButton.center];
    } else {
        buttonView = [self createSwrveUIButtonWithButton:swrveButton andText:textStr andUrlAssetSha1:urlAssetSha1];
    }

    if (textStr) {
        buttonView.displayString = textStr; // store the text that was displayed for testing
    }
    buttonView.buttonId = swrveButton.buttonId;
    buttonView.buttonName = swrveButton.name;

    [self addButtonTarget:buttonView];
    [self addButtonAction:buttonView button:swrveButton action:actionStr];
    [self addAccessibilityText:swrveButton.accessibilityText backupText:textStr withPersonalization:self.personalization toView:buttonView];

    buttonView.accessibilityIdentifier = swrveButton.name;
    buttonView.tag = buttonTag;
    [self addSubview:buttonView];
}

- (CGRect)frameWithDynamicScale:(CGFloat)dynamicScale width:(CGFloat)width height:(CGFloat)height {
    return CGRectMake(0, 0, width * self.renderScale * dynamicScale, height * self.renderScale * dynamicScale);
}

- (void)setPosition:(UIView *)view center:(CGPoint)center {
    CGPoint position = scaled(center, (float) self.renderScale);
    [view setCenter:CGPointMake(position.x + (float) self.centerX, position.y + (float) self.centerY)];
}

- (void)addButtonTarget:(SwrveUIButton *)buttonView {
    SEL buttonPressedSelector = NSSelectorFromString(@"onButtonPressed:");
#if TARGET_OS_IOS /** TouchUpInside is iOS only **/
    [buttonView addTarget:self action:buttonPressedSelector forControlEvents:UIControlEventTouchUpInside];
#elif TARGET_OS_TV
    // There are no touch actions in tvOS, so Primary Action Triggered is the event to run it
    [buttonView  addTarget:self action:buttonPressedSelector forControlEvents:UIControlEventPrimaryActionTriggered];
#endif
}

- (IBAction)onButtonPressed:(id)buttonView {
    if ([self.controller isKindOfClass:[SwrveMessageViewController class]]) {
        SwrveUIButton *button = buttonView;
        SwrveMessageViewController *messageViewController = (SwrveMessageViewController *) self.controller;
        [messageViewController onButtonPressed:button pageId:self.pageId];
    }
    self.controller = nil;
}

- (void)addButtonAction:(SwrveUIButton *)buttonView button:(SwrveButton *)swrveButton action:(NSString *)actionStr {
    if (swrveButton.actionType == kSwrveActionClipboard || swrveButton.actionType == kSwrveActionCustom) {
        buttonView.actionString = actionStr;
    } else if (swrveButton.actionType == kSwrveActionPageLink) {
        buttonView.actionString = swrveButton.actionString; // set the pageId
    }
}

- (SwrveUIButton *)createSwrveUIButtonWithButton:(SwrveButton *)swrveButton
                                         andText:(NSString *)textStr
                                 andUrlAssetSha1:(NSString *)urlAssetSha1 {
    UIImage *up = nil;
    CGFloat dynamicScale = 1.0;
    SwrveMessageImageInfo *imageInfo = nil;
    if (textStr != nil) {
        up = [self createTextUIImage:swrveButton.image text:textStr];
    } else if (urlAssetSha1 != nil) {
        imageInfo = [self createDynamicUrlUIImage:urlAssetSha1 fallback:swrveButton.image];
        up = imageInfo.image;
        dynamicScale = [self scaleForDynamicImage:up width:swrveButton.size.width height:swrveButton.size.height];
    } else {
        imageInfo = [self createUIImage:swrveButton.image];
        up = imageInfo.image;
    }

    SwrveUIButton *swrveUIButton;
    if (up) {
        swrveUIButton = [SwrveUIButton buttonWithType:UIButtonTypeCustom];
#if TARGET_OS_TV
        swrveUIButton.imageView.adjustsImageWhenAncestorFocused = YES;
#endif
        if (imageInfo.isGif) {
            [swrveUIButton sd_setBackgroundImageWithURL:imageInfo.fileImageURL forState:UIControlStateNormal];
        } else {
            [swrveUIButton setBackgroundImage:up forState:UIControlStateNormal];
        }
    } else {
        swrveUIButton = [SwrveUIButton buttonWithType:UIButtonTypeRoundedRect];
    }

    // set size and position
    CGFloat width = DEFAULT_WIDTH;
    CGFloat height = DEFAULT_HEIGHT;
    if (up) {
        width = [up size].width;
        height = [up size].height;
    }
    CGRect frame = [self frameWithDynamicScale:dynamicScale width:width height:height];
    [swrveUIButton setFrame:frame];
    [self setPosition:swrveUIButton center:swrveButton.center];

    return swrveUIButton;
}

- (NSString *)resolveUrlImageAssetToSha1:(NSString *)assetUrl andQAInfo:(SwrveQAImagePersonalizationInfo *)qaInfo {
    NSString *urlAssetSha1 = nil;
    if (assetUrl == nil) {
        return urlAssetSha1;
    }

    NSError *error;
    NSString *resolvedUrl = [TextTemplating templatedTextFromString:assetUrl withProperties:self.personalization andError:&error];
    if (error != nil || resolvedUrl == nil) {
        [SwrveLogger debug:@"Could not resolve url with personalization: %@", assetUrl];
        [qaInfo setReason:@"Could not resolve url personalization"];
        [SwrveQA assetFailedToDisplay:qaInfo];
    } else {
        NSData *data = [resolvedUrl dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
        urlAssetSha1 = [SwrveUtils sha1:data];
        // set QAInfo in case there is a cache failure later
        [qaInfo setResolvedUrl:resolvedUrl];
        [qaInfo setAssetName:urlAssetSha1];
    }

    return urlAssetSha1;
}

-(void)addAccessibilityText:(NSString *)accessibilityText backupText:(NSString *)backupText withPersonalization:(NSDictionary *)personalizationDict toView:(UIView *)view {
    view.isAccessibilityElement = true;
    if (accessibilityText != nil && ![accessibilityText isEqualToString:@""]) {
        NSError *error;
        NSString *personalizedAccessibilityText = [TextTemplating templatedTextFromString:accessibilityText withProperties:personalizationDict andError:&error];
        if (error == nil) {
            view.accessibilityLabel = personalizedAccessibilityText;
        } else {
            [SwrveLogger error:@"Adding accessibility text error: %@", error];
        }
    } else {
        if (backupText != nil && ![backupText isEqualToString:@""]) {
            view.accessibilityLabel = backupText;
        }
    }

    // disable traits as we dont want additional information read out from VO image / speech recognition
    // instead just assign simple hints as the role type: image or button
    view.accessibilityTraits = UIAccessibilityTraitNone;
    if (view.accessibilityLabel != nil && ![view.accessibilityLabel isEqualToString:@""]) {
        if ([view isKindOfClass:[SwrveUIButton class]]) {
            view.accessibilityHint = @"Button";
        } else if ([view isKindOfClass:[UIImageView class]]) {
            view.accessibilityHint = @"Image";
        }
    }
}
@end
