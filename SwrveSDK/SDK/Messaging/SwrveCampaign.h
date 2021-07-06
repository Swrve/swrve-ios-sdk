#import "SwrveCampaignStatus.h"
#if __has_include(<SwrveSDKCommon/SwrveQACampaignInfo.h>)
#import <SwrveSDKCommon/SwrveQACampaignInfo.h>
#else
#import "SwrveQACampaignInfo.h"
#endif

@class SwrveMessageController;

/*! Base campaign state. */
@interface SwrveCampaignState : NSObject

@property (atomic)            NSUInteger campaignID;                /*!< Unique identifier. */
@property (atomic)            NSUInteger impressions;               /*!< Amount of times this campaign has been shown for a user. */
@property (nonatomic)         SwrveCampaignStatus status;           /*!< The status of the Message Center campaign. */
@property (nonatomic, retain) NSDate* showMsgsAfterDelay;           /*!< Timestamp to block messages from appearing too frequently . */

/*! Initialize a fresh campaign status. */
-(id)initWithID:(NSUInteger)ID;

/*! Initialize the campaign status. */
-(id)initWithJSON:(NSDictionary*)data;

/*! Serialized state */
-(NSDictionary*)asDictionary;

@end

/*! Base campaign. */
@interface SwrveCampaign : NSObject

@property (atomic)            NSUInteger ID;                        /*!< Unique identifier. */
@property (nonatomic, retain) NSString* name;                       /*!< Name of the campaign. */
@property (atomic)            NSUInteger maxImpressions;            /*!< Maximum number of impressions per user. */
@property (atomic, retain)    SwrveCampaignState* state;            /*!< Saveable state of the campaign. */
@property (atomic)            NSTimeInterval minDelayBetweenMsgs;   /*!< Minimum interval between different campaigns being shown. */
@property (nonatomic, retain) NSDate* showMsgsAfterLaunch;          /*!< Timestamp to block messages after launch. */
@property (atomic)            bool messageCenter;                   /*!< Flag indicating if it is a Message Center campaign. */
@property (nonatomic, retain) NSString* subject;                    /*!< Message Center subject of the campaign. */
@property (nonatomic, retain) NSDate* dateStart;                    /*!< Timestamp representing the start date of Message Center campaign. */
@property (atomic)            SwrveCampaignType campaignType;       /*!< Enum representing the campaign type for QA Logging. */

/*! Initialize the campaign.
 *
 * \param time Used to initialize time-based rules.
 * \data json blob containing the campaign data.
 * \returns Initialized campaign.
 */
-(id)initAtTime:(NSDate *)time fromDictionary:(NSDictionary *)json;

#if TARGET_OS_IOS /** exclude tvOS **/
/*! Check if the campaign supports the given orientation.
 *
 * \returns true if the campaign supports the given orientation.
 */
-(BOOL)supportsOrientation:(UIInterfaceOrientation)orientation;
#endif

/*! Check if assets are downloaded.
 *
 * \returns TRUE if all assets have been downloaded.
 */
-(BOOL)assetsReady:(NSSet *)assets withPersonalization:(NSDictionary *)personalization;

@end
