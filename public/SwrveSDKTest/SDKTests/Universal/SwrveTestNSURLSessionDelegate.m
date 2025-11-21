#import <XCTest/XCTest.h>
#import "SwrveTestHelper.h"
#import "SwrveRESTClient.h"

#if __has_include(<OCMock/OCMock.h>)
#import <OCMock/OCMock.h>
#endif

@interface SwrveTestNSURLSessionDelegate : XCTestCase

@end

@implementation SwrveTestNSURLSessionDelegate

- (void)setUp {
}

- (void)tearDown {
}

- (void)testNSURLSessionDelegate {
    id delegate = OCMProtocolMock(@protocol(NSURLSessionDelegate));
    id urlsessionmock = OCMClassMock([NSURLSession class]);
    
    OCMStub([urlsessionmock dataTaskWithRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
    OCMExpect([urlsessionmock sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                              delegate:delegate
                                         delegateQueue:NSOperationQueue.mainQueue]);
    
    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
    restClient.urlSessionDelegate = delegate;
    id mockRestClient = OCMPartialMock(restClient);

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"someurl"]  cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60];
    [mockRestClient sendHttpRequest:request completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
    }];
    
    OCMVerifyAll(urlsessionmock);
}

- (void)testNSURLSessionDelegateNil {
    id delegate = OCMProtocolMock(@protocol(NSURLSessionDelegate));
    id urlsessionmock = OCMClassMock([NSURLSession class]);
    
    OCMStub([urlsessionmock dataTaskWithRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
    OCMReject([urlsessionmock sessionWithConfiguration:OCMOCK_ANY
                                              delegate:delegate
                                         delegateQueue:OCMOCK_ANY]);
    OCMExpect([urlsessionmock sharedSession]);
    
    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
    id mockRestClient = OCMPartialMock(restClient);

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"someurl"]  cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60];
    [mockRestClient sendHttpRequest:request completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
    }];
    
    OCMVerifyAll(urlsessionmock);
}

@end
