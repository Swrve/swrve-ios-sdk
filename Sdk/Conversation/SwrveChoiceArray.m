#import "SwrveChoiceArray.h"
#import "SwrveSetup.h"

@implementation SwrveChoiceArray

@synthesize questionId = _questionId;
@synthesize choices = _choices;
@synthesize selectedIndex = _selectedIndex;
@synthesize title = _title;
@synthesize hasMore = _hasMore;

// So, choices may be an array of strings...or an array of dictionaries.
// It it is an array of dictionaries, we effectively have to make more of ourselves....
-(id) initWithArray:(NSArray *)choices andQuestionId:(NSString*)questionId andTitle:(NSString *)title {
    self = [super init];
    if(self) {
        _questionId = [questionId copy];
        _title = [title copy];
        _choices = [choices copy];
        self.selectedIndex = -1;
    }
    return self;
}

-(NSString *)selectedItem {
    if(self.selectedIndex < 0) {
        return @"";
    }
    
    NSUInteger inx = (NSUInteger)self.selectedIndex;
    NSDictionary *item = (NSDictionary*)[_choices objectAtIndex:inx];
    return [item objectForKey:@"answer_text"];
}

-(NSString *)selectedItemTag {
    if(self.selectedIndex < 0) {
        return @"";
    }
    
    NSUInteger inx = (NSUInteger)self.selectedIndex;
    NSDictionary *item = (NSDictionary*)[_choices objectAtIndex:inx];
    return [item objectForKey:@"answer_id"];
}

-(NSDictionary *)userResponse {
    if(_hasMore) {
        NSMutableDictionary *ret = [[NSMutableDictionary alloc] init];
        for(SwrveChoiceArray *innerChoice in _choices) {
            NSDictionary *innerResp = [innerChoice userResponse];
            [ret addEntriesFromDictionary:innerResp];
        }
        return ret;
    }
    return [NSDictionary dictionaryWithObject:[self selectedItemTag] forKey:self.questionId];
}

@end
