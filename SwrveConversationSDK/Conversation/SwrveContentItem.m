#import "SwrveContentItem.h"
#import "SwrveSetup.h"

@implementation SwrveContentItem
@synthesize value = _value;

static NSString *const kSwrveKeyValue = @"value";

-(id) initWithTag:(NSString *)tag type:(NSString *)type andDictionary:(NSDictionary *)dict {
    self = [super initWithTag:tag andType:type];
    if(self) {
        _value = [dict objectForKey:kSwrveKeyValue];
        self.delegate = self;
    }
    return self;
}
#if TARGET_OS_IOS /** exclude tvOS **/
- (void) respondToDeviceOrientationChange:(UIDeviceOrientation)orientation {
#pragma unused (orientation)
}
#endif
@end
