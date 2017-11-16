#import <Foundation/Foundation.h>
#import "SwrveUtils.h"

@interface SwrveDeviceProperties : NSObject

@property (nonatomic) NSString * sdk_version;
@property (nonatomic) NSString * sdk_language;
@property (nonatomic, assign) UInt64 installTimeSeconds;
@property (nonatomic, assign) int  conversationVersion;
@property (nonatomic) NSString * deviceToken;
@property (nonatomic) NSDictionary* permissionStatus;
@property (nonatomic) CTCarrier* carrierInfo;


/**
 Initializes an `SwrveDeviceProperties` object
 
 @param sdk_version         The SDK version string
 @param installTimeSeconds  The install time in seconds
 @param conversationVersion The SDK conversation version
 @param deviceToken         The device token
 @param permissionStatus    Permission status dictionary
 @param sdk_language        The SDK langauge string
 @param carrierInfo         The carrier info
    
 @return The initialized SwrveDeviceProperties
*/
- (instancetype) initWithVersion:(NSString *)sdk_version
              installTimeSeconds:(UInt64)installTimeSeconds
             conversationVersion:(int)conversationVersion
                     deviceToken:(NSString *)deviceToken
                permissionStatus:(NSDictionary *)permissionStatus
                    sdk_language:(NSString *)sdk_language
                     carrierInfo:(CTCarrier * )carrierInfo;


/**
 Get the device properties
 
 The following values are tracked
 
 swrve.device_name
 swrve.os
 swrve.os_version
 swrve.device_dpi
 swrve.install_date
 swrve.conversation_version
 swrve.sim_operator.code
 swrve.sim_operator.name
 swrve.sim_operator.iso_country_code
 swrve.ios_min_version
 swrve.language
 swrve.device_height
 swrve.device_width
 swrve.sdk_version
 swrve.app_store
 swrve.utc_offset_seconds
 swrve.timezone_name
 swrve.device_region
 swrve.ios_token
 swrve.support.rich_buttons
 swrve.support.rich_attachment
 swrve.support.rich_gif
 swrve.IDFA
 swrve.IDFV
 
 Swrve.permission.ios.location.always
 Swrve.permission.ios.location.when_in_use
 Swrve.permission.ios.photos
 Swrve.permission.ios.camera
 Swrve.permission.ios.contacts
 Swrve.permission.ios.push_notifications
 Swrve.permission.ios.push_bg_refresh
 
 @return NSDictionary
 */
- (NSDictionary*) deviceProperties;

/**
Get existing deviceId or create new one
 
 @return Device Id as NSNumber
 */
+ (NSNumber *)deviceId;

@end
