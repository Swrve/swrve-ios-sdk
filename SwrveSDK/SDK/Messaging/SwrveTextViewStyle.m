#import "SwrveTextViewStyle.h"

@implementation SwrveTextViewStyle

@synthesize fontsize;
@synthesize text;
@synthesize textAlignment;
@synthesize scrollable;
@synthesize font;
@synthesize foregroundColor;
@synthesize backgroundColor;

- (instancetype)initWithDictionary:(NSDictionary *)style {
    self = [super init];
    if (self) {
        self.text = [style objectForKey:@"value"];
        self.fontsize = [[style objectForKey:@"font_size"] floatValue];
        self.scrollable = [[style objectForKey:@"scrollable"] boolValue];
        self.textAlignment = [self textAlignmentFromString:[style objectForKey:@"h_align"]];
    }
    return self;
}

- (NSTextAlignment)textAlignmentFromString:(NSString *)textAlignmentString {
    if ([textAlignmentString isEqualToString:@"CENTER"]) {
        return NSTextAlignmentCenter;
    } else if ([textAlignmentString isEqualToString:@"RIGHT"]) {
        return NSTextAlignmentRight;
    } else {
        return NSTextAlignmentLeft;
    }
}

@end

