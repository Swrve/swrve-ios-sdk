#import "SwrveCampaign.h"
#import "SwrveMessage.h"

@class SwrveMessageController;

/*! In-app campaign. */
@interface SwrveInAppCampaign : SwrveCampaign

@property(atomic, retain) SwrveMessage *message; /*!< Message attached to this campaign. */

- (id)initAtTime:(NSDate *)time fromDictionary:(NSDictionary *)json withAssetsQueue:(NSMutableSet *)assetsQueue forController:(SwrveMessageController *)controller withPersonalization:(NSDictionary *)personalization;

- (void)addAssetsToQueue:(NSMutableSet *)assetsQueue withPersonalization:(NSDictionary *)personalization;

/*! Check if the campaign has any message setup for the
 * given trigger.
 *
 * \param event Trigger event.
 * \returns TRUE if the campaign contains a message for the
 * given trigger.
 */
- (BOOL)hasMessageForEvent:(NSString *)event;

/*! Check if the campaign has any message setup for the
 * given trigger.
 *
 * \param event Trigger event.
 * \param payload Payload for verifying conditions
 * \returns TRUE if the campaign contains a message for the
 * given trigger.
 */
- (BOOL)hasMessageForEvent:(NSString *)event withPayload:(NSDictionary *)payload;

/*! Search for a message with the given trigger event and that satisfies
 * the specific rules for the campaign.
 *
 * \param event Trigger event.
 * \param assets Set of downloaded assets.
 * \param personalization Dictionary of properties which can be resolved for the assets
 * \param time Device time.
 * \returns Message setup for the given trigger or nil.
 */
- (SwrveMessage *)messageForEvent:(NSString *)event
                       withAssets:(NSSet *)assets
              withPersonalization:(NSDictionary *)personalization
                           atTime:(NSDate *)time;

/*! Search for a message with the given trigger event and that satisfies
 * the specific rules for the campaign.
 *
 * \param event Trigger event.
 * \param payload Payload
 * \param assets Set of downloaded assets.
 * \param personalization Dictionary of properties which can be resolved for the assets
 * \param time Device time.
 * \param campaignReasons Will contain the reason the campaign returned no message.
 * \returns Message setup for the given trigger or nil.
 */
- (SwrveMessage *)messageForEvent:(NSString *)event
                      withPayload:(NSDictionary *)payload
                       withAssets:(NSSet *)assets
              withPersonalization:(NSDictionary *)personalization
                           atTime:(NSDate *)time
                      withReasons:(NSMutableDictionary *)campaignReasons;

/*! Notify that a message was shown to the user.
 *
 * \param messageShown Message that was shown to the user.
 */
- (void)messageWasShownToUser:(SwrveMessage *)messageShown;

/*! Notify that a message was dismissed.
 *
 * \param timeDismissed When was the message dismissed.
 */
- (void)messageDismissed:(NSDate *)timeDismissed;

@end
