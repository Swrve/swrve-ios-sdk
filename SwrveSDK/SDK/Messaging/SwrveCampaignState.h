#import <Foundation/Foundation.h>
#import "SwrveCampaignStatus.h"


NS_ASSUME_NONNULL_BEGIN

/*! Base campaign state. */
@interface SwrveCampaignState : NSObject

@property(atomic) NSUInteger campaignID;                    /*!< Unique identifier. */
@property(atomic) NSUInteger impressions;                   /*!< Amount of times this campaign has been shown for a user. */
@property(nonatomic) SwrveCampaignStatus status;            /*!< The status of the Message Center campaign. */
@property(nonatomic, retain) NSDate *showMsgsAfterDelay;    /*!< Timestamp to block messages from appearing too frequently . */
@property(nonatomic, retain) NSDate *downloadDate;   /*!< Timestamp campaign was first download . */

/*! Initialize a fresh campaign status. */
- (id)initWithID:(NSUInteger)ID date:(NSDate *)date;

/*! Initialize the campaign status. */
- (id)initWithJSON:(NSDictionary *)data;

/*! Serialized state */
- (NSDictionary *)asDictionary;

@end

NS_ASSUME_NONNULL_END
