#import "SwrveUtils.h"
#import "SwrveCommon.h"
#import <CommonCrypto/CommonHMAC.h>

@implementation SwrveUtils

+ (CGRect)deviceScreenBounds {
    UIScreen *screen   = [UIScreen mainScreen];
    CGRect bounds = [screen bounds];
    float screen_scale = (float)[[UIScreen mainScreen] scale];
    bounds.size.width  = bounds.size.width  * screen_scale;
    bounds.size.height = bounds.size.height * screen_scale;
    const int side_a = (int)bounds.size.width;
    const int side_b = (int)bounds.size.height;
    bounds.size.width  = (side_a > side_b)? side_b : side_a;
    bounds.size.height = (side_a > side_b)? side_a : side_b;
    return bounds;
}

+ (float)estimate_dpi {
    float scale = (float)[[UIScreen mainScreen] scale];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return 132.0f * scale;
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        return 163.0f * scale;
    }
    return 160.0f * scale;
}

+ (NSString *)hardwareMachineName {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = (char*)malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

#if TARGET_OS_IOS /** exclude tvOS **/
+ (CTCarrier*) carrierInfo {
    // Obtain carrier info from the device
    static CTTelephonyNetworkInfo *netinfo;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        netinfo = [CTTelephonyNetworkInfo new];
    });
    
    // It's possible to have devices with multiple SIM cards
    if (@available(iOS 12, *)) {
        return [[netinfo serviceSubscriberCellularProviders] allValues].firstObject;
    }
    else {
	    // We won't get carrier info in iOS 11, but this is only way to make it compatible
        return [CTCarrier new];
    }
}
#endif

+ (NSDictionary *)parseURLQueryParams:(NSString *)queryString API_AVAILABLE(ios(7.0)) {
    NSMutableDictionary *queryParams = [NSMutableDictionary new];
    NSArray *queryElements = [queryString componentsSeparatedByString:@"&"];
    for (NSString *element in queryElements) {
        NSArray *keyVal = [element componentsSeparatedByString:@"="];
        if (keyVal.count > 0) {
            NSString *paramKey = [keyVal objectAtIndex:0];
            NSString *paramValue = (keyVal.count == 2) ? [[keyVal lastObject] stringByRemovingPercentEncoding] : nil;
            if (paramValue != nil) {
                [queryParams setObject:paramValue forKey:paramKey];
            }
        }
    }
    return queryParams;
}

+ (NSString *)getStringFromDic:(NSDictionary *)dic withKey:(NSString *)key {
    id value = [dic objectForKey:key];
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    } else if ([value respondsToSelector:@selector(stringValue)]) {
        return [value stringValue];
    } else {
        // return nil regarding couldn't find a valid string from this key.
        return nil;
    }
}

+ (UInt64)getTimeEpoch {
    struct timeval time;
    gettimeofday(&time, NULL);
    return (((UInt64) time.tv_sec) * 1000) + (((UInt64) time.tv_usec) / 1000);
}

+ (BOOL)supportsConversations {
#if TARGET_OS_IOS /** conversations are only supported in iOS **/
    return YES;
#endif
    return NO;
}

@end
