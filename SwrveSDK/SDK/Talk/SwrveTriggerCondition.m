#import "SwrveTriggerCondition.h"

static const NSString *andOperator = @"and";

@implementation SwrveTriggerCondition

@synthesize key = _key;
@synthesize value = _value;
@synthesize triggerOperator = _triggerOperator;
@synthesize conditionOperator = _conditionOperator;

- (id) initWithDictionary:(NSDictionary *)dictionary andOperator:(NSString *) operatorKey {
    self = [super init];
    if(self) {
        
        _key = [dictionary objectForKey:@"key"];
        _value = [dictionary objectForKey:@"value"];
        _triggerOperator = [self determineOperator:operatorKey];
        _conditionOperator = [self determineConditionOperator:[dictionary objectForKey:@"op"]];
        
    }
    
    return self;
}

- (SwrveTriggerOperator) determineOperator:(NSString *)operator {

    if([operator isEqualToString:[NSString stringWithFormat:@"%@", andOperator]]){
        return SwrveTriggerOperatorAND;
    }else{
        return SwrveTriggerOperatorOTHER;
    }
}

- (SwrveConditionOperator) determineConditionOperator:(NSString *)operator {
    
    if([operator isEqualToString:@"eq"]){
        return SwrveConditionOperatorEQUALS;
    }else{
        return SwrveConditionOperatorOTHER;
    }
    
}

- (BOOL) hasFulfilledCondition:(NSDictionary *)payload {
    
    NSArray *payloadKeys = [payload allKeys];
    
    if([payloadKeys containsObject:_key]){
        NSString *payloadValue = [payload objectForKey:_key];
        return ([payloadValue isEqualToString:_value]);
    }else{
        return NO;
    }
}


@end
