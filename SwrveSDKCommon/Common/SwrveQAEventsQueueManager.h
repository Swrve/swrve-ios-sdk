#import <Foundation/Foundation.h>
#import "SwrveEvents.h"
#import "SwrveLocalStorage.h"

NS_ASSUME_NONNULL_BEGIN

@interface SwrveQAEventsQueueManager : NSObject

- (instancetype)initWithSessionToken:(NSString *) sessionToken;
- (void)queueEvent:(NSMutableDictionary *)qalogevent;
- (void)flushEvents;

@end

NS_ASSUME_NONNULL_END
