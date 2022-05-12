#import "SwrveMessage.h"
#import "Swrve.h"
#import "SwrveButton.h"
#import "SwrveImage.h"
#import "SwrveMessageController.h"
#import "SwrveMessagePage.h"

#if __has_include(<SwrveSDKCommon/TextTemplating.h>)

#import <SwrveSDKCommon/TextTemplating.h>
#import <SwrveSDKCommon/SwrveUtils.h>

#else
#import "TextTemplating.h"
#import "SwrveUtils.h"
#endif

@interface SwrveMessage ()

@property(nonatomic, weak) SwrveMessageController *controller;

@end

@interface SwrveMessageController ()
@property(nonatomic, retain) NSMutableDictionary *appStoreURLs;
@end

@implementation SwrveMessage

@synthesize controller, campaign, name, formats;

- (id)initWithDictionary:(NSDictionary *)json forCampaign:(SwrveInAppCampaign *)_campaign forController:(SwrveMessageController *)_controller {
    if (self = [super init]) {
        self.campaign = (SwrveCampaign *) _campaign;
        self.controller = _controller;
        self.messageID = [json objectForKey:@"id"];
        self.name = [json objectForKey:@"name"];
        if ([json objectForKey:@"priority"]) {
            self.priority = [json objectForKey:@"priority"];
        } else {
            self.priority = [NSNumber numberWithInt:9999];
        }
        NSDictionary *messageTemplate = (NSDictionary *) [json objectForKey:@"template"];
        NSArray *jsonFormats = [messageTemplate objectForKey:@"formats"];
        NSMutableArray *loadedFormats = [NSMutableArray new];
        for (NSDictionary *jsonFormat in jsonFormats) {
            SwrveMessageFormat *format = [[SwrveMessageFormat alloc] initFromJson:jsonFormat
                                                                       campaignId:(int)self.campaign.ID
                                                                        messageId:[self.messageID integerValue]
                                                                     appStoreURLs:[controller appStoreURLs]];
            [loadedFormats addObject:format];
        }
        self.formats = [[NSArray alloc] initWithArray:loadedFormats];
    }
    return self;
}

#if TARGET_OS_IOS /** exclude tvOS **/

- (SwrveMessageFormat *)bestFormatForOrientation:(UIInterfaceOrientation)orientation {
    for (SwrveMessageFormat *format in formats) {
        bool format_is_landscape = format.orientation == SWRVE_ORIENTATION_LANDSCAPE;
        if (UIInterfaceOrientationIsLandscape(orientation)) { // device is landscape
            if (format_is_landscape) return format;
        } else { // device is portrait
            if (!format_is_landscape) return format;
        }
    }
    return nil;
}

- (BOOL)supportsOrientation:(UIInterfaceOrientation)orientation {
    return (nil != [self bestFormatForOrientation:orientation]);
}

#endif

static bool in_cache(NSString *file, NSSet *set) {
    return [set containsObject:file];
}

- (BOOL)assetsReady:(NSSet *)assets withPersonalization:(NSDictionary *)personalization {
    if (self.formats == nil) {
        return YES; // exit quickly
    }

    for (SwrveMessageFormat *format in self.formats) {
        NSDictionary *pages = [format pages];
        for (id key in pages) {
            SwrveMessagePage *page = [pages objectForKey:key];

            for (SwrveButton *button in page.buttons) {
                BOOL hasButtonImage = in_cache(button.image, assets);
                if (button.dynamicImageUrl) {
                    if ([self canResolvePersonalizedImageAsset:button.dynamicImageUrl withPersonalization:personalization withAssets:assets]) {
                        hasButtonImage = YES;
                    }
                }
                if (!hasButtonImage) {
                    [SwrveLogger debug:@"Button Asset not yet downloaded: %@ / %@", button.image, button.dynamicImageUrl];
                    return NO;
                }
            }

            for (SwrveImage* image in page.images) {
                if(image.multilineText) {
                    NSString *font_file = [image.multilineText objectForKey:@"font_file"];
                    if (font_file && ![font_file isEqualToString:@"_system_font_"]) {
                        if (!in_cache(font_file, assets)) {
                            [SwrveLogger debug:@"Font Asset not yet downloaded: %@", name];
                            return NO;
                        }
                    }
                } else {
                    BOOL hasImage = in_cache(image.file, assets);
                    if (image.dynamicImageUrl) {
                        if([self canResolvePersonalizedImageAsset:image.dynamicImageUrl withPersonalization:personalization withAssets:assets]){
                            hasImage = YES;
                        }
                    }
                    if (!hasImage) {
                        [SwrveLogger debug:@"Image Asset not yet downloaded: %@ / %@", image.file, image.dynamicImageUrl];
                        return NO;
                    }
                }
            }
        }
    }

    return YES;
}

- (BOOL)canResolvePersonalizedImageAsset:(NSString *)assetUrl withPersonalization:(NSDictionary *)personalization withAssets:(NSSet *)assets {
    NSError *error;
    NSString *resolvedUrl = [TextTemplating templatedTextFromString:assetUrl withProperties:personalization andError:&error];
    if (error != nil || resolvedUrl == nil) {
        [SwrveLogger debug:@"Could not resolve personalization: %@", assetUrl];
    } else {
        NSData *data = [resolvedUrl dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
        NSString *canditateAsset = [SwrveUtils sha1:data];
        if (in_cache(canditateAsset, assets)) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)canResolvePersonalization:(NSDictionary *)personalization {
    for (SwrveMessageFormat *format in self.formats) {

        NSDictionary *pages = [format pages];
        for (id key in pages) {
            SwrveMessagePage *page = [pages objectForKey:key];

            for (SwrveButton *button in page.buttons) {
                if (button.text) {
                    NSError *error;
                    NSString *text = [TextTemplating templatedTextFromString:button.text withProperties:personalization andError:&error];
                    if (error != nil || text == nil) {
                        [SwrveLogger warning:@"Button Asset has no personalization for text: %@", button.text];
                        return false;
                    }
                }

                if (button.actionType == kSwrveActionClipboard || button.actionType == kSwrveActionCustom) {
                    NSError *error;
                    NSString *text = [TextTemplating templatedTextFromString:button.actionString withProperties:personalization andError:&error];
                    if (error != nil || text == nil) {
                        [SwrveLogger warning:@"Button Asset has no personalization for action: %@", button.actionString];
                        return false;
                    }
                }
            }

            for (SwrveImage *image in page.images) {
                if (image.text) {
                    NSError *error;
                    NSString *text = [TextTemplating templatedTextFromString:image.text withProperties:personalization andError:&error];
                    if (error != nil || text == nil) {
                        [SwrveLogger warning:@"Button Asset has no personalization for text: %@", image.text];
                        return false;
                    }
                }
            }
        }
    }
    return true;
}

- (void)wasShownToUser {
    SwrveMessageController *c = self.controller;
    if (c != nil) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [c messageWasShownToUser:self];
#pragma clang diagnostic pop
    }
}

@end
