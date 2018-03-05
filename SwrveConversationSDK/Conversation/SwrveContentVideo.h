#import "SwrveContentItem.h"

#if TARGET_OS_IOS /** exclude tvOS **/
@interface SwrveContentVideo : SwrveContentItem <UIWebViewDelegate, UIGestureRecognizerDelegate>

@property (readonly, atomic, strong) NSString *height;
@property (nonatomic) BOOL interactedWith;

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict;

@end
#endif
