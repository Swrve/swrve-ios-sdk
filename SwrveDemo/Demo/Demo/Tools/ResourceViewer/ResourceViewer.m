#import "ResourceViewer.h"
#import "DemoFramework.h"

#define UIViewAutoresizingFlexibleMargins       \
    UIViewAutoresizingFlexibleBottomMargin    | \
    UIViewAutoresizingFlexibleLeftMargin      | \
    UIViewAutoresizingFlexibleRightMargin     | \
    UIViewAutoresizingFlexibleTopMargin

@implementation ResourceViewer
@synthesize resourceTable;
@synthesize resources;
@synthesize attributes;
@synthesize toolbar;

-(id) init
{
    self = [super initWithNibName:@"ResourceViewer" bundle:nil];

    // Initialize resources
    resources = [[NSArray alloc] init];
    attributes = [[NSMutableArray alloc] init];
    [self updateResource];

    return self;
}

-(void) viewDidLoad
{
    [super viewDidLoad];
    
    // GET SCREEN PARAMETERS
    CGSize screenSize = self.view.bounds.size;
    CGFloat screenWidth = screenSize.width;
    CGFloat screenHeight = screenSize.height;
    
    // UITABLE
    resourceTable = [[UITableView alloc] initWithFrame:CGRectMake(0, 44, screenWidth, screenHeight - 88) style:UITableViewStylePlain];
    resourceTable.dataSource = self;
    resourceTable.delegate = self;
    resourceTable.autoresizingMask = UIViewAutoresizingFlexibleMargins;
    [self.view addSubview:resourceTable];

    // TOOLBAR
    toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 44)];
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithTitle:@"Refresh"
                                                                 style:UIBarButtonItemStyleBordered
                                                                 target:self
                                                                 action:@selector(updateResource)];
    NSMutableArray *buttonsArray = [[NSMutableArray alloc] initWithObjects:refreshButton, nil];
    [toolbar setItems:buttonsArray animated:NO];
    [self.view addSubview:toolbar];
}

-(IBAction)updateResource
{
    [self updateResourcesToLatest];
    [self.resourceTable reloadData];
}

-(void)updateResourcesToLatest
{
    SwrveResourceManager* resourceManager = [[DemoFramework getSwrve] getSwrveResourceManager];
    NSDictionary* resourceDict = [resourceManager getResources];
    NSMutableArray* resourceArray = [[NSMutableArray alloc] init];

    for (NSString* key in resourceDict) {
        SwrveResource* resource = [resourceManager getResource:key];
        [resourceArray addObject:resource];
    }
    
    self.resources = resourceArray;
}

-(IBAction)goBack
{
    viewAttributes = 0;
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithTitle:@"Refresh"
                                                                      style:UIBarButtonItemStyleBordered
                                                                     target:self
                                                                     action:@selector(updateResource)];
    NSMutableArray *buttonsArray = [[NSMutableArray alloc] initWithObjects:refreshButton, nil];
    [toolbar setItems:buttonsArray animated:NO];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.75];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.view cache:YES];
    [UIView commitAnimations];
    [resourceTable reloadData];
}

#pragma mark - TableView DataSource Implementation

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    #pragma unused(tableView, section)
    if (viewAttributes)
    {
        return (int)[attributes count];
    }
    else
    {
        return (int)[resources count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
    }
    
    unsigned int row = (unsigned int)indexPath.row;
    if (viewAttributes)
    {
        cell.textLabel.text = [[attributes objectAtIndex:row] objectAtIndex:0];
        cell.detailTextLabel.text = [[attributes objectAtIndex:row] objectAtIndex:1];
    } else
    {
        cell.textLabel.text = [[resources objectAtIndex:row] getAttributeAsString:@"uid" withDefault:@""];
        cell.detailTextLabel.text = @"";
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (!viewAttributes)
    {
        SwrveResource* resource = [resources objectAtIndex:(unsigned int)indexPath.row];
        attributes = [[NSMutableArray alloc] init];

        for (NSString* key in [resource attributes]) {
            NSString* value = [[resource attributes] objectForKey:key];
            NSArray* attribute = [[NSArray alloc] initWithObjects:key, value, nil];
            [attributes addObject:attribute];
        }

        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                         style:UIBarButtonItemStyleBordered
                                                                         target:self
                                                                         action:@selector(goBack)];
        UIBarButtonItem *attrTitle = [[UIBarButtonItem alloc] initWithTitle:[resource getAttributeAsString:@"uid" withDefault:@""]
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(goBack)];
        NSMutableArray *newArray = [[NSMutableArray alloc] initWithObjects:backButton,attrTitle, nil];
        [toolbar setItems:newArray animated:NO];
        viewAttributes = 1;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.75];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.view cache:YES];
        [UIView commitAnimations];
        [tableView reloadData];
    }
}

@end
