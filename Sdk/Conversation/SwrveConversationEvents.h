#ifndef SwrveDemoFramework_SwrveConversationEvents_h
#define SwrveDemoFramework_SwrveConversationEvents_h

#include <Foundation/Foundation.h>

@class SwrveCommonConversation;
@class SwrveConversationPane;

@interface SwrveConversationEvents : NSObject

// Conversation related
+(void)started:(SwrveCommonConversation*)conversation onStartPage:(NSString*)startPageTag;
+(void)done:(SwrveCommonConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag;
+(void)cancel:(SwrveCommonConversation*)conversation onPage:(NSString*)pageTag;

// Page related
+(void)impression:(SwrveCommonConversation*)conversation onPage:(NSString*)pageTag;
+(void)pageTransition:(SwrveCommonConversation*)conversation fromPage:(NSString*)originPage toPage:(NSString*)toPage withControl:(NSString*)controlTag;

// Actions
+(void)linkVisit:(SwrveCommonConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag;
+(void)callNumber:(SwrveCommonConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag;
+(void)deeplinkVisit:(SwrveCommonConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag;
+(void)permissionRequest:(SwrveCommonConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag;

// Atom actions
+(void)gatherAndSendUserInputs:(SwrveConversationPane*)pane forConversation:(SwrveCommonConversation*)conversation;

// Errors
+(void)error:(SwrveCommonConversation*)conversation onPage:(NSString*)pageTag;
+(void)error:(SwrveCommonConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag;
 
@end

#endif
