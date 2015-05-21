#if !__has_feature(objc_arc)
#error ConverserSDK must be built with ARC.
// You can turn on ARC for only ConverserSDK files by adding -fobjc-arc to the build phase for each of its files.
#endif

#import "SwrveConversationResponse.h"

@implementation SwrveConversationResponse {
    NSMutableArray *_mutableResponseItems;
}

@synthesize control;

-(id) initWithControl:(NSString *)pcontrol {
    self = [super init];
    if(self) {
        control = [pcontrol copy];
        _mutableResponseItems = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void) addResponseItem:(SwrveConversationResponseItem *)item {
    if([_mutableResponseItems containsObject:item]) {
        return;
    }
    [_mutableResponseItems addObject:item];
}

-(NSArray *)responseItems {
    return [NSArray arrayWithArray:_mutableResponseItems];
}

@end
