#import <Foundation/Foundation.h>

typedef enum SwrveTriggerOperator : NSUInteger {
    SwrveTriggerOperatorAND,
    SwrveTriggerOperatorOR,
    SwrveTriggerOperatorOTHER
} SwrveTriggerOperator;

typedef enum SwrveConditionOperator : NSUInteger {
    SwrveConditionOperatorEQUALS,
    SwrveConditionOperatorOTHER
} SwrveConditionOperator;

@interface SwrveTriggerCondition : NSObject

@property (nonatomic) SwrveTriggerOperator triggerOperator;
@property (nonatomic) SwrveConditionOperator conditionOperator;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *value;

- (id) initWithDictionary:(NSDictionary *)dictionary andOperator:(NSString *) operatorKey;
- (BOOL) hasFulfilledCondition:(NSDictionary *)payload;

@end
