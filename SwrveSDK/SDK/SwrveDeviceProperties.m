#import "SwrveDeviceProperties.h"
#if __has_include(<SwrveSDKCommon/SwrveLocalStorage.h>)
#import <SwrveSDKCommon/SwrveLocalStorage.h>
#else
#import "SwrveLocalStorage.h"
#endif

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

static NSString* SWRVE_DEVICE_NAME =                    @"swrve.device_name";
static NSString* SWRVE_OS =                             @"swrve.os";
static NSString* SWRVE_OS_VERSION =                     @"swrve.os_version";
static NSString* SWRVE_DEVICE_DPI =                     @"swrve.device_dpi";
static NSString* SWRVE_INSTALL_DATE =                   @"swrve.install_date";
static NSString* SWRVE_CONVERSION_VERSION =             @"swrve.conversation_version";
static NSString* SWRVE_SIM_OPERATOR_CODE =              @"swrve.sim_operator.code";
static NSString* SWRVE_SIM_OPERATOR_NAME =              @"swrve.sim_operator.name";
static NSString* SWRVE_SIM_OPERATOR_ISO_COUNTRY_CODE =  @"swrve.sim_operator.iso_country_code";
static NSString* SWRVE_IOS_MIN_VERSION =                @"swrve.ios_min_version";
static NSString* SWRVE_LANGUAGE =                       @"swrve.language";
static NSString* SWRVE_DEVICE_HEIGHT =                  @"swrve.device_height";
static NSString* SWRVE_DEVICE_WIDTH =                   @"swrve.device_width";
static NSString* SWRVE_SDK_VERSION =                    @"swrve.sdk_version";
static NSString* SWRVE_APP_STORE =                      @"swrve.app_store";
static NSString* SWRVE_UTC_OFFSET_SECONDS =             @"swrve.utc_offset_seconds";
static NSString* SWRVE_TIMEZONE_NAME =                  @"swrve.timezone_name";
static NSString* SWRVE_DEVICE_REGION =                  @"swrve.device_region";
static NSString* SWRVE_IOS_TOKEN =                      @"swrve.ios_token";
static NSString* SWRVE_SUPPORT_RICH_BUTTONS  =          @"swrve.support.rich_buttons";
static NSString* SWRVE_SUPPORT_RICH_ATTACHMENT  =       @"swrve.support.rich_attachment";
static NSString* SWRVE_SUPPORT_RICH_GIF  =              @"swrve.support.rich_gif";
static NSString* SWRVE_IDFA  =                          @"swrve.IDFA";
static NSString* SWRVE_IDFV =                           @"swrve.IDFV";
static NSString* SWRVE_CAN_RECEIVE_AUTH_PUSH =          @"swrve.can_receive_authenticated_push";
static NSString* SWRVE_SDK_INIT_MODE =                  @"swrve.sdk_init_mode";
static NSString* SWRVE_DEVICE_TYPE =                    @"swrve.device_type";
static NSString* SWRVE_TRACKING_STATE =                 @"swrve.tracking_state";

static NSString* PLATFORM =                             @"iOS "; // with trailing space

@implementation SwrveDeviceProperties

#pragma mark - properties

@synthesize sdk_version = _sdk_version;
@synthesize appInstallTimeSeconds = _appInstallTimeSeconds;
@synthesize permissionStatus = _permissionStatus;
@synthesize sdk_language = _sdk_language;
@synthesize swrveInitMode = _swrveInitMode;
@synthesize autoCollectIDFV = _autoCollectIDFV;
@synthesize idfa = _idfa;

#if TARGET_OS_IOS /** exclude tvOS **/
@synthesize conversationVersion = _conversationVersion;
@synthesize deviceToken = _deviceToken;
@synthesize carrierInfo = _carrierInfo;

#pragma mark - init

- (instancetype) initWithVersion:(NSString *)sdk_version
           appInstallTimeSeconds:(UInt64)appInstallTimeSeconds
             conversationVersion:(int)conversationVersion
                     deviceToken:(NSString *)deviceToken
                permissionStatus:(NSDictionary *)permissionStatus
                    sdk_language:(NSString *)sdk_language
                     carrierInfo:(CTCarrier * )carrierInfo
                        swrveInitMode:(NSString *)initMode {
    
    if ((self = [super init])) {
        
        self.sdk_version = sdk_version;
        self.appInstallTimeSeconds = appInstallTimeSeconds;
        self.conversationVersion = conversationVersion;
        self.deviceToken = deviceToken;
        self.permissionStatus = permissionStatus;
        self.sdk_language = sdk_language;
        self.carrierInfo = carrierInfo;
        self.swrveInitMode = initMode;
    }
    return self;
}
#elif TARGET_OS_TV
- (instancetype) initWithVersion:(NSString *)sdk_version
           appInstallTimeSeconds:(UInt64)appInstallTimeSeconds
                permissionStatus:(NSDictionary *)permissionStatus
                    sdk_language:(NSString *)sdk_language
                        swrveInitMode:(NSString *)initMode {
    if ((self = [super init])) {
        
        self.sdk_version = sdk_version;
        self.appInstallTimeSeconds = appInstallTimeSeconds;
        self.permissionStatus = permissionStatus;
        self.sdk_language = sdk_language;
        self.swrveInitMode = initMode;
    }
    return self;
}
#endif

#pragma mark - methods

- (NSString *)installDate:(UInt64)appInstallTimeSeconds {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [dateFormatter setDateFormat:@"yyyyMMdd"];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:appInstallTimeSeconds];
    return [dateFormatter stringFromDate:date];
}

- (NSDictionary *)deviceProperties {
    
    NSMutableDictionary *deviceProperties = [NSMutableDictionary new];
    
    // Basic Device Properties
    UIDevice* device = [UIDevice currentDevice];
    CGRect screen_bounds = [SwrveUtils deviceScreenBounds];
    NSNumber* device_width  = [NSNumber numberWithFloat: (float)screen_bounds.size.width];
    NSNumber* device_height = [NSNumber numberWithFloat: (float)screen_bounds.size.height];
    NSNumber* dpi = [NSNumber numberWithFloat:[SwrveUtils estimate_dpi]];
    
    [deviceProperties setValue:[SwrveUtils hardwareMachineName] forKey:SWRVE_DEVICE_NAME];
    [deviceProperties setValue:[[device systemName] lowercaseString]            forKey:SWRVE_OS];
    [deviceProperties setValue:[device systemVersion]                           forKey:SWRVE_OS_VERSION];
    [deviceProperties setValue:dpi                                              forKey:SWRVE_DEVICE_DPI];
    
    // Install Date / Version
    [deviceProperties setValue:[self installDate:self.appInstallTimeSeconds] forKey:SWRVE_INSTALL_DATE];
    
    // Device Permisisons
    [deviceProperties addEntriesFromDictionary:self.permissionStatus];
    
    // Language / Regional
    NSTimeZone* tz     = [NSTimeZone localTimeZone];
    NSNumber* min_os = [NSNumber numberWithInt: __IPHONE_OS_VERSION_MIN_REQUIRED];
    NSString *sdk_language = self.sdk_language;
    NSNumber* secondsFromGMT = [NSNumber numberWithInteger:[tz secondsFromGMT]];
    NSString* timezone_name = [tz name];
    NSString* regionCountry = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
    
    [deviceProperties setValue:min_os               forKey:SWRVE_IOS_MIN_VERSION];
    [deviceProperties setValue:sdk_language         forKey:SWRVE_LANGUAGE];
    [deviceProperties setValue:device_height        forKey:SWRVE_DEVICE_HEIGHT];
    [deviceProperties setValue:device_width         forKey:SWRVE_DEVICE_WIDTH];
    if(self.sdk_version) {
        NSString *sdkVersionString = [PLATFORM stringByAppendingString:self.sdk_version];
        [deviceProperties setValue:sdkVersionString     forKey:SWRVE_SDK_VERSION];
    }
    [deviceProperties setValue:@"apple"             forKey:SWRVE_APP_STORE];
    [deviceProperties setValue:secondsFromGMT       forKey:SWRVE_UTC_OFFSET_SECONDS ];
    [deviceProperties setValue:timezone_name        forKey:SWRVE_TIMEZONE_NAME];
    [deviceProperties setValue:regionCountry        forKey:SWRVE_DEVICE_REGION];
    [deviceProperties setValue:self.swrveInitMode   forKey:SWRVE_SDK_INIT_MODE];
    [deviceProperties setValue:[SwrveUtils platformDeviceType] forKey:SWRVE_DEVICE_TYPE];
    
    NSString *trackingState =  [SwrveDeviceProperties trackingStateString:[SwrveLocalStorage trackingState]];
    [deviceProperties setValue:trackingState forKey:SWRVE_TRACKING_STATE];

#if TARGET_OS_IOS /** retrieve the properties only supported by iOS **/
    [deviceProperties setValue:[NSNumber numberWithInteger:self.conversationVersion] forKey:SWRVE_CONVERSION_VERSION];
    
    // Carrier info
    if (self.carrierInfo != nil) {
        NSString* mobileCountryCode = [self.carrierInfo mobileCountryCode];
        NSString* mobileNetworkCode = [self.carrierInfo mobileNetworkCode];
        if (mobileCountryCode != nil && mobileNetworkCode != nil) {
            NSMutableString* carrierCode = [[NSMutableString alloc] initWithString:mobileCountryCode];
            [carrierCode appendString:mobileNetworkCode];
            [deviceProperties setValue:carrierCode forKey:SWRVE_SIM_OPERATOR_CODE];
        }
        [deviceProperties setValue:[self.carrierInfo carrierName]     forKey:SWRVE_SIM_OPERATOR_NAME];
        [deviceProperties setValue:[self.carrierInfo isoCountryCode]  forKey:SWRVE_SIM_OPERATOR_ISO_COUNTRY_CODE];
    }
    
    // Push properties
    if (self.deviceToken) {
        [deviceProperties setValue:self.deviceToken forKey:SWRVE_IOS_TOKEN];
        [deviceProperties setValue:@"true" forKey:SWRVE_CAN_RECEIVE_AUTH_PUSH];
        
        NSString *richSupported = @"true";
        [deviceProperties setValue:richSupported forKey:SWRVE_SUPPORT_RICH_BUTTONS];
        [deviceProperties setValue:richSupported forKey:SWRVE_SUPPORT_RICH_ATTACHMENT];
        [deviceProperties setValue:richSupported forKey:SWRVE_SUPPORT_RICH_GIF];
    }
#endif //TARGET_OS_IOS
    
    // Optional identifiers
    if (self.idfa == nil) {
        self.idfa = [SwrveLocalStorage idfa];
    }
    
    if (self.idfa != nil) {
        [deviceProperties setValue:self.idfa forKey:SWRVE_IDFA];
    }
    
    if (self.autoCollectIDFV) {
        NSString *idfv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        [deviceProperties setValue:idfv forKey:SWRVE_IDFV];
    }

    return deviceProperties;
}

+ (NSString *)trackingStateString:(enum SwrveTrackingState)swrveTrackingState {
    switch (swrveTrackingState) {
        case UNKNOWN:
            return @"UNKNOWN";
            break;
        case STARTED:
            return @"STARTED";
            break;
        case EVENT_SENDING_PAUSED:
            return @"EVENT_SENDING_PAUSED";
            break;
        case STOPPED:
            return @"STOPPED";
            break;
        default:
            return @"UNKNOWN";
            break;
    }
}

@end
