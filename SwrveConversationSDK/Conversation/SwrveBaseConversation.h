#import <Foundation/Foundation.h>
#import "SwrveMessageEventHandler.h"
#include <UIKit/UIKit.h>

const static int CONVERSATION_VERSION = 4;

@class SwrveConversationPane;

@interface SwrveBaseConversation : NSObject

@property (nonatomic, retain)            NSNumber* conversationID;            /*!< Identifies the conversation in a campaign */
@property (nonatomic, retain)            NSString* name;                      /*!< Name of the conversation */
@property (nonatomic, retain)            NSArray* pages;                      /*!< Pages of the message */

-(SwrveBaseConversation*) updateWithJSON:(NSDictionary*)json forController:(id<SwrveMessageEventHandler>)_controller;

/*! Create an in-app conversation from the JSON content.
 *
 * \param json In-app conversation JSON content.
 * \param controller Message controller.
 * \returns Parsed conversation.
 */
+(SwrveBaseConversation*)fromJSON:(NSDictionary*)json forController:(id<SwrveMessageEventHandler>)controller;

/*! Check if assets are downloaded.
 *
 * \returns TRUE if all assets have been downloaded.
 */
-(BOOL)assetsReady:(NSSet*)assets;

/*! Notify that this message was shown to the user.
 */
-(void)wasShownToUser;

/*! Return the page at a given index in the conversation
 */

-(SwrveConversationPane*)pageAtIndex:(NSUInteger)index;

/*! Return the page in the conversation with the given tag
 */

-(SwrveConversationPane*)pageForTag:(NSString*)tag;

/*! Check if font is given style is system font.
 *
 * \returns TRUE if font to use is system font.
 */
+(BOOL)isSystemFont:(NSDictionary *)style;

@end
