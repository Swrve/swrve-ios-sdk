#import <Foundation/Foundation.h>

@interface SwrveLocationMessage : NSObject

@property(atomic, strong) NSString *locationMessageId;
@property(atomic, strong) NSString *body;

- (id)initWithDictionary:(NSDictionary *)dictionary;

- (NSString *)description;
@end
