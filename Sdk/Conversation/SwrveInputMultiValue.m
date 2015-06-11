#import "SwrveInputMultiValue.h"
#import "SwrveConversationStyler.h"

@implementation SwrveInputMultiValue

@synthesize selectedIndex;

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict {
    self = [super initWithTag:tag type:kSwrveInputMultiValue andDictionary:dict];
    if(self) {
        self.description = [dict objectForKey:@"description"];
        // Get the values here
        NSArray *vals = [dict objectForKey:@"values"];
        self.values = vals;
        self.selectedIndex = -1;
    }
    return self;
}

-(void)setSelectedIndex:(NSInteger)inx {
    selectedIndex = inx;
}

-(UITableViewCell *) cellForRow:(NSUInteger)row inTableView:(UITableView *)tableView {
    if (![self hasDescription] || row > 0) {
        UITableViewCell *cell = [self fetchStandardCell:tableView];
        NSUInteger finalRow = row - ([self hasDescription]? 1 : 0);
        NSDictionary *dict = [self.values objectAtIndex:finalRow];
        
        // The form for each cell in the choice is
        // {
        //    "answer_id" = "54264172-option";
        //    "answer_text" = "The text to show";
        // }
        
        cell.textLabel.text = [dict objectForKey:@"answer_text"];
        
        if(self.selectedIndex == (NSInteger)row) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        [SwrveConversationStyler styleView:cell withStyle:self.style];
        return [self styleCell:cell atRow:finalRow];
    } else {
        return [self fetchDescriptionCell:tableView];
    }
}

-(NSString *) userResponse {
    if(self.selectedIndex <= 0) {
        return @"";
    }
    NSUInteger inx = (NSUInteger)(self.selectedIndex - 1);
    NSDictionary *dict = [self.values objectAtIndex:inx];
    return [dict valueForKey:@"answer_id"];
}

-(BOOL)isComplete {
    return self.selectedIndex > 0;
}
@end
