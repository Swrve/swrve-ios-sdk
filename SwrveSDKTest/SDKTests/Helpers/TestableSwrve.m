#import "TestableSwrve.h"
#import "TestableSwrveRESTClient.h"

@implementation TestableSwrve

@synthesize customNowDate;
@synthesize customTimeSeconds;
@synthesize resourceUpdaterEnabled;
#if TARGET_OS_IOS /** exclude tvOS **/
@synthesize carrier;
#endif //TARGET_OS_IOS


+ (TestableSwrve*) sharedInstanceWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey
{
    TestableSwrve* instance = [TestableSwrve alloc];
    [SwrveSDK resetSwrveSharedInstance];
    [SwrveSDK addSharedInstance:instance];

    SwrveConfig *newConfig = [[SwrveConfig alloc] init];
    return [instance initWithAppID:swrveAppID apiKey:swrveAPIKey config:newConfig];
}

+(TestableSwrve*) sharedInstanceWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey config:(SwrveConfig*)swrveConfig
{
    TestableSwrve* instance = [TestableSwrve alloc];
    [SwrveSDK resetSwrveSharedInstance];
    [SwrveSDK addSharedInstance:instance];

    return [instance initWithAppID:swrveAppID apiKey:swrveAPIKey config:swrveConfig];
}

+ (TestableSwrve*) sharedInstanceWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey config:(SwrveConfig*)swrveConfig customNow:(NSDate*)customNow
{
    TestableSwrve* instance = [TestableSwrve alloc];
    [instance setCustomNowDate:customNow];
    [SwrveSDK resetSwrveSharedInstance];
    [SwrveSDK addSharedInstance:instance];

    return [instance initWithAppID:swrveAppID apiKey:swrveAPIKey config:swrveConfig];
}

#pragma mark - time mocking methods

- (NSDate*) getNow
{
    if ([self customNowDate]) {
        return [self customNowDate];
    }
    
    return [super getNow];
}

- (UInt64) getTime {
    
    if (self.customTimeSeconds != 0) {
        return self.customTimeSeconds;
    }
    
    return [super getTime];
}

- (UInt64) secondsSinceEpoch {
    
    if (self.customTimeSeconds != 0) {
        return self.customTimeSeconds;
    }
    
    return [super secondsSinceEpoch];
}

#pragma mark - private methods

- (void)initSwrveRestClient: (NSTimeInterval)timeOut{
    TestableSwrveRESTClient *restClient = [[TestableSwrveRESTClient alloc] initWithTimeoutInterval:timeOut];
    [restClient initializeRequests];
    [self setRestClient:restClient];
}


- (void)initSwrveRestClient:(NSTimeInterval)timeOut urlSssionDelegate:(id <NSURLSessionDelegate>)urlSssionDelegate {
    TestableSwrveRESTClient *restClient = [[TestableSwrveRESTClient alloc] initWithTimeoutInterval:timeOut urlSessionDelegate:urlSssionDelegate];
    [restClient initializeRequests];
    [self setRestClient:restClient];
}

@end
