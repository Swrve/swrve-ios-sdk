//
//  Settings.h
//  SwrveDemoFramework
//
//  Copyright (c) 2010-2014 Swrve. All rights reserved.
//

#import <UIKit/UIKit.h>

/*
 * UI to change settings in the app
 */
@interface SettingsView : UIViewController<UITextFieldDelegate, UIAlertViewDelegate> {
   
}

@property (nonatomic, retain) IBOutlet UITextField *apiKeyTextField;
@property (nonatomic, retain) IBOutlet UITextField *gameIdTextField;
@property (nonatomic, retain) IBOutlet UITextField *qaUserIdField;
@property (nonatomic, retain) IBOutlet UISwitch *qaUserEnabledSwitch;

@end
