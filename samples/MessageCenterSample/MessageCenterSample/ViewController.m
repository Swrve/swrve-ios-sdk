#import "ViewController.h"
#import "Swrve.h"
#import "SwrveBaseCampaign.h"

@interface ViewController ()

@property (nonatomic, retain) NSTimer *checkWindowTimer;
@property (nonatomic, retain) UIWindow *previousWindow;

@end

@implementation ViewController

@synthesize campaigns;
@synthesize checkWindowTimer;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self refreshDataSource];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshDataSource];
    [self.tableView reloadData];
    // Observe for the new campaigns
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newSwrveCampaigns)
                                                 name:@"SwrveUserResourcesUpdated"
                                               object:nil];
    
    // The Swrve SDK creates new UIWindows to display content to avoid
    // creating issues for games etc. However, this means that the controllers
    // do not get their callbacks called.
    //
    // This will be fixed by submitting events to the notification center in
    // an upcoming release.
    //
    // To workaround this we can query the current UIWindow active,
    // if the window is different from the previous iteration we can
    // notify the table view that the status of one of the items changed
    // "unread" -> "read"
    //
    self.checkWindowTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(checkCurrentWindow)
                                   userInfo:nil
                                    repeats:YES];
}

- (void) checkCurrentWindow
{
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    if (window != self.previousWindow) {
        self.previousWindow = window;
        // An in-app message or conversation might have been displayed.
        // Notify the table view that the state of a campaign might have changed.
        [self.tableView reloadData];
    }
}

- (void) newSwrveCampaigns
{
    [self refreshDataSource];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // Remove observe
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.checkWindowTimer invalidate];
}

- (void)refreshDataSource {
    // Obtain latest campaigns and order by the campaign ID
    self.campaigns = [[[Swrve sharedInstance].talk messageCenterCampaigns] sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        int idA = (int)((SwrveBaseCampaign*)a).ID;
        int idB = (int)((SwrveBaseCampaign*)b).ID;
        if (idA > idB) {
            return NSOrderedDescending;
        } if (idA == idB) {
            return NSOrderedAscending;
        }
        return NSOrderedSame;
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#pragma unused (tableView)
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#pragma unused (tableView)
    return self.campaigns.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MessageCenterCell"];
    
    // Configure the cell
    SwrveBaseCampaign* campaign = [self.campaigns objectAtIndex:indexPath.row];
    
    // Campaign subject
    cell.textLabel.text = campaign.subject;
    
    // Campaign start date
    switch(campaign.state.status) {
        case SWRVE_CAMPAIGN_STATUS_UNSEEN:
            cell.detailTextLabel.text = @"Unseen";
            break;
        case SWRVE_CAMPAIGN_STATUS_SEEN:
            cell.detailTextLabel.text = @"Seen";
            break;
        default:
            cell.detailTextLabel.text = @"Other";
            break;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Display the campaign when clicked
    [[Swrve sharedInstance].talk showMessageCenterCampaign:[self.campaigns objectAtIndex:indexPath.row]];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Remove campaign from the sliding button
        [tableView beginUpdates];
        [[Swrve sharedInstance].talk removeMessageCenterCampaign:[self.campaigns objectAtIndex:indexPath.row]];
        [self refreshDataSource];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
        [tableView endUpdates];
    }
}

@end
