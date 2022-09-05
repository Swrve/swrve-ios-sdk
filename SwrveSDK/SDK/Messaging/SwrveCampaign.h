#import "SwrveCampaignState.h"
#import "SwrveMessageCenterDetails.h"

#if __has_include(<SwrveSDKCommon/SwrveQACampaignInfo.h>)

#import <SwrveSDKCommon/SwrveQACampaignInfo.h>

#else
#import "SwrveQACampaignInfo.h"
#endif

@class SwrveMessageController;

/*! Base campaign. */
@interface SwrveCampaign : NSObject

@property(atomic) NSUInteger ID;                            /*!< Unique identifier. */
@property(nonatomic, retain) NSString *name;                /*!< Name of the campaign. */
@property(atomic) NSUInteger maxImpressions;                /*!< Maximum number of impressions per user. */
@property(atomic, retain) SwrveCampaignState *state;        /*!< Saveable state of the campaign. */
@property(atomic) NSTimeInterval minDelayBetweenMsgs;       /*!< Minimum interval between different campaigns being shown. */
@property(nonatomic, retain) NSDate *showMsgsAfterLaunch;   /*!< Timestamp to block messages after launch. */
@property(atomic) bool messageCenter;                       /*!< Flag indicating if it is a Message Center campaign. */
@property(nonatomic, retain) NSString *subject __deprecated_msg ("This is populated by the Campaign description field from your Dashboard. Migrate to using the SwrveMessageCenterDetails subject"); /*!<Message Center Campaign subject */
@property(nonatomic, retain) NSDate *dateStart;             /*!< Timestamp representing the start date of Message Center campaign. */
@property(atomic) SwrveCampaignType campaignType;           /*!< Enum representing the campaign type for QA Logging. */
@property(retain, nonatomic) NSDate *dateEnd;               /*!< Timestamp representing the ed date of Message Center campaign. */
@property(retain, nonatomic) NSNumber *priority;            /*!< Priority of the campain */
@property(retain, atomic) SwrveMessageCenterDetails *messageCenterDetails;  /*!< Message Center campaign details, subject , decsription and icon*/

/*! Initialize the campaign.
 *
 * \param time Used to initialize time-based rules.
 * \data json blob containing the campaign data.
 * \returns Initialized campaign.
 */
- (id)initAtTime:(NSDate *)time fromDictionary:(NSDictionary *)json;

#if TARGET_OS_IOS /** exclude tvOS **/

/*! Check if the campaign supports the given orientation.
 *
 * \returns true if the campaign supports the given orientation.
 */
- (BOOL)supportsOrientation:(UIInterfaceOrientation)orientation;

#endif

/*! Check if assets are downloaded.
 *
 * \returns TRUE if all assets have been downloaded.
 */
- (BOOL)assetsReady:(NSSet *)assets withPersonalization:(NSDictionary *)personalization;

/*! Get the date the campaign was downloaded.
 *
 * \returns date the campaign was downloaded.
 */
- (NSDate *)downloadDate;

@end
