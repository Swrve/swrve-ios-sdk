#import <XCTest/XCTest.h>
#import "SwrveTestHelper.h"

#if TARGET_OS_TV
#import "SwrveSDK_tvOSTests-Swift.h"
#else
#import "SwrveSDK_iOSTests-Swift.h"
#endif

@interface SwrveTestFreemarkerAssetPipeline : XCTestCase
@end

@implementation SwrveTestFreemarkerAssetPipeline

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

// ---------------------------------------------------------------------------
// MARK: - Helpers
// ---------------------------------------------------------------------------

/** Build a minimal SwrveInAppCampaign with freemarker_enabled=YES.
 *  The format (legacy single-page layout) contains:
 *    - one button with text `buttonText` and a static image_up asset "abc123"
 *    - one image (no static file) with dynamic_image_url `dynamicImageUrl`
 */
- (SwrveInAppCampaign *)freemarkerCampaignWithButtonText:(NSString *)buttonText
                                         dynamicImageUrl:(NSString *)dynamicImageUrl
                                         personalization:(NSDictionary *)personalization
                                             assetsQueue:(NSMutableSet *)assetsQueue {
    return [self freemarkerCampaignWithButtonText:buttonText
                                  dynamicImageUrl:dynamicImageUrl
                                     timezoneType:@"global"
                                  personalization:personalization
                                      assetsQueue:assetsQueue];
}

- (SwrveInAppCampaign *)freemarkerCampaignWithButtonText:(NSString *)buttonText
                                         dynamicImageUrl:(NSString *)dynamicImageUrl
                                            timezoneType:(NSString *)timezoneType
                                         personalization:(NSDictionary *)personalization
                                             assetsQueue:(NSMutableSet *)assetsQueue {
    NSDictionary *button = @{
        @"name": @"test_button",
        @"x": @{@"type": @"number", @"value": @0},
        @"y": @{@"type": @"number", @"value": @0},
        @"w": @{@"type": @"number", @"value": @100},
        @"h": @{@"type": @"number", @"value": @50},
        @"image_up": @{@"type": @"asset", @"value": @"abc123"},
        @"game_id": @{@"type": @"number", @"value": @"1"},
        @"text": @{@"type": @"text", @"value": buttonText},
        @"action": @{@"type": @"text", @"value": @"http://example.com"},
        @"type": @{@"type": @"text", @"value": @"CUSTOM"}
    };

    NSDictionary *image = @{
        @"name": @"background",
        @"dynamic_image_url": dynamicImageUrl,
        @"x": @{@"type": @"number", @"value": @0},
        @"y": @{@"type": @"number", @"value": @0},
        @"w": @{@"type": @"number", @"value": @300},
        @"h": @{@"type": @"number", @"value": @300}
    };

    NSDictionary *format = @{
        @"orientation": @"portrait",
        @"size": @{
            @"w": @{@"type": @"number", @"value": @320},
            @"h": @{@"type": @"number", @"value": @480}
        },
        @"images": @[image],
        @"buttons": @[button],
        @"name": @"test_format",
        @"language": @"en-US"
    };

    NSDictionary *message = @{
        @"id": @1001,
        @"name": @"FreeMarker Test",
        @"priority": @9999,
        @"template": @{@"formats": @[format]}
    };

    NSDictionary *campaignDict = @{
        @"id": @9999,
        @"freemarker_enabled": @YES,
        @"start_date_iso": @"2010-01-01T00:00:00Z",
        @"end_date_iso": @"2099-01-01T00:00:00Z",
        @"timezone_type": timezoneType,
        @"triggers": @[@{@"event_name": @"Swrve.currency_given", @"conditions": @{}}],
        @"rules": @{
            @"delay_first_message": @0,
            @"dismiss_after_views": @99,
            @"display_order": @"random",
            @"min_delay_between_messages": @0
        },
        @"message": message
    };

    SwrveMessageController *controller = [[SwrveMessageController alloc] init];
    return [[SwrveInAppCampaign alloc] initAtTime:[NSDate date]
                                    fromDictionary:campaignDict
                                   withAssetsQueue:assetsQueue
                                     forController:controller
                              withPersonalization:personalization];
}

/** SHA1 of a URL string — matches what addAssetToQueue and canResolvePersonalizedImageAsset produce. */
- (NSString *)sha1ForUrl:(NSString *)url {
    NSData *data = [url dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    return [SwrveUtils sha1:data];
}

// ---------------------------------------------------------------------------
// MARK: - canResolvePersonalization
// ---------------------------------------------------------------------------

/** FreeMarker button text resolves successfully when required properties are present. */
- (void)testCanResolvePersonalization_freemarkerButtonText_validProps_returnsTrue {
    NSString *buttonText = @"<#if Recipient.tier == \"platinum\">Buy Premium<#else>Buy Standard</#if>";
    NSDictionary *personalization = @{@"Recipient.tier": @"platinum"};

    NSMutableSet *assetsQueue = [NSMutableSet new];
    SwrveInAppCampaign *campaign = [self freemarkerCampaignWithButtonText:buttonText
                                                          dynamicImageUrl:@"https://cdn.example.com/img.png"
                                                          personalization:personalization
                                                              assetsQueue:assetsQueue];

    XCTAssertTrue(campaign.freemarkerEnabled, @"Campaign should have freemarkerEnabled set");
    BOOL result = [campaign.message canResolvePersonalization:personalization];
    XCTAssertTrue(result, @"canResolvePersonalization should return YES when FreeMarker text resolves");
}

/** FreeMarker button text fails when required properties are missing. */
- (void)testCanResolvePersonalization_freemarkerButtonText_missingProps_returnsFalse {
    NSString *buttonText = @"<#if Recipient.tier == \"platinum\">Buy Premium<#else>Buy Standard</#if>";
    NSDictionary *emptyPersonalization = @{};

    NSMutableSet *assetsQueue = [NSMutableSet new];
    SwrveInAppCampaign *campaign = [self freemarkerCampaignWithButtonText:buttonText
                                                          dynamicImageUrl:@"https://cdn.example.com/img.png"
                                                          personalization:emptyPersonalization
                                                              assetsQueue:assetsQueue];

    BOOL result = [campaign.message canResolvePersonalization:emptyPersonalization];
    XCTAssertFalse(result, @"canResolvePersonalization should return NO when FreeMarker property is missing");
}

/** Non-FreeMarker campaign with static button text always resolves. */
- (void)testCanResolvePersonalization_nonFreemarkerCampaign_staticText_returnsTrue {
    NSDictionary *button = @{
        @"name": @"btn",
        @"x": @{@"type": @"number", @"value": @0},
        @"y": @{@"type": @"number", @"value": @0},
        @"w": @{@"type": @"number", @"value": @100},
        @"h": @{@"type": @"number", @"value": @50},
        @"image_up": @{@"type": @"asset", @"value": @"abc123"},
        @"game_id": @{@"type": @"number", @"value": @"1"},
        @"text": @{@"type": @"text", @"value": @"Press me"},
        @"action": @{@"type": @"text", @"value": @"http://example.com"},
        @"type": @{@"type": @"text", @"value": @"CUSTOM"}
    };
    NSDictionary *format = @{
        @"orientation": @"portrait",
        @"size": @{@"w": @{@"type": @"number", @"value": @320}, @"h": @{@"type": @"number", @"value": @480}},
        @"images": @[],
        @"buttons": @[button],
        @"name": @"test_format",
        @"language": @"en-US"
    };
    NSDictionary *campaignDict = @{
        @"id": @8888,
        @"start_date_iso": @"2010-01-01T00:00:00Z",
        @"end_date_iso": @"2099-01-01T00:00:00Z",
        @"timezone_type": @"global",
        @"triggers": @[@{@"event_name": @"test", @"conditions": @{}}],
        @"rules": @{@"delay_first_message": @0, @"dismiss_after_views": @99,
                    @"display_order": @"random", @"min_delay_between_messages": @0},
        @"message": @{
            @"id": @1002,
            @"name": @"Non-FM Test",
            @"priority": @9999,
            @"template": @{@"formats": @[format]}
        }
    };

    SwrveMessageController *controller = [[SwrveMessageController alloc] init];
    SwrveInAppCampaign *campaign = [[SwrveInAppCampaign alloc] initAtTime:[NSDate date]
                                                            fromDictionary:campaignDict
                                                           withAssetsQueue:[NSMutableSet new]
                                                             forController:controller
                                                      withPersonalization:@{}];

    XCTAssertFalse(campaign.freemarkerEnabled);
    BOOL result = [campaign.message canResolvePersonalization:@{}];
    XCTAssertTrue(result, @"canResolvePersonalization should return YES for static text regardless of properties");
}

// ---------------------------------------------------------------------------
// MARK: - assetsReady
// ---------------------------------------------------------------------------

/** When the FreeMarker dynamic_image_url resolves and the resulting SHA1 is in the assets set,
 *  assetsReady returns YES. */
- (void)testAssetsReady_freemarkerDynamicImageUrl_correctAssetInSet_returnsTrue {
    NSString *dynamicImageUrl = @"<#if Recipient.tier == \"platinum\">https://cdn.example.com/platinum.png<#else>https://cdn.example.com/standard.png</#if>";
    NSDictionary *personalization = @{@"Recipient.tier": @"platinum"};

    NSMutableSet *assetsQueue = [NSMutableSet new];
    SwrveInAppCampaign *campaign = [self freemarkerCampaignWithButtonText:@"Press"
                                                          dynamicImageUrl:dynamicImageUrl
                                                          personalization:personalization
                                                              assetsQueue:assetsQueue];

    // Compute expected SHA1: the FreeMarker evaluator resolves to the platinum URL,
    // then SHA1 is used as the asset filename on disk.
    NSString *resolvedUrl = @"https://cdn.example.com/platinum.png";
    NSString *expectedImageHash = [self sha1ForUrl:resolvedUrl];

    // The button's static image_up ("abc123") must also be present.
    NSSet<NSString *> *assets = [NSSet setWithObjects:expectedImageHash, @"abc123", nil];
    BOOL result = [campaign.message assetsReady:assets withPersonalization:personalization];
    XCTAssertTrue(result, @"assetsReady should return YES when the resolved FreeMarker image SHA1 is in the assets set");
}

/** When the correct asset is absent, assetsReady returns NO. */
- (void)testAssetsReady_freemarkerDynamicImageUrl_missingAsset_returnsFalse {
    NSString *dynamicImageUrl = @"<#if Recipient.tier == \"platinum\">https://cdn.example.com/platinum.png<#else>https://cdn.example.com/standard.png</#if>";
    NSDictionary *personalization = @{@"Recipient.tier": @"platinum"};

    NSMutableSet *assetsQueue = [NSMutableSet new];
    SwrveInAppCampaign *campaign = [self freemarkerCampaignWithButtonText:@"Press"
                                                          dynamicImageUrl:dynamicImageUrl
                                                          personalization:personalization
                                                              assetsQueue:assetsQueue];

    // Only include the button's static asset; the FreeMarker image hash is absent.
    NSSet<NSString *> *assets = [NSSet setWithObject:@"abc123"];
    BOOL result = [campaign.message assetsReady:assets withPersonalization:personalization];
    XCTAssertFalse(result, @"assetsReady should return NO when the FreeMarker image SHA1 is not in the assets set");
}

/** When properties are missing and FreeMarker cannot evaluate, assetsReady returns NO. */
- (void)testAssetsReady_freemarkerDynamicImageUrl_missingProps_returnsFalse {
    NSString *dynamicImageUrl = @"<#if Recipient.tier == \"platinum\">https://cdn.example.com/platinum.png<#else>https://cdn.example.com/standard.png</#if>";

    NSMutableSet *assetsQueue = [NSMutableSet new];
    SwrveInAppCampaign *campaign = [self freemarkerCampaignWithButtonText:@"Press"
                                                          dynamicImageUrl:dynamicImageUrl
                                                          personalization:@{@"Recipient.tier": @"platinum"}
                                                              assetsQueue:assetsQueue];

    // Supply a large assets set, but personalization is now empty.
    NSSet<NSString *> *assetsEverything = [NSSet setWithObjects:
        @"abc123",
        [self sha1ForUrl:@"https://cdn.example.com/platinum.png"],
        [self sha1ForUrl:@"https://cdn.example.com/standard.png"],
        nil];
    BOOL result = [campaign.message assetsReady:assetsEverything withPersonalization:@{}];
    XCTAssertFalse(result, @"assetsReady should return NO when FreeMarker cannot evaluate due to missing props");
}

// ---------------------------------------------------------------------------
// MARK: - addAssetsToQueue
// ---------------------------------------------------------------------------

/** addAssetsToQueue enqueues a queue item whose 'name' is the SHA1 of the FreeMarker-resolved URL. */
- (void)testAddAssetsToQueue_freemarkerDynamicImageUrl_queuesResolvedAssetHash {
    NSString *dynamicImageUrl = @"<#if Recipient.tier == \"platinum\">https://cdn.example.com/platinum.png<#else>https://cdn.example.com/standard.png</#if>";
    NSDictionary *personalization = @{@"Recipient.tier": @"platinum"};

    NSMutableSet *assetsQueue = [NSMutableSet new];
    // init calls addAssetsToQueue internally
    [self freemarkerCampaignWithButtonText:@"Press"
                           dynamicImageUrl:dynamicImageUrl
                           personalization:personalization
                               assetsQueue:assetsQueue];

    NSString *resolvedUrl = @"https://cdn.example.com/platinum.png";
    NSString *expectedHash = [self sha1ForUrl:resolvedUrl];

    BOOL found = NO;
    for (NSDictionary *item in assetsQueue) {
        if ([[item objectForKey:@"name"] isEqualToString:expectedHash]) {
            found = YES;
            XCTAssertEqualObjects([item objectForKey:@"digest"], resolvedUrl,
                                  @"digest should be the resolved FreeMarker URL");
            XCTAssertTrue([[item objectForKey:@"isExternal"] boolValue],
                          @"FreeMarker-resolved URL assets should be marked as external");
            break;
        }
    }
    XCTAssertTrue(found, @"Expected SHA1 of the platinum URL to be in the assets queue");
}

/** A FreeMarker-enabled campaign with a plain URL (no FreeMarker syntax) passes through unchanged —
 *  the SHA1 of the unmodified URL is enqueued. */
- (void)testAddAssetsToQueue_freemarkerEnabledCampaign_plainUrl_queuesUrlSha {
    NSString *plainUrl = @"https://cdn.example.com/plain.png";
    NSDictionary *personalization = @{};

    NSMutableSet *assetsQueue = [NSMutableSet new];
    [self freemarkerCampaignWithButtonText:@"Press"
                           dynamicImageUrl:plainUrl
                           personalization:personalization
                               assetsQueue:assetsQueue];

    NSString *expectedHash = [self sha1ForUrl:plainUrl];
    BOOL found = NO;
    for (NSDictionary *item in assetsQueue) {
        if ([[item objectForKey:@"name"] isEqualToString:expectedHash]) {
            found = YES;
            break;
        }
    }
    XCTAssertTrue(found, @"Plain URL should be queued unchanged when FreeMarker evaluator finds no syntax");
}


/** A FreeMarker interpolation-only dynamic_image_url (no <# directive) is correctly evaluated
 *  by SwrveFreemarkerEvaluator and the right SHA1 is enqueued by addAssetToQueue and
 *  verified at display time by canResolvePersonalizedImageAsset. */
- (void)testAddAssetsToQueue_freemarkerInterpolationUrl_queuesResolvedHash {
    // URL uses FreeMarker ! default operator — no <# directive.
    NSString *dynamicImageUrl = @"https://cdn.example.com/${Recipient.tier!\"standard\"}.png";
    NSDictionary *personalization = @{@"Recipient.tier": @"platinum"};

    NSMutableSet *assetsQueue = [NSMutableSet new];
    [self freemarkerCampaignWithButtonText:@"Press"
                           dynamicImageUrl:dynamicImageUrl
                           personalization:personalization
                               assetsQueue:assetsQueue];

    // FreeMarker evaluates ${Recipient.tier!"standard"} → "platinum"
    NSString *resolvedUrl = @"https://cdn.example.com/platinum.png";
    NSString *expectedHash = [self sha1ForUrl:resolvedUrl];

    BOOL found = NO;
    for (NSDictionary *item in assetsQueue) {
        if ([[item objectForKey:@"name"] isEqualToString:expectedHash]) {
            found = YES;
            XCTAssertEqualObjects([item objectForKey:@"digest"], resolvedUrl);
            break;
        }
    }
    XCTAssertTrue(found, @"SHA1 of the FreeMarker-interpolated URL should be queued");
}

- (void)testAssetsReady_freemarkerInterpolationUrl_correctAssetInSet_returnsTrue {
    NSString *dynamicImageUrl = @"https://cdn.example.com/${Recipient.tier!\"standard\"}.png";
    NSDictionary *personalization = @{@"Recipient.tier": @"platinum"};

    NSMutableSet *assetsQueue = [NSMutableSet new];
    SwrveInAppCampaign *campaign = [self freemarkerCampaignWithButtonText:@"Press"
                                                          dynamicImageUrl:dynamicImageUrl
                                                          personalization:personalization
                                                              assetsQueue:assetsQueue];

    NSString *expectedHash = [self sha1ForUrl:@"https://cdn.example.com/platinum.png"];
    NSSet<NSString *> *assets = [NSSet setWithObjects:expectedHash, @"abc123", nil];
    XCTAssertTrue([campaign.message assetsReady:assets withPersonalization:personalization]);
}

// ---------------------------------------------------------------------------
// MARK: - visible_if
// ---------------------------------------------------------------------------

/** visible_if with a valid FreeMarker boolean expression passes canResolvePersonalization,
 *  even when freemarker_enabled is not set on the campaign. */
- (void)testCanResolvePersonalization_visibleIfButton_validExpression_returnsTrue {
    NSDictionary *button = @{
        @"name": @"conditional_btn",
        @"visible_if": @"show_button?boolean",
        @"x": @{@"type": @"number", @"value": @0},
        @"y": @{@"type": @"number", @"value": @0},
        @"w": @{@"type": @"number", @"value": @100},
        @"h": @{@"type": @"number", @"value": @50},
        @"image_up": @{@"type": @"asset", @"value": @"abc123"},
        @"action": @{@"type": @"text", @"value": @""},
        @"type": @{@"type": @"text", @"value": @"DISMISS"}
    };
    NSDictionary *format = @{
        @"orientation": @"portrait",
        @"size": @{@"w": @{@"type": @"number", @"value": @320}, @"h": @{@"type": @"number", @"value": @480}},
        @"images": @[],
        @"buttons": @[button],
        @"name": @"test_format",
        @"language": @"en-US"
    };
    NSDictionary *campaignDict = @{
        @"id": @7001,
        @"start_date_iso": @"2010-01-01T00:00:00Z",
        @"end_date_iso": @"2099-01-01T00:00:00Z",
        @"timezone_type": @"global",
        @"triggers": @[@{@"event_name": @"visible_if_test", @"conditions": @{}}],
        @"rules": @{@"delay_first_message": @0, @"dismiss_after_views": @99,
                    @"display_order": @"random", @"min_delay_between_messages": @0},
        @"message": @{
            @"id": @7001,
            @"name": @"VisibleIfTest",
            @"priority": @9999,
            @"template": @{@"formats": @[format]}
        }
    };

    SwrveMessageController *controller = [[SwrveMessageController alloc] init];
    SwrveInAppCampaign *campaign = [[SwrveInAppCampaign alloc] initAtTime:[NSDate date]
                                                            fromDictionary:campaignDict
                                                           withAssetsQueue:[NSMutableSet new]
                                                             forController:controller
                                                      withPersonalization:@{}];

    NSDictionary *personalization = @{@"show_button": @"true"};
    BOOL result = [campaign.message canResolvePersonalization:personalization];
    XCTAssertTrue(result, @"canResolvePersonalization should return YES when visible_if expression is valid");
}

/** visible_if on an image element (not a button) is also validated by canResolvePersonalization. */
- (void)testCanResolvePersonalization_visibleIfImage_validExpression_returnsTrue {
    NSDictionary *image = @{
        @"name": @"conditional_image",
        @"visible_if": @"show_image?boolean",
        @"color": @{@"type": @"color", @"value": @"FF0000"},
        @"x": @{@"type": @"number", @"value": @0},
        @"y": @{@"type": @"number", @"value": @0},
        @"w": @{@"type": @"number", @"value": @100},
        @"h": @{@"type": @"number", @"value": @50}
    };
    NSDictionary *format = @{
        @"orientation": @"portrait",
        @"size": @{@"w": @{@"type": @"number", @"value": @320}, @"h": @{@"type": @"number", @"value": @480}},
        @"images": @[image],
        @"buttons": @[],
        @"name": @"test_format",
        @"language": @"en-US"
    };
    NSDictionary *campaignDict = @{
        @"id": @7003,
        @"start_date_iso": @"2010-01-01T00:00:00Z",
        @"end_date_iso": @"2099-01-01T00:00:00Z",
        @"timezone_type": @"global",
        @"triggers": @[@{@"event_name": @"visible_if_image_test", @"conditions": @{}}],
        @"rules": @{@"delay_first_message": @0, @"dismiss_after_views": @99,
                    @"display_order": @"random", @"min_delay_between_messages": @0},
        @"message": @{
            @"id": @7003,
            @"name": @"VisibleIfImageTest",
            @"priority": @9999,
            @"template": @{@"formats": @[format]}
        }
    };

    SwrveMessageController *controller = [[SwrveMessageController alloc] init];
    SwrveInAppCampaign *campaign = [[SwrveInAppCampaign alloc] initAtTime:[NSDate date]
                                                            fromDictionary:campaignDict
                                                           withAssetsQueue:[NSMutableSet new]
                                                             forController:controller
                                                      withPersonalization:@{}];

    NSDictionary *personalization = @{@"show_image": @"true"};
    BOOL result = [campaign.message canResolvePersonalization:personalization];
    XCTAssertTrue(result, @"canResolvePersonalization should return YES for a valid visible_if on an image element");
}

/** visible_if with a malformed FreeMarker expression fails canResolvePersonalization. */
- (void)testCanResolvePersonalization_visibleIfButton_malformedExpression_returnsFalse {
    NSDictionary *button = @{
        @"name": @"malformed_btn",
        @"visible_if": @"[[[ INVALID FREEMARKER",
        @"x": @{@"type": @"number", @"value": @0},
        @"y": @{@"type": @"number", @"value": @0},
        @"w": @{@"type": @"number", @"value": @100},
        @"h": @{@"type": @"number", @"value": @50},
        @"image_up": @{@"type": @"asset", @"value": @"abc123"},
        @"action": @{@"type": @"text", @"value": @""},
        @"type": @{@"type": @"text", @"value": @"DISMISS"}
    };
    NSDictionary *format = @{
        @"orientation": @"portrait",
        @"size": @{@"w": @{@"type": @"number", @"value": @320}, @"h": @{@"type": @"number", @"value": @480}},
        @"images": @[],
        @"buttons": @[button],
        @"name": @"test_format",
        @"language": @"en-US"
    };
    NSDictionary *campaignDict = @{
        @"id": @7002,
        @"start_date_iso": @"2010-01-01T00:00:00Z",
        @"end_date_iso": @"2099-01-01T00:00:00Z",
        @"timezone_type": @"global",
        @"triggers": @[@{@"event_name": @"visible_if_malformed", @"conditions": @{}}],
        @"rules": @{@"delay_first_message": @0, @"dismiss_after_views": @99,
                    @"display_order": @"random", @"min_delay_between_messages": @0},
        @"message": @{
            @"id": @7002,
            @"name": @"VisibleIfMalformedTest",
            @"priority": @9999,
            @"template": @{@"formats": @[format]}
        }
    };

    SwrveMessageController *controller = [[SwrveMessageController alloc] init];
    SwrveInAppCampaign *campaign = [[SwrveInAppCampaign alloc] initAtTime:[NSDate date]
                                                            fromDictionary:campaignDict
                                                           withAssetsQueue:[NSMutableSet new]
                                                             forController:controller
                                                      withPersonalization:@{}];

    BOOL result = [campaign.message canResolvePersonalization:@{}];
    XCTAssertFalse(result, @"canResolvePersonalization should return NO when visible_if expression is malformed");
}

// ---------------------------------------------------------------------------
// MARK: - timezone_type wiring (end-to-end)
// ---------------------------------------------------------------------------

/** Proves the campaign's timezone_type is wired end-to-end into the FreeMarker evaluator so ?date
 *  comparisons resolve in the correct timezone. Recipient.b is 23:30 UTC on Apr 16 — still Apr 16
 *  in UTC (GLOBAL) but already Apr 17 in UTC+14 (LOCAL/device). Against Recipient.a = Apr 17,
 *  `a?date gt b?date` is true under GLOBAL (17 > 16 → "future") and false under LOCAL (17 > 17 →
 *  "past"), so the resolved dynamic-image URL — and therefore the asset that `assetsReady`
 *  accepts — differs purely by the campaign's timezone_type. */
- (void)testDynamicImageUrlDateConditionUsesCampaignTimezone {
    NSTimeZone *savedTimeZone = [NSTimeZone defaultTimeZone];
    // Fixed +14h offset (no tz-database lookup, never nil, no DST). The evaluator's LOCAL path reads
    // Calendar.current.timeZone, which reflects this overridden NSTimeZone.default — making it deterministic.
    [NSTimeZone setDefaultTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:14 * 3600]];
    @try {
        NSString *dynamicImageUrl = @"https://cdn.example.com/<#if Recipient.a?date gt Recipient.b?date>future<#else>past</#if>.png";
        NSDictionary *personalization = @{@"Recipient.a": @"2026-04-17", @"Recipient.b": @"2026-04-16T23:30:00Z"};
        // Build the asset sets in locals — inlining setWithObjects:...,nil inside an XCTAssert macro
        // would let the preprocessor mis-split on the commas (brackets don't protect macro args).
        NSString *futureSha1 = [self sha1ForUrl:@"https://cdn.example.com/future.png"];
        NSString *pastSha1 = [self sha1ForUrl:@"https://cdn.example.com/past.png"];
        NSSet<NSString *> *futureAssets = [NSSet setWithObjects:futureSha1, @"abc123", nil];
        NSSet<NSString *> *pastAssets = [NSSet setWithObjects:pastSha1, @"abc123", nil];

        // GLOBAL: ?date resolved in UTC → b is Apr 16 → a(17) gt b(16) → "future"
        SwrveInAppCampaign *globalCampaign = [self freemarkerCampaignWithButtonText:@"Press"
                                                                    dynamicImageUrl:dynamicImageUrl
                                                                       timezoneType:@"global"
                                                                    personalization:personalization
                                                                        assetsQueue:[NSMutableSet new]];
        XCTAssertTrue([globalCampaign.message assetsReady:futureAssets withPersonalization:personalization],
                      @"GLOBAL campaign should resolve ?date in UTC and accept the 'future' asset");
        XCTAssertFalse([globalCampaign.message assetsReady:pastAssets withPersonalization:personalization],
                       @"GLOBAL campaign should not accept the 'past' asset");

        // LOCAL: ?date resolved in device timezone (UTC+14) → b is Apr 17 → a(17) gt b(17) false → "past"
        SwrveInAppCampaign *localCampaign = [self freemarkerCampaignWithButtonText:@"Press"
                                                                   dynamicImageUrl:dynamicImageUrl
                                                                      timezoneType:@"local"
                                                                   personalization:personalization
                                                                       assetsQueue:[NSMutableSet new]];
        XCTAssertTrue([localCampaign.message assetsReady:pastAssets withPersonalization:personalization],
                      @"LOCAL campaign should resolve ?date in device timezone and accept the 'past' asset");
        XCTAssertFalse([localCampaign.message assetsReady:futureAssets withPersonalization:personalization],
                       @"LOCAL campaign should not accept the 'future' asset");
    } @finally {
        [NSTimeZone setDefaultTimeZone:savedTimeZone];
    }
}

@end
