#import "SwrveCommon.h"
#import "SwrveConversationEvents.h"
#import "SwrveCommonConversation.h"
#import "SwrveConversationAtom.h"
#import "SwrveConversationPane.h"
#import "SwrveInputMultiValue.h"
#import "SwrveContentVideo.h"
#import "SwrveContentStarRating.h"

@implementation SwrveConversationEvents

+(void)eventInternal:(NSString*)eventName payload:(NSDictionary*)eventPayload {
    [[SwrveCommon sharedInstance] eventInternal:eventName payload:eventPayload triggerCallback:true];
}

+(void)started:(SwrveCommonConversation*)conversation onStartPage:(NSString*)pageTag {
    [self genericEvent:@"start" forConversation:conversation onPage:pageTag];
}

+(void)done:(SwrveCommonConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag {
    [self genericEvent:@"done" forConversation:conversation onPage:pageTag withControl:controlTag];
}

+(void)cancel:(SwrveCommonConversation*)conversation onPage:(NSString*)pageTag {
    [self genericEvent:@"cancel" forConversation:conversation onPage:pageTag];
}

+(void)genericEvent:(NSString*)name forConversation:(SwrveCommonConversation*)conversation onPage:(NSString*)pageTag withControl:controlTag{
    NSDictionary *eventPayload =
    @{
      @"event" : name,
      @"page" : pageTag,
      @"conversation" : [conversation.conversationID stringValue],
      @"control" : controlTag
    };
    NSString *eventName = [self nameOf:name for:conversation];
    [self eventInternal:eventName payload:eventPayload];
}

+(void)genericEvent:(NSString*)name forConversation:(SwrveCommonConversation*)conversation onPage:(NSString*)pageTag {
    NSDictionary *eventPayload =
    @{
      @"event" : name,
      @"page" : pageTag,
      @"conversation" : [conversation.conversationID stringValue]
    };
    NSString *eventName = [self nameOf:name for:conversation];
    [self eventInternal:eventName payload:eventPayload];
}

+(NSString*)nameOf:(NSString*)event for:(SwrveCommonConversation*)conversation {
   return [NSString stringWithFormat:@"Swrve.Conversations.Conversation-%@.%@", conversation.conversationID, event];
}

// Page related
+(void)impression:(SwrveCommonConversation*)conversation onPage:(NSString*)pageTag {
    [self genericEvent:@"impression" forConversation:conversation onPage:pageTag];
}

+(void)pageTransition:(SwrveCommonConversation*)conversation fromPage:(NSString*)originPage toPage:(NSString*)toPage withControl:(NSString*)controlTag{
    NSDictionary *eventPayload =
    @{
      @"event" : @"navigation",
      @"to" : toPage,
      @"page" : originPage,
      @"conversation" : [conversation.conversationID stringValue],
      @"control" : controlTag
    };
    NSString *eventName = [self nameOf:@"navigation" for:conversation];
    [self eventInternal:eventName payload:eventPayload];
}

// Atom actions
+(void)gatherAndSendUserInputs:(SwrveConversationPane*)conversationPane forConversation:(SwrveCommonConversation*)conversation {
    // Send the queued user input elements
    for(SwrveConversationAtom *atom in conversationPane.content) {
        if([atom isKindOfClass:[SwrveInputMultiValue class]]) {
            SwrveInputMultiValue *item = (SwrveInputMultiValue*)atom;
            NSString* result = item.userResponse;
            if (result && ![result isEqualToString:@""]) {
                NSDictionary *payload =
                        @{
                                @"event" : @"choice",
                                @"page" : conversationPane.tag,
                                @"conversation" : [conversation.conversationID stringValue],
                                @"fragment" : item.tag,
                                @"result" : result
                        };
                NSString *eventName = [self nameOf:@"choice" for:conversation];
                [self eventInternal:eventName payload:payload];
            }
        } else if ([atom isKindOfClass:[SwrveContentVideo class]]) {
            SwrveContentVideo *item = (SwrveContentVideo*)atom;
            if (item.interactedWith) {
                NSDictionary *payload =
                @{
                  @"event" : @"play",
                  @"page" : conversationPane.tag,
                  @"conversation" : [conversation.conversationID stringValue],
                  @"fragment" : item.tag
                };
                NSString *eventName = [self nameOf:@"play" for:conversation];
                [self eventInternal:eventName payload:payload];
            }
        }  else if ([atom isKindOfClass:[SwrveContentStarRating class]]) {
            SwrveContentStarRating *item = (SwrveContentStarRating*)atom;
            if (item.currentRating > 0.0) {
                NSDictionary *payload =
                @{
                  @"event" : @"star-rating",
                  @"page" : conversationPane.tag,
                  @"conversation" : [conversation.conversationID stringValue],
                  @"fragment" : item.tag,
                  @"result" :[NSString stringWithFormat:@"%.01f", item.currentRating]
                  };
                NSString *eventName = [self nameOf:@"star-rating" for:conversation];
                [[SwrveCommon sharedInstance] eventInternal:eventName payload:payload triggerCallback:true];
            }
        }
    }

}

// Actions
+(void)linkVisit:(SwrveCommonConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag {
    [self genericEvent:@"visit" forConversation:conversation onPage:pageTag withControl:controlTag];
}

+(void)callNumber:(SwrveCommonConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag {
    [self genericEvent:@"call" forConversation:conversation onPage:pageTag withControl:controlTag];
}

+(void)deeplinkVisit:(SwrveCommonConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag {
    [self genericEvent:@"deeplink" forConversation:conversation onPage:pageTag withControl:controlTag];
}

+(void)permissionRequest:(SwrveCommonConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag {
    [self genericEvent:@"permission" forConversation:conversation onPage:pageTag withControl:controlTag];
}

// Error
+(void)error:(SwrveCommonConversation*)conversation onPage:(NSString*)pageTag {
    [self genericEvent:@"error" forConversation:conversation onPage:pageTag];
}

+(void)error:(SwrveCommonConversation*)conversation onPage:(NSString*)pageTag withControl:(NSString*)controlTag {
    [self genericEvent:@"error" forConversation:conversation onPage:pageTag withControl:controlTag];
}
@end
