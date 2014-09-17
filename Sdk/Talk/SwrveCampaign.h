@class SwrveMessage;
@class SwrveButton;
@class SwrveMessageController;

/*! In-app campaign. */
@interface SwrveCampaign : NSObject

@property (atomic)            NSUInteger ID;                        /*!< Unique identifier. */
@property (nonatomic, retain) NSString* name;                       /*!< Name of the campaign. */
@property (atomic, retain)    NSArray*  messages;                   /*!< List of messages. */
@property (atomic)            NSUInteger next;                      /*!< Next message to be shown if set-up as round robin. */
@property (atomic)            NSUInteger maxImpressions;            /*!< Maximum number of impressions per user. */
@property (atomic)            NSUInteger impressions;               /*!< Amount of times this campaign has been shown for a user. */
@property (atomic)            NSTimeInterval minDelayBetweenMsgs;   /*!< Minimum interval between different campaigns being shown. */
@property (nonatomic, retain) NSDate* showMsgsAfterLaunch;          /*!< Timestamp to block messages after launch. */
@property (nonatomic, retain) NSDate* showMsgsAfterDelay;           /*!< Timestamp to block messages from appearing too frequently . */

/*! Initialize the campaign.
 *
 * \param time Used to initialize time-based rules.
 * \returns Initialized campaign.
 */
-(id)initAtTime:(NSDate*)time;

/*! Check if the campaign has any message setup for the
 * given trigger.
 *
 * \param event Trigger event.
 * \returns TRUE if the campaign contains a message for the
 * given trigger.
 */
-(BOOL)hasMessageForEvent:(NSString*)event;

/*! Search for a message with the given trigger event and that satisfies
 * the specific rules for the campaign.
 *
 * \param event Trigger event.
 * \param withAssets Set of downloaded assets.
 * \param time Device time.
 * \returns Message setup for the given trigger or nil.
 */
-(SwrveMessage*)getMessageForEvent:(NSString*)event
                        withAssets:(NSSet*)assets
                            atTime:(NSDate*)time;

/*! Search for a message with the given trigger event and that satisfies
 * the specific rules for the campaign.
 *
 * \param event Trigger event.
 * \param withAssets Set of downloaded assets.
 * \param time Device time.
 * \param campaignReasons Will contain the reason the campaign returned no message.
 * \returns Message setup for the given trigger or nil.
 */
-(SwrveMessage*)getMessageForEvent:(NSString*)event
                        withAssets:(NSSet*)assets
                            atTime:(NSDate*)time
                       withReasons:(NSMutableDictionary*)campaignReasons;

/*! Increment impressions by one.
 */
-(void)incrementImpressions;

/*! Notify that a message was shown to the user.
 *
 * \param message Message that was shown to the user.
 */
-(void)messageWasShownToUser:(SwrveMessage*)message;

/*! Notify that a message was dismissed.
 *
 * \param timeDismissed When was the message dismissed.
 */
-(void)messageDismissed:(NSDate*)timeDismissed;

/*! Get the campaign settings.
 *
 * \returns Stored campaign settings.
 */
-(NSDictionary*)campaignSettings;

/*! Load the triggers from the JSON response.
 *
 * \param json JSON object containing the triggers.
 */
-(void)loadTriggersFrom:(NSDictionary*)json;

/*! Load the rules from the JSON response.
 *
 * \param json JSON object containing the rules.
 */
-(void)loadRulesFrom:(NSDictionary*)json;

/*! Load the start and end dates from the JSON response.
 *
 * \param json JSON object containing the dates.
 */
-(void)loadDatesFrom:(NSDictionary*)json;

@end
