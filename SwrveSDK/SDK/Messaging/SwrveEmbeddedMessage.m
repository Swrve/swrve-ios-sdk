#import "SwrveEmbeddedMessage.h"
#import "SwrveMessageController.h"

@interface SwrveEmbeddedMessage()

@property (nonatomic, weak) SwrveMessageController* controller;

@end

@implementation SwrveEmbeddedMessage

@synthesize controller, campaign, data, type, buttons;

-(id)initWithDictionary:(NSDictionary *)json forCampaign:(SwrveEmbeddedCampaign *)_campaign forController:(SwrveMessageController*)_controller {
    if (self = [super init]) {
        self.campaign     = _campaign;
        self.controller   = _controller;
        self.messageID    = [json objectForKey:@"id"];
        if ([json objectForKey:@"priority"]) {
            self.priority = [json objectForKey:@"priority"];
        } else {
            self.priority = [NSNumber numberWithInt:9999];
        }
        
        if ([json objectForKey:@"buttons"]) {
            self.buttons = [json mutableArrayValueForKey:@"buttons"];
        }
        
        if ([json objectForKey:@"type"]) {
            self.type = [self retrieveType:[json objectForKey:@"type"]];
        }
        
        if ([json objectForKey:@"data"]) {
            self.data = [json objectForKey:@"data"];
        }
        
        if ([json objectForKey:@"name"]) {
            self.name = [json objectForKey:@"name"];
        }
        
        if ([json objectForKey:@"message_center_details"]) {
            self.messageCenterDetails = [[SwrveMessageCenterDetails alloc] initWithJSON:[json objectForKey:@"message_center_details"]];
        }
    }
    return self;
}

-(SwrveEmbeddedDataType) retrieveType:(NSString *) typeString {
    if([typeString isEqualToString:@"json"]) {
        return kSwrveEmbeddedDataTypeJson;
    }
        
    return kSwrveEmbeddedDataTypeOther;
}

@end
