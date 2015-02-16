//
//  UIScrollView+SwrveKeyboardAvoidingAdditions.h
//  SwrveKeyboardAvoidingSample
//
//  Created by Michael Tyson on 30/09/2013.
//  Copyright 2013 A Tasty Pixel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIScrollView (SwrveKeyboardAvoidingAdditions)

- (BOOL)SwrveKeyboardAvoiding_focusNextTextField;
- (void)SwrveKeyboardAvoiding_scrollToActiveTextField;

- (void)SwrveKeyboardAvoiding_keyboardWillShow:(NSNotification*)notification;
- (void)SwrveKeyboardAvoiding_keyboardWillHide:(NSNotification*)notification;
- (void)SwrveKeyboardAvoiding_updateContentInset;
- (void)SwrveKeyboardAvoiding_updateFromContentSizeChange;
- (void)SwrveKeyboardAvoiding_assignTextDelegateForViewsBeneathView:(UIView*)view;
- (UIView*)SwrveKeyboardAvoiding_findFirstResponderBeneathView:(UIView*)view;
- (CGSize)SwrveKeyboardAvoiding_calculatedContentSizeFromSubviewFrames;

@end
