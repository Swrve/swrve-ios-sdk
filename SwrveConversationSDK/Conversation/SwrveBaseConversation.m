#import "SwrveCommon.h"
#import "SwrveMessageEventHandler.h"
#import "SwrveContentItem.h"
#import "SwrveBaseConversation.h"
#import "SwrveConversationPane.h"

@interface SwrveBaseConversation()

@property (nonatomic, weak)     id<SwrveMessageEventHandler> controller;

@end

@implementation SwrveBaseConversation

@synthesize controller, conversationID, name, pages;

-(SwrveBaseConversation*) updateWithJSON:(NSDictionary*)json
                             forController:(id<SwrveMessageEventHandler>)_controller
{
    self.controller     = _controller;
    self.conversationID = [json objectForKey:@"id"];
    self.name           = [json objectForKey:@"name"];
    self.pages          = [json objectForKey:@"pages"];
    return self;
}

+(SwrveBaseConversation*) fromJSON:(NSDictionary*)json
                       forController:(id<SwrveMessageEventHandler>)controller
{
    return [[[SwrveBaseConversation alloc] init] updateWithJSON:json forController:controller];
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
    id<SwrveMessageEventHandler> c = self.controller;
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
