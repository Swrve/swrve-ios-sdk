
/*******************************************************
 * Copyright (C) 2011-2012 Converser contact@converser.io
 *
 * This file is part of the Converser iOS SDK.
 *
 * This code may not be copied and/or distributed without the express
 * permission of Converser. Please email contact@converser.io for
 * all redistribution and reuse enquiries.
 *******************************************************/

#import "SwrveInputMultiValue.h"
#import "SwrveSetup.h"

@implementation SwrveInputMultiValue

@synthesize selectedIndex;

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict {
    self = [super initWithTag:tag andType:kSwrveInputMultiValue];
    if(self) {
        self.description = [dict objectForKey:@"description"];
        // Get the values here
        NSArray *vals = [dict objectForKey:@"values"];
        self.values = vals;
        self.selectedIndex = -1;
    }
    return self;
}

-(UITableViewCell *) cellForRow:(NSUInteger)row inTableView:(UITableView *)tableView {
    if (![self hasDescription] || row > 0) {
        UITableViewCell *cell = [self fetchStandardCell:tableView];
        
        NSDictionary *dict = [self.values objectAtIndex:(row - [self hasDescription])];
        
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
        return [self styleCell:cell atRow:(row - [self hasDescription])];
    } else {
        return [self fetchDescriptionCell:tableView];
    }
}

-(NSString *) userResponse {
    if(self.selectedIndex == -1) {
        return @"";
    }
    
    // TODO: check for zero
    NSUInteger inx = (NSUInteger)(self.selectedIndex - 1);
    NSDictionary *dict = [self.values objectAtIndex:inx];
    return [[dict allValues] objectAtIndex:0];
}

-(BOOL)isComplete {
    return self.selectedIndex > -1;
}
@end
