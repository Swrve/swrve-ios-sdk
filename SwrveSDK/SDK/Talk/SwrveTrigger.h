#import <Foundation/Foundation.h>

#define kTriggerEventNameKey @"event_name"
#define kTriggerEventConditionsKey @"conditions"

@interface SwrveTrigger : NSObject

@property (nonatomic, readonly) NSString *eventName;
@property (nonatomic) NSArray *conditions;
@property (nonatomic, readwrite) BOOL isValidTrigger;


- (id) initWithDictionary:(NSDictionary *)dictionary;
- (BOOL) canTriggerWithPayload:(NSDictionary *)payload;

@end
