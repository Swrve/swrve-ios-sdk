#import <UIKit/UIKit.h>

@class SwrveConversationStarRatingView;

@protocol SwrveConversationStarRatingViewDelegate

- (void) ratingView:(SwrveConversationStarRatingView *) ratingView ratingDidChange:(float) rating;

@end

@interface SwrveConversationStarRatingView : UIView

- (void) initRatingTypewithStarColor:(UIColor *) starColor WithForegroundColor:(UIColor *)foregroundColor withBackgroundColor:(UIColor *)backgroundColor;

- (float) swrveCurrentRating;

@end
