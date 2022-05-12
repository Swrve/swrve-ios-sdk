#import "Swrve.h"
#import "SwrveMessageFormat.h"
#import "SwrveMessagePage.h"

@implementation SwrveMessageFormat

@synthesize size;
@synthesize pages;
@synthesize firstPageId;
@synthesize name;
@synthesize scale;
@synthesize language;
@synthesize orientation;
@synthesize backgroundColor;
@synthesize calibration;

static CGFloat extractHex(NSString *color, NSUInteger index) {
    NSString *componentString = [color substringWithRange:NSMakeRange(index, 2)];
    unsigned hexResult;
    [[NSScanner scannerWithString:componentString] scanHexInt:&hexResult];
    return hexResult / 255.0f;
}

- (id)initFromJson:(NSDictionary *)json campaignId:(long)campaignId messageId:(long)messageId appStoreURLs:(NSMutableDictionary *)appStoreURLs {
    self = [super init];

    self.name = [json objectForKey:@"name"];
    self.language = [json objectForKey:@"language"];

    NSString *jsonOrientation = [json objectForKey:@"orientation"];
    if (jsonOrientation) {
        self.orientation = ([jsonOrientation caseInsensitiveCompare:@"landscape"] == NSOrderedSame) ? SWRVE_ORIENTATION_LANDSCAPE : SWRVE_ORIENTATION_PORTRAIT;
    }

    NSString *jsonColor = [json objectForKey:@"color"];
    if (jsonColor) {
        NSString *hexColor = [jsonColor uppercaseString];
        CGFloat alpha = 0, red = 0, blue = 0, green = 0;
        switch ([hexColor length]) {
            case 6: // #RRGGBB
                alpha = 1.0f;
                red = extractHex(hexColor, 0);
                green = extractHex(hexColor, 2);
                blue = extractHex(hexColor, 4);
                break;
            case 8: // #AARRGGBB
                alpha = extractHex(hexColor, 0);
                red = extractHex(hexColor, 2);
                green = extractHex(hexColor, 4);
                blue = extractHex(hexColor, 6);
                break;
        }
        self.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
    }

    // If doesn't exist default to 1.0
    NSNumber *jsonScale = [json objectForKey:@"scale"];
    if (jsonScale != nil) {
        self.scale = [jsonScale floatValue];
    } else {
        self.scale = 1.0;
    }

    NSDictionary* sizeData = [json objectForKey:@"size"];
    NSNumber *w = [(NSDictionary *) [sizeData objectForKey:@"w"] objectForKey:@"value"];
    NSNumber *h = [(NSDictionary *) [sizeData objectForKey:@"h"] objectForKey:@"value"];
    self.size = CGSizeMake(w.floatValue, h.floatValue);

    [SwrveLogger debug:@"Format %@ Scale: %g  Size: %gx%g", self.name, self.scale, self.size.width, self.size.height];

    if ([json objectForKey:@"pages"]) {
        NSArray *pagesArray = [json objectForKey:@"pages"];
        NSMutableDictionary *loadedPages = [NSMutableDictionary new];
        for (NSDictionary *pageData in pagesArray) {
            SwrveMessagePage *page = [[SwrveMessagePage alloc] initFromJson:pageData campaignId:campaignId messageId:messageId appStoreURLs:appStoreURLs];
            [loadedPages setObject:page forKey:[NSNumber numberWithLong:page.pageId]];
            if(firstPageId == 0) {
                self.firstPageId = page.pageId;
            }
        }
        self.pages = [NSDictionary dictionaryWithDictionary:loadedPages];
    } else {
        // for backward compatibility, convert old IAM's into a single page Dictionary
        NSMutableDictionary *loadedPages = [NSMutableDictionary new];
        SwrveMessagePage *page = [[SwrveMessagePage alloc] initFromJson:json campaignId:campaignId messageId:messageId appStoreURLs:appStoreURLs];
        self.firstPageId = page.pageId;
        [loadedPages setObject:page forKey:[NSNumber numberWithLong:firstPageId]];
        self.pages = [NSDictionary dictionaryWithDictionary:loadedPages];
    }

    self.calibration = [[SwrveCalibration alloc] initWithDictionary:[json objectForKey:@"calibration"]];

    return self;
}

@end
