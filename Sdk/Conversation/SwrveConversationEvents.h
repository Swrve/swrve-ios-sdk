#ifndef SwrveDemoFramework_SwrveConversationEvents_h
#define SwrveDemoFramework_SwrveConversationEvents_h

#include <Foundation/Foundation.h>

@class SwrveConversation;
@class SwrveConversationPane;

@interface SwrveConversationEvents : NSObject

// Conversation related
+(void)started:(SwrveConversation*)conversation onStartPage:(NSString*)startPageTag;
+(void)done:(SwrveConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag;
+(void)cancel:(SwrveConversation*)conversation onPage:(NSString*)pageTag;

// Page related
+(void)impression:(SwrveConversation*)conversation onPage:(NSString*)pageTag;
+(void)pageTransition:(SwrveConversation*)conversation fromPage:(NSString*)originPage toPage:(NSString*)toPage withControl:(NSString*)controlTag;

// Actions
+(void)linkVisit:(SwrveConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag;
+(void)callNumber:(SwrveConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag;
+(void)deeplinkVisit:(SwrveConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag;
+(void)permissionRequest:(SwrveConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag;

// Atom actions
+(void)gatherAndSendUserInputs:(SwrveConversationPane*)pane forConversation:(SwrveConversation*)conversation;

// Errors
+(void)error:(SwrveConversation*)conversation onPage:(NSString*)pageTag;
+(void)error:(SwrveConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag;
 
@end

#endif
