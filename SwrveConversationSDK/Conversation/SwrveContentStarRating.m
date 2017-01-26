#import "SwrveContentStarRating.h"
#import "SwrveConversationStyler.h"

#define kSwrveKeyStarColor @"star_color"

@implementation SwrveContentStarRating

@synthesize currentRating = _currentRating;
@synthesize starColor = _starColor;

- (id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict {
    self = [super initWithTag:tag andType:kSwrveContentStarRating];
    if(self) {
        _starColor = [dict objectForKey:kSwrveKeyStarColor];
    }
    
    self.delegate = self;
    return self;
}

-(void) loadViewWithContainerView:(UIView*)containerView {
    _view = [[SwrveContentStarRatingView alloc] initWithDefaults];
    [(SwrveContentStarRatingView*)_view setSwrveRatingDelegate:self];
    
    CGFloat containerWidth = containerView.bounds.size.width;
    [(SwrveContentStarRatingView*)_view setAvailableWidth:containerWidth];
    
    [SwrveConversationStyler styleStarRating:(SwrveContentStarRatingView *)_view withStyle:self.style withStarColor:_starColor];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSwrveNotificationViewReady object:nil];
}

-(void) respondToDeviceOrientationChange:(UIDeviceOrientation)orientation {
#pragma unused(orientation)
    CGRect newFrame = [self newFrameForOrientationChange];
    CGFloat containerWidth = newFrame.size.width;
    [(SwrveContentStarRatingView*)_view setAvailableWidth:containerWidth];
}

- (void) ratingView:(SwrveContentStarRatingView *)ratingView ratingDidChange:(float)rating{
#pragma unused (ratingView)
    _currentRating = rating;
}

@end
