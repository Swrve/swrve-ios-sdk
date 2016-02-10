#import "SwrveContentItem.h"

//#define SWRVE_NO_PHOTO_CAMERA

@interface SwrveContentVideo : SwrveContentItem <UIWebViewDelegate, UIGestureRecognizerDelegate>

@property (readonly, atomic, strong) NSString *height;
@property (nonatomic) BOOL interactedWith;

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict;

@end
