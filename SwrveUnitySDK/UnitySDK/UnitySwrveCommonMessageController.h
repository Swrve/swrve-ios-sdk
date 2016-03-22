#import "SwrveMessageEventHandler.h"

@interface UnitySwrveMessageEventHandler : NSObject<SwrveMessageEventHandler>

-(void) showConversationFromString:(NSString*)_conversation;

@end
