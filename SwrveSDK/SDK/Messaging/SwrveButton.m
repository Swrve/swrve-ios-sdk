#import "SwrveButton.h"

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

@end
