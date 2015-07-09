#import "SwrveInputMultiBase.h"

@interface SwrveInputMultiValue : SwrveInputMultiBase

@property (nonatomic, assign) NSInteger selectedIndex;

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict;

@end
