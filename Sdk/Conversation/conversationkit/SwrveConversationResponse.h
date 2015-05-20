#import <Foundation/Foundation.h>
#import "SwrveConversationResponseItem.h"

@interface SwrveConversationResponse : NSObject

@property (nonatomic, strong) NSString *control;
@property (nonatomic, readonly) NSArray *responseItems;

-(id)   initWithControl:(NSString *)control;
-(void) addResponseItem:(SwrveConversationResponseItem *)item;

@end
