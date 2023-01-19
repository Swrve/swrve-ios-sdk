#import <Foundation/Foundation.h>

typedef enum SwrveTriggerOperator : NSUInteger {
    SwrveTriggerOperatorAND,
    SwrveTriggerOperatorOR,
    SwrveTriggerOperatorEQUALS,
    SwrveTriggerOperatorCONTAINS,
    SwrveTriggerOperatorNUMBER_GT,
    SwrveTriggerOperatorNUMBER_LT,
    SwrveTriggerOperatorNUMBER_EQUALS,
    SwrveTriggerOperatorNUMBER_BETWEEN,
    SwrveTriggerOperatorNUMBER_NOT_BETWEEN,
    SwrveTriggerOperatorOTHER
} SwrveTriggerOperator;


@interface SwrveTriggerCondition : NSObject

@property (nonatomic) SwrveTriggerOperator triggerOperator;
@property (nonatomic) SwrveTriggerOperator conditionOperator;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSObject *value;

- (id) initWithDictionary:(NSDictionary *)dictionary andOperator:(NSString *)operatorKey;
- (BOOL) hasFulfilledCondition:(NSDictionary *)payload;

@end
