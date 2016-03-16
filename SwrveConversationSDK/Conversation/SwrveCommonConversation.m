#import "SwrveCommon.h"
#import "SwrveCommonMessageController.h"
#import "SwrveContentItem.h"
#import "SwrveCommonConversation.h"
#import "SwrveConversationPane.h"

@interface SwrveCommonConversation()

@property (nonatomic, weak)     id<SwrveCommonMessageController> controller;

@end

@implementation SwrveCommonConversation

@synthesize controller, conversationID, name, pages;

-(SwrveCommonConversation*) updateWithJSON:(NSDictionary*)json
                             forController:(id<SwrveCommonMessageController>)_controller
{
    self.controller     = _controller;
    self.conversationID = [json objectForKey:@"id"];
    self.name           = [json objectForKey:@"name"];
    self.pages          = [json objectForKey:@"pages"];
    return self;
}

+(SwrveCommonConversation*) fromJSON:(NSDictionary*)json
                       forController:(id<SwrveCommonMessageController>)controller
{
    return [[[SwrveCommonConversation alloc] init] updateWithJSON:json forController:controller];
}

-(BOOL)assetsReady:(NSSet*)assets {
    for (NSDictionary* page in self.pages) {
        SwrveConversationPane *pane = [[SwrveConversationPane alloc] initWithDictionary:page];
        for (SwrveContentItem* contentItem in pane.content) {
            if([contentItem.type isEqualToString:kSwrveContentTypeImage]) {
                if([assets containsObject:contentItem.value]) {
                    return true;
                }
                else {
                    DebugLog(@"Conversation asset not yet downloaded: %@", contentItem.value);
                    return false;
                }
            }
        }
    }
    return true;
}

-(void)wasShownToUser {
    id<SwrveCommonMessageController> c = self.controller;
    if (c != nil) {
        [c conversationWasShownToUser:self];
    }
}

-(SwrveConversationPane*)pageAtIndex:(NSUInteger)index {
    if (index > self.pages.count - 1) {
        return nil;
    } else {
        return [[SwrveConversationPane alloc] initWithDictionary:[self.pages objectAtIndex:index]];
    }
}

-(SwrveConversationPane*)pageForTag:(NSString*)tag {
    for (NSDictionary *page in self.pages) {
        if ([tag isEqualToString:[page objectForKey:@"tag"]]) {
            return [[SwrveConversationPane alloc] initWithDictionary:page];
        }
    }
    return nil;
}

@end
