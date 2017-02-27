#import "ViewController.h"
#import "AppDelegate.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


    // Button callback.  Changes user ID to 'User_A'
- (IBAction)initUserA:(id)sender {
    NSLog(@"Button A Pressed");
    [self changeToUserID:@"User_A"];
}

    // Button callback.  Changes user ID to 'User_B'
- (IBAction)initUserB:(id)sender {
    NSLog(@"Button B Pressed");
    [self changeToUserID:@"User_B"];
}

     // Initialize an empty SDK, no events will be sent
- (IBAction)initUserNull:(id)sender {
    NSLog(@"Button Null Pressed");
        [self changeToUserID:nil];
}


    // Utility function that changes the user id and sends diagnostic events
    // to make sure events are sent correctly with the old user ID and the
    // new user ID.
- (void) changeToUserID:(NSString*) userID {
    // Save the userID in defaults to be used when the app is launched next time
    [[NSUserDefaults standardUserDefaults] setObject:userID forKey:@"userID"];
    
    NSString *oldUserID = [[Swrve sharedInstance] userID];
    NSString* eventName = [NSString stringWithFormat:@"Changing from %@ to %@", oldUserID, userID];
    [[Swrve sharedInstance]event:eventName];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.identityUtils changeUserID:userID];
    
    eventName = [NSString stringWithFormat:@"Changed to %@ from %@", userID, oldUserID];
    [[Swrve sharedInstance]event:eventName];
    [[Swrve sharedInstance] sendQueuedEvents];
}

@end
