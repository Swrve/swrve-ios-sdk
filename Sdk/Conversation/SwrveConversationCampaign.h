#import "SwrveBaseCampaign.h"
#import "SwrveConversation.h"

@class SwrveMessageController;

/*! In-app conversation campaign. */
@interface SwrveConversationCampaign : SwrveBaseCampaign

@property (atomic)            NSUInteger ID;                        /*!< Unique identifier. */
@property (nonatomic, retain) NSString* name;                       /*!< Name of the campaign. */
@property (atomic)            NSUInteger maxImpressions;            /*!< Maximum number of impressions per user. */
@property (atomic)            NSUInteger impressions;               /*!< Amount of times this campaign has been shown for a user. */
@property (atomic)            NSTimeInterval minDelayBetweenMsgs;   /*!< Minimum interval between different campaigns being shown. */
@property (nonatomic, retain) NSDate* showMsgsAfterLaunch;          /*!< Timestamp to block messages after launch. */
@property (nonatomic, retain) NSDate* showMsgsAfterDelay;           /*!< Timestamp to block messages from appearing too frequently . */
@property (atomic)            NSUInteger next;                      /*!< Next message to be shown if set-up as round robin. */

@property (atomic, retain)    SwrveConversation*  conversation;     /*!< Conversation attached to this campaign. */

/*! Check if the campaign has any conversation setup for the
 * given trigger.
 *
 * \param event Trigger event.
 * \returns TRUE if the campaign contains a conversation for the
 * given trigger.
 */
-(BOOL)hasConversationForEvent:(NSString*)event;

/*! Search for a conversation with the given trigger event and that satisfies
 * the specific rules for the campaign.
 *
 * \param event Trigger event.
 * \param withAssets Set of downloaded assets.
 * \param time Device time.
 * \returns Conversation setup for the given trigger or nil.
 */
-(SwrveConversation*)getConversationForEvent:(NSString*)event
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
-(SwrveConversation*)getConversationForEvent:(NSString*)event
                        withAssets:(NSSet*)assets
                            atTime:(NSDate*)time
                       withReasons:(NSMutableDictionary*)campaignReasons;

/*! Notify that a conversation was shown to the user.
 *
 * \param conversation Conversation that was shown to the user.
 */
-(void)conversationWasShownToUser:(SwrveConversation*)conversation;

-(void)conversationWasShownToUser:(SwrveConversation*)conversation at:(NSDate*)timeShown;

/*! Notify that a conversation was dismissed.
 *
 * \param timeDismissed When was the conversation dismissed.
 */
-(void)conversationDismissed:(NSDate*)timeDismissed;

@end
