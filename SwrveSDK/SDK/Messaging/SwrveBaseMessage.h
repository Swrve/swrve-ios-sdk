#import <Foundation/Foundation.h>

@class SwrveCampaign;

@interface SwrveBaseMessage : NSObject

@property (nonatomic, retain)            SwrveCampaign *campaign; /*!< reference to campaign*/
@property (nonatomic, retain)            NSNumber *messageID;     /*!< Identifies the message in a campaign */
@property (nonatomic, retain)            NSNumber *priority;      /*!< Priority of the message */
@property (nonatomic, strong)            NSString *name;          /*!< Name of the message */

@end

