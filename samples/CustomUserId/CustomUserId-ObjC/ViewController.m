#import <SwrveSDK/SwrveSDK.h>
#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize textView;

- (void)viewDidLoad {
    [super viewDidLoad];

    [self updateTextView];
}

- (IBAction)startSwrve:(id)sender {

    __block UITextField *textField;
    NSString *title = @"Enter custom userId to start swrve with or leave blank to generate one.";
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textFieldToHandle) {
        textFieldToHandle.keyboardAppearance = UIKeyboardAppearanceDark;
        textFieldToHandle.keyboardType = UIKeyboardTypeDefault;
        textFieldToHandle.text = @"";
        textField = textFieldToHandle;
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Start" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (textField.text && [textField.text length] > 0) {
            [SwrveSDK startWithUserId:textField.text];
        } else {
            [SwrveSDK start];
        }

        NSString *message = @"Swrve SDK Started";
        UIAlertController *alertConfirmation = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
        [alertConfirmation addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self updateTextView];
        }]];
        [self presentViewController:alertConfirmation animated:YES completion:nil];
    }]];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)updateTextView {
    if ([SwrveSDK started]) {
        textView.text = [@"Started with userId:" stringByAppendingString:[SwrveSDK userID]];
    } else {
        textView.text = @"Not started.";
    }
}

@end
