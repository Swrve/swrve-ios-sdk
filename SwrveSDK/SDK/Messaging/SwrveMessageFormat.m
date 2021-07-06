#import "Swrve.h"
#import "SwrveMessageFormat.h"
#import "SwrveMessageController.h"
#import "SwrveButton.h"
#import "SwrveImage.h"
#if __has_include(<SwrveSDKCommon/SwrveLocalStorage.h>)
#import <SwrveSDKCommon/SwrveLocalStorage.h>
#import <SwrveSDKCommon/SwrveUtils.h>
#import <SwrveSDKCommon/SwrveQA.h>
#import <SwrveSDKCommon/SwrveQAImagePersonalizationInfo.h>
#import <SwrveSDKCommon/TextTemplating.h>
#else
#import "SwrveLocalStorage.h"
#import "SwrveUtils.h"
#import "SwrveQA.h"
#import "SwrveQAImagePersonalizationInfo.h"
#import "TextTemplating.h"
#endif

@implementation SwrveMessageFormat

@synthesize images;
@synthesize text;
@synthesize size;
@synthesize buttons;
@synthesize name;
@synthesize scale;
@synthesize language;
@synthesize orientation;
@synthesize backgroundColor;
@synthesize inAppConfig;

+(CGPoint)centerFromImageData:(NSDictionary*)data
{
    NSNumber* x = [(NSDictionary*)[data objectForKey:@"x"] objectForKey:@"value"];
    NSNumber* y = [(NSDictionary*)[data objectForKey:@"y"] objectForKey:@"value"];
    return CGPointMake(x.floatValue, y.floatValue);
}

+(CGSize)sizeFromImageData:(NSDictionary*)data
{
    NSNumber* w = [(NSDictionary*)[data objectForKey:@"w"] objectForKey:@"value"];
    NSNumber* h = [(NSDictionary*)[data objectForKey:@"h"] objectForKey:@"value"];
    return CGSizeMake(w.floatValue, h.floatValue);
}

+(SwrveImage*)createImage:(NSDictionary*)imageData forMessage:(SwrveMessage *)message {

    SwrveImage* image = [[SwrveImage alloc] init];
    image.message = message;
    
    if ([imageData objectForKey:@"image"]) {
        image.file = [(NSDictionary*)[imageData objectForKey:@"image"] objectForKey:@"value"];
    }

    if ([imageData objectForKey:@"dynamic_image_url"]) {
        image.dynamicImageUrl = [imageData objectForKey:@"dynamic_image_url"];
    }
    
    image.center = [SwrveMessageFormat centerFromImageData:imageData];
    image.size = [SwrveMessageFormat sizeFromImageData:imageData];
    
    NSDictionary *textDictionary = (NSDictionary*)[imageData objectForKey:@"text"];
    
    if (textDictionary) {
        image.text = [textDictionary objectForKey:@"value"];
    }
    
    [SwrveLogger debug:@"Image Loaded: Asset: \"%@\" (x: %g y: %g)",
          image.file,
          image.center.x,
          image.center.y];

    return image;
}

+(SwrveButton*)createButton:(NSDictionary*)buttonData
              forController:(SwrveMessageController*)controller
                 forMessage:(SwrveMessage*)message
{
    SwrveButton* button = [[SwrveButton alloc] init];
    button.message = message;

    button.name       = [buttonData objectForKey:@"name"];
    button.center     = [SwrveMessageFormat centerFromImageData:buttonData];
    button.size       = [SwrveMessageFormat sizeFromImageData:buttonData];
    
    if ([buttonData objectForKey:@"image_up"]) {
        button.image = [(NSDictionary*)[buttonData objectForKey:@"image_up"] objectForKey:@"value"];
    }

    if ([buttonData objectForKey:@"dynamic_image_url"]) {
        button.dynamicImageUrl = [buttonData objectForKey:@"dynamic_image_url"];
    }
    
    NSDictionary *textDictionary = (NSDictionary*)[buttonData objectForKey:@"text"];
    if (textDictionary) {
        button.text = [textDictionary objectForKey:@"value"];
    }

    button.messageID  = [message.messageID integerValue];

    // Set up the action for the button.
    button.actionType   = kSwrveActionDismiss;
    button.appID       = 0;
    button.actionString = @"";
    
    NSString* buttonType = [(NSDictionary*)[buttonData objectForKey:@"type"] objectForKey:@"value"];
    if ([buttonType isEqualToString:@"INSTALL"]){
        button.actionType   = kSwrveActionInstall;
        button.appID       = [[(NSDictionary*)[buttonData objectForKey:@"game_id"] objectForKey:@"value"] integerValue];
        button.actionString = [controller appStoreURLForAppId:button.appID];
    } else if ([buttonType isEqualToString:@"CUSTOM"]) {
        button.actionType   = kSwrveActionCustom;
        button.actionString = [(NSDictionary*)[buttonData objectForKey:@"action"] objectForKey:@"value"];
    } else if ([buttonType isEqualToString:@"COPY_TO_CLIPBOARD"]) {
        button.actionType = kSwrveActionClipboard;
        button.actionString = [(NSDictionary*)[buttonData objectForKey:@"action"] objectForKey:@"value"];
    } else if ([buttonType isEqualToString:@"REQUEST_CAPABILITY"]) {
        button.actionType = kSwrveActionCapability;
        button.actionString = [(NSDictionary*)[buttonData objectForKey:@"action"] objectForKey:@"value"];
    }
    return button;
}

static CGFloat extractHex(NSString* color, NSUInteger index) {
    NSString* componentString = [color substringWithRange:NSMakeRange(index, 2)];
    unsigned hexResult;
    [[NSScanner scannerWithString:componentString] scanHexInt: &hexResult];
    return hexResult / 255.0f;
}

-(id)initFromJson:(NSDictionary*)json forController:(SwrveMessageController*)controller forMessage:(SwrveMessage*)message
{
    self = [super init];

    self.name     = [json objectForKey:@"name"];
    self.language = [json objectForKey:@"language"];
    

    NSString* jsonOrientation = [json objectForKey:@"orientation"];
    if (jsonOrientation)
    {
        self.orientation = ([jsonOrientation caseInsensitiveCompare:@"landscape"] == NSOrderedSame)? SWRVE_ORIENTATION_LANDSCAPE : SWRVE_ORIENTATION_PORTRAIT;
    }

    NSString* jsonColor = [json objectForKey:@"color"];
    if (jsonColor)
    {
        NSString* hexColor = [jsonColor uppercaseString];
        CGFloat alpha = 0, red = 0, blue = 0, green = 0;
        switch ([hexColor length]) {
            case 6: // #RRGGBB
                alpha = 1.0f;
                red   = extractHex(hexColor, 0);
                green = extractHex(hexColor, 2);
                blue  = extractHex(hexColor, 4);
                break;
            case 8: // #AARRGGBB
                alpha = extractHex(hexColor, 0);
                red   = extractHex(hexColor, 2);
                green = extractHex(hexColor, 4);
                blue  = extractHex(hexColor, 6);
                break;
        }
        self.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
    }

    // If doesn't exist default to 1.0
    NSNumber * jsonScale = [json objectForKey:@"scale"];
    if (jsonScale != nil)
    {
        self.scale = [jsonScale floatValue];
    }
    else
    {
        self.scale = 1.0;
    }

    self.size = [SwrveMessageFormat sizeFromImageData:[json objectForKey:@"size"]];

    [SwrveLogger debug:@"Format %@ Scale: %g  Size: %gx%g", self.name, self.scale, self.size.width, self.size.height];

    NSArray* jsonButtons = [json objectForKey:@"buttons"];
    NSMutableArray *loadedButtons = [NSMutableArray new];

    for (NSDictionary* jsonButton in jsonButtons)
    {
        [loadedButtons addObject:[SwrveMessageFormat createButton:jsonButton forController:controller forMessage:message]];
    }

    self.buttons = [NSArray arrayWithArray:loadedButtons];

    self.text = [[NSArray alloc]init];

    NSMutableArray *loadedImages = [NSMutableArray new];

    NSArray* jsonImages = [json objectForKey:@"images"];
    for (NSDictionary* jsonImage in jsonImages) {

        [loadedImages addObject:[SwrveMessageFormat createImage:jsonImage forMessage:message]];
    }

    self.images = [NSArray arrayWithArray:loadedImages];

    return self;
}

-(UIView*)createViewToFit:(UIView*)view
          thatDelegatesTo:(UIViewController*)delegate
                 withSize:(CGSize)sizeParent
                  rotated:(BOOL)rotated
                    
{
    return [self createViewToFit:view thatDelegatesTo:delegate withSize:sizeParent rotated:rotated personalization:nil];
}


-(UIView*)createViewToFit:(UIView*)view
          thatDelegatesTo:(UIViewController*)delegate
                 withSize:(CGSize)sizeParent
                  rotated:(BOOL)rotated
          personalization:(NSDictionary*)personalization
                    
{
    CGRect containerViewSize = CGRectMake(0, 0, sizeParent.width, sizeParent.height);
    if (rotated) {
        containerViewSize = CGRectMake(0, 0, sizeParent.height, sizeParent.width);
    }
    UIView* containerView = [[UIView alloc] initWithFrame:containerViewSize];

    // Find the center point of the view
    CGFloat half_screen_width = sizeParent.width/2;
    CGFloat half_screen_height = sizeParent.height/2;

    CGFloat logical_half_screen_width = (rotated)? half_screen_height : half_screen_width;
    CGFloat logical_half_screen_height = (rotated)? half_screen_width : half_screen_height;

    // Adjust scale, accounting for retina devices
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    CGFloat renderScale = self.scale / screenScale;

    [SwrveLogger debug:@"MessageViewFormat scale :%g", self.scale];
    [SwrveLogger debug:@"UI scale :%g", screenScale];

    [self addImageViews:containerView centerX:logical_half_screen_width centerY:logical_half_screen_height scale:renderScale personalization:personalization];
    [self addButtonViews:containerView delegate:delegate centerX:logical_half_screen_width centerY:logical_half_screen_height scale:renderScale personalization:personalization];
    
    if (rotated) {
        containerView.transform = CGAffineTransformMakeRotation((CGFloat)M_PI_2);
    }
    [containerView setCenter:CGPointMake(half_screen_width, half_screen_height)];
    [view addSubview:containerView];
    return containerView;
}

-(UIView*)createViewToFit:(UIView*)view
    thatDelegatesTo:(UIViewController*)delegate
           withSize:(CGSize)sizeParent
{
    return [self createViewToFit:view thatDelegatesTo:delegate withSize:sizeParent personalization:nil];
}

-(UIView*)createViewToFit:(UIView*)view
          thatDelegatesTo:(UIViewController*)delegate
                 withSize:(CGSize)sizeParent
          personalization:(NSDictionary*)personalization
{
    // Calculate the scale needed to fit the format in the current viewport
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    float wscale = (float)((sizeParent.width * screenScale)/self.size.width);
    float hscale = (float)((sizeParent.height * screenScale)/self.size.height);
    float viewportScale = (wscale < hscale)? wscale : hscale;

    CGRect containerViewSize = CGRectMake(0, 0, sizeParent.width, sizeParent.height);
    UIView* containerView = [[UIView alloc] initWithFrame:containerViewSize];

    // Find the center point of the view
    CGFloat centerX = sizeParent.width/2;
    CGFloat centerY = sizeParent.height/2;

    // Adjust scale, accounting for retina devices
    CGFloat renderScale = (self.scale / screenScale) * viewportScale;

    [SwrveLogger debug:@"MessageViewFormat scale :%g", self.scale];
    [SwrveLogger debug:@"UI scale :%g", screenScale];

    [self addImageViews:containerView centerX:centerX centerY:centerY scale:renderScale personalization:personalization];
    [self addButtonViews:containerView delegate:delegate centerX:centerX centerY:centerY scale:renderScale personalization:personalization];
    
    [containerView setCenter:CGPointMake(centerX, centerY)];
    [view addSubview:containerView];

#if TARGET_OS_TV
    [containerView setAlpha:1];
#endif
    [view setAlpha:1];
    [containerView setUserInteractionEnabled:YES];
    [view setUserInteractionEnabled:YES];

    [view setHidden:NO];
    [containerView setHidden:NO];

    return containerView;
}

-(void)addButtonViews:(UIView*)containerView delegate:(UIViewController*)delegate centerX:(CGFloat)centerX centerY:(CGFloat)centerY scale:(CGFloat)renderScale personalization:(NSDictionary *)personalization
{
    SEL buttonPressedSelector = NSSelectorFromString(@"onButtonPressed:");
    int buttonTag = 0;

    for (SwrveButton* button in self.buttons) {
        
        NSString *personalizedTextStr = nil;
        NSString *personalizedActionStr = nil;
        NSString *personalizedUrlAssetSha1 = nil;
        SwrveQAImagePersonalizationInfo *imagePersonalizationQAInfo = nil;
        
        if (button.text) {
             NSError *error;
             personalizedTextStr = [TextTemplating templatedTextFromString:button.text withProperties:personalization andError:&error];
             
             if (error != nil){
                 [SwrveLogger error:@"%@", error];
             }
        }
        
        if (button.dynamicImageUrl) {
            // set up QA Info in case it doesn't work
            imagePersonalizationQAInfo = [[SwrveQAImagePersonalizationInfo alloc] initWithCampaign:button.message.campaign.ID
                                                                                         variantID:[button.message.messageID unsignedIntegerValue]
                                                                                         assetName:nil
                                                                                       hasFallback:(button.image != nil)
                                                                                     unresolvedUrl:button.dynamicImageUrl
                                                                                       resolvedUrl:nil
                                                                                            reason:nil];
            
            personalizedUrlAssetSha1 = [self resolvePersonalizedImageAsset:button.dynamicImageUrl
                                                       withPersonalization:personalization
                                                                 andQAInfo:imagePersonalizationQAInfo];
            
        }
        
        if (button.actionType == kSwrveActionClipboard || button.actionType == kSwrveActionCustom) {
            NSError *error;
            personalizedActionStr = [TextTemplating templatedTextFromString:button.actionString withProperties:personalization andError:&error];
            
            if (error != nil){
                [SwrveLogger error:@"%@", error];
            }
        }
        
        UISwrveButton* buttonView = [button createButtonWithDelegate:delegate
                                                         andSelector:buttonPressedSelector
                                                            andScale:(float)renderScale
                                                          andCenterX:(float)centerX
                                                          andCenterY:(float)centerY
                                               andPersonalizedAction:personalizedActionStr
                                                  andPersonalization:personalizedTextStr
                                         andPersonalizedUrlAssetSha1:personalizedUrlAssetSha1
                                                          withConfig:self.inAppConfig
                                                              qaInfo:imagePersonalizationQAInfo];
        buttonView.tag = buttonTag;

        NSString * buttonType;
        switch (button.actionType) {
            case kSwrveActionInstall:
                buttonType = @"Install";
                break;
            case kSwrveActionDismiss:
                buttonType = @"Dismiss";
                break;
            case kSwrveActionClipboard:
                buttonType = @"Clipboard";
                break;
            default:
                buttonType = @"Custom";
        }

        buttonView.accessibilityLabel = [NSString stringWithFormat:@"TalkButton_%d_%@", buttonTag, buttonType];
        //Used by sdk systemtests
        buttonView.accessibilityIdentifier = button.name;
        [containerView addSubview:buttonView];
        buttonTag++;
    }
}

-(void)addImageViews:(UIView*)containerView centerX:(CGFloat)centerX centerY:(CGFloat)centerY scale:(CGFloat)renderScale personalization:(NSDictionary *)personalization
{
    NSString *cacheFolder = [SwrveLocalStorage swrveCacheFolder];
    for (SwrveImage* image in self.images)
    {
        NSString *personalizedTextStr = nil;
        NSString *personalizedUrlAssetSha1 = nil;
        SwrveQAImagePersonalizationInfo *imagePersonalizationQAInfo = nil;
        
        if (image.text) {
             NSError *error;
             personalizedTextStr = [TextTemplating templatedTextFromString:image.text withProperties:personalization andError:&error];
             
             if (error != nil){
                 [SwrveLogger error:@"%@", error];
             }
        }
        
        if (image.dynamicImageUrl) {
            imagePersonalizationQAInfo = [[SwrveQAImagePersonalizationInfo alloc] initWithCampaign:image.message.campaign.ID
                                               variantID:[image.message.messageID unsignedIntegerValue]
                                               assetName:nil
                                             hasFallback:(image.file != nil)
                                           unresolvedUrl:image.dynamicImageUrl
                                             resolvedUrl:nil reason:nil];
            
            personalizedUrlAssetSha1 = [self resolvePersonalizedImageAsset:image.dynamicImageUrl
                                                       withPersonalization:personalization andQAInfo:imagePersonalizationQAInfo];
        }
    
        UIImage *background = [image createImage:cacheFolder
                                 personalization:personalizedTextStr
                        personalizedUrlAssetSha1:personalizedUrlAssetSha1
                                     inAppConfig:self.inAppConfig
                                          qaInfo:imagePersonalizationQAInfo];
        
        CGRect frame = CGRectMake(0, 0,
                                  background.size.width * renderScale,
                                  background.size.height * renderScale);


        UIImageView* imageView = [[UIImageView alloc] initWithFrame:frame];
        imageView.image = background;

        //shows focus on tvOS
#if TARGET_OS_TV
        imageView.adjustsImageWhenAncestorFocused = YES;
#endif

        [imageView setCenter:CGPointMake(centerX + (image.center.x * renderScale),
                                         centerY + (image.center.y * renderScale))];
        [containerView addSubview:imageView];
    }
}

- (NSString *)resolvePersonalizedImageAsset:(NSString *)assetUrl withPersonalization:(NSDictionary *)personalization andQAInfo:(SwrveQAImagePersonalizationInfo *) qaInfo {
    if (assetUrl != nil) {
        NSError *error;
        NSString *resolvedUrl = [TextTemplating templatedTextFromString:assetUrl withProperties:personalization andError:&error];
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

@end
