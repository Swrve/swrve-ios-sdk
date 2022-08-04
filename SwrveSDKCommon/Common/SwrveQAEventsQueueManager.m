#import "SwrveQAEventsQueueManager.h"
#import "SwrveCommon.h"
#import "SwrveRESTClient.h"

@interface SwrveQAEventsQueueManager ()

@property(atomic) NSMutableArray  *queue;
@property(atomic) SwrveRESTClient *restClient;
@property(nonatomic) NSString     *sessionToken;
@property(atomic) NSTimer         *flushTimer;

@end

@implementation SwrveQAEventsQueueManager

@synthesize queue = _queue;
@synthesize restClient = _restClient;
@synthesize sessionToken = _sessionToken;
@synthesize flushTimer = _flushTimer;

double queueQAFlushDelay = 4.0;
// The keys below are the same as SwrveEvents class.
static NSString *const LOG_TYPE_KEY = @"log_type";
static NSString *const LOG_SOURCE_KEY = @"log_source";
static NSString *const LOG_DETAILS_KEY = @"log_details";

#pragma mark - init

- (instancetype)initWithSessionToken:(NSString *) sessionToken {
    if ((self = [super init])) {
        if (self.restClient == nil) {
            self.restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
        }
        self.queue = [NSMutableArray new];
        self.sessionToken = sessionToken;
    }
    return self;
}

#pragma mark - Request

- (void)makeRequest {
    NSMutableDictionary *newBody = [self createJSONBodyForQAEvent];
    NSURL *baseURL = [NSURL URLWithString:[SwrveCommon sharedInstance].eventsServer];
    NSURL *requestURL = [NSURL URLWithString:@"/1/batch" relativeToURL:baseURL];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:newBody options:0 error:nil];
    // Convert to string for logging
    if (jsonData) {
        NSString *json_string = nil;
        json_string = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [SwrveLogger debug:@"QaUser URL: %@", requestURL];
        [SwrveLogger debug:@"QaUser Body: %@", json_string];
    }
    [self.restClient sendHttpPOSTRequest:requestURL
                                jsonData:jsonData
                       completionHandler: ^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [SwrveLogger error:@"QA Error: %@", error];
        } else if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
            [SwrveLogger error:@"QA response was not a HTTP response: %@", response];
        } else {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
            long status = [httpResponse statusCode];
            NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [SwrveLogger debug:@"HTTP Send to QA Log %ld", status];
            if (status != 200) {
#pragma unused(responseBody)
                [SwrveLogger error:@"HTTP Error %ld sending QA events", status];
                [SwrveLogger error:@"  %@", responseBody];
            }
        }

    }];
}

- (NSMutableDictionary *)createJSONBodyForQAEvent {
    NSMutableDictionary *jsonPacket = [NSMutableDictionary new];
    [jsonPacket setValue:[SwrveCommon sharedInstance].userID forKey:@"user"];
    [jsonPacket setValue:[SwrveCommon sharedInstance].deviceUUID forKey:@"unique_device_id"];
    [jsonPacket setValue:[NSNumber numberWithInt:SWRVE_VERSION] forKey:@"version"];
    [jsonPacket setValue:NullableNSString([SwrveCommon sharedInstance].appVersion) forKey:@"app_version"];
    [jsonPacket setValue:self.sessionToken forKey:@"session_token"];
    @synchronized (self.queue) {
        [jsonPacket setValue:[self.queue copy] forKey:@"data"];
        [self.queue removeAllObjects];
    }
    return jsonPacket;
}

- (void)queueEvent:(NSMutableDictionary *)qalogevent {
    // Check if it's a valid qalogevent.
    if (![qalogevent objectForKey:LOG_TYPE_KEY] &&
        ![qalogevent objectForKey:LOG_SOURCE_KEY] &&
        ![qalogevent objectForKey:LOG_DETAILS_KEY]) {
        [SwrveLogger error:@"Invalid qalogevent: %@", qalogevent];
        return;
    }
    @synchronized (self.flushTimer) {
        // When we queue an event we check if the timer is already running
        // if not we also start our timer, so it will [self flushEvents] after "queueQAFlushDelay".
        if (self.flushTimer == nil) {
            if (NSThread.currentThread.isMainThread) {
                self.flushTimer = [NSTimer scheduledTimerWithTimeInterval:queueQAFlushDelay target:self selector:@selector(flushEvents) userInfo:nil repeats:YES];
            } else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.flushTimer = [NSTimer scheduledTimerWithTimeInterval:queueQAFlushDelay target:self selector:@selector(flushEvents) userInfo:nil repeats:YES];
                });
            }
        }
        // Add common attributes (if not already present)
        if (![qalogevent objectForKey:@"type"]) {
           [qalogevent setValue:@"qa_log_event" forKey:@"type"];
        }
        [self.queue addObject:qalogevent];
    }
}

- (void)flushEvents {
    @synchronized (self.flushTimer) {
        if ([self.queue count] == 0) {
            [self.flushTimer invalidate];
            self.flushTimer = nil;
            return;
        }
        [self makeRequest];
    }
}

@end
