#import "SwrveTriggerCondition.h"

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
        _triggerOperator = [self determineSwrveOperator:operatorKey];
        _conditionOperator = [self determineSwrveOperator:[dictionary objectForKey:@"op"]];
        if(_key && _value && _conditionOperator){
            return self;
        }
    }
    return nil;
}

- (SwrveTriggerOperator) determineSwrveOperator:(NSString *)op {

    if([op isEqualToString:@"and"]){
        return SwrveTriggerOperatorAND;
    }else if([op isEqualToString:@"eq"]){
        return SwrveTriggerOperatorEQUALS;
    }else if([op isEqualToString:@"or"]){
        return SwrveTriggerOperatorOR;
    } else if([op isEqualToString:@"contains"]){
        return SwrveTriggerOperatorCONTAINS;
    } else if([op isEqualToString:@"number_eq"]){
        return SwrveTriggerOperatorNUMBER_EQUALS;
    } else if([op isEqualToString:@"number_gt"]){
        return SwrveTriggerOperatorNUMBER_GT;
    } else if([op isEqualToString:@"number_lt"]){
        return SwrveTriggerOperatorNUMBER_LT;
    } else if([op isEqualToString:@"number_not_between"]){
        return SwrveTriggerOperatorNUMBER_NOT_BETWEEN;
    } else if([op isEqualToString:@"number_between"]){
        return SwrveTriggerOperatorNUMBER_BETWEEN;
    } else{
        return SwrveTriggerOperatorOTHER;
    }
}

- (BOOL) hasFulfilledCondition:(NSDictionary *)payload {
    
    if (!payload) {
        return NO;
    }
    
    NSArray *payloadKeys = [payload allKeys];
    if ([payloadKeys containsObject:_key]) {
        if ([payload objectForKey:_key] != [NSNull null]) {
            id payloadObject = [payload objectForKey:_key];
            NSString *payloadValue = nil;
            if ([payloadObject isKindOfClass:[NSString class]]) {
                payloadValue = payloadObject;
            } else {
                if ([payloadObject respondsToSelector:@selector(stringValue)]) {
                    payloadValue = [(id)payloadObject stringValue];
                } else {
                    return NO;
                }
            }
            
            NSDictionary *valueDictionary = nil;
            NSString *valueString = nil;
            NSNumber *valueInteger = nil;
            if([_value isKindOfClass:[NSString class]]) {
                valueString = (NSString*)_value;
            } else if([_value isKindOfClass:[NSDictionary class]]) {
                valueDictionary = (NSDictionary*)_value;
            } else if([_value isKindOfClass:[NSNumber class]]) {
                valueInteger = (NSNumber*)_value;
            }

            if(_conditionOperator == SwrveTriggerOperatorCONTAINS) {
                return (payloadValue && [payloadValue localizedCaseInsensitiveContainsString:valueString]);
            } else if (_conditionOperator == SwrveTriggerOperatorEQUALS) {
                return (payloadValue && [payloadValue caseInsensitiveCompare:valueString] == NSOrderedSame);
            } else if (_conditionOperator == SwrveTriggerOperatorNUMBER_GT) {
                return (payloadValue && payloadValue.integerValue > valueInteger.integerValue);
            } else if (_conditionOperator == SwrveTriggerOperatorNUMBER_LT) {
                return (payloadValue && payloadValue.integerValue < valueInteger.integerValue);
            } else if (_conditionOperator == SwrveTriggerOperatorNUMBER_EQUALS) {
                return (payloadValue && payloadValue.integerValue == valueInteger.integerValue);
            } else if (_conditionOperator == SwrveTriggerOperatorNUMBER_BETWEEN) {
                NSNumber *lower = nil;
                NSNumber *upper = nil;
                if([valueDictionary objectForKey:@"lower"] != [NSNull null]) {
                    lower = [valueDictionary objectForKey:@"lower"];
                }
                if([valueDictionary objectForKey:@"upper"] != [NSNull null]) {
                    upper = [valueDictionary objectForKey:@"upper"];
                }
                return (valueDictionary && payloadValue.integerValue > lower.integerValue && payloadValue.integerValue < upper.integerValue);
            } else if (_conditionOperator == SwrveTriggerOperatorNUMBER_NOT_BETWEEN) {
                NSNumber *lower = nil;
                NSNumber *upper = nil;
                if([valueDictionary objectForKey:@"lower"] != [NSNull null]) {
                    lower = [valueDictionary objectForKey:@"lower"];
                }
                if([valueDictionary objectForKey:@"upper"] != [NSNull null]) {
                    upper = [valueDictionary objectForKey:@"upper"];
                }
                return (valueDictionary && (payloadValue.integerValue < lower.integerValue || payloadValue.integerValue > upper.integerValue));
            } else {
                return NO;
            }
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}


@end
