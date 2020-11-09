#import "SwrveMessage.h"
#import "Swrve.h"
#import "SwrveButton.h"
#import "SwrveImage.h"

#if __has_include(<SwrveSDKCommon/TextTemplating.h>)
#import <SwrveSDKCommon/TextTemplating.h>
#else
#import "TextTemplating.h"
#endif

@interface SwrveMessage()

@property (nonatomic, weak) SwrveMessageController* controller;

@end

@implementation SwrveMessage

@synthesize controller, campaign, messageID, name, priority, formats;

-(id)initWithDictionary:(NSDictionary *)json forCampaign:(SwrveInAppCampaign *)_campaign forController:(SwrveMessageController*)_controller {
    if (self = [super init]) {
        self.campaign     = _campaign;
        self.controller   = _controller;
        self.messageID    = [json objectForKey:@"id"];
        self.name         = [json objectForKey:@"name"];
        if ([json objectForKey:@"priority"]) {
            self.priority = [json objectForKey:@"priority"];
        } else {
            self.priority = [NSNumber numberWithInt:9999];
        }

        NSDictionary* messageTemplate = (NSDictionary*)[json objectForKey:@"template"];

        NSArray* jsonFormats = [messageTemplate objectForKey:@"formats"];

        NSMutableArray *loadedFormats = [NSMutableArray new];

        for (NSDictionary* jsonFormat in jsonFormats)
        {
            SwrveMessageFormat* format = [[SwrveMessageFormat alloc] initFromJson:jsonFormat
                                                                    forController:controller
                                                                       forMessage:self];
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
        if (UIInterfaceOrientationIsLandscape(orientation)) {
            // device is landscape
            if (format_is_landscape) return format;
        } else {
            // device is portrait
            if (!format_is_landscape) return format;
        }
    }
    return nil;
}

- (BOOL)supportsOrientation:(UIInterfaceOrientation)orientation {
    return (nil != [self bestFormatForOrientation:orientation]);
}
#endif

static bool in_cache(NSString* file, NSSet* set){
    return [file length] == 0 || [set containsObject:file];
}

-(BOOL)assetsReady:(NSSet*)assets
{
    for (SwrveMessageFormat* format in self.formats) {
        for (SwrveButton* button in format.buttons) {
            if (!in_cache(button.image, assets)){
                DebugLog(@"Button Asset not yet downloaded: %@", button.image);
                return false;
            }
        }

        for (SwrveImage* image in format.images) {
            if (!in_cache(image.file, assets)){
                DebugLog(@"Image Asset not yet downloaded: %@", image.file);
                return false;
            }
        }
    }

    return true;
}

-(BOOL)canResolvePersonalisation:(NSDictionary*)personalisation
{
    for (SwrveMessageFormat* format in self.formats) {

        for (SwrveButton *button in format.buttons) {
            if (button.text) {
                NSError *error;
                NSString *text = [TextTemplating templatedTextFromString:button.text withProperties:personalisation andError:&error];
                if (error != nil || text == nil) {
                    DebugLog(@"Button Asset has no personalisation for text: %@", button.text);
                    return false;
                }
            }
            
            if (button.actionType == kSwrveActionClipboard || button.actionType == kSwrveActionCustom) {
                NSError *error;
                NSString *text = [TextTemplating templatedTextFromString:button.actionString withProperties:personalisation andError:&error];
                if (error != nil || text == nil) {
                    DebugLog(@"Button Asset has no personalisation for action: %@", button.actionString);
                    return false;
                }
            }
        }
        
        for (SwrveImage *image in format.images) {
            if (image.text) {
                NSError *error;
                NSString *text = [TextTemplating templatedTextFromString:image.text withProperties:personalisation andError:&error];
                if (error != nil || text == nil) {
                    DebugLog(@"Button Asset has no personalisation for text: %@", image.text);
                    return false;
                }
            }
        }
    }
    return true;
}

-(void)wasShownToUser
{
    SwrveMessageController* c = self.controller;
    if (c != nil) {
        [c messageWasShownToUser:self];
    }
}

@end
