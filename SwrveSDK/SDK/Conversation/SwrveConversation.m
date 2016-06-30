#import "Swrve.h"
#import "SwrveContentItem.h"
#import "SwrveConversation.h"
#import "SwrveConversationPane.h"

@interface SwrveConversation()

@property (nonatomic, weak)     SwrveMessageController* controller;

@end

@implementation SwrveConversation

@synthesize controller, campaign, conversationID, name, pages, priority;

-(SwrveConversation*) updateWithJSON:(NSDictionary*)json
                         forCampaign:(SwrveConversationCampaign*)_campaign
                       forController:(SwrveMessageController*)_controller
{
    self.campaign       = _campaign;
    self.controller     = _controller;
    self.conversationID = [json objectForKey:@"id"];
    self.name           = [json objectForKey:@"name"];
    NSArray* jsonPages  = [json objectForKey:@"pages"];
    NSMutableArray* loadedPages = [[NSMutableArray alloc] init];
    for (NSDictionary* pageJson in jsonPages) {
        [loadedPages addObject:[[SwrveConversationPane alloc] initWithDictionary:pageJson]];
    }
    self.pages = loadedPages;
    
    if ([json objectForKey:@"priority"]) {
        self.priority   = [json objectForKey:@"priority"];
    } else {
        self.priority   = [NSNumber numberWithInt:9999];
    }
    return self;
}

+(SwrveConversation*) fromJSON:(NSDictionary*)json
                   forCampaign:(SwrveConversationCampaign*)campaign
                 forController:(SwrveMessageController*)controller
{
    return [[[SwrveConversation alloc] init] updateWithJSON:json forCampaign:campaign forController:controller];
}

@end
