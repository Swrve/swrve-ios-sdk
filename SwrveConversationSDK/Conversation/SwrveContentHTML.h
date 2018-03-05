#import "SwrveContentItem.h"

#if TARGET_OS_IOS /** exclude tvOS **/
@interface SwrveContentHTML : SwrveContentItem <UIWebViewDelegate>

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict;
@end
#endif
