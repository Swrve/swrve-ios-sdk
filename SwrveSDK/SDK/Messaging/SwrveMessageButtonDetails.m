#import "SwrveMessageButtonDetails.h"

@implementation SwrveMessageButtonDetails

@synthesize buttonName;
@synthesize buttonText;
@synthesize actionType;
@synthesize actionString;

- (id)initWith:(NSString *)name buttonText:(NSString *)text actionType:(SwrveActionType)type actionString:(NSString *)action {
    if (self = [super init]) {
        self.buttonName = name;
        self.buttonText = text;
        self.actionType = type;
        self.actionString = action;
    }
    return self;
}
@end
