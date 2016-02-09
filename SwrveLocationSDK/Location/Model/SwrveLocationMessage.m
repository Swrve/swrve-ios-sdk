#import "SwrveLocationMessage.h"
//#import "Swrve.h"
#import "SwrveCommon.h"

NSString* const GEOFENCE_LABEL_PLACEHOLDER = @"${geofence.label}";

@implementation SwrveLocationMessage

@synthesize locationMessageId;
@synthesize body;
@synthesize payload;

- (id)initWithDictionary:(NSDictionary *)dictionary {

    if (self = [super init]) {
        locationMessageId = [dictionary objectForKey:@"id"];
        body = [dictionary objectForKey:@"body"];
        payload = [dictionary objectForKey:@"payload"];
    }

    return self;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.locationMessageId=%@", self.locationMessageId];
    [description appendFormat:@", self.body=%@", self.body];
    [description appendFormat:@", self.payload=%@", self.payload];
    [description appendString:@">"];
    return description;
}

- (NSString *) toJson {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    [dict setValue:locationMessageId forKey:@"id"];
    [dict setValue:body forKey:@"body"];
    [dict setValue:payload forKey:@"payload"];

    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    NSString *json = @"";
    if (!error) {
        json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    } else {
        DebugLog(@"Error creating json:%@", self.description);
    }

    return json;
}


- (NSDictionary *) getPayloadDictionary {
    NSDictionary *dictionary = [[NSDictionary alloc] init];
    if(payload == nil) {
        return dictionary;
    }

    NSData *jsonData = [payload dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    if (!error) {
        dictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    } else {
        DebugLog(@"Error parsing payload into dictionary. Payload:%@ Reason:%@", payload, error.description);
    }

    return dictionary;
}

- (BOOL) expectsGeofenceLabel {
    if ([body rangeOfString:GEOFENCE_LABEL_PLACEHOLDER].location == NSNotFound) {
        return NO;
    } else {
        return YES;
    }
}

@end
