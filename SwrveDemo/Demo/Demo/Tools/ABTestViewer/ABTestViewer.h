//
//  ABTestViewer.h
//  SwrveDemoFramework
//
//  Copyright (c) 2010-2014 Swrve. All rights reserved.
//

#import "Demo.h"

/*
 * A simple utility to view active AB tests running on Swrve's servers.
 */
@interface ABTestViewer : Demo <UITableViewDataSource,UITableViewDelegate> {
    IBOutlet UITableView *resourceTable;
    IBOutlet UIButton *button;
    NSArray *resources;
    NSMutableArray *attributes;
    UIToolbar *toolbar;
    int viewAttributes;
}
@property (nonatomic, retain) UIToolbar *toolbar;
@property (nonatomic, retain) NSArray *resources;
@property (atomic, retain) NSMutableArray *attributes;
@property (nonatomic, retain) IBOutlet UITableView *resourceTable;

@end
