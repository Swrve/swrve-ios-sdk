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

            if(_conditionOperator == SwrveTriggerOperatorCONTAINS) {
                return (payloadValue && [payloadValue localizedCaseInsensitiveContainsString:_value]);
            } else if (_conditionOperator == SwrveTriggerOperatorEQUALS) {
                return (payloadValue && [payloadValue caseInsensitiveCompare:_value] == NSOrderedSame);
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
