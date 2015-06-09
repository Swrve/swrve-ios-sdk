#import <Foundation/Foundation.h>

@class SwrveMessageController;
@class SwrveConversationCampaign;
@class SwrveConversationPane;

@interface SwrveConversation : NSObject

@property (nonatomic, weak)              SwrveConversationCampaign* campaign; /*!< Reference to parent campaign */
@property (nonatomic, retain)            NSNumber* conversationID;            /*!< Identifies the conversation in a campaign */
@property (nonatomic, retain)            NSString* name;                      /*!< Name of the conversation */
@property (nonatomic, retain)            NSArray* pages;                      /*!< Pages of the message */

/*! Create an in-app conversation from the JSON content.
 *
 * \param json In-app conversation JSON content.
 * \param campaign Parent conversationcampaign.
 * \param controller Message controller.
 * \returns Parsed conversation.
 */
+(SwrveConversation*)fromJSON:(NSDictionary*)json forCampaign:(SwrveConversationCampaign*)campaign forController:(SwrveMessageController*)controller;

/*! Check if assets are downloaded.
 *
 * \returns TRUE if all assets have been downloaded.
 */
-(BOOL)areDownloaded:(NSSet*)assets;

/*! Notify that this message was shown to the user.
 */
-(void)wasShownToUser;

/*! Return the page at a given index in the conversation
 */

-(SwrveConversationPane*)pageAtIndex:(NSUInteger)index;

/*! Return the page in the conversation with the given tag
 */

-(SwrveConversationPane*)pageForTag:(NSString*)tag;


@end
