#import <Foundation/Foundation.h>

typedef enum SwrveTriggerOperator : NSUInteger {
    SwrveTriggerOperatorAND,
    SwrveTriggerOperatorOR,
    SwrveTriggerOperatorEQUALS,
    SwrveTriggerOperatorCONTAINS,
    SwrveTriggerOperatorOTHER
} SwrveTriggerOperator;


@interface SwrveTriggerCondition : NSObject

@property (nonatomic) SwrveTriggerOperator triggerOperator;
@property (nonatomic) SwrveTriggerOperator conditionOperator;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *value;

- (id) initWithDictionary:(NSDictionary *)dictionary andOperator:(NSString *)operatorKey;
- (BOOL) hasFulfilledCondition:(NSDictionary *)payload;

@end
