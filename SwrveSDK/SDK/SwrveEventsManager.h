#import <Foundation/Foundation.h>

@protocol SwrveCommonDelegate;
@class SwrveConfig;
@class ImmutableSwrveConfig;

@interface SwrveEventsManager : NSObject

- (id)initWithDelegate:(id <SwrveCommonDelegate>)swrveCommon;
- (BOOL) isValidEventName:(NSString *)eventName;

@end
