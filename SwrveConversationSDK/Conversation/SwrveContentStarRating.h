#import "SwrveConversationAtom.h"
#import "SwrveContentStarRatingView.h"

@interface SwrveContentStarRating : SwrveConversationAtom <SwrveConversationStarRatingViewDelegate>

- (id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *) dict;

@property (readwrite, nonatomic) float      currentRating;
@property (readonly, nonatomic) NSString   *starColor;

@end
