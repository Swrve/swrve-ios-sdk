#import "SwrveConversationStarRating.h"
#import "SwrveContentHTML.h"
#import "SwrveConversationStyler.h"
#import "SwrveConversationStarRatingView.h"
#import "SwrveSetup.h"

#define kSwrveKeyStarColor @"star_color"
#define kSwrveStarRatingHeight 40.0f
#define kSwrveStarRatingPadding 40.0f


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

-(void) loadViewWithContainerView:(UIView*)containerView {
    _view = [[SwrveConversationStarRatingView alloc] initWithDefaults];
    [(SwrveConversationStarRatingView*)_view setSwrveRatingDelegate:self];
    
    _view.frame = CGRectMake(0,0, 1, 1);
    //set width
    CGRect frame = _view.frame;
    frame.size.width = containerView.frame.size.width - kSwrveStarRatingPadding;
    _view.frame = frame;
    //set height
    frame = _view.frame;
    frame.size.height = kSwrveStarRatingHeight;
    _view.frame = frame;
    //center
    [_view setCenter:CGPointMake(containerView.center.x, _view.center.y)];
    
    [SwrveConversationStyler styleStarRating:(SwrveConversationStarRatingView *)_view withStyle:self.style withStarColor:_starColor];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSwrveNotificationViewReady object:nil];
}

- (void) ratingView:(SwrveConversationStarRatingView *)ratingView ratingDidChange:(float)rating{
#pragma unused (ratingView)
    _currentRating = rating;
}

@end

