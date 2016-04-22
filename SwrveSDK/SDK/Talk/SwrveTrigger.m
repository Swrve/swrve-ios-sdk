#import "SwrveTrigger.h"
#import "SwrveTriggerCondition.h"

@implementation SwrveTrigger


@synthesize eventName = _eventName;
@synthesize conditions = _conditions;
@synthesize isValidTrigger = _isValidTrigger;

- (id) initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if(self) {
        _isValidTrigger = YES;
        _eventName = [[dictionary objectForKey:kTriggerEventNameKey] lowercaseString];
        _conditions = [self produceConditionsFromDictionary: [dictionary objectForKey:kTriggerEventConditionsKey]];
    }
    
    return self;
}

- (NSArray *) produceConditionsFromDictionary:(NSDictionary *) dictionary {
    
    NSMutableArray *resultantConditions = [[NSMutableArray alloc] init];
    
    NSString *triggerOperator = [dictionary objectForKey:@"op"];
    NSDictionary *arguments = [dictionary objectForKey:@"args"];
    
    if(!arguments){
        return nil;
    }
    
    for(NSDictionary *triggerCondition in arguments){
        
        SwrveTriggerCondition *condition = [[SwrveTriggerCondition alloc] initWithDictionary:triggerCondition andOperator:triggerOperator];
        [resultantConditions addObject:condition];
        
    }
    
    for (SwrveTriggerCondition *condition in resultantConditions){
        
        switch (condition.triggerOperator) {
            case SwrveTriggerOperatorAND:
                if([resultantConditions count] <= 1){
                    _isValidTrigger = NO;
                }
                break;
                
            case SwrveTriggerOperatorOTHER:
                if([resultantConditions count] > 1){
                    _isValidTrigger = NO;
                }
                break;
                
            default:
                break;
        }
        
        switch (condition.conditionOperator) {
            case SwrveTriggerOperatorEQUALS:
                break;
                
            case SwrveTriggerOperatorOTHER:
                _isValidTrigger = NO;
                break;
                
            default:
                _isValidTrigger = NO;
                break;
        }
    }
    
    return resultantConditions;
}

- (BOOL) canTriggerWithPayload:(NSDictionary *)payload {
    
    BOOL fulfilled = YES;
    
    if([_conditions count] > 0) {
        
        for (SwrveTriggerCondition *condition in _conditions) {
            fulfilled = [condition hasFulfilledCondition:payload];
        }
    }
    
    return fulfilled;
}

- (BOOL) isValidTrigger {
    return _isValidTrigger;
}

@end


