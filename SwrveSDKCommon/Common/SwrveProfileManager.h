#import <Foundation/Foundation.h>

@interface SwrveProfileManager : NSObject

@property (nonatomic, retain) NSString * userId;
@property (atomic) BOOL isNewUser;

- (id)initWithUserID:(NSString*)userID;
- (NSString*)sessionTokenFromAppId:(long)appID
                           apiKey:(NSString*)apiKey
                           userID:(NSString*)userID
                        startTime:(long)startTime;

@end
