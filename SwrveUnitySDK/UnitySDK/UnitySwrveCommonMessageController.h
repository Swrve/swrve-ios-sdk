#import "SwrveMessageEventHandler.h"
#import "SwrveBaseConversation.h"

@interface UnitySwrveMessageEventHandler : NSObject<SwrveMessageEventHandler>

-(SwrveBaseConversation*) conversationFromString:(NSString*)conversation;
-(void) showConversationFromString:(NSString*)conversation;

@end
