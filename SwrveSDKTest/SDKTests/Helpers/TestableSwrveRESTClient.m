#import "TestableSwrveRESTClient.h"

@implementation TestableSwrveRESTClient

@synthesize savedRequests;
@synthesize savedResponses;
@synthesize failPostRequests;

/**
 * Method overrides
 */

- (void)initializeRequests {
    if (self.savedRequests == nil) {
        [self setSavedRequests:[[NSMutableDictionary alloc] init]];
    }

    if (self.savedResponses == nil) {
        [self setSavedResponses:[[NSMutableDictionary alloc] init]];
    }
}

- (void)sendHttpPOSTRequest:(NSURL *)url jsonData:(NSData *)json completionHandler:(void (^)(NSURLResponse *, NSData *, NSError *))handler {
//    if ([[self typeFromURL:url] isEqual:@"event"]) {
//        [self setEventsSending:YES];
//    }

    [self saveRequest:url withData:json];

    if (self.failPostRequests) {
        handler(nil, nil, [NSError errorWithDomain:@"swrve" code:-111 userInfo:nil]);
    } else {
        void (^testableCompletionHandler)(NSURLResponse *, NSData *, NSError *) = ^(NSURLResponse *response, NSData *data, NSError *error) {
            if ([[self typeFromURL:url] isEqual:@"event"]) {
//                [self setEventsSending:NO];
            }
            [self saveResponse:url withData:data withResponse:response];
            handler(response, data, error);
        };

        [super sendHttpPOSTRequest:url jsonData:json completionHandler:testableCompletionHandler];
    }
}

- (void)sendHttpGETRequest:(NSURL *)url completionHandler:(void (^)(NSURLResponse *, NSData *, NSError *))handler {
    [self saveRequest:url];

    void (^originalHandler)(NSURLResponse *, NSData *, NSError *) = [handler copy];
    void (^testableCompletionHandler)(NSURLResponse *, NSData *, NSError *) = ^(NSURLResponse *response, NSData *data, NSError *error) {
        [self saveResponse:url withData:data withResponse:response];
        if (originalHandler) {
            originalHandler(response, data, error);
        }
    };

    [super sendHttpGETRequest:url completionHandler:[testableCompletionHandler copy]];
}

- (NSArray *)eventRequests {
    return [self requestsOfType:@"eventRequests"];
}

- (void)saveRequest:(NSURL *)url {
    [self saveRequest:url withData:nil];
}

- (void)saveRequest:(NSURL *)url withData:(NSData *)json {
    NSString *requestType = [self typeFromURL:url];
    if (!requestType) {
        return;
    }

    requestType = [NSString stringWithFormat:@"%@%@", requestType, @"Requests"];

    [self initializeRequests];
    @synchronized ([self savedRequests]) {
        NSMutableArray *requestsForType = [[self savedRequests] valueForKey:requestType];
        if (requestsForType == nil) {
            requestsForType = [[NSMutableArray alloc] init];
        }

        NSString *requestEntry = [url absoluteString];
        if (json) {
            NSString *jsonString = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
            requestEntry = [[NSString alloc] initWithFormat:@"%@ %@", requestEntry, jsonString];

        }

        [requestsForType addObject:requestEntry];
        [[self savedRequests] setValue:requestsForType forKey:requestType];
    }
}

- (void)saveResponse:(NSURL *)url withData:(NSData *)data withResponse:(NSURLResponse *)response {
    NSString *responseType = [self typeFromURL:url];
    if (!responseType) {
        return;
    }

    responseType = [NSString stringWithFormat:@"%@%@", responseType, @"Responses"];

    [self initializeRequests];
    @synchronized ([self savedResponses]) {
        NSMutableArray *responsesForType = [[self savedResponses] valueForKey:responseType];
        if (responsesForType == nil) {
            responsesForType = [[NSMutableArray alloc] init];
        }

        NSInteger statusCode = 0;
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            statusCode = [(NSHTTPURLResponse *) response statusCode];
        }
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        NSString *responseEntry = [NSString stringWithFormat:@"%@ Status code:%ld Response data:%@", [url absoluteString], (long) statusCode, responseString];
        [responsesForType addObject:responseEntry];

        [[self savedResponses] setValue:responsesForType forKeyPath:responseType];
    }
}

- (NSString *)typeFromURL:(NSURL *)url {
    NSString *requestType;

    if ([[url absoluteString] rangeOfString:@"1/batch"].location != NSNotFound) {
        requestType = @"event";
    } else if ([[url absoluteString] rangeOfString:@"api/1/user_content"].location != NSNotFound) {
        requestType = @"campaignsAndResources";
    } else if ([[url host] hasSuffix:@".qa-log.swrve.com"]) {
        requestType = @"talkQA";
    }

    return requestType;
}

- (NSArray *)requestsOfType:(NSString *)type {
    NSArray *requests = [[self savedRequests] valueForKey:type];
    if (requests != nil) {
        return requests;
    }

    return [[NSArray alloc] init];
}

@end
