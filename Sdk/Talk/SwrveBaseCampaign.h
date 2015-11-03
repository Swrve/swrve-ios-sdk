#import "SwrveCampaignStatus.h"
@class SwrveMessageController;

/*! Base campaign. */
@interface SwrveBaseCampaign : NSObject

@property (atomic)            NSUInteger ID;                        /*!< Unique identifier. */
@property (nonatomic, retain) NSString* name;                       /*!< Name of the campaign. */
@property (atomic)            NSUInteger maxImpressions;            /*!< Maximum number of impressions per user. */
@property (atomic)            NSUInteger impressions;               /*!< Amount of times this campaign has been shown for a user. */
@property (atomic)            NSTimeInterval minDelayBetweenMsgs;   /*!< Minimum interval between different campaigns being shown. */
@property (nonatomic, retain) NSDate* showMsgsAfterLaunch;          /*!< Timestamp to block messages after launch. */
@property (nonatomic, retain) NSDate* showMsgsAfterDelay;           /*!< Timestamp to block messages from appearing too frequently . */
@property (atomic)            NSUInteger next;                      /*!< Next message to be shown if set-up as round robin. */
@property (atomic)            bool inbox;                           /*!< Flag indicating if it is an Inbox campaign. */
@property (nonatomic, retain) NSString* subject;                    /*!< Inbox subject of the campaign. */
@property (nonatomic)         SwrveCampaignStatus status;           /*!< The status of the Inbox campaign. */

/*! Initialize the campaign.
 *
 * \param time Used to initialize time-based rules.
 * \data json blob containing the campaign data.
 * \returns Initialized campaign.
 */
-(id)initAtTime:(NSDate*)time fromJSON:(NSDictionary*)data withAssetsQueue:(NSMutableSet*)assetsQueue forController:(SwrveMessageController*)controller;

/*! PRIVATE: Notify when the campaign was displayed.
 */
-(void)wasShownToUserAt:(NSDate*)timeShown;

/*! PRIVATE: Get the campaign settings.
 *
 * \returns Stored campaign settings.
 */
-(NSMutableDictionary*)campaignSettings;

/*! PRIVATE: Load the campaign settings. */
-(void)loadSettings:(NSDictionary*)settings;

/*! PRIVATE: Returns true if the campaign is active at a given time . */
-(BOOL)isActive:(NSDate*)date withReasons:(NSMutableDictionary*)campaignReasons;

/*! PRIVATE: Set the message mimimum delay time. */
-(void)setMessageMinDelayThrottle:(NSDate*)timeShown;

/*! PRIVATE: Add the required assets to the given queue. */
-(void)addAssetsToQueue:(NSMutableSet*)assetsQueue;

@end
