#import <Foundation/Foundation.h>

@interface SwrveProfileManager : NSObject

@property (readonly, nonatomic, retain) NSString * userId;
@property (readonly, nonatomic, retain) NSString * sessionToken;
@property (atomic) BOOL isNewUser;

- (void)persistUser;

@end
