#if __has_include(<SwrveSDK/Swrve.h>)
#import <SwrveSDK/Swrve.h>
#import <SwrveSDK/SwrveMessageController.h>
#else
#import "Swrve.h"
#import "SwrveMessageController.h"
#endif

const static int CAMPAIGN_VERSION = 10;
const static int CAMPAIGN_RESPONSE_VERSION = 2;
const static int EMBEDDED_CAMPAIGN_VERSION = 4;
const static int IN_APP_CAMPAIGN_VERSION = 17;

/*! In-app messages controller */
@interface SwrveMessageController ()

/*! Initialize the message controller.
 *
 * \param swrve Swrve SDK instance.
 * \returns Initialized message controller.
 */
- (id)initWithSwrve:(Swrve *)swrve;

/*! Save campaigns current state*/
- (void)saveCampaignsState;


/*! Format the given time into POSIX time.
 *
 * \param date Date to format into text.
 * \returns Date formatted into a POSIX string.
 */
+ (NSString *)formattedTime:(NSDate *)date;

/*! Shuffle the given array randomly.
 *
 \param source Array to be shuffled.
 \returns Copy of the array, now shuffled randomly.
 */
+ (NSArray *)shuffled:(NSArray *)source;

/*! Called when an event is raised by the Swrve SDK.
 *
 * \param event Event triggered.
 * \returns YES if an in-app message was shown.
 */
- (BOOL)eventRaised:(NSDictionary *)event;

/**! Fire the personalization callback given as part of the SDK and combine it with real time user properties.
 *
 * \param payload the event payload that will be passed to the messageController's callback
 * \returns NSDictionary of the personalization properties.
 */
- (NSDictionary *)retrievePersonalizationProperties:(NSDictionary *)payload;

/*! Called when the app became active */
- (void)appDidBecomeActive;

- (void)refreshInAppCampaignAssets;

#pragma mark Properties

@property(nonatomic) Swrve *analyticsSDK;

#pragma mark -

@end

