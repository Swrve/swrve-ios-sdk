#import <Foundation/Foundation.h>
#import "SwrveConversationAtom.h"

static NSString *const kSwrveKeyDescription         = @"description";
static NSString *const kSwrveKeyTarget              = @"target";
static NSString *const kSwrveKeyAction              = @"action";
static NSString *const kSwrveDefaultButtonAlignment = @"center";
#define kSwrveDefaultButtonFontSize [NSNumber numberWithDouble:18.0]
static NSString *const kSwrveStyleTypeSolid         = @"solid";
static NSString *const kSwrveStyleTypeOutline       = @"outline";

@interface SwrveConversationButton : SwrveConversationAtom

-(id)initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict;
-(BOOL)endsConversation;

@property (readonly, nonatomic) NSString     *description;
@property (strong, nonatomic)   NSDictionary *actions;
@property (strong, nonatomic)   NSString     *target;

@end
