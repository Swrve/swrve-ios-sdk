#import "SwrveConversationStarRating.h"
#import "SwrveContentHTML.h"
#import "SwrveConversationStyler.h"
#import "SwrveConversationStarRatingView.h"
#import "SwrveSetup.h"

#define kSwrveKeyValue @"value"
#define kSwrveKeyStarColor @"star_color"

@implementation SwrveConversationStarRating

@synthesize currentRating = _currentRating;
@synthesize starColor = _starColor;

- (id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict {
    self = [super initWithTag:tag andType:kSwrveControlStarRating];
    if(self) {
        _starColor = [dict objectForKey:kSwrveKeyStarColor];
    }
    return self;
}

- (UIView *)view {
    if(_view == nil) {
        SwrveConversationStarRatingView *ratingView = [[SwrveConversationStarRatingView alloc] initWithDefaults];
        [SwrveConversationStyler styleStarRating:ratingView withStyle:self.style withStarColor:_starColor];
        _view = ratingView;
    }
    return _view;
}

- (void) ratingView:(SwrveConversationStarRatingView *)ratingView ratingDidChange:(float)rating{
    #pragma unused (ratingView)
    _currentRating = rating;
}

@end

