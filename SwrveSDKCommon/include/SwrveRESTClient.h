#import <Foundation/Foundation.h>

@interface SwrveRESTClient : NSObject

@property(atomic) NSTimeInterval timeoutInterval;

- (id)initWithTimeoutInterval:(NSTimeInterval)timeoutInterval;

- (void)sendHttpGETRequest:(NSURL *)url queryString:(NSString *)query;

- (void)sendHttpGETRequest:(NSURL *)url;

- (void)sendHttpGETRequest:(NSURL *)baseUrl queryString:(NSString *)query completionHandler:(void (^)(NSURLResponse *, NSData *, NSError *))handler;

- (void)sendHttpGETRequest:(NSURL *)url completionHandler:(void (^)(NSURLResponse *, NSData *, NSError *))handler;

- (void)sendHttpPOSTRequest:(NSURL *)url jsonData:(NSData *)json;

- (void)sendHttpPOSTRequest:(NSURL *)url jsonData:(NSData *)json completionHandler:(void (^)(NSURLResponse *, NSData *, NSError *))handler;

- (void)sendHttpRequest:(NSMutableURLRequest *)request completionHandler:(void (^)(NSURLResponse *, NSData *, NSError *))handler;

@end

