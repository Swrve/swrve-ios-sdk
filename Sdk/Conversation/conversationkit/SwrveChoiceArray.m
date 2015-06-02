#import "SwrveChoiceArray.h"
#import "SwrveSetup.h"

@implementation SwrveChoiceArray

@synthesize choices = _choices;
@synthesize selectedIndex = _selectedIndex;
@synthesize title = _title;
@synthesize hasMore = _hasMore;

// So, choices may be an array of strings...or an array of dictionaries.
// It it is an array of dictionaries, we effectively have to make more of ourselves....
-(id) initWithArray:(NSArray *)choices andTitle:(NSString *)title {
    self = [super init];
    if(self) {
        _title = [title copy];
        _choices = [choices copy];
        self.selectedIndex = -1;
    }
    return self;
}

-(NSString *)selectedItem {
    if(self.selectedIndex == -1) {
        return @"";
    }
    
    NSUInteger inx = (NSUInteger)self.selectedIndex;
    NSDictionary *item = (NSDictionary*)[_choices objectAtIndex:inx];
    return [item objectForKey:@"answer_text"];
}

-(NSDictionary *)userResponse {
    if(_hasMore) {
        NSMutableDictionary *ret = [[NSMutableDictionary alloc] init ];
        for(SwrveChoiceArray *innerChoice in _choices) {
            NSDictionary *innerResp = [innerChoice userResponse];
            [ret addEntriesFromDictionary:innerResp];
        }
        return ret;
    }
    return [NSDictionary dictionaryWithObject:self.selectedItem forKey:self.title];
}

@end
