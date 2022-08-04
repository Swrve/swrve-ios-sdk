#import "SwrveImage.h"
#if __has_include(<SwrveSDKCommon/SwrveLogger.h>)
#import <SwrveSDKCommon/SwrveLogger.h>
#else
#import "SwrveLogger.h"
#endif

@implementation SwrveImage

@synthesize file;
@synthesize dynamicImageUrl;
@synthesize text;
@synthesize center;
@synthesize size;
@synthesize messageId;
@synthesize campaignId;
@synthesize multilineText;
@synthesize accessibilityText;

- (id)initWithDictionary:(NSDictionary *)imageData
              campaignId:(long)swrveCampaignId
               messageId:(long)swrveMessageId {
    if (self = [super init]) {
        self.campaignId = swrveCampaignId;
        self.messageId = swrveMessageId;

        if ([imageData objectForKey:@"image"]) {
            self.file = [(NSDictionary *) [imageData objectForKey:@"image"] objectForKey:@"value"];
        }

        if ([imageData objectForKey:@"dynamic_image_url"]) {
            self.dynamicImageUrl = [imageData objectForKey:@"dynamic_image_url"];
        }

        NSNumber *x = [(NSDictionary *) [imageData objectForKey:@"x"] objectForKey:@"value"];
        NSNumber *y = [(NSDictionary *) [imageData objectForKey:@"y"] objectForKey:@"value"];
        self.center = CGPointMake(x.floatValue, y.floatValue);

        NSNumber *w = [(NSDictionary *) [imageData objectForKey:@"w"] objectForKey:@"value"];
        NSNumber *h = [(NSDictionary *) [imageData objectForKey:@"h"] objectForKey:@"value"];
        self.size = CGSizeMake(w.floatValue, h.floatValue);

        NSDictionary *textDictionary = (NSDictionary *) [imageData objectForKey:@"text"];

        if (textDictionary) {
            self.text = [textDictionary objectForKey:@"value"];
        }

        self.multilineText = (NSDictionary *) [imageData objectForKey:@"multiline_text"];
        [SwrveLogger debug:@"Image Loaded: Asset: \"%@\" (x: %g y: %g)",
                           self.file,
                           self.center.x,
                           self.center.y];
        
        if ([imageData objectForKey:@"accessibility_text"]) {
            self.accessibilityText = [imageData objectForKey:@"accessibility_text"];
        }

    }
    return self;
}

@end
