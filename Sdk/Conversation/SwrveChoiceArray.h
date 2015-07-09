#import <Foundation/Foundation.h>

@interface SwrveChoiceArray : NSObject

-(id) initWithArray:(NSArray *)choices andQuestionId:(NSString*)questionId andTitle:(NSString *)title;

@property(nonatomic, readonly) NSString *questionId;
@property(nonatomic, readonly) BOOL hasMore;
@property(nonatomic, assign) NSInteger selectedIndex;
@property(nonatomic, readonly, strong) NSArray *choices;
@property(nonatomic, readonly, strong) NSString *title;
@property(nonatomic, readonly) NSString *selectedItem;

-(NSDictionary *)userResponse;

@end
