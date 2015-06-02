#import "SwrveContentItem.h"

@interface SwrveContentVideo : SwrveContentItem <UIWebViewDelegate>

@property (readonly, atomic, strong) NSString *height;

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict;

@end
