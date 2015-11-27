#import <Foundation/Foundation.h>

@interface SwrveLocationMessage : NSObject

@property(atomic, strong) NSString *locationMessageId;
@property(atomic, strong) NSString *body;
@property(atomic, strong) NSString *payload;

- (id)initWithDictionary:(NSDictionary *)dictionary;

- (NSString *)description;

- (NSString *) toJson;

- (NSDictionary *) getPayloadDictionary;

@end
