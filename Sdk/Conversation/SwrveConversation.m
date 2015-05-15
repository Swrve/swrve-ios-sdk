#import "Swrve.h"
#import "SwrveCampaign.h"
#import "SwrveMessageController.h"
#import "SwrveContentItem.h"
#import "SwrveConversation.h"
#import "SwrveConversationPane.h"

@interface SwrveConversation()

@property (nonatomic, weak)     SwrveMessageController* controller;

@end

@implementation SwrveConversation

@synthesize controller, campaign, conversationID, name, pages;

-(SwrveConversation*) updateWithJSON:(NSDictionary*)json
                         forCampaign:(SwrveConversationCampaign*)_campaign
                       forController:(SwrveMessageController*)_controller
{
    self.campaign       = _campaign;
    self.controller     = _controller;
    self.conversationID = [json objectForKey:@"id"];
    self.name           = [json objectForKey:@"name"];
    self.pages          = [json objectForKey:@"pages"];
    return self;
}

+(SwrveConversation*) fromJSON:(NSDictionary*)json
                   forCampaign:(SwrveConversationCampaign*)campaign
                 forController:(SwrveMessageController*)controller
{
    return [[[SwrveConversation alloc] init] updateWithJSON:json
                                                forCampaign:campaign
                                              forController:controller];
}

-(BOOL)areDownloaded:(NSSet*)assets {

    for (NSDictionary* page in self.pages) {
        SwrveConversationPane *pane = [[SwrveConversationPane alloc] initWithDictionary:page];
        for (SwrveContentItem* contentItem in pane.content) {
            if([contentItem.type isEqualToString:kSwrveContentTypeImage]) {
                if([assets containsObject:contentItem.value]) {
                    DebugLog(@"Conversation asset downloaded: %@", contentItem.value);
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
    SwrveMessageController* c = self.controller;
    if (c != nil) {
        [c conversationWasShownToUser:self];
    }
}

-(SwrveConversationPane*)pageAtIndex:(NSUInteger)index {
    if (index > self.pages.count - 1) {
        DebugLog(@"Seeking page %lu in a %lu-paged conversation", (unsigned long)index, (unsigned long)self.pages.count);
        return nil;
    } else {
        return [[SwrveConversationPane alloc] initWithDictionary:[self.pages objectAtIndex:index]];
    }
}

-(SwrveConversationPane*)pageForTag:(NSString*)tag {
    for (NSDictionary* page in self.pages) {
        if ([tag isEqualToString:[page objectForKey:@"tag"]]) {
            return [[SwrveConversationPane alloc] initWithDictionary:page];
        }
    }
    DebugLog(@"FAIL: page for tag %@ not found in conversation", tag);
    return nil;
}
@end
