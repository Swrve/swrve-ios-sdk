#import "Swrve.h"

@interface Swrve (SwrveInternalAccess)

- (int)eventInternal:(NSString *)eventName payload:(NSDictionary *)eventPayload triggerCallback:(bool)triggerCallback;
- (int)locationImpressionEvent:(int)messageId;
- (int)locationEngagedEvent:(int)messageId;

@end
