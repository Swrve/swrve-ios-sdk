#import "UserSettings.h"

static NSString *demoApiKeyKey = @"swrve.demoApiKey";
static NSString *demoGameIdKey = @"swrve.demoGameId";
static NSString *swrveApiKeyKey = @"swrve.swrveApiKey";
static NSString *swrveGameIdKey = @"swrve.swrveGameId";
static NSString *firstRunIdKey = @"swrve.firstTimeRunningApp";
static NSString *qaUserIdKey = @"swrve.qaUserId";
static NSString *qaUserEnabledKey = @"swrve.qaUserEnabled";

static NSString *swrveApiKey = @"VhZ4d59QKL0tRPjmBhnP";
static NSString *swrveGameId = @"415";

static NSString *demoApiKey = @"VhZ4d59QKL0tRPjmBhnP";
static NSString *demoGameId = @"415";

@implementation UserSettings

+ (void) init
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:swrveApiKey forKey:swrveApiKeyKey];
    [defaults setObject:swrveGameId forKey:swrveGameIdKey];
    
    if( [defaults objectForKey:demoApiKeyKey] == nil )
    {
        [defaults setObject:demoApiKey forKey:demoApiKeyKey];
        [defaults setObject:demoGameId forKey:demoGameIdKey];
    }
    
    if( [defaults objectForKey:qaUserIdKey] == nil )
    {
        [self setQAUserId:[self genRandStringLength:8]];
    }

    [defaults synchronize];
}

+ (BOOL) isFirstTimeRunningApp
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString* result = [defaults objectForKey:firstRunIdKey];
    
    [defaults setObject:@"true" forKey:firstRunIdKey];
    [defaults synchronize];

    return result == nil;
}

+ (NSString *) getAppApiKey;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:demoApiKeyKey];
}

+ (void) setAppApiKey:(NSString*) apiKey
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:apiKey forKey:demoApiKeyKey];
    [defaults synchronize];
}

+ (NSString *) getAppId;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:demoGameIdKey];
}

+ (void) setAppId:(NSString*) appId
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:appId forKey:demoGameIdKey];
    [defaults synchronize];
}

+ (NSString *) getSwrveAppApiKey;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:swrveApiKeyKey];
}

+ (NSString *) getSwrveAppId;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:swrveGameIdKey];
}

+ (NSString *) getQAUserId
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:qaUserIdKey];
}

+ (void) setQAUserId:(NSString*) userId
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:userId forKey:qaUserIdKey];
    [defaults synchronize];
}

+ (BOOL) getQAUserEnabled
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString* result = [defaults objectForKey:qaUserEnabledKey];
    
    return result != nil && [result isEqualToString:@"true"];
}

+ (void) setQAUserEnabled:(BOOL) enabled
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:(enabled ? @"true" : @"false") forKey:qaUserEnabledKey];
    [defaults synchronize];
}

+ (NSString *) getQAUserIdIfEnabled
{
    if( ![self getQAUserEnabled] )
    {
        return nil;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:qaUserIdKey];
}

+(NSString *) genRandStringLength: (unsigned int) len
{
    NSString *letters = @"abcdefghijklmnopqrstuvwxyz0123456789";

    NSMutableString *randomString = [NSMutableString stringWithCapacity:len];
    
    for (unsigned int i = 0; i < len; i++)
    {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random() % [letters length]]];
    }
    
    return randomString;
}


@end
