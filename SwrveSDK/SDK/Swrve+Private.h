#if __has_include(<SwrveSDK/Swrve.h>)
#import <SwrveSDK/Swrve.h>
#import <SwrveSDK/SwrveMessageController.h>
#else
#import "Swrve.h"
#import "SwrveMessageController.h"
#endif

@interface Swrve ()

#if TARGET_OS_IOS
@property (atomic, readonly)         SwrvePush *push;
@property (atomic)                   SwrveMessageController *messaging;
#endif //TARGET_OS_IOS

- (SwrveMessageController *)messaging;
- (int)eventInternal:(NSString *)eventName payload:(NSDictionary *)eventPayload triggerCallback:(bool)triggerCallback;
- (int)queueEvent:(NSString*)eventType data:(NSMutableDictionary*)eventData triggerCallback:(bool)triggerCallback;
- (NSString *)signatureKey;
- (void)invokeCampaignsUpdatedDelegate;

@end
