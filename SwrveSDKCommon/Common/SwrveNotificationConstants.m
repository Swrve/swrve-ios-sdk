#import "SwrveNotificationConstants.h"

#pragma mark - internal keys
NSString *const SwrveNotificationDeprecatedDeeplinkKey = @"_d";
NSString *const SwrveNotificationDeeplinkKey = @"_sd";
NSString *const SwrveNotificationIdentifierKey = @"_p";
NSString *const SwrveNotificationSilentPushIdentifierKey = @"_sp";
NSString *const SwrveNotificationSilentPushPayloadKey = @"_s.SilentPayload";

#pragma mark - notification keys
NSString *const SwrveNotificationContentIdentifierKey = @"_sw";
NSString *const SwrveNotificationContentVersionKey = @"version";
int const SwrveNotificationContentVersion = 1;
NSString *const SwrveNotificationCampaignTypeKey = @"campaign_type";
NSString *const SwrveNotificationCampaignTypeGeo = @"geo";
NSString *const SwrveNotificationCampaignTypePush = @"push";
NSString *const SwrveNotificationEventPayload = @"event_payload";
NSString *const SwrveNotificationAuthenticatedUserKey = @"_aui";
NSString *const SwrveNotificationMediaDownloadFailed = @"media_failed";

#pragma mark - campaign key
NSString *const SwrveCampaignKey = @"campaign";

#pragma mark - rich media keys
NSString *const SwrveNotificationMediaKey = @"media";
NSString *const SwrveNotificationTitleKey = @"title";
NSString *const SwrveNotificationSubtitleKey = @"subtitle";
NSString *const SwrveNotificationBodyKey = @"body";
NSString *const SwrveNotificationUrlKey = @"url";
NSString *const SwrveNotificationFallbackUrlKey = @"fallback_url";
NSString *const SwrveNotificationFallbackDeeplinkKey = @"fallback_sd";

#pragma mark - category button keys
NSString *const SwrveNotificationButtonListKey = @"buttons";
NSString *const SwrveNotificationButtonTitleKey = @"title";
NSString *const SwrveNotificationButtonActionTypeKey = @"action_type";
NSString *const SwrveNotificationButtonActionKey = @"action";
NSString *const SwrveNotificationButtonTypeKey = @"button_type";
NSString *const SwrveNotificationCustomButtonUrlIdentiferKey = @"open_url";
NSString *const SwrveNotificationCategoryOptionsKey = @"category_options";
NSString *const SwrveNotificaitonCustomButtonCampaignIdentiferKey = @"open_campaign";

#pragma mark - category option / action keys
NSString *const SwrveNotificationCategoryTypeOptionsCarPlayKey = @"carplay";
NSString *const SwrveNotificationCategoryTypeOptionsCustomDismissKey = @"custom_dismiss";
NSString *const SwrveNotificationCategoryTypeOptionsHiddenShowTitleKey = @"hidden_show_title";
NSString *const SwrveNotificationCategoryTypeOptionsHiddenShowSubtitleKey = @"hidden_show_subtitle";
NSString *const SwrveNotificationActionTypeForegroundKey = @"foreground";
NSString *const SwrveNotificationActionTypeDestructiveKey = @"destructive";
NSString *const SwrveNotificationActionTypeAuthorisationKey = @"auth-required";
NSString *const SwrveNotificationHiddenPreviewTextPlaceholderKey = @"hidden_placeholder";
NSString *const SwrveNotificationResponseDefaultActionKey = @"com.apple.UNNotificationDefaultActionIdentifier";
