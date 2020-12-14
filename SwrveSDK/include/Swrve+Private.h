#import "Swrve.h"

@interface Swrve ()

#if !defined(SWRVE_NO_PUSH) && TARGET_OS_IOS
@property (atomic, readonly)         SwrvePush *push;
#endif //!defined(SWRVE_NO_PUSH)

- (int)eventInternal:(NSString *)eventName payload:(NSDictionary *)eventPayload triggerCallback:(bool)triggerCallback;
- (int)queueEvent:(NSString*)eventType data:(NSMutableDictionary*)eventData triggerCallback:(bool)triggerCallback;

@end
