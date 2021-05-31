#if TARGET_OS_IOS /** exclude tvOS **/
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#endif //TARGET_OS_IOS

#import "SwrveSDK.h"
#import "Swrve+Private.h"
#import "SwrvePrivateAccess.h"

@interface TestableSwrve : Swrve

@property (atomic) NSDate* customNowDate;
@property (atomic) UInt64 customTimeSeconds;
@property (atomic) BOOL resourceUpdaterEnabled;
#if TARGET_OS_IOS /** exclude tvOS **/
@property (atomic) CTCarrier* carrier;
#endif //TARGET_OS_IOS

/**
 * Method overrides
 */

+ (TestableSwrve*) sharedInstanceWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey;
+ (TestableSwrve*) sharedInstanceWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey config:(SwrveConfig*)swrveConfig;
+ (TestableSwrve*) sharedInstanceWithAppID:(int)swrveAppID apiKey:(NSString*)swrveAPIKey config:(SwrveConfig*)swrveConfig customNow:(NSDate*)date;

- (NSDate*) getNow;
- (UInt64) getTime;
- (UInt64) secondsSinceEpoch;

@end
