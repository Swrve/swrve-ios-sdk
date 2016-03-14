#import <UIKit/UIKit.h>

@class SwrveConversationStarRatingView;

@protocol SwrveConversationStarRatingViewDelegate
- (void) ratingView:(SwrveConversationStarRatingView *) ratingView ratingDidChange:(float) rating;
@end

@interface SwrveConversationStarRatingView : UIView

@property (strong, nonatomic) id <SwrveConversationStarRatingViewDelegate> swrveRatingDelegate;

- (id) initWithDefaults;
- (void) initRatingTypewithStarColor:(UIColor *) starColor withBackgroundColor:(UIColor *)backgroundColor;

@end
