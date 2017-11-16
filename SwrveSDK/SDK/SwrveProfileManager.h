#import <Foundation/Foundation.h>

#import "SwrveConfig.h"

@interface SwrveProfileManager : NSObject

@property (nonatomic, retain) NSString * userId;
@property (atomic) BOOL isNewUser;

- (id)initWithConfig:(ImmutableSwrveConfig *)config;
- (NSString*)sessionTokenFromAppId:(long)appID
                           apiKey:(NSString*)apiKey
                           userID:(NSString*)userID
                        startTime:(long)startTime;

@end
