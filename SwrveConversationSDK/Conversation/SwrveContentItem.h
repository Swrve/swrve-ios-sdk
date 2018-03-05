#import <Foundation/Foundation.h>
#import "SwrveConversationAtom.h"

@interface SwrveContentItem : SwrveConversationAtom <SwrveConversationAtomDelegate>

@property (readonly, nonatomic) NSString *value;

-(id) initWithTag:(NSString *)tag type:(NSString *)type andDictionary:(NSDictionary *)dict;

#if TARGET_OS_IOS /** exclude tvOS **/
+(UIScrollView*) scrollView:(UIWebView*)web;
#endif

@end
