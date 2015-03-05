#import "Menu.h"
#import "DemoFramework.h"

@implementation DemoMenuNode

@synthesize title;
@synthesize name;
@synthesize description;
@synthesize children;
@synthesize demo;

+(void) enumerate:(DemoMenuNode *)node withCallback:(void (^)(DemoMenuNode *node))callback
{
    if( node == nil )
    {
        return;
    }
    
    callback(node);
    
    for( unsigned int childIndex = 0; node.children != nil && childIndex < [node.children count]; ++childIndex )
    {
        [DemoMenuNode enumerate:[node.children objectAtIndex:childIndex] withCallback:callback];
    }
}

@end

@implementation DemoMenuViewController

@synthesize menuNode;

- (void)viewWillAppear:(BOOL)animated
{
    #pragma unused(animated)
    if( menuNode != nil && menuNode.name != nil )
    {
        // [TRACK] What demos and menus do users look at
        [[DemoFramework getSwrveInternal] event:@"Swrve.Demo.UI.Menu.Click"
                                       payload:[NSDictionary dictionaryWithObject:menuNode.name forKey:@"name"]];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    #pragma unused(animated)
    if( menuNode != nil && menuNode.name != nil )
    {
        // [TRACK] Send events to swrve when a user exits a demo so it's a little easier to debug
        [[DemoFramework getSwrveInternal]sendQueuedEvents];
    }
}

#pragma mark UITableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    #pragma unused(tableView)
    if( self.menuNode.children != nil )
    {
        return (int)[self.menuNode.children count];
    }
    else
    {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    #pragma unused(tableView, section)
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    #pragma unused(tableView)
    if( self.menuNode.children != nil )
    {
        DemoMenuNode *child = [self.menuNode.children objectAtIndex:(unsigned int)section];
        return child.title;
    }
    else
    {
        return @"";
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    #pragma unused(tableView)
    if( self.menuNode.children != nil )
    {
        DemoMenuNode *child = [self.menuNode.children objectAtIndex:(unsigned int)section];
        return child.description;
    }
    else
    {
        return @"";
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    #pragma unused(tableView)
    NSString* footerText = @"";
    if( self.menuNode.children != nil )
    {
        DemoMenuNode *child = [self.menuNode.children objectAtIndex:(unsigned int)section];
        footerText = child.description;
    }
        
    CGRect footerFrame = [tableView rectForFooterInSection:section];
    CGRect labelFrame = CGRectMake(10, 0, footerFrame.size.width - 20, footerFrame.size.height);
    
    UIView* view = [[UIView alloc] initWithFrame:footerFrame];
    UITextView* textView = [[UITextView alloc] initWithFrame:labelFrame];
    
    textView.editable = NO;
    textView.font = [UIFont systemFontOfSize:15];
    textView.backgroundColor = [UIColor clearColor];
    textView.text = footerText;
    [textView setUserInteractionEnabled:false];
    
    [view addSubview:textView];
    
    return view;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *SimpleTableIdentifier = @"SimpleTableIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: SimpleTableIdentifier];
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc]
                 initWithStyle:UITableViewCellStyleDefault
                 reuseIdentifier:SimpleTableIdentifier];
    }
    
    if( self.menuNode.children != nil )
    {
        DemoMenuNode *child = [self.menuNode.children objectAtIndex:(unsigned int)[indexPath section]];
        cell.textLabel.text = child.name;
    }
    else
    {
        cell.textLabel.text = @"";
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    #pragma unused(tableView, indexPath)
    DemoMenuNode *selectedChild = [self.menuNode.children objectAtIndex:(unsigned int)[indexPath section]];
    
    UIViewController *toView = nil;
    if( selectedChild.children != nil )
    {
        toView = [[DemoMenuViewController alloc] initWithNibName:@"Menu" bundle:nil];
        ((DemoMenuViewController*)toView).menuNode = selectedChild;
    }
    else if( selectedChild.demo != nil )
    {
        toView = selectedChild.demo;
    }
    
    if( toView != nil )
    {
        [[self navigationController] pushViewController:toView animated:YES];
    }
}
@end
