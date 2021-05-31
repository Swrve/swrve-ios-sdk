#import "Swrve.h"
#import "SwrveMessageController.h"

@interface Swrve ()

#if TARGET_OS_IOS
@property (atomic, readonly)         SwrvePush *push;
@property (atomic)                   SwrveMessageController *messaging;
#endif //TARGET_OS_IOS

- (SwrveMessageController *)messaging;
- (int)eventInternal:(NSString *)eventName payload:(NSDictionary *)eventPayload triggerCallback:(bool)triggerCallback;
- (int)queueEvent:(NSString*)eventType data:(NSMutableDictionary*)eventData triggerCallback:(bool)triggerCallback;

@end
