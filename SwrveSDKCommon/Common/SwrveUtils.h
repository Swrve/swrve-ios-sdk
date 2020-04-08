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
 
 @return NSDictionary of paramters
 */
+ (NSDictionary *)parseURLQueryParams:(NSString *) queryString;

/**
 Parse a string into paramaters

 @param dic Dictionary that contain a NSNumber or a NSString value on it.
 @param key The key that is going to be used to get NSString value from dic.
 @return NSString of paramters
 */
+ (NSString *)getStringFromDic:(NSDictionary *)dic withKey:(NSString *)key;

/**
Get current time in epoch in milliseconds.

@return UInt64 time in milliseconds.
*/
+ (UInt64)getTimeEpoch;


/**
 Returns YES if running on platforms that support Conversations
 
 @return BOOL
 */
+ (BOOL) supportsConversations;

@end
