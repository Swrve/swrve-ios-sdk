
/*******************************************************
 * Copyright (C) 2011-2012 Converser contact@converser.io
 *
 * This file is part of the Converser iOS SDK.
 *
 * This code may not be copied and/or distributed without the express
 * permission of Converser. Please email contact@converser.io for
 * all redistribution and reuse enquiries.
 *******************************************************/

#import "SwrveInputMultiValueLong.h"
#import "SwrveChoiceArray.h"
#import "SwrveSetup.h"

@implementation SwrveInputMultiValueLong

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict {
    self = [super initWithTag:tag andType:kSwrveInputMultiValueLong];
    if(self) {
        self.description = [dict objectForKey:@"description"];
        NSArray *arr = [dict objectForKey:@"values"];
        NSMutableArray *vals =[[NSMutableArray alloc] initWithCapacity:arr.count];
        for(NSDictionary *innerDict in arr) {
            NSArray *options = [innerDict objectForKey:@"options"];
            NSString *title = [innerDict objectForKey:@"title"];
            SwrveChoiceArray  *vgChoiceArray = [[SwrveChoiceArray alloc] initWithArray:options andTitle:title];
            [vals addObject:vgChoiceArray];
        }
        self.values = vals;
    }
    return self;
}

-(UITableViewCell *) cellForRow:(NSUInteger)row inTableView:(UITableView *)tableView {
    if (![self hasDescription] || row > 0) {
        UITableViewCell *cell = [self fetchStandardCell:tableView];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        SwrveChoiceArray *vgChoiceArray = [self.values objectAtIndex:(row - [self hasDescription])];
        cell.textLabel.text = vgChoiceArray.title;
        cell.detailTextLabel.text = vgChoiceArray.selectedItem;
        return [self styleCell:cell atRow:(row - [self hasDescription])];
    } else {
        return [self fetchDescriptionCell:tableView];
    }
}

-(NSDictionary *) userResponse {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:self.values.count];
    for(SwrveChoiceArray *choiceArray in self.values) {
        [dict addEntriesFromDictionary:[choiceArray userResponse]];
    }
    return [NSDictionary dictionaryWithDictionary:dict];
}

-(id)choicesForRow:(NSUInteger) row {
    return [self.values objectAtIndex:row-[self hasDescription]];
}

-(BOOL)isComplete {
    for(SwrveChoiceArray *choiceArray in self.values) {
        NSDictionary *dict = [choiceArray userResponse];
        for (NSString *key in [dict allKeys]) {
            if ([[dict objectForKey:key] isEqualToString:@""]) {
                return NO;
            }
        }
    }
    return YES;
}

-(void)highlight {
    //[_view.layer setBorderColor:[UIColor redColor].CGColor];
}

@end
