#if !__has_feature(objc_arc)
#error ConverserSDK must be built with ARC.
// You can turn on ARC for only ConverserSDK files by adding -fobjc-arc to the build phase for each of its files.
#endif

#import "SwrveConversationResponseItem.h"

@implementation SwrveConversationResponseItem

@synthesize tag;
@synthesize value;

-(id) initWithInputItem:(SwrveInputItem *)inputItem {
    self = [super init];
    if(self) {
        tag = inputItem.tag;
        value = inputItem.userResponse;
    }
    return self;
}

@end
