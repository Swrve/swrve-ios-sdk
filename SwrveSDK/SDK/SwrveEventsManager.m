#import "SwrveEventsManager.h"
#import "SwrveLocalStorage.h"
#import "Swrve.h"


@interface SwrveEventsManager () {
    id <SwrveCommonDelegate> swrveCommon;
}
@end

@implementation SwrveEventsManager

- (id)initWithDelegate:(id <SwrveCommonDelegate>)swrveCommonDelegate {
    if (self = [super init]) {
        swrveCommon = swrveCommonDelegate;
    }
    return self;
}

- (BOOL)isValidEventName:(NSString *)eventName {
    
    NSMutableArray *restrictedNamesStartWith = [NSMutableArray arrayWithObjects:@"Swrve.", @"swrve.", nil];
    for (NSString *restricted in restrictedNamesStartWith) {
        if (eventName == nil || [eventName hasPrefix:restricted]) {
            DebugLog(@"Event names cannot begin with %@* This event will not be sent. Eventname:%@", restricted, eventName);
            return false;
        }
    }
    return true;
}

@end
