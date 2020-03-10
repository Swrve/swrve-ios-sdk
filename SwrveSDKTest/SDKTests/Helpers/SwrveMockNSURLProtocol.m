#import "SwrveMockNSURLProtocol.h"
#import "SwrveSDK.h"

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
    NSDictionary * headers = @{@"Content-Type" : @"application/json; charset=utf-8"};
    NSHTTPURLResponse* fakeResponse = [[NSHTTPURLResponse alloc]initWithURL:self.request.URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:headers];
    
    if ([self.request.URL.absoluteString containsString:@"logo"]) {
        NSString *str= [[NSBundle mainBundle] pathForResource:@"logo" ofType:@"gif"];
        fakeData = [NSData dataWithContentsOfFile:str];
    }
    else if ([self.request.URL.absoluteString containsString:@"user_resource"]) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"campaignsNone" ofType:@"json"];
        fakeData  = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
        NSDictionary *jsonObject=[NSJSONSerialization
                                  JSONObjectWithData:fakeData
                                  options:NSJSONReadingMutableLeaves
                                  error:nil];
        NSLog(@"jsonObject is %@",jsonObject);
    }
    else if ([self.request.URL.absoluteString containsString:@"ExternalUser1"]) {
        NSString *emptyJson = @"{ \"swrve_id\":\"SwrveUser1\"}";
        fakeData = [emptyJson dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    else if ([self.request.URL.absoluteString containsString:@"500"]) {
            NSString *emptyJson = @"{}";
            fakeData = [emptyJson dataUsingEncoding:NSUTF8StringEncoding];
            fakeResponse = [[NSHTTPURLResponse alloc]initWithURL:self.request.URL statusCode:500 HTTPVersion:@"HTTP/1.1" headerFields:headers];
            
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey: NSLocalizedString(@"Operation was unsuccessful.", nil),
                                       NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The operation timed out.", nil),
                                       NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Have you tried turning it off and on again?", nil)
                                       };
            error = [NSError errorWithDomain:@"Swrve" code:500 userInfo:userInfo];
            
            fakeResponse = [[NSHTTPURLResponse alloc]initWithURL:self.request.URL statusCode:500 HTTPVersion:@"HTTP/1.1" headerFields:headers];
        
        if (self.request.HTTPBody != nil) {
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:self.request.HTTPBody options:0 error:&error];
            NSLog(@"500 Body: %@",jsonDict);
        }
    }
    else {
        fakeData = [NSData dataWithContentsOfFile:emptyJson];
    }
    
    [self.client URLProtocol:self didReceiveResponse:fakeResponse cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [self.client URLProtocol:self didLoadData:fakeData];
    [self.client URLProtocolDidFinishLoading:self];
}

@end
