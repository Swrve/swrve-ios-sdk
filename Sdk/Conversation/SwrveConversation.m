#import "Swrve.h"
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
    self.pages          = [[NSMutableArray alloc] init];
    NSArray* pagesJson  = [json objectForKey:@"pages"];
    for (NSDictionary* page in pagesJson) {
        [self.pages addObject:[[SwrveConversationPane alloc] initWithDictionary:page]];
    }
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
    for (SwrveConversationPane *pane in self.pages) {
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
    SwrveMessageController* c = self.controller;
    if (c != nil) {
        [c conversationWasShownToUser:self];
    }
}

-(SwrveConversationPane*)pageAtIndex:(NSUInteger)index {
    if (index > self.pages.count - 1) {
        return nil;
    } else {
        return [self.pages objectAtIndex:index];
    }
}

-(SwrveConversationPane*)pageForTag:(NSString*)tag {
    for (SwrveConversationPane* page in self.pages) {
        if ([tag isEqualToString:[page tag]]) {
            return page;
        }
    }
    return nil;
}
@end
