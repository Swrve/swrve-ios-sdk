#import <Foundation/Foundation.h>
#import "SwrvePushConstants.h"

#pragma mark - internal keys
NSString *const SwrvePushDeprecatedDeeplinkKey= @"_d";
NSString *const SwrvePushDeeplinkKey = @"_sd";
NSString *const SwrvePushIdentifierKey = @"_p";
NSString *const SwrveInfluencedWindowMinsKey = @"_siw";
#pragma mark - silent push keys
NSString *const SwrveSilentPushIdentifierKey = @"_sp";
NSString *const SwrveInfluenceDataKey = @"swrve.influence_data";
NSString *const SwrveSilentPushPayloadKey = @"_s.SilentPayload";
NSString *const SwrvePushContentIdentifierKey = @"_sw";
NSString *const SwrvePushContentVersionKey = @"version";
int const SwrvePushContentVersion = 1;

#pragma mark - rich media keys
NSString *const SwrvePushMediaKey = @"media";
NSString *const SwrvePushTitleKey = @"title";
NSString *const SwrvePushSubtitleKey = @"subtitle";
NSString *const SwrvePushBodyKey = @"body";
NSString *const SwrvePushUrlKey = @"url";
NSString *const SwrvePushFallbackUrlKey = @"fallback_url";
NSString *const SwrvePushFallbackDeeplinkKey = @"fallback_sd";

#pragma mark - category button keys
NSString *const SwrvePushButtonListKey = @"buttons";
NSString *const SwrvePushButtonTitleKey = @"title";
NSString *const SwrvePushButtonActionTypeKey = @"action_type";
NSString *const SwrvePushButtonActionKey = @"action";
NSString *const SwrvePushButtonTypeKey = @"button_type";
NSString *const SwrvePushCustomButtonUrlIdentiferKey = @"open_url";
NSString *const SwrvePushButtonOptionsKey = @"button_options";

#pragma mark - category option / action keys
NSString *const SwrvePushCategoryTypeOptionsCarPlayKey = @"carplay";
NSString *const SwrvePushCategoryTypeOptionsCustomDismissKey = @"custom_dismiss";
NSString *const SwrvePushActionTypeForegroundKey = @"foreground";
NSString *const SwrvePushActionTypeDestructiveKey = @"destructive";
NSString *const SwrvePushActionTypeAuthorisationKey = @"auth-required";
NSString *const SwrvePushResponseDismissKey = @"com.apple.UNNotificationDismissActionIdentifier";
NSString *const SwrvePushResponseDefaultActionKey = @"com.apple.UNNotificationDefaultActionIdentifier";
