//
//  SwrveKeyboardAvoidingScrollView.h
//
//  Created by Michael Tyson on 30/09/2013.
//  Copyright 2013 A Tasty Pixel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIScrollView+SwrveKeyboardAvoidingAdditions.h"

@interface SwrveKeyboardAvoidingScrollView : UIScrollView <UITextFieldDelegate, UITextViewDelegate>

- (void)contentSizeToFit;
- (BOOL)focusNextTextField;
- (void)scrollToActiveTextField;

@end
