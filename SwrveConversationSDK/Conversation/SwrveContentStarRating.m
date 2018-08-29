#import "SwrveContentStarRating.h"
#import "SwrveConversationStyler.h"

static NSString *const kSwrveKeyStarColor = @"star_color";

@implementation SwrveContentStarRating

@synthesize currentRating = _currentRating;
@synthesize starColor = _starColor;
@synthesize description = _description;

- (id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict {
    self = [super initWithTag:tag andType:kSwrveContentStarRating];
    if(self) {
        _starColor = [dict objectForKey:kSwrveKeyStarColor];
        _description = [dict objectForKey:@"value"];
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
    //Used by sdk systemtests
    _view.accessibilityIdentifier = _description;
}

#if TARGET_OS_IOS /** exclude tvOS **/
-(void) respondToDeviceOrientationChange:(UIDeviceOrientation)orientation {
#pragma unused(orientation)
    CGRect newFrame = [self newFrameForOrientationChange];
    CGFloat containerWidth = newFrame.size.width;
    [(SwrveContentStarRatingView*)_view setAvailableWidth:containerWidth];
}
#endif

- (void) ratingView:(SwrveContentStarRatingView *)ratingView ratingDidChange:(float)rating{
#pragma unused (ratingView)
    _currentRating = rating;
}

-(void)parentViewChangedSize:(CGSize)size {
    // Mantain full width
    [(SwrveContentStarRatingView*)_view setAvailableWidth:size.width];
}

@end
