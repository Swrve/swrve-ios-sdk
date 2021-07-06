#import "SwrveEventsManager.h"
#if __has_include(<SwrveSDKCommon/SwrveCommon.h>)
#import <SwrveSDKCommon/SwrveCommon.h>
#import <SwrveSDKCommon/SwrveLocalStorage.h>
#else
#import "SwrveCommon.h"
#import "SwrveLocalStorage.h"
#endif
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
            [SwrveLogger error:@"Event names cannot begin with %@* This event will not be sent. Eventname:%@", restricted, eventName];
            return false;
        }
    }
    return true;
}

@end
