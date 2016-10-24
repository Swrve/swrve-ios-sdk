#import <Foundation/Foundation.h>
#import "SwrveConversationAtom.h"

#define kSwrveKeyDescription @"description"
#define kSwrveKeyTarget @"target"
#define kSwrveKeyAction @"action"
#define kSwrveDefaultButtonAlignment @"center"
#define kSwrveDefaultButtonFontSize [NSNumber numberWithDouble:18.0]
#define kSwrveStyleTypeSolid @"solid"
#define kSwrveStyleTypeOutline @"outline"

@interface SwrveConversationButton : SwrveConversationAtom

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict;
-(BOOL) endsConversation;

@property (readonly, nonatomic) NSString     *description;
@property (strong, nonatomic)   NSDictionary *actions;
@property (strong, nonatomic)   NSString     *target;

@end
