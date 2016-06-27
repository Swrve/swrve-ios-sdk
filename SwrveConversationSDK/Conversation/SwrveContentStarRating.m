#import "SwrveContentStarRating.h"
#import "SwrveContentHTML.h"
#import "SwrveConversationStyler.h"
#import "SwrveContentStarRatingView.h"
#import "SwrveSetup.h"

#define kSwrveKeyStarColor @"star_color"
#define kSwrveStarRatingHeight 60.0f
#define kSwrveStarRatingPadding 40.0f


@implementation SwrveContentStarRating

@synthesize currentRating = _currentRating;
@synthesize starColor = _starColor;

- (id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict {
    self = [super initWithTag:tag andType:kSwrveControlStarRating];
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
    
    if(containerWidth >= 414.0f){
        containerWidth = 414.0f;
    }
    
    _view.frame = CGRectMake(0,0, 1, 1);
    //set width
    CGRect frame = _view.frame;
    frame.size.width = containerWidth - kSwrveStarRatingPadding;
    _view.frame = frame;
    //set height
    frame = _view.frame;
    frame.size.height = kSwrveStarRatingHeight;
    _view.frame = frame;

    [SwrveConversationStyler styleStarRating:(SwrveContentStarRatingView *)_view withStyle:self.style withStarColor:_starColor];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSwrveNotificationViewReady object:nil];
}

-(void) respondToDeviceOrientationChange:(UIDeviceOrientation)orientation {
#pragma unused(orientation)
    _view.frame = [self newFrameForOrientationChange];
}

- (void) ratingView:(SwrveContentStarRatingView *)ratingView ratingDidChange:(float)rating{
#pragma unused (ratingView)
    _currentRating = rating;
}

@end
