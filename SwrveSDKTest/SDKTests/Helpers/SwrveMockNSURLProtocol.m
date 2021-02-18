#import "SwrveMockNSURLProtocol.h"
#import "SwrveCommon.h"
#import "SwrveSDK.h"
#import "SwrveEventQueueItem.h"

@interface Swrve()
- (void)switchUser:(NSString *)newUserID isFirstSession:(BOOL)isFirstSession;
- (void)maybeFlushToDisk;
@property(atomic) NSMutableArray *pausedEventsArray;
@end

@implementation SwrveMockNSURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if ([NSURLProtocol propertyForKey:@"URLProtocolHandledKey" inRequest:request]) {
        return NO;
    }
    
    static NSUInteger requestCount = 0;
    NSLog(@"Request #%lu: URL = %@", (unsigned long)requestCount++, request);
    
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (void)stopLoading {
    
}

- (void)startLoading {
    NSMutableURLRequest *newRequest = [self.request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:@"MyURLProtocolHandledKey" inRequest:newRequest];
    
    //Default is 200 with an empty response, add to the if statements below to override.
    NSData *fakeData = nil;
    NSError *error = nil;
    NSString *emptyJson = @"{}";
    NSData *httpBody = nil;
    NSDictionary * headers = @{@"Content-Type" : @"application/json; charset=utf-8"};
    NSHTTPURLResponse* fakeResponse = [[NSHTTPURLResponse alloc]initWithURL:self.request.URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:headers];
    
    NSInputStream *stream = self.request.HTTPBodyStream;
    uint8_t byteBuffer[4096];

    [stream open];
    if (stream.hasBytesAvailable) {
        
        NSInteger bytesRead = [stream read:byteBuffer maxLength:sizeof(byteBuffer)];
        NSString *dataString = [[NSString alloc] initWithBytes:byteBuffer length:(NSUInteger)bytesRead encoding:NSUTF8StringEncoding];
        httpBody = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    }
    [stream close];
    
    if ([self.request.URL.absoluteString containsString:@"SwitchUserID"]) {
        Swrve *swrve = [SwrveSDK sharedInstance];
        dispatch_async(dispatch_get_main_queue(), ^{
            [swrve switchUser:@"SwrveUser0" isFirstSession:true];
        });
    }
    
    if ([self.request.URL.absoluteString containsString:@"IdentifyBody"]) {
        
        NSDictionary *httpBodyDic = [self getBodyDic:httpBody];
        
        NSDictionary *expected = @{  @"swrve_id" : @"SwrveUser0",
                                     @"external_user_id" : @"ExternalID",
                                     @"unique_device_id" : [SwrveCommon sharedInstance].deviceUUID,
                                     @"api_key" : [SwrveCommon sharedInstance].apiKey};
        
        assert([httpBodyDic isEqualToDictionary:expected]);
        
    }
    
    if ([self.request.URL.absoluteString containsString:@"logo"]) {
        NSString *str= [[NSBundle mainBundle] pathForResource:@"logo" ofType:@"gif"];
        fakeData = [NSData dataWithContentsOfFile:str];
    }
    
    if ([self.request.URL.absoluteString containsString:@"batch"]) {
        emptyJson = @"{}";
        fakeData = [emptyJson dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    if ([self.request.URL.absoluteString containsString:@"user_resource"]) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsIdentity" ofType:@"json"];
        fakeData  = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
    }

    if ([self.request.URL.absoluteString containsString:@"QueueEventWhileIdentifying"]) {
        [self assertEventWhileIdentifying];
        emptyJson = @"{}";
        fakeData = [emptyJson dataUsingEncoding:NSUTF8StringEncoding];
    }

    if ([self.request.URL.absoluteString containsString:@"Queue500EventWhileIdentifying"]) {
        [self assertEventWhileIdentifying];
        [self mock500Response];
        return;
    }

    if ([self.request.URL.absoluteString containsString:@"ReturnSameUserId"]) {
        NSDictionary *httpBodyDic = [self getBodyDic:httpBody];
        emptyJson = [NSString stringWithFormat:@"{ \"swrve_id\":\"%@\" }",[httpBodyDic valueForKey:@"swrve_id"]];
        fakeData = [emptyJson dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    if ([self.request.URL.absoluteString containsString:@"User1"]) {
        emptyJson = @"{ \"swrve_id\":\"SwrveUser1\" }";
        fakeData = [emptyJson dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    if ([self.request.URL.absoluteString containsString:@"User2"]) {
        emptyJson = @"{ \"swrve_id\":\"SwrveUser2\" }";
        fakeData = [emptyJson dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    if ([self.request.URL.absoluteString containsString:@"User3"]) {
        emptyJson = @"{ \"swrve_id\":\"SwrveUser3\" }";
        fakeData = [emptyJson dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    if ([self.request.URL.absoluteString containsString:@"email"]) {
        emptyJson = @"{ \"Message\":\"Sorry you can't use an email address\" }";
        fakeData = [emptyJson dataUsingEncoding:NSUTF8StringEncoding];
        fakeResponse = [[NSHTTPURLResponse alloc]initWithURL:self.request.URL statusCode:400 HTTPVersion:@"HTTP/1.1" headerFields:headers];
    }
    
    if ([self.request.URL.absoluteString containsString:@"200"]) {
        emptyJson = @"{}";
        fakeData = [emptyJson dataUsingEncoding:NSUTF8StringEncoding];
        
        if (httpBody != nil) {
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:httpBody options:0 error:nil];
            NSLog(@"200 Body: %@",jsonDict);
        }
        
    }
    if ([self.request.URL.absoluteString containsString:@"500"]) {
        [self mock500Response];
        return;
    }
    
    if ([self.request.URL.absoluteString containsString:@"SwrveError"]) {
        emptyJson = @"{ \"code\" : 404, \"message\" : \"Unknown Route\"}";
        fakeData = [emptyJson dataUsingEncoding:NSUTF8StringEncoding];
        fakeResponse = [[NSHTTPURLResponse alloc]initWithURL:self.request.URL statusCode:404 HTTPVersion:@"HTTP/1.1" headerFields:headers];
    }
    
    if ([self.request.URL.absoluteString containsString:@"Email"]) {
        emptyJson = @"{ \"code\" : 403, \"message\" : \"Attempted to use PII (eg email) as external ID\"}";
        fakeData = [emptyJson dataUsingEncoding:NSUTF8StringEncoding];
        fakeResponse = [[NSHTTPURLResponse alloc]initWithURL:self.request.URL statusCode:403 HTTPVersion:@"HTTP/1.1" headerFields:headers];
    }
    
    [self.client URLProtocol:self didReceiveResponse:fakeResponse cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [self.client URLProtocol:self didLoadData:fakeData];
    [self.client URLProtocolDidFinishLoading:self];
}

- (NSDictionary *)getBodyDic:(NSData *)httpBody {
    
    if (httpBody == nil) return nil;
    
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:httpBody
                                                           options:NSJSONReadingAllowFragments
                                                             error:nil];
    return result;
}

- (void)assertEventWhileIdentifying {

    Swrve *swrve = [SwrveSDK sharedInstance];
    [swrve event:@"TestEventWhileIdentifying500"];

    bool containsTestEvent = NO;
    for (id queueItem in [swrve pausedEventsArray]) {
        NSMutableDictionary *eventData = ((SwrveEventQueueItem *) queueItem).eventData;
        if ([[eventData objectForKey:@"name"] isEqual:@"TestEventWhileIdentifying500"]) {
            containsTestEvent = YES;
            break;
        }
    }
    if (containsTestEvent == NO) {
        NSLog(@"assertEventWhileIdentifying: failed to add test event onto the pausedEventsArray queue while identiying.");
    }
    assert(containsTestEvent == YES);
}

- (void)mock500Response {

    NSString *emptyJson = @"{}";
    NSData *fakeData  = [emptyJson dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary * headers = @{@"Content-Type" : @"application/json; charset=utf-8"};
    NSHTTPURLResponse* fakeResponse = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL statusCode:500 HTTPVersion:@"HTTP/1.1" headerFields:headers];

    NSDictionary *userInfo = @{
            NSLocalizedDescriptionKey: NSLocalizedString(@"Operation was unsuccessful.", nil),
            NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The operation timed out.", nil),
            NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Have you tried turning it off and on again?", nil)
    };
    NSError *error = [NSError errorWithDomain:@"Swrve" code:500 userInfo:userInfo];

    [self.client URLProtocol:self didReceiveResponse:fakeResponse cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [self.client URLProtocol:self didLoadData:fakeData];
    [self.client URLProtocol:self didFailWithError:error];
    [self.client URLProtocolDidFinishLoading:self];
}

@end
