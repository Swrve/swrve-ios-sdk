#import "SwrveConversationAtom.h"

@interface SwrveConversationStarRating : SwrveConversationAtom


- (id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *) dict;

@property (readonly, nonatomic) NSString   *value;
@property (readonly, nonatomic) NSString   *starColor;

@end
