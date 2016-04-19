
#import "SwrveTrigger.h"
#import "SwrveTriggerCondition.h"

@implementation SwrveTrigger

@synthesize eventName = _eventName;
@synthesize conditions = _conditions;

- (id) initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if(self) {
        _eventName = [[dictionary objectForKey:kTriggerEventNameKey] lowercaseString];
        _conditions = [self produceConditionsFromDictionary:dictionary];
    }
    
    return self;
}

- (NSArray *) produceConditionsFromDictionary:(NSDictionary *) dictionary {
    
    NSString *triggerOperator = [dictionary objectForKey:@"op"];
    NSDictionary *conditionsDictionary = [dictionary objectForKey:kTriggerEventConditionsKey];
    NSDictionary *arguments = [conditionsDictionary objectForKey:@"args"];
    
    NSMutableArray *resultantConditions = [[NSMutableArray alloc] init];
    
    for(NSDictionary *singleCondition in arguments){
        
        SwrveTriggerCondition *condition = [[SwrveTriggerCondition alloc] initWithDictionary:singleCondition andOperator:triggerOperator];
        [resultantConditions addObject:condition];
    }
    
    return resultantConditions;
}

- (BOOL) hasFufilledAllConditions:(NSDictionary *)payload {
    
    BOOL fulfilled = YES;
    
    if([_conditions count] > 0){
    
        for (SwrveTriggerCondition *condition in _conditions){
            fulfilled = [condition hasFulfilledCondition:payload];
        }
    }
    
    return fulfilled;
}

@end


