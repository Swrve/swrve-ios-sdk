#import "SwrveInputMultiBase.h"

@interface SwrveInputMultiValueLong : SwrveInputMultiBase

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict;
-(id) choicesForRow:(NSUInteger) row;

@end
