#import "SwrveConversationAtom.h"
#import "SwrveConversationStarRatingView.h"

@interface SwrveConversationStarRating : SwrveConversationAtom <SwrveConversationStarRatingViewDelegate>

- (id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *) dict;

@property (readonly, nonatomic) float       currentRating;
@property (readonly, nonatomic) NSString   *starColor;

@end
