#import "SwrveContentItem.h"

#if TARGET_OS_IOS /** exclude tvOS **/
#import <WebKit/WebKit.h>

@interface SwrveContentHTML : SwrveContentItem <WKUIDelegate, WKNavigationDelegate>

- (id)initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict;

@end
#endif
