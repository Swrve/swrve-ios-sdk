#import "SwrveConversationStarRating.h"
#import "SwrveConversationStarRatingView.h"
#import "SwrveSetup.h"

#define kSwrveKeyValue @"value"
#define kSwrveKeyStarColor @"star_color"

@implementation SwrveConversationStarRating

@synthesize value = _value;
@synthesize starColor = _starColor;

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict {
    self = [super initWithTag:tag andType:kSwrveControlStarRating];
    if(self) {
        _value = [dict objectForKey:kSwrveKeyValue];
        _starColor = [dict objectForKey:kSwrveKeyStarColor];
    }
    return self;
}

-(UIView *)view {
    if(_view == nil) {
        SwrveConversationStarRatingView *view = [[SwrveConversationStarRatingView alloc] init];
        _view = view;
    }
    return _view;
}


@end

