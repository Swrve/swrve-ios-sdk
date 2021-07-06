#import <Foundation/Foundation.h>
#import "SwrveConfig.h"
#if __has_include(<SwrveSDKCommon/SwrveUtils.h>)
#import <SwrveSDKCommon/SwrveUtils.h>
#else
#import "SwrveUtils.h"
#endif

@interface SwrveDeviceProperties : NSObject

@property (nonatomic) NSString * sdk_version;
@property (nonatomic) NSString * sdk_language;
@property (nonatomic, assign) UInt64 appInstallTimeSeconds;
@property (nonatomic, assign) int  conversationVersion;
@property (nonatomic) NSString * deviceToken;
@property (nonatomic) NSDictionary* permissionStatus;
@property (nonatomic) NSString* swrveInitMode;
@property (nonatomic) BOOL autoCollectIDFV;
@property (nonatomic) NSString *idfa;

#if TARGET_OS_IOS /** exclude tvOS **/
@property (nonatomic) CTCarrier* carrierInfo;


/**
 Initializes an `SwrveDeviceProperties` object for the iOS platform
 
 @param sdk_version         The SDK version string
 @param appInstallTimeSeconds  The install time in seconds
 @param conversationVersion The SDK conversation version
 @param deviceToken         The device token
 @param permissionStatus    Permission status dictionary
 @param sdk_language        The SDK langauge string
 @param carrierInfo         The carrier info
 @param swrveInitMode       The SDK initMode string from SwrveConfig
 
 @return The initialized SwrveDeviceProperties
 */
- (instancetype) initWithVersion:(NSString *)sdk_version
           appInstallTimeSeconds:(UInt64)appInstallTimeSeconds
             conversationVersion:(int)conversationVersion
                     deviceToken:(NSString *)deviceToken
                permissionStatus:(NSDictionary *)permissionStatus
                    sdk_language:(NSString *)sdk_language
                     carrierInfo:(CTCarrier * )carrierInfo
                   swrveInitMode:(NSString *)swrveInitMode;

#elif TARGET_OS_TV
/**
 Initializes a reduced `SwrveDeviceProperties` object for the tvOS platform
 
 @param sdk_version         The SDK version string
 @param appInstallTimeSeconds  The app install time in seconds
 @param permissionStatus    Permission status dictionary
 @param sdk_language        The SDK langauge string
 @param swrveInitMode       The SDK initMode string from SwrveConfig
 
 @return The initialized SwrveDeviceProperties
 */
- (instancetype) initWithVersion:(NSString *)sdk_version
           appInstallTimeSeconds:(UInt64)appInstallTimeSeconds
                permissionStatus:(NSDictionary *)permissionStatus
                    sdk_language:(NSString *)sdk_language
                   swrveInitMode:(NSString *)swrveInitMode;
#endif
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
 swrve.can_receive_authenticated_push
 swrve.sdk_init_mode
 
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

@end
