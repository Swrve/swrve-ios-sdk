#import <UIKit/UIKit.h>
#import "SwrveConversationAtom.h"

@interface SwrveConversationAtomFactory : NSObject

+(SwrveConversationAtom *) atomForDictionary:(NSDictionary *)dict;

@end
