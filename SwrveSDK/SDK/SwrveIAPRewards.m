#import "SwrveIAPRewards.h"

#if __has_include(<SwrveSDKCommon/SwrveCommon.h>)
#import <SwrveSDKCommon/SwrveCommon.h>
#else
#import "SwrveCommon.h"
#endif

@interface SwrveIAPRewards()
@property (nonatomic, retain) NSMutableDictionary* rewards;
@end

@implementation SwrveIAPRewards
@synthesize rewards;

- (id) init
{
    self = [super init];
    self.rewards = [NSMutableDictionary new];
    return self;
}

- (void) addItem:(NSString*) resourceName withQuantity:(long) quantity
{
    [self addObject:resourceName withQuantity: quantity ofType: @"item"];
}

- (void) addCurrency:(NSString*) currencyName withAmount:(long) amount
{
    [self addObject:currencyName withQuantity:amount ofType:@"currency"];
}

- (void) addObject:(NSString*) name withQuantity:(long) quantity ofType:(NSString*) type
{
    if (![self checkArguments:name andQuantity:quantity andType:type]) {
        [SwrveLogger error:@"ERROR: SwrveIAPRewards has not been added because it received an illegal argument", nil];
        return;
    }
    
    NSDictionary* item = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithLong:quantity], @"amount", type, @"type", nil];
    [[self rewards] setValue:item forKey:name];
}

- (bool) checkArguments:(NSString*) name andQuantity:(long) quantity andType:(NSString*) type
{
    if (name == nil || [name length] <= 0) {
        [SwrveLogger error:@"SwrveIAPRewards illegal argument: reward name cannot be empty", nil];
        return false;
    }
    if (quantity <= 0) {
        [SwrveLogger error:@"SwrveIAPRewards illegal argument: reward amount must be greater than zero", nil];
        return false;
    }
    if (type == nil || [type length] <= 0) {
        [SwrveLogger error:@"SwrveIAPRewards illegal argument: type cannot be empty", nil];
        return false;
    }
    
    return true;
}

- (NSDictionary*) rewards {
    return rewards;
}

@end
