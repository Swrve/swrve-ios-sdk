#import "Swrve.h"
#import "SwrveCampaign.h"
#import "SwrveMessageController.h"
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

/*static bool in_cache(NSString* file, NSSet* set){
    return [file length] == 0 || [set containsObject:file];
}*/

-(BOOL)areDownloaded:(NSSet*)assets
{
    #pragma unused(assets)
    // Iterate through the images and check in_cache(image, assets)
    /*for (SwrveMessageFormat* format in self.formats) {
     for (SwrveButton* button in format.buttons) {
     if (!in_cache(button.image, assets)){
     DebugLog(@"Button Asset not yet downloaded: %@", button.image);
     return false;
     }
     }
     
     for (SwrveImage* image in format.images) {
     if (!in_cache(image.file, assets)){
     DebugLog(@"Image Asset not yet downloaded: %@", image.file);
     return false;
     }
     }
     }*/
    
    return true;
}

-(void)wasShownToUser {
    SwrveMessageController* c = self.controller;
    if (c != nil) {
        [c conversationWasShownToUser:self];
    }
}

-(SwrveConversationPane*)pageAtIndex:(NSUInteger)index {
    if (index > self.pages.count) {
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
