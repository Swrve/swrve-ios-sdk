#import <Foundation/Foundation.h>
#import "SwrveInputItem.h"

@interface SwrveConversationResponseItem : NSObject

@property(nonatomic, readonly, strong) NSString *tag;
@property(nonatomic, readonly, strong) NSString *value;

-(id) initWithInputItem:(SwrveInputItem *)inputItem;

@end
