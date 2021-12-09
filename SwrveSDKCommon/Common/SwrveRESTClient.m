#import "SwrveRESTClient.h"
#import "SwrveCommon.h"

@implementation SwrveRESTClient

@synthesize timeoutInterval;
@synthesize urlSessionDelegate;

- (id)initWithTimeoutInterval:(NSTimeInterval)timeoutInt {
    return [self initWithTimeoutInterval:timeoutInt urlSessionDelegate:nil];
}

- (id)initWithTimeoutInterval:(NSTimeInterval)timeoutInt urlSessionDelegate:(id <NSURLSessionDelegate>)nsurlSessionDelegate {
    self = [super init];
    if (self) {
        [self setTimeoutInterval:timeoutInt];
        self.urlSessionDelegate = nsurlSessionDelegate;
    }
    return self;
}

- (void)sendHttpGETRequest:(NSURL *)url queryString:(NSString *)query {
    [self sendHttpGETRequest:url queryString:query completionHandler:nil];
}

- (void)sendHttpGETRequest:(NSURL *)url {
    [self sendHttpGETRequest:url completionHandler:nil];
}

- (void)sendHttpGETRequest:(NSURL *)baseUrl queryString:(NSString *)query completionHandler:(void (^)(NSURLResponse *, NSData *, NSError *))handler {
    NSURL *url = [NSURL URLWithString:query relativeToURL:baseUrl];
    [self sendHttpGETRequest:url completionHandler:handler];
}

- (void)sendHttpGETRequest:(NSURL *)url completionHandler:(void (^)(NSURLResponse *, NSData *, NSError *))handler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:timeoutInterval];
    if (handler == nil) {
        [request setHTTPMethod:@"HEAD"];
    } else {
        [request setHTTPMethod:@"GET"];
    }
    [self sendHttpRequest:request completionHandler:handler];
}

- (void)sendHttpPOSTRequest:(NSURL *)url jsonData:(NSData *)json {
    [self sendHttpPOSTRequest:url jsonData:json completionHandler:nil];
}

- (void)sendHttpPOSTRequest:(NSURL*)url jsonData:(NSData*)json completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:timeoutInterval];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:json];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long) [json length]] forHTTPHeaderField:@"Content-Length"];

    [self sendHttpRequest:request completionHandler:handler];
}

- (void)sendHttpRequest:(NSMutableURLRequest *)request completionHandler:(void (^)(NSURLResponse *, NSData *, NSError *))handler API_AVAILABLE(ios(7.0)) {
    NSURLSession *session = nil;
    id<NSURLSessionDelegate> del = self.urlSessionDelegate;
    if (del) {
        session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                delegate:del
                                           delegateQueue:NSOperationQueue.mainQueue];
    } else {
        session = [NSURLSession sharedSession];
    }
        
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(response, data, error);
        });
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        [task resume];
    });
}

@end
