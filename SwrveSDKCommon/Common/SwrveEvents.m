#import "SwrveEvents.h"
#import "SwrveCommon.h"
#import "SwrveUtils.h"
#import "SwrveQA.h"
#import "SwrveQACampaignInfo.h"

@implementation SwrveEvents : NSObject

static NSString *const LOG_SOURCE_SDK = @"sdk";
static NSString *const LOG_TYPE_KEY = @"log_type";
static NSString *const TYPE_KEY = @"type";
static NSString *const LOG_QA_TYPE = @"qa_log_event";
static NSString *const LOG_SOURCE_KEY = @"log_source";
static NSString *const LOG_DETAILS_KEY = @"log_details";
static NSString *const TIME_KEY = @"time";
static NSString *const SEQNUM_KEY = @"seqnum";

#pragma mark QA SDK Events

+ (NSMutableDictionary *)qalogWrappedEvent:(NSDictionary *) dic {
    NSNumber *time = [NSNumber numberWithUnsignedLongLong:[SwrveUtils getTimeEpoch]];
    NSDictionary *logDetails = [SwrveEvents qaWrapperEvent:[dic mutableCopy]];
    NSMutableDictionary *qaLog = [@{
        TYPE_KEY: LOG_QA_TYPE,
        LOG_TYPE_KEY: @"event",
        LOG_SOURCE_KEY: LOG_SOURCE_SDK,
        LOG_DETAILS_KEY: logDetails,
        TIME_KEY: time
    } mutableCopy];

    return qaLog;
}

+ (NSMutableDictionary *) qalogCampaignsDownloaded:(NSArray *) array {
    NSNumber *time = [NSNumber numberWithUnsignedLongLong:[SwrveUtils getTimeEpoch]];
    NSMutableDictionary *qaLog = [@{
        TYPE_KEY: LOG_QA_TYPE,
        LOG_TYPE_KEY: @"campaigns-downloaded",
        LOG_SOURCE_KEY: LOG_SOURCE_SDK,
        TIME_KEY: time
    } mutableCopy];

    // Iterate through the campaigns to create "LogDetails" content.
    NSMutableArray *campaigns = [NSMutableArray new];
    for (NSDictionary *campaign in array) {
        NSMutableDictionary *campaignDic = [NSMutableDictionary new];
        [campaignDic setValue:[campaign objectForKey:@"id"] forKey:@"id"];
        NSDictionary *conversation = campaign[@"conversation"];
        NSDictionary *message = campaign[@"message"];
        NSDictionary *embedded = campaign[@"embedded_message"];

        if (conversation != nil && conversation[@"id"] != nil) {
            NSInteger variantID = [conversation[@"id"] integerValue];
            [campaignDic setValue:@"conversation" forKey:@"type"];
            [campaignDic setValue:[NSNumber numberWithInteger:variantID] forKey:@"variant_id"];
        } else if (message != nil && message[@"id"] != nil) {
            NSInteger variantID = [message[@"id"] integerValue];
            [campaignDic setValue:@"iam" forKey:@"type"];
            [campaignDic setValue:[NSNumber numberWithInteger:variantID] forKey:@"variant_id"];
        } else if (embedded != nil && embedded[@"id"] != nil){
            NSInteger variantID = [embedded[@"id"] integerValue];
            [campaignDic setValue:@"embedded" forKey:@"type"];
            [campaignDic setValue:[NSNumber numberWithInteger:variantID] forKey:@"variant_id"];
        } else {
            [SwrveLogger error: @"Unknown campaign type. Not adding to campaigns-downloaded qa log event."];
            continue;
        }

        [campaigns addObject:campaignDic];
    }
    NSDictionary *logDetails = @{ @"campaigns": campaigns };
    [qaLog setObject:logDetails forKey:LOG_DETAILS_KEY];
    return qaLog;
}

+ (NSMutableDictionary *) qalogCampaignButtonClicked:(NSDictionary *) campaign {
    NSNumber *time = [NSNumber numberWithUnsignedLongLong:[SwrveUtils getTimeEpoch]];
    NSMutableDictionary *qaLog = [@{
        TYPE_KEY: LOG_QA_TYPE,
        LOG_TYPE_KEY: @"campaign-button-clicked",
        LOG_SOURCE_KEY: LOG_SOURCE_SDK,
        TIME_KEY: time,
    } mutableCopy];
    
    NSDictionary *logDetails = [campaign mutableCopy];
    [qaLog setValue:logDetails forKey:LOG_DETAILS_KEY];
    return qaLog;
}


+ (NSMutableDictionary *) qaLogEvent:(NSDictionary *) logDetails logType:(NSString *) logType {
    NSNumber *time = [NSNumber numberWithUnsignedLongLong:[SwrveUtils getTimeEpoch]];
    NSMutableDictionary *qaLog = [@{
        TYPE_KEY: LOG_QA_TYPE,
        LOG_TYPE_KEY: logType,
        LOG_SOURCE_KEY: LOG_SOURCE_SDK,
        TIME_KEY: time,
    } mutableCopy];

    [qaLog setValue:logDetails forKey:LOG_DETAILS_KEY];
    
    return qaLog;
}

#pragma mark Internal methods.

// Helper method that wrap a SDK into QAEvent format.
+ (NSDictionary *) qaWrapperEvent: (NSMutableDictionary *)event {
    if(event == nil) {
        return [NSMutableDictionary new];
    }

    NSMutableDictionary *logDetails = [NSMutableDictionary new];
    if([event objectForKey:@"type"]) {
        [logDetails setObject:[event objectForKey:@"type"] forKey:@"type"];
        [event removeObjectForKey:@"type"];
    }

    if ([event valueForKey:@"time"]) {
        [logDetails setObject:[event valueForKey:@"time"] forKey:@"client_time"];
        [event removeObjectForKey:@"time"];
    }

    if([event objectForKey:@"seqnum"]) {
           [logDetails setObject:[event objectForKey:@"seqnum"] forKey:@"seqnum"];
           [event removeObjectForKey:@"seqnum"];
    }

    NSString *payloadString = @"{}"; // QAEvent currently only accepting payload jsonobject as a string, and not a proper jsonobject
    if([event objectForKey:@"payload"]) {
        payloadString = [self convertToJSONString:[event objectForKey:@"payload"]];
        [event removeObjectForKey:@"payload"];
    }
    [logDetails setObject:payloadString forKey:@"payload"];

    // If we still have keys available on our content we do add them as part of event parameters
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    if ([event count] > 0) {
        for (NSString *key in [event allKeys]) {
            [parameters setObject:[[event objectForKey:key] copy] forKey:key];
        }
    }
    // Event wrapped must contain an parameters key even if it's an empty object
    [logDetails setObject:parameters forKey:@"parameters"];
    return [NSDictionary dictionaryWithDictionary:logDetails];;
}

+ (NSString *) convertToJSONString:(NSDictionary *) dict {
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:0
                                                         error:&error];

    if (! jsonData) {
        [SwrveLogger error:@"Got an error: %@", error];
        return @"{}";
    } else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}

@end
