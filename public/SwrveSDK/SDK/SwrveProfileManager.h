#import <Foundation/Foundation.h>
#if __has_include(<SwrveSDKCommon/SwrveLocalStorage.h>)
#import <SwrveSDKCommon/SwrveLocalStorage.h>
#else
#import "SwrveLocalStorage.h"
#endif

@interface SwrveProfileManager : NSObject

@property (readonly, nonatomic, retain) NSString * userId;
@property (readonly, nonatomic, retain) NSString * sessionToken;
@property (atomic) BOOL isNewUser;
@property (nonatomic) enum SwrveTrackingState trackingState;

- (void)persistUser;

@end
