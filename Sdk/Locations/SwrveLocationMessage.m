#import <AVFoundation/AVFoundation.h>
#import "SwrveLocationMessage.h"

@implementation SwrveLocationMessage

@synthesize locationMessageId;
@synthesize body;

- (id)initWithDictionary:(NSDictionary *)dictionary {

    if (self = [super init]) {
        locationMessageId = [dictionary objectForKey:@"id"];
        body = [dictionary objectForKey:@"body"];
    }

    return self;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.locationMessageId=%@", self.locationMessageId];
    [description appendFormat:@", self.body=%@", self.body];
    [description appendString:@">"];
    return description;
}

@end
