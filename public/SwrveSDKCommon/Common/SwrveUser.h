#import <Foundation/Foundation.h>

@interface SwrveUser : NSObject  <NSCoding,NSSecureCoding>

- (instancetype)initWithExternalId:(NSString *)externalId
                           swrveId:(NSString *)swrveId
                          verified:(BOOL)verified;

+ (NSString*)sessionTokenFromAppId:(long)appId
                            apiKey:(NSString*)apiKey
                            userId:(NSString*)userId
                         startTime:(long)startTime;

@end
