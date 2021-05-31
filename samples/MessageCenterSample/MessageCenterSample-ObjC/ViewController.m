#import "ViewController.h"
#import "SwrveSDK.h"
#import "SwrveCampaign.h"

@implementation ViewController

@synthesize campaigns;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self refreshDataSource];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshDataSource];
    [self.tableView reloadData];

    // Observe for the new campaigns
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadDataAndView) name:@"SwrveUserResourcesUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadDataAndView) name:@"SwrveMessageWillBeHidden" object:nil];
}

- (void) reloadDataAndView
{
    [self refreshDataSource];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // Remove observe
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)refreshDataSource {
    // Obtain latest campaigns and order by the campaign dateStart property
    NSSortDescriptor *dateDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"dateStart" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:dateDescriptor];
    self.campaigns = [[SwrveSDK messageCenterCampaigns] sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.campaigns.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MessageCenterCell"];

    // Configure the cell
    SwrveCampaign *campaign = [self.campaigns objectAtIndex:indexPath.row];

    // Campaign subject
    cell.textLabel.text = campaign.subject;
    [cell.textLabel setBackgroundColor:[UIColor clearColor]];
    [cell.detailTextLabel setBackgroundColor:[UIColor clearColor]];

    // Format the start date for display
    NSDateFormatter *dformat = [NSDateFormatter new];
    [dformat setDateFormat:@"MMMM dd, yyyy (EEEE) HH:mm:ss z Z"];

    // Campaign start date, change cell background colour based on seen / unseen status
    switch(campaign.state.status) {
        case SWRVE_CAMPAIGN_STATUS_UNSEEN:
            cell.detailTextLabel.text = [dformat stringFromDate:campaign.dateStart];
            [cell setBackgroundColor:[UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:0.4f]];

            break;
        case SWRVE_CAMPAIGN_STATUS_SEEN:
            cell.detailTextLabel.text = [dformat stringFromDate:campaign.dateStart];
            [cell setBackgroundColor:[UIColor colorWithRed:0.0f green:1.0f blue:0.0f alpha:0.4f]];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Display the campaign when clicked
    [SwrveSDK showMessageCenterCampaign:[self.campaigns objectAtIndex:indexPath.row]];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Remove campaign from the sliding button
        [tableView beginUpdates];
        [SwrveSDK removeMessageCenterCampaign:[self.campaigns objectAtIndex:indexPath.row]];
        [self refreshDataSource];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
        [tableView endUpdates];
    }
}

@end
