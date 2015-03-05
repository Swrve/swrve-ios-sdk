#import "SettingsView.h"
#import "UserSettings.h"
#import "DemoFramework.h"

@implementation SettingsView

@synthesize apiKeyTextField;
@synthesize gameIdTextField;
@synthesize qaUserIdField;
@synthesize qaUserEnabledSwitch;

-(id) init
{
    return [super initWithNibName:@"SettingsView" bundle:nil];
}

-(void) viewDidLoad
{
    [super viewDidLoad];
    
    [self apiKeyTextField].delegate = self;
    [self gameIdTextField].delegate = self;
    [self qaUserIdField].delegate = self;
    
    [self apiKeyTextField].text = [UserSettings getAppApiKey];
    [self gameIdTextField].text = [UserSettings getAppId];
    [self qaUserIdField].text = [UserSettings getQAUserId];
    [self qaUserEnabledSwitch].selected = [UserSettings getQAUserEnabled];
}

- (void)saveSettings
{
    NSString* apiKey = [self apiKeyTextField].text;
    NSString* gameId = [self gameIdTextField].text;
    NSString* qaUserId = [self qaUserIdField].text;
    BOOL qaEnabled = [[self qaUserEnabledSwitch] isOn];
    
    apiKey = [apiKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    gameId = [gameId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    qaUserId = [qaUserId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    [UserSettings setAppApiKey:apiKey];
    [UserSettings setAppId:gameId];
    
    [UserSettings setQAUserId:qaUserId];
    [UserSettings setQAUserEnabled:qaEnabled];
    
    [DemoFramework intializeSwrveSdk];
    [DemoFramework getDemoResourceManager].userIdOverride = [UserSettings getQAUserIdIfEnabled];
}

- (void)textFieldDidBeginEditing:(UITextView *)textView
{
    float viewSize = (float)self.view.frame.size.height;
    int keyboardHeight = 216;
    
    if (textView.frame.origin.y + textView.frame.size.height > viewSize - keyboardHeight)
    {
        float offset = (float)(viewSize - keyboardHeight - textView.frame.origin.y - textView.frame.size.height);
        CGRect rect = CGRectMake(0, offset, self.view.frame.size.width, self.view.frame.size.height);
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.3];
        
        self.view.frame = rect;
        
        [UIView commitAnimations];
    }    
}

- (void)textFieldDidEndEditing:(UITextView *)textView
{
    #pragma unused(textView)
    CGRect rect = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    
    self.view.frame = rect;
    
    [UIView commitAnimations];
    
    [self saveSettings];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

- (IBAction)qaUserSwitchChanged:(id)sender
{
    #pragma unused(sender)
    [self saveSettings];
}

- (IBAction)uploadResourcesToSwrve:(id)sender
{
    #pragma unused(sender)
    // Send demo events used to setup Swrve Talk.    
    [[DemoFramework getSwrve]event:@"Swrve.Demo.OfferMessage"];
    [[DemoFramework getSwrve]event:@"Swrve.Demo.CrossPromoMessage"];
    [[DemoFramework getSwrve]event:@"Swrve.Demo.ItemPromotion"];
    [[DemoFramework getSwrve]sendQueuedEvents];
    
    // Send warning message first.  This will trigger a sequence of alerts.
    UIAlertView *warning = [[UIAlertView alloc] initWithTitle:@"Upload Resources"
                                                    message:@"This feature will upload the resources used in this demo app to your Swrve Dashboard.  It will overwrite or add to the data that is already present.  Typically this is done by engineers when they are getting started with Swrve.  Are you sure you want to upload resources?"
                                                   delegate:nil
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
    warning.tag = 1;
    warning.delegate = self;
    [warning show];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Warning view
    if( alertView.tag == 1 )
    {
        NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
        if([title isEqualToString:@"Yes"])
        {
            UIAlertView* personalKeyDialog = [[UIAlertView alloc] initWithTitle:@"Enter your personal key"
                                                             message:@" "
                                                            delegate:self
                                                   cancelButtonTitle:@"Cancel"
                                                   otherButtonTitles:@"OK", nil];
            personalKeyDialog.tag = 2;
            personalKeyDialog.delegate = self;
            UITextField *nameField = [[UITextField alloc]
                                      initWithFrame:CGRectMake(20.0, 45.0, 245.0, 25.0)];
            [nameField setBackgroundColor:[UIColor whiteColor]];
            [personalKeyDialog addSubview:nameField];
            [personalKeyDialog show];
        }
    }
    else if( alertView.tag == 2 )
    {
        NSString* personalKey = nil;
        for (UIView* view in alertView.subviews)
        {
            if ([view isKindOfClass:[UITextField class]])
            {
                UITextField* textField = (UITextField*)view;
                personalKey = textField.text;
                break;
            }
        }
        
        if(personalKey != nil)
        {
            long result = [[DemoFramework getDemoResourceManager] pushAllResourcesToDashboard:[DemoFramework getSwrve] withApiKey:[UserSettings getAppApiKey] withPersonalKey:personalKey];
            
            if( result == 403 )
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Authentication Failed"
                                                                message:@"We could not connect to your game.  Check your API and Personal keys and try again.  If it's still not working send an e-mail to support@swrve.com and we'll help you out!"
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
            else if (result != 200 )
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unknown error"
                                                                message:@"Could not upload data."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
            else
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload Complete"
                                                                message:@"All data has been uploaded."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        }
    }
}

@end
