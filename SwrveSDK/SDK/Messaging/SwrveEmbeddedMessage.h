#import "SwrveBaseMessage.h"
#import "SwrveEmbeddedCampaign.h"

/*! Enumerates the possible types of data that can be returned as part of an embedded campaign */
typedef enum {
    kSwrveEmbeddedDataTypeJson,    /*!< json */
    kSwrveEmbeddedDataTypeOther,   /*!< other */
} SwrveEmbeddedDataType;

@interface SwrveEmbeddedMessage : SwrveBaseMessage

@property (nonatomic, strong) NSString *data;
@property (nonatomic)       SwrveEmbeddedDataType type;
@property (nonatomic)       NSArray<NSString*> *buttons;

-(id)initWithDictionary:(NSDictionary *)json forCampaign:(SwrveEmbeddedCampaign *)_campaign forController:(SwrveMessageController*)_controller;

@end

