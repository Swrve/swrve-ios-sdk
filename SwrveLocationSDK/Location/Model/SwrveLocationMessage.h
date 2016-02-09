#import <Foundation/Foundation.h>

extern NSString *const GEOFENCE_LABEL_PLACEHOLDER;

@interface SwrveLocationMessage : NSObject

@property(atomic, strong) NSString *locationMessageId;
@property(atomic, strong) NSString *body;
@property(atomic, strong) NSString *payload;

- (id)initWithDictionary:(NSDictionary *)dictionary;

- (NSString *)description;

- (NSString *) toJson;

- (NSDictionary *) getPayloadDictionary;

- (BOOL) expectsGeofenceLabel;

@end
