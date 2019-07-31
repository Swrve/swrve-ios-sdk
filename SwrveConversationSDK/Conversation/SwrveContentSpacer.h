#import "SwrveContentItem.h"

@interface SwrveContentSpacer : SwrveContentItem

@property (readonly, nonatomic) float height;

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict;

@end
