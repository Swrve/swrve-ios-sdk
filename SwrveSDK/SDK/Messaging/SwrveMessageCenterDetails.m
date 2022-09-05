#import "SwrveMessageCenterDetails.h"

@implementation SwrveMessageCenterDetails

@synthesize subject;
@synthesize description;
@synthesize image;
@synthesize imageUrl;
@synthesize imageSha;
@synthesize imageAccessibilityText;

- (id)initWithJSON:(NSDictionary *)data {
    if (self = [super init]) {
        self.subject = [data objectForKey:@"subject"];
        self.description = [data objectForKey:@"description"];
        self.imageAccessibilityText = [data objectForKey:@"accessibility_text"];

        NSString *imageAsset = [data objectForKey:@"image_asset"];
        if (imageAsset != nil) {
            self.imageSha = imageAsset;
        }
        NSString *dynamicImageUrl = [data objectForKey:@"dynamic_image_url"];
        if (dynamicImageUrl != nil) {
            self.imageUrl = dynamicImageUrl;
        }
    }
    return self;
}

- (id)initWith:(NSString *)subjectStr description:(NSString *)descriptionStr accessibilityText:(NSString *)accessibilityTextStr
      imageUrl:(NSString *)imageUrlStr imageSha:(NSString *)imageShaStr image:(UIImage *)imageUI {
    if (self = [super init]) {
        self.subject = subjectStr;
        self.description = descriptionStr;
        self.imageAccessibilityText = accessibilityTextStr;
        self.imageUrl = imageUrlStr;
        self.imageSha = imageShaStr;
        self.image = imageUI;
    }
    return self;
}

@end
