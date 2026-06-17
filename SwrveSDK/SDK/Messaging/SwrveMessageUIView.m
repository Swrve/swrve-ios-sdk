#import "SwrveMessageUIView.h"
#import "SwrveMessagePage.h"
#import "SwrveTextViewStyle.h"
#import "SwrveUITextView.h"
#import "SwrveButtonActions.h"
#import "SwrveTextImageView.h"
#import "SwrveSDKUtils.h"
#import "SwrveMessageViewController.h"
#import "SwrveMessagePageViewController.h"

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

#if __has_include(<SwrveSDK/SwrveSDK-Swift.h>)
#import <SwrveSDK/SwrveSDK-Swift.h>
#elif __has_include("SwrveSDK-Swift.h")
#import "SwrveSDK-Swift.h"
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

@interface SwrveMessageUIView () <SwrveVideoPlayerViewDelegate>

@property(nonatomic) SwrveMessageFormat *messageFormat;
@property(nonatomic) NSNumber *pageId;
@property(nonatomic) NSNumber *mediaId;
@property(nonatomic, weak) UIViewController *controller;
@property(nonatomic) NSDictionary *personalization;
@property(nonatomic) SwrveInAppMessageConfig *inAppConfig;
@property(nonatomic) CGFloat centerX;
@property(nonatomic) CGFloat centerY;
@property(nonatomic) CGFloat renderScale;
@property(nonatomic) SwrveVideoPlayerView *videoPlayerView;
@property(nonatomic) BOOL freemarkerEnabled;
@property(nonatomic) BOOL useLocalTimezone;
@end

@implementation SwrveMessageUIView

@synthesize messageFormat;
@synthesize pageId;
@synthesize mediaId;
@synthesize controller;
@synthesize personalization;
@synthesize inAppConfig;
@synthesize centerX;
@synthesize centerY;
@synthesize renderScale;
@synthesize videoPlayerView;
@synthesize freemarkerEnabled;
@synthesize useLocalTimezone;
@synthesize renderError;

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
        if ([delegate isKindOfClass:[SwrveMessageViewController class]]) {
            self.freemarkerEnabled = ((SwrveMessageViewController *)delegate).message.campaign.freemarkerEnabled;
            self.useLocalTimezone = ((SwrveMessageViewController *)delegate).message.campaign.useLocalTimezone;
        }

        self.centerX = sizeParent.width / 2;
        self.centerY = sizeParent.height / 2;
        self.renderScale = [SwrveSDKUtils renderScaleFor:format withParentSize:sizeParent];
        [self setCenter:CGPointMake(self.centerX, self.centerY)];
        [self setAlpha:1];
        [self setClipsToBounds:YES];

        NSArray *pageElements = [self pageElements];
        int buttonTag = 0;
        for (id obj in pageElements) {
            if (![self shouldRenderElement:obj]) {
                if (self.renderError) {
                    break;
                }
                continue;
            }
            if ([obj isKindOfClass:[SwrveButton class]]) {
                [self addButton:(SwrveButton *) obj buttonTag:buttonTag];
                buttonTag++;
            } else if ([obj isKindOfClass:[SwrveImage class]]) {
                if ([obj videoSettings] != nil) {
                    [self addVideoView:(SwrveImage *) obj];
                } else {
                    [self addImage:(SwrveImage *) obj];
                }
            }
        }
    }
    return self;
}


- (BOOL)shouldRenderElement:(id)element {
    NSString *visibleIf = @"";
    if ([element isKindOfClass:[SwrveButton class]]) {
        visibleIf = ((SwrveButton *)element).visibleIf;
    } else if ([element isKindOfClass:[SwrveImage class]]) {
        visibleIf = ((SwrveImage *)element).visibleIf;
    }
    if (visibleIf.length == 0) {
        return YES;
    }
    NSString *template = [NSString stringWithFormat:@"<#if %@>true<#else>false</#if>", visibleIf];
    NSError *error = nil;
    NSString *result = [SwrveFreemarkerEvaluator evaluate:template properties:(NSDictionary<NSString*, NSString*>*)self.personalization useLocalTimezone:self.useLocalTimezone error:&error];
    if (error != nil || result == nil) {
        NSString *errorDetail = error != nil ? error.localizedDescription : @"evaluator returned nil result";
        [SwrveLogger error:@"visible_if evaluation failed for condition '%@': %@", visibleIf, errorDetail];
        self.renderError = YES;
        return NO;
    }
    return [result isEqualToString:@"true"];
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

- (void)addVideoView:(SwrveImage *)swrveVideo {
    SwrveMessagePageViewController *currentPageController = [self currentPageController];
    if (currentPageController) {
        SwrveQAImagePersonalizationInfo *imagePersonalizationQAInfo = [[SwrveQAImagePersonalizationInfo alloc]
                initWithCampaign:(NSUInteger) swrveVideo.campaignId
                       variantID:(NSUInteger) swrveVideo.messageId
                     hasFallback:(swrveVideo.file != nil)
                   unresolvedUrl:swrveVideo.dynamicImageUrl];
        
        self.mediaId = swrveVideo.mediaId;
        
        NSString *urlSha = [self resolveUrlImageAssetToSha1:swrveVideo.dynamicImageUrl andQAInfo:imagePersonalizationQAInfo];
        NSURL *videoURL = [self fileURL:urlSha];
        if (videoURL) {
            
            CGRect frame = [self frameWithDynamicScale:1.0f width:swrveVideo.size.width height:swrveVideo.size.height];
              
            self.videoPlayerView = [[SwrveVideoPlayerView alloc]initWithFrame:frame videoSettings: swrveVideo.videoSettings videoURL:videoURL controller:currentPageController delegate:self];
            [self setPosition:self.videoPlayerView center:swrveVideo.center];
 
            [self addAccessibilityText:swrveVideo.accessibilityText backupText:nil withPersonalization:self.personalization toView:self.videoPlayerView];
                    
            [self addSubview:self.videoPlayerView];
        }
    }
}

- (void)addTextView:(SwrveImage *)image {

    SwrveTextViewStyle *style = [[SwrveTextViewStyle alloc] initWithDictionary:image.multilineText
                                                                   defaultFont:self.inAppConfig.personalizationFont
                                                        defaultForegroundColor:self.inAppConfig.personalizationForegroundColor
                                                        defaultBackgroundColor:self.inAppConfig.personalizationBackgroundColor];

    NSError *error = nil;
    if (self.freemarkerEnabled) {
        style.text = [SwrveFreemarkerEvaluator evaluate:style.text properties:(NSDictionary<NSString*, NSString*>*)self.personalization useLocalTimezone:self.useLocalTimezone error:&error];
    } else {
        style.text = [TextTemplating templatedTextFromString:style.text withProperties:self.personalization andError:&error];
    }
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
        NSError *error = nil;
        if (self.freemarkerEnabled) {
            textStr = [SwrveFreemarkerEvaluator evaluate:swrveImage.text properties:(NSDictionary<NSString*, NSString*>*)self.personalization useLocalTimezone:self.useLocalTimezone error:&error];
        } else {
            textStr = [TextTemplating templatedTextFromString:swrveImage.text withProperties:self.personalization andError:&error];
        }
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
        NSError *error = nil;
        if (self.freemarkerEnabled) {
            textStr = [SwrveFreemarkerEvaluator evaluate:swrveButton.text properties:(NSDictionary<NSString*, NSString*>*)self.personalization useLocalTimezone:self.useLocalTimezone error:&error];
        } else {
            textStr = [TextTemplating templatedTextFromString:swrveButton.text withProperties:self.personalization andError:&error];
        }
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
        NSError *error = nil;
        if (self.freemarkerEnabled) {
            actionStr = [SwrveFreemarkerEvaluator evaluate:swrveButton.actionString properties:(NSDictionary<NSString*, NSString*>*)self.personalization useLocalTimezone:self.useLocalTimezone error:&error];
        } else {
            actionStr = [TextTemplating templatedTextFromString:swrveButton.actionString withProperties:self.personalization andError:&error];
        }
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
                                                    calibration:self.messageFormat.calibration
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
            if ([imageInfo.image isKindOfClass:[SDAnimatedImage class]]) {
                SDAnimatedImage *anim = (SDAnimatedImage *)imageInfo.image;
                //Use SDAnimatedImageView to set animated gif for button, better performance for large gifs
                //SDWebImage logic is kept in Objective-C to avoid exposing its types in the Swift interface, which breaks SPM binary XCFramework loading.
                SDAnimatedImageView *imageView = [[SDAnimatedImageView alloc] initWithFrame:swrveUIButton.bounds];
                imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                imageView.image = anim;

                [swrveUIButton addSubview:imageView];
                
            } else {
                // Fallback: image is not an SDAnimatedImage, set as static background
                [swrveUIButton setBackgroundImage:up forState:UIControlStateNormal];
            }
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

    NSError *error = nil;
    NSString *resolvedUrl = nil;
    if (self.freemarkerEnabled) {
        resolvedUrl = [SwrveFreemarkerEvaluator evaluate:assetUrl properties:(NSDictionary<NSString*, NSString*>*)self.personalization useLocalTimezone:self.useLocalTimezone error:&error];
    } else {
        resolvedUrl = [TextTemplating templatedTextFromString:assetUrl withProperties:self.personalization andError:&error];
    }
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
        NSError *error = nil;
        NSString *personalizedAccessibilityText = nil;
        if (self.freemarkerEnabled) {
            personalizedAccessibilityText = [SwrveFreemarkerEvaluator evaluate:accessibilityText properties:(NSDictionary<NSString*, NSString*>*)personalizationDict useLocalTimezone:self.useLocalTimezone error:&error];
        } else {
            personalizedAccessibilityText = [TextTemplating templatedTextFromString:accessibilityText withProperties:personalizationDict andError:&error];
        }
        if (error != nil) {
            personalizedAccessibilityText = nil;
            [SwrveLogger error:@"Adding accessibility text error: %@", error];
        }
        if (personalizedAccessibilityText != nil) {
            view.accessibilityLabel = personalizedAccessibilityText;
        }
    } else {
        if (backupText != nil && ![backupText isEqualToString:@""]) {
            view.accessibilityLabel = backupText;
        }
    }

    // disable traits as we dont want additional information read out from VO image / speech recognition
    // instead just assign simple hints as the role type: image / button or video
    view.accessibilityTraits = UIAccessibilityTraitNone;
    if (view.accessibilityLabel != nil && ![view.accessibilityLabel isEqualToString:@""]) {
        if ([view isKindOfClass:[SwrveUIButton class]]) {
            view.accessibilityHint = @"Button";
        } else if ([view isKindOfClass:[UIImageView class]]) {
            view.accessibilityHint = @"Image";
        }  else if ([view isKindOfClass:[SwrveVideoPlayerView class]]) {
            view.accessibilityHint = @"Video";
        }
    }
}

- (NSURL *)fileURL:(NSString *)assetName {
    NSString *cacheFolder = [SwrveLocalStorage swrveCacheFolder];
    
    NSArray<NSString *> *supportedExtensions = @[@"gif", @"mp4", @"mov"];
    
    for (NSString *extension in supportedExtensions) {
        NSString *filenameWithExt = [assetName stringByAppendingPathExtension:extension];
        NSString *fullPath = [cacheFolder stringByAppendingPathComponent:filenameWithExt];
        if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
            return [NSURL fileURLWithPath:fullPath];
        }
    }
    
    // Fall back to raw asset name
    NSString *fallbackPath = [cacheFolder stringByAppendingPathComponent:assetName];
    return [NSURL fileURLWithPath:fallbackPath];
}

- (SwrveMessagePageViewController *)currentPageController {
    //when transitioning between pages, 2 SwrveMessagePageViewController can exist, we need
    //to ensure we add the video to the correct video AVPlayerViewController.
    NSArray<UIViewController *> *childViewControllers = self.controller.childViewControllers;
    SwrveMessagePageViewController *currentPageController = nil;
    for (UIViewController *childVC in childViewControllers) {
        if ([childVC isKindOfClass:[SwrveMessagePageViewController class]]) {
            NSNumber *childVCPageId = [(SwrveMessagePageViewController *)childVC pageId];
            if ([childVCPageId compare:self.pageId] == NSOrderedSame) {
                currentPageController = (SwrveMessagePageViewController *)childVC;
                return currentPageController;
            }
        }
    }
    return nil;
}

- (void)videoDidStartPlaying {
    if ([self.controller isKindOfClass:[SwrveMessageViewController class]]) {
        SwrveMessageViewController *messageViewController = (SwrveMessageViewController *) self.controller;
        [messageViewController queueVideoEvent:self.pageId mediaId:self.mediaId action:@"video_started"];
    }
}

- (void)videoDidFinishPlaying {
    if ([self.controller isKindOfClass:[SwrveMessageViewController class]]) {
        SwrveMessageViewController *messageViewController = (SwrveMessageViewController *) self.controller;
        [messageViewController queueVideoEvent:self.pageId mediaId:self.mediaId action:@"video_ended"];
    }
}
 
@end
