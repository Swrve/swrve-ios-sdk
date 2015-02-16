//
//  SwrveInputMultiBase.h
//  SwrveConversationKit
//
//  Created by Oisin Hurley on 17/09/2014.
//  Copyright (c) 2014 Converser. All rights reserved.
//

#import "SwrveInputItem.h"

@interface SwrveInputMultiBase : SwrveInputItem

@property (nonatomic, strong) NSArray *values;
@property (nonatomic, strong) NSString *description;

-(void)             loadView;
-(BOOL)             hasDescription;
-(NSUInteger)       numberOfRowsNeeded;
-(CGFloat)          heightForRow:(NSUInteger)row;

-(UITableViewCell*) fetchDescriptionCell:(UITableView*)tableView;
-(UITableViewCell*) fetchStandardCell:(UITableView*)tableView;
-(UITableViewCell*) styleCell:(UITableViewCell *)cell atRow:(NSUInteger)row;
@end
