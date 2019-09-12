#import "SwrveContentItem.h"

#if TARGET_OS_IOS /** exclude tvOS **/
#import <WebKit/WebKit.h>

@interface SwrveContentVideo : SwrveContentItem <WKUIDelegate, WKNavigationDelegate, UIGestureRecognizerDelegate>

@property (readonly, nonatomic) float height;
@property (nonatomic) BOOL interactedWith;

- (id)initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict;

@end
#endif
