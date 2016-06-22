#import <Foundation/Foundation.h>
#import "SwrveConversationAtom.h"

@interface SwrveContentItem : SwrveConversationAtom <SwrveConversationAtomDelegate>

@property (readonly, nonatomic) NSString *value;

-(id) initWithTag:(NSString *)tag type:(NSString *)type andDictionary:(NSDictionary *)dict;
-(void) respondToDeviceOrientationChange:(UIDeviceOrientation)orientation;

+(UIScrollView*) scrollView:(UIWebView*)web;

@end
