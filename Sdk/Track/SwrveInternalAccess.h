#import "Swrve.h"

@interface Swrve (SwrveInternalAccess)

- (int)eventInternal:(NSString *)eventName payload:(NSDictionary *)eventPayload triggerCallback:(bool)triggerCallback;

@end
