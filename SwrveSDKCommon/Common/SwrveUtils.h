#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <sys/time.h>
#import <sys/sysctl.h>
#if TARGET_OS_IOS /** exclude tvOS **/
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#endif /** TARGET_OS_IOS **/

@interface SwrveUtils : NSObject

/**
 Get the bounds for the screen
 
 @return Device screen bounds CGRect
*/
+ (CGRect)deviceScreenBounds;

/**
  Get an estimate for the dpi of the device
 
  @return dpi as float
 */
+ (float)estimate_dpi;

/**
  Get the machine namne for the device
 
  @return Machine name string
*/
+ (NSString *)hardwareMachineName;

#if TARGET_OS_IOS /** exclude tvOS **/
/**
  CTCarrier info
 
  @return CTCarrier object
*/
+ (CTCarrier*) carrierInfo;
#endif

/**
 Parse a string into paramaters
 
 @return NSDictionary of parameters
 */
+ (NSDictionary *)parseURLQueryParams:(NSString *) queryString;

/**
 Parse a string into paramaters

 @param dic Dictionary that contain a NSNumber or a NSString value on it.
 @param key The key that is going to be used to get NSString value from dic.
 @return NSString of parameters
 */
+ (NSString *)getStringFromDic:(NSDictionary *)dic withKey:(NSString *)key;

/**
    Return current time since the epoch in milliseconds
    @return UInt64 of current time
 */
+ (UInt64)getTimeEpoch;

/**
 Returns YES if running on platforms that support Conversations
 
 @return BOOL
 */
+ (BOOL) supportsConversations;

/**
 Returns one of three options "mobile" , "tv" or "desktop" based on the platform running it.
 
 @return NSString representing the device type
 */
+ (NSString *) platformDeviceType;

/**
 Check if IDFA doesn't contain all zeros and dashes
 
 @return Bool
 */
+ (BOOL)isValidIDFA:(NSString *)idfa;

/**
 Produce a SHA1 code for a given piece of NSData
 
 @return NSString representing the sha1 of the message argument
 */
+ (NSString *)sha1:(NSData *)messageData;

/**
 Combine two NSDictionaries to make a single one.
 One is considered the 'root' dictionary which will the other will be passed into. Any duplicate keys will have their contents overriden by the second.
 
 @return NSDictionay with the duplicates stripped out
 */
+ (NSDictionary *)combineDictionary:(NSDictionary*)rootDictionary withDictionary:(NSDictionary *)overiddingDictionary;

+ (BOOL)isDifferentUserForAuthenticatedPush:(NSDictionary *)authenticatedPushUserInfo userId:(NSString *)userId;

+ (BOOL)isAuthenticatedPush:(NSDictionary *)userInfo;
                              
+ (UIBackgroundTaskIdentifier)startBackgroundTaskCommon:(UIBackgroundTaskIdentifier)bgTask withName:(NSString *)name;

+ (void)stopBackgroundTaskCommon:(UIBackgroundTaskIdentifier)bgTask withName:(NSString *)name;

@end
