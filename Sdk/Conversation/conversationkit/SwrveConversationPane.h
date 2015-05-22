#import <Foundation/Foundation.h>

@interface SwrveConversationPane : NSObject 

@property (atomic, strong) NSArray *content;  // Array of SwrveConversationAtoms
@property (readonly, atomic, strong) NSArray *controls; // Array of SwrveConversationButtons
@property (readonly, atomic, strong) NSString *tag;
@property (readonly, atomic, strong) NSString *title;
@property (readonly, atomic, strong) NSDictionary *pageStyle;

-(id) initWithDictionary:(NSDictionary *)dict;

@end
