#import <Foundation/Foundation.h>
#import "SwrveBaseConversation.h"


@class SwrveMessageController;
@class SwrveConversationCampaign;

@interface SwrveConversation : SwrveBaseConversation

@property (nonatomic, retain)            SwrveConversationCampaign* campaign; /*!< Reference to parent campaign */
@property (nonatomic, retain)            NSNumber* conversationID;            /*!< Identifies the conversation in a campaign */
@property (nonatomic, retain)            NSString* name;                      /*!< Name of the conversation */
@property (nonatomic, retain)            NSArray* pages;                      /*!< Pages of the message */
@property (nonatomic, retain)            NSNumber* priority;                  /*!< Priority of the message */

/*! Create an in-app conversation from the JSON content.
 *
 * \param json In-app conversation JSON content.
 * \param campaign Parent conversationcampaign.
 * \param controller Message controller.
 * \returns Parsed conversation.
 */
- (id)initWithJSON:(NSDictionary *)json forCampaign:(SwrveConversationCampaign *)campaign forController:(SwrveMessageController *)controller;

@end
