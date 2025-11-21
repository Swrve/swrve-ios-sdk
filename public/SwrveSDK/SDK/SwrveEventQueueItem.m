#import "SwrveEventQueueItem.h"

@implementation SwrveEventQueueItem

@synthesize eventType;
@synthesize eventData;
@synthesize triggerCallback;
@synthesize notifyMessageController;

- (instancetype)initWithEventType:(NSString *)eventTypeString
                        eventData:(NSMutableDictionary *)eventDataDict
                  triggerCallback:(bool)triggerCallbackBool
          notifyMessageController:(bool)notifyMessageControllerBool {

    self = [super init];
    if (self) {
        self.eventType = eventTypeString;
        self.eventData = eventDataDict;
        self.triggerCallback = triggerCallbackBool;
        self.notifyMessageController = notifyMessageControllerBool;
    }

    return self;
}

@end
