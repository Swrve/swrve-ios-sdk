#import "SwrveDeviceProperties.h"
#import <AdSupport/ASIdentifierManager.h>


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

@implementation SwrveDeviceProperties

#pragma mark - properties

@synthesize sdk_version = _sdk_version;
@synthesize installTimeSeconds = _installTimeSeconds;
@synthesize conversationVersion = _conversationVersion;
@synthesize deviceToken = _deviceToken;
@synthesize permissionStatus = _permissionStatus;
@synthesize sdk_language = _sdk_language;
@synthesize carrierInfo = _carrierInfo;

#pragma mark - init

- (instancetype) initWithVersion:(NSString *)sdk_version
              installTimeSeconds:(UInt64)installTimeSeconds
             conversationVersion:(int)conversationVersion
                     deviceToken:(NSString *)deviceToken
                permissionStatus:(NSDictionary *)permissionStatus
                    sdk_language:(NSString *)sdk_language
                     carrierInfo:(CTCarrier * )carrierInfo {

    if ((self = [super init])) {
        
        self.sdk_version = sdk_version;
        self.installTimeSeconds = installTimeSeconds;
        self.conversationVersion = conversationVersion;
        self.deviceToken = deviceToken;
        self.permissionStatus = permissionStatus;
        self.sdk_language = sdk_language;
        self.carrierInfo = carrierInfo;
    }
    return self;
}

#pragma mark - methods

- (NSDictionary*) deviceProperties {
    
    NSMutableDictionary* deviceProperties = [[NSMutableDictionary alloc] init];
    
    // Basic Device Properties
    UIDevice* device = [UIDevice currentDevice];
    CGRect screen_bounds = [SwrveUtils deviceScreenBounds];
    NSNumber* device_width  = [NSNumber numberWithFloat: (float)screen_bounds.size.width];
    NSNumber* device_height = [NSNumber numberWithFloat: (float)screen_bounds.size.height];
    NSNumber* dpi = [NSNumber numberWithFloat:[SwrveUtils estimate_dpi]];
    
    [deviceProperties setValue:[SwrveUtils hardwareMachineName] forKey:SWRVE_DEVICE_NAME];
    [deviceProperties setValue:[device systemName]              forKey:SWRVE_OS];
    [deviceProperties setValue:[device systemVersion]           forKey:SWRVE_OS_VERSION];
    [deviceProperties setValue:dpi                              forKey:SWRVE_DEVICE_DPI];
    
    // Install Date / Version
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd"];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:self.installTimeSeconds];
    
    [deviceProperties setValue:[dateFormatter stringFromDate:date] forKey:SWRVE_INSTALL_DATE];
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
    [deviceProperties setValue:self.sdk_version     forKey:SWRVE_SDK_VERSION];
    [deviceProperties setValue:@"apple"             forKey:SWRVE_APP_STORE];
    [deviceProperties setValue:secondsFromGMT       forKey:SWRVE_UTC_OFFSET_SECONDS ];
    [deviceProperties setValue:timezone_name        forKey:SWRVE_TIMEZONE_NAME];
    [deviceProperties setValue:regionCountry        forKey:SWRVE_DEVICE_REGION];
    
    // Push properties
    if (self.deviceToken) {
        [deviceProperties setValue:self.deviceToken forKey:SWRVE_IOS_TOKEN];
    
        NSString *supported = ((SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) ? @"true" : @"false");
        [deviceProperties setValue:supported forKey:SWRVE_SUPPORT_RICH_BUTTONS];
        [deviceProperties setValue:supported forKey:SWRVE_SUPPORT_RICH_ATTACHMENT];
        [deviceProperties setValue:supported forKey:SWRVE_SUPPORT_RICH_GIF];
    }
    
    // Optional identifiers
#if defined(SWRVE_LOG_IDFA)
    if([[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled])
    {
        NSString *idfa = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
        [deviceProperties setValue:idfa forKey:SWRVE_IDFA];
    }
#endif //defined(SWRVE_LOG_IDFA)
    
#if defined(SWRVE_LOG_IDFV)
        NSString *idfv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        [deviceProperties setValue:idfv forKey:SWRVE_IDFV];
#endif //defined(SWRVE_LOG_IDFV)
    
    return deviceProperties;
}

+ (NSNumber *)deviceId {
    NSNumber *deviceId;
    id shortDeviceIdDisk = [[NSUserDefaults standardUserDefaults] objectForKey:@"short_device_id"];
    if (shortDeviceIdDisk == nil || ![shortDeviceIdDisk isKindOfClass:[NSNumber class]]) {
        // This is the first time we see this device, assign a UUID to it
        NSUInteger deviceUUID = [[[NSUUID UUID] UUIDString] hash];
        unsigned short newShortDeviceID = (unsigned short) deviceUUID;
        deviceId = [NSNumber numberWithUnsignedShort:newShortDeviceID];
        [[NSUserDefaults standardUserDefaults] setObject:deviceId forKey:@"short_device_id"];
    } else {
        deviceId = shortDeviceIdDisk;
    }
    return deviceId;
}

@end
