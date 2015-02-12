//
//  SwrveConversation.m
//  swrvinator
//
//  Created by Oisin Hurley on 06/01/2015.
//  Copyright (c) 2015 Converser. All rights reserved.
//
#import "SwrveCampaign.h"
#import "SwrveMessageController.h"
#import "SwrveConversation.h"

@interface SwrveConversation()

@property (nonatomic, weak)     SwrveMessageController* controller;

@end

@implementation SwrveConversation

@synthesize controller, campaign, conversationID, title, subtitle, notification;

-(SwrveConversation*) updateWithJSON:(NSDictionary*)json
                         forCampaign:(SwrveCampaign*)_campaign
                       forController:(SwrveMessageController*)_controller
{
    self.campaign       = _campaign;
    self.controller     = _controller;
    self.conversationID = [json objectForKey:@"id"];
    self.title          = [json objectForKey:@"title"];
    self.subtitle       = [json objectForKey:@"subtitle"];
    self.notification   = [json objectForKey:@"notification"];

    return self;
}

+(SwrveConversation*) fromJSON:(NSDictionary*)json
                   forCampaign:(SwrveCampaign*)campaign
                 forController:(SwrveMessageController*)controller
{
    return [[[SwrveConversation alloc] init] updateWithJSON:json
                                                forCampaign:campaign
                                              forController:controller];
}
@end
