#import "SwrveMessageDetails.h"

@implementation SwrveMessageDetails

@synthesize campaignSubject;
@synthesize campaignId;
@synthesize variantId;
@synthesize messageName;
@synthesize buttons;

- (id)initWith:(NSString *)subject campaignId:(NSUInteger)campId variantId:(NSUInteger)varId messageName:(NSString *)name buttons:(NSMutableArray *)buttonsArray {
    if (self = [super init]) {
        self.campaignSubject = subject;
        self.campaignId = campId;
        self.variantId = varId;
        self.messageName = name;
        self.buttons = buttonsArray;
    }
    return self;
}

@end
