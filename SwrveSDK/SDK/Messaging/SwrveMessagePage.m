#import "SwrveMessagePage.h"
#import "SwrveButton.h"
#import "SwrveImage.h"

@implementation SwrveMessagePage

@synthesize buttons;
@synthesize images;
@synthesize pageName;
@synthesize pageId;
@synthesize swipeForward;
@synthesize swipeBackward;

- (id)initFromJson:(NSDictionary *)json campaignId:(long)campaignId messageId:(long)messageId appStoreURLs:(NSMutableDictionary *)appStoreURLs {
    self = [super init];

    NSArray *jsonButtons = [json objectForKey:@"buttons"];
    NSMutableArray *loadedButtons = [NSMutableArray new];
    for (NSDictionary *jsonButton in jsonButtons) {
        SwrveButton *swrveButton = [[SwrveButton alloc] initWithDictionary:jsonButton
                                                                campaignId:campaignId
                                                                 messageId:messageId
                                                              appStoreURLs:appStoreURLs];
        [loadedButtons addObject:swrveButton];
    }
    self.buttons = [NSArray arrayWithArray:loadedButtons];

    NSArray *jsonImages = [json objectForKey:@"images"];
    NSMutableArray *loadedImages = [NSMutableArray new];
    for (NSDictionary *jsonImage in jsonImages) {
        SwrveImage *image = [[SwrveImage alloc] initWithDictionary:jsonImage campaignId:campaignId messageId:messageId];
        [loadedImages addObject:image];
    }
    self.images = [NSArray arrayWithArray:loadedImages];

    if ([json objectForKey:@"page_name"]) {
        self.pageName = [json objectForKey:@"page_name"];
    }

    if ([json objectForKey:@"page_id"]) {
        self.pageId = [[json objectForKey:@"page_id"] integerValue];
    }

    if ([json objectForKey:@"swipe_forward"]) {
        self.swipeForward = [[json objectForKey:@"swipe_forward"] integerValue];
    }

    if ([json objectForKey:@"swipe_backward"]) {
        self.swipeBackward = [[json objectForKey:@"swipe_backward"] integerValue];
    }

    return self;
}

@end
