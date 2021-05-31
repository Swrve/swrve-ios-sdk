#import "Swrve.h"
#import "SwrveConversation.h"

@interface SwrveConversation()

@property (nonatomic, weak)     SwrveMessageController* controller;

@end

@implementation SwrveConversation

@synthesize controller, campaign, conversationID, name, pages, priority;

-(id) initWithJSON:(NSDictionary*)json forCampaign:(SwrveConversationCampaign*)_campaign forController:(id<SwrveMessageEventHandler>)_controller {
    [self updateWithJSON:json forController:_controller];
    self.campaign       = _campaign;
    
    if ([json objectForKey:@"priority"]) {
        self.priority   = [json objectForKey:@"priority"];
    } else {
        self.priority   = [NSNumber numberWithInt:9999];
    }
    return self;
}

@end
