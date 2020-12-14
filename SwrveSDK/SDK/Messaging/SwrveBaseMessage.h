#import <Foundation/Foundation.h>

@class SwrveCampaign;

@interface SwrveBaseMessage : NSObject

@property (nonatomic, weak)              SwrveCampaign *campaign; /*!< reference to campaign*/
@property (nonatomic, retain)            NSNumber *messageID;     /*!< Identifies the message in a campaign */
@property (nonatomic, retain)            NSNumber *priority;      /*!< Priority of the message */

@end

