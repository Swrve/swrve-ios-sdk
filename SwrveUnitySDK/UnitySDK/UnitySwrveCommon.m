#import "UnitySwrveCommon.h"
#import "UnitySwrveHelper.h"
#import "SwrveSignatureProtectedFile.h"
#import "SwrveCommonConnectionDelegate.h"

#include <sys/time.h>
#import <CommonCrypto/CommonHMAC.h>

static UnitySwrveCommonDelegate *_swrveSharedUnity = NULL;
static dispatch_once_t sharedInstanceToken = 0;

@interface UnitySwrveCommonDelegate()

@property(atomic, strong) NSDictionary* configDict;

// An in-memory buffer of messages that are ready to be sent to the Swrve
// server the next time sendQueuedEvents is called.
@property (atomic) NSMutableArray* eventBuffer;

// Count the number of UTF-16 code points stored in buffer
@property (atomic) int eventBufferBytes;

@end

@implementation UnitySwrveCommonDelegate

@synthesize configDict;
@synthesize eventBuffer;
@synthesize eventBufferBytes;

-(id) init {
    self = [super init];
    if(self) {
        [self initBuffer];
    }
    return self;
}

+(UnitySwrveCommonDelegate*) sharedInstance
{
    dispatch_once(&sharedInstanceToken, ^{
        _swrveSharedUnity = [[UnitySwrveCommonDelegate alloc] init];
        [SwrveCommon addSharedInstance:_swrveSharedUnity];
    });
    return _swrveSharedUnity;
}

-(void) shutdown {
    [SwrveCommon addSharedInstance:nil];
    sharedInstanceToken = 0;
    _swrveSharedUnity = nil;
}

+(void) init:(char*)jsonConfig {
    UnitySwrveCommonDelegate* swrve = [UnitySwrveCommonDelegate sharedInstance];
    
    NSError* error = nil;
    swrve.configDict =
        [NSJSONSerialization JSONObjectWithData:[[UnitySwrveHelper CStringToNSString:jsonConfig] dataUsingEncoding:NSUTF8StringEncoding]
                                        options:NSJSONReadingMutableContainers error:&error];
    NSLog(@"full config dict: %@", swrve.configDict);
    
    [swrve initLocation];
}

-(NSString*) stringFromConfig:(NSString*)key {
    return [self.configDict valueForKey:key];
}

-(int) intFromConfig:(NSString*)key {
    return [[self.configDict valueForKey:key] intValue];
}

-(long) longFromConfig:(NSString*)key {
    return [[self.configDict valueForKey:key] longValue];
}

-(NSString*) applicationPath {
    return [self stringFromConfig:@"swrvePath"];
}

-(NSString*) locTag {
    return [self stringFromConfig:@"locTag"];
}

-(NSString*) sigSuffix {
    return [self stringFromConfig:@"sigSuffix"];
}

-(NSString*) userId {
    return [self stringFromConfig:@"userId"];
}

-(NSString*) apiKey {
    return [self stringFromConfig:@"apiKey"];
}

-(long) appId {
    return [self longFromConfig:@"appId"];
}

-(NSString*) appVersion {
    return [self stringFromConfig:@"appVersion"];
}

-(NSString*) uniqueKey {
    return [self stringFromConfig:@"uniqueKey"];
}

-(NSString*) batchUrl {
    return [self stringFromConfig:@"batchUrl"];
}

-(NSString*) eventsServer {
    return [self stringFromConfig:@"eventsServer"];
}

-(NSURL*) getBatchUrl {
    return [NSURL URLWithString:[self batchUrl] relativeToURL:[NSURL URLWithString:[self eventsServer]]];
}

-(int) httpTimeout {
    return [self intFromConfig:@"httpTimeout"];
}

-(NSString*) getLocationPath {
    return [NSString stringWithFormat:@"%@/%@%@", [self applicationPath], [self locTag], [self userId]];
}

-(NSData*) getCampaignData:(int)category {
    if(SWRVE_CAMPAIGN_LOCATION == category) {
        NSURL *fileURL = [NSURL fileURLWithPath:[self getLocationPath]];
        NSURL *signatureURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", [self getLocationPath], [self sigSuffix]]];
        NSString *signatureKey = [self uniqueKey];
        SwrveSignatureProtectedFile *locationCampaignFile = [[SwrveSignatureProtectedFile alloc] initFile:fileURL signatureFilename:signatureURL usingKey:signatureKey];
        return [locationCampaignFile readFromFile];
    }
    return nil;
}

-(BOOL) processPermissionRequest:(NSString*)action { return TRUE; }

- (UInt64) getTime
{
    // Get the time since the epoch in seconds
    struct timeval time;
    gettimeofday(&time, NULL);
    return (((UInt64)time.tv_sec) * 1000) + (((UInt64)time.tv_usec) / 1000);
}

-(int) eventInternal:(NSString*)eventName payload:(NSDictionary*)eventPayload triggerCallback:(bool)triggerCallback {
    if (!eventPayload) {
        eventPayload = [[NSDictionary alloc]init];
    }
    
    NSMutableDictionary* json = [[NSMutableDictionary alloc] init];
    [json setValue:NullableNSString(eventName) forKey:@"name"];
    [json setValue:eventPayload forKey:@"payload"];
    [self queueEvent:@"event" data:json triggerCallback:triggerCallback];

    return SWRVE_SUCCESS;
}

-(void) queueEvent:(NSString*)eventType data:(NSMutableDictionary*)eventData triggerCallback:(bool)triggerCallback
{
    if ([self eventBuffer]) {
        // Add common attributes (if not already present)
        if (![eventData objectForKey:@"type"]) {
            [eventData setValue:eventType forKey:@"type"];
        }
        if (![eventData objectForKey:@"time"]) {
            [eventData setValue:[NSNumber numberWithUnsignedLongLong:[self getTime]] forKey:@"time"];
        }
        
        // Convert to string
        NSData* json_data = [NSJSONSerialization dataWithJSONObject:eventData options:0 error:nil];
        if (json_data) {
            NSString* json_string = [[NSString alloc] initWithData:json_data encoding:NSUTF8StringEncoding];
            [self setEventBufferBytes:[self eventBufferBytes] + (int)[json_string length]];
            [[self eventBuffer] addObject:json_string];
        }
        [self sendQueuedEvents];
    }
}

-(void) sendQueuedEvents
{   
    // Early out if length is zero.
    if ([[self eventBuffer] count] == 0) return;
    
    // Swap buffers
    NSArray* buffer = [self eventBuffer];
    int bytes = [self eventBufferBytes];
    [self initBuffer];
    
    NSString* session_token = [self createSessionToken];
    NSString* array_body = [self copyBufferToJson:buffer];
    NSString* json_string = [self createJSON:session_token events:array_body];
    
    NSData* json_data = [json_string dataUsingEncoding:NSUTF8StringEncoding];
    
    [self sendHttpPOSTRequest:[self getBatchUrl]
                     jsonData:json_data
            completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {
                
                if (error){
                    DebugLog(@"Error opening HTTP stream: %@ %@", [error localizedDescription], [error localizedFailureReason]);
                    [self setEventBufferBytes:[self eventBufferBytes] + bytes];
                    [[self eventBuffer] addObjectsFromArray:buffer];
                    return;
                }
                else{
                    NSLog(@"response: %@", response);
                    NSLog(@"data: %@", data);
                }
            }];
}

- (void) sendHttpPOSTRequest:(NSURL*)url jsonData:(NSData*)json
{
    [self sendHttpPOSTRequest:url jsonData:json completionHandler:nil];
}

- (void) sendHttpPOSTRequest:(NSURL*)url jsonData:(NSData*)json completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler
{
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:[self httpTimeout]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:json];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[json length]] forHTTPHeaderField:@"Content-Length"];
    
    [self sendHttpRequest:request completionHandler:handler];
}

- (void) sendHttpRequest:(NSMutableURLRequest*)request completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler
{
    // Add http request performance metrics for any previous requests into the header of this request (see JIRA SWRVE-5067 for more details)
    NSArray* allMetricsToSend;
    
    if (allMetricsToSend != nil && [allMetricsToSend count] > 0) {
        NSString* fullHeader = [allMetricsToSend componentsJoinedByString:@";"];
        [request addValue:fullHeader forHTTPHeaderField:@"Swrve-Latency-Metrics"];
    }
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            handler(response, data, error);
        }];
        [task resume];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        SwrveCommonConnectionDelegate* connectionDelegate = [[SwrveCommonConnectionDelegate alloc] init:handler];
        [NSURLConnection connectionWithRequest:request delegate:connectionDelegate];
#pragma clang diagnostic pop
    }
}

- (void) initBuffer {
    [self setEventBuffer:[[NSMutableArray alloc] initWithCapacity:SWRVE_MEMORY_QUEUE_INITIAL_SIZE]];
    [self setEventBufferBytes:0];
}

- (NSString*) createSessionToken
{
    // Get the time since the epoch in seconds
    struct timeval time; gettimeofday(&time, NULL);
    const long session_start = time.tv_sec;
    
    NSString* source = [NSString stringWithFormat:@"%@%ld%@", [self userId], session_start, [self apiKey]];
    
    NSString* digest = [self createStringWithMD5:source];
    
    // $session_token = "$app_id=$user_id=$session_start=$md5_hash";
    NSString* session_token = [NSString stringWithFormat:@"%ld=%@=%ld=%@",
                               [self appId],
                               [self userId],
                               session_start,
                               digest];
    return session_token;
}

- (NSString*) createStringWithMD5:(NSString*)source
{
#define C "%02x"
#define CCCC C C C C
#define DIGEST_FORMAT CCCC CCCC CCCC CCCC
    
    NSString* digestFormat = [NSString stringWithFormat:@"%s", DIGEST_FORMAT];
    
    NSData* buffer = [source dataUsingEncoding:NSUTF8StringEncoding];
    
    unsigned char digest[CC_MD5_DIGEST_LENGTH] = {0};
    unsigned int length = (unsigned int)[buffer length];
    CC_MD5_CTX context;
    CC_MD5_Init(&context);
    CC_MD5_Update(&context, [buffer bytes], length);
    CC_MD5_Final(digest, &context);
    
    NSString* result = [NSString stringWithFormat:digestFormat,
                        digest[ 0], digest[ 1], digest[ 2], digest[ 3],
                        digest[ 4], digest[ 5], digest[ 6], digest[ 7],
                        digest[ 8], digest[ 9], digest[10], digest[11],
                        digest[12], digest[13], digest[14], digest[15]];
    
    return result;
}

// Convert the array of strings into a json array.
// This does not add the square brackets.
- (NSString*) copyBufferToJson:(NSArray*) buffer
{
    return [buffer componentsJoinedByString:@",\n"];
}

- (NSString*) createJSON:(NSString*)sessionToken events:(NSString*)rawEvents
{
    NSString *eventArray = [NSString stringWithFormat:@"[%@]", rawEvents];
    NSData *bodyData = [eventArray dataUsingEncoding:NSUTF8StringEncoding];
    NSArray* body = [NSJSONSerialization
                     JSONObjectWithData:bodyData
                     options:NSJSONReadingMutableContainers
                     error:nil];
    
    NSMutableDictionary* jsonPacket = [[NSMutableDictionary alloc] init];
    [jsonPacket setValue:[self userId] forKey:@"user"];
    [jsonPacket setValue:[NSNumber numberWithInt:SWRVE_VERSION] forKey:@"version"];
    [jsonPacket setValue:NullableNSString([self appVersion]) forKey:@"app_version"];
    [jsonPacket setValue:NullableNSString(sessionToken) forKey:@"session_token"];
    [jsonPacket setValue:body forKey:@"data"];
    
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:jsonPacket options:0 error:nil];
    NSString* json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    return json;
}

-(void) initLocation
{
#ifdef SWRVE_LOCATION_SDK
    [SwrvePlot initializeWithLaunchOptions:nil delegate:self];
#endif
}

-(void) setLocationVersion:(NSString *)version {
    [self sendMessageUp:@"SetLocationVersion" msg:version];
}

-(int) userUpdate:(NSDictionary *)attributes {
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:attributes options:0 error:nil];
    NSString* json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    [self sendMessageUp:@"UserUpdate" msg:json];
    
    return SWRVE_SUCCESS;
}

-(void) sendMessageUp:(NSString*)method msg:(NSString*)msg
{
    UnitySendMessage("SwrvePrefab",
                     [UnitySwrveHelper NSStringCopy:method],
                     [UnitySwrveHelper NSStringCopy:msg]);
}

@end
