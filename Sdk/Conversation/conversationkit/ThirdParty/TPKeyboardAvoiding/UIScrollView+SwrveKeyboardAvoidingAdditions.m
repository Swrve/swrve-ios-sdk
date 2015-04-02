//
//  UIScrollView+SwrveKeyboardAvoidingAdditions.m
//  SwrveKeyboardAvoidingSample
//
//  Created by Michael Tyson on 30/09/2013.
//  Copyright 2013 A Tasty Pixel. All rights reserved.
//

#import "UIScrollView+SwrveKeyboardAvoidingAdditions.h"
#import "SwrveKeyboardAvoidingScrollView.h"
#import <objc/runtime.h>

static const CGFloat kCalculatedContentPadding = 10;
static const CGFloat kMinimumScrollOffsetPadding = 20;

static const int kStateKey = 0;

#define _UIKeyboardFrameEndUserInfoKey (&UIKeyboardFrameEndUserInfoKey != NULL ? UIKeyboardFrameEndUserInfoKey : @"UIKeyboardBoundsUserInfoKey")

@interface SwrveKeyboardAvoidingState : NSObject
@property (nonatomic, assign) UIEdgeInsets priorInset;
@property (nonatomic, assign) UIEdgeInsets priorScrollIndicatorInsets;
@property (nonatomic, assign) BOOL         keyboardVisible;
@property (nonatomic, assign) CGRect       keyboardRect;
@property (nonatomic, assign) CGSize       priorContentSize;
@end

@implementation UIScrollView (SwrveKeyboardAvoidingAdditions)

- (SwrveKeyboardAvoidingState*)keyboardAvoidingState {
    SwrveKeyboardAvoidingState *state = objc_getAssociatedObject(self, &kStateKey);
    if ( !state ) {
        state = [[SwrveKeyboardAvoidingState alloc] init];
        objc_setAssociatedObject(self, &kStateKey, state, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
#if !__has_feature(objc_arc)
        [state release];
#endif
    }
    return state;
}

- (void)SwrveKeyboardAvoiding_keyboardWillShow:(NSNotification*)notification {
    SwrveKeyboardAvoidingState *state = self.keyboardAvoidingState;

    if ( state.keyboardVisible ) {
        return;
    }

    UIView *firstResponder = [self SwrveKeyboardAvoiding_findFirstResponderBeneathView:self];

    state.keyboardRect = [self convertRect:[[[notification userInfo] objectForKey:_UIKeyboardFrameEndUserInfoKey] CGRectValue] fromView:nil];
    state.keyboardVisible = YES;
    state.priorInset = self.contentInset;
    state.priorScrollIndicatorInsets = self.scrollIndicatorInsets;

    if ( [self isKindOfClass:[SwrveKeyboardAvoidingScrollView class]] ) {
        state.priorContentSize = self.contentSize;

        if ( CGSizeEqualToSize(self.contentSize, CGSizeZero) ) {
            // Set the content size, if it's not set. Do not set content size explicitly if auto-layout
            // is being used to manage subviews
            self.contentSize = [self SwrveKeyboardAvoiding_calculatedContentSizeFromSubviewFrames];
        }
    }

    // Shrink view's inset by the keyboard's height, and scroll to show the text field/view being edited
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:(UIViewAnimationCurve)[[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    [UIView setAnimationDuration:(UIViewAnimationCurve)[[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]];

    self.contentInset = [self SwrveKeyboardAvoiding_contentInsetForKeyboard];

    if ( firstResponder ) {
        CGFloat viewableHeight = self.bounds.size.height - self.contentInset.top - self.contentInset.bottom;
        [self setContentOffset:CGPointMake(self.contentOffset.x,
                                           [self SwrveKeyboardAvoiding_idealOffsetForView:firstResponder
                                                                 withViewingAreaHeight:viewableHeight])
                      animated:NO];
    }

    self.scrollIndicatorInsets = self.contentInset;

    [UIView commitAnimations];
}

- (void)SwrveKeyboardAvoiding_keyboardWillHide:(NSNotification*)notification {
    SwrveKeyboardAvoidingState *state = self.keyboardAvoidingState;

    if ( !state.keyboardVisible ) {
        return;
    }

    state.keyboardRect = CGRectZero;
    state.keyboardVisible = NO;

    // Restore dimensions to prior size
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:(UIViewAnimationCurve)[[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    [UIView setAnimationDuration:(UIViewAnimationCurve)[[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]];

    if ( [self isKindOfClass:[SwrveKeyboardAvoidingScrollView class]] ) {
        self.contentSize = state.priorContentSize;
    }

    self.contentInset = state.priorInset;
    self.scrollIndicatorInsets = state.priorScrollIndicatorInsets;
    [UIView commitAnimations];
}

- (void)SwrveKeyboardAvoiding_updateContentInset {
    SwrveKeyboardAvoidingState *state = self.keyboardAvoidingState;
    if ( state.keyboardVisible ) {
        self.contentInset = [self SwrveKeyboardAvoiding_contentInsetForKeyboard];
    }
}

- (void)SwrveKeyboardAvoiding_updateFromContentSizeChange {
    SwrveKeyboardAvoidingState *state = self.keyboardAvoidingState;
    if ( state.keyboardVisible ) {
		state.priorContentSize = self.contentSize;
        self.contentInset = [self SwrveKeyboardAvoiding_contentInsetForKeyboard];
    }
}

#pragma mark - Utilities

- (BOOL)SwrveKeyboardAvoiding_focusNextTextField {
    UIView *firstResponder = [self SwrveKeyboardAvoiding_findFirstResponderBeneathView:self];
    if ( !firstResponder ) {
        return NO;
    }

    CGFloat minY = CGFLOAT_MAX;
    UIView *view = nil;
    [self SwrveKeyboardAvoiding_findTextFieldAfterTextField:firstResponder beneathView:self minY:&minY foundView:&view];

    if ( view ) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wselector"
        [view performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.0];
#pragma clang diagnostic pop
        return YES;
    }

    return NO;
}

-(void)SwrveKeyboardAvoiding_scrollToActiveTextField {
    SwrveKeyboardAvoidingState *state = self.keyboardAvoidingState;

    if ( !state.keyboardVisible ) return;

    CGFloat visibleSpace = self.bounds.size.height - self.contentInset.top - self.contentInset.bottom;

    CGPoint idealOffset = CGPointMake(0, [self SwrveKeyboardAvoiding_idealOffsetForView:[self SwrveKeyboardAvoiding_findFirstResponderBeneathView:self]
                                                               withViewingAreaHeight:visibleSpace]);

    // Ordinarily we'd use -setContentOffset:animated:YES here, but it does not appear to
    // scroll to the desired content offset. So we wrap in our own animation block.
    [UIView animateWithDuration:0.25 animations:^{
        [self setContentOffset:idealOffset animated:NO];
    }];
}

#pragma mark - Helpers

- (UIView*)SwrveKeyboardAvoiding_findFirstResponderBeneathView:(UIView*)view {
    // Search recursively for first responder
    for ( UIView *childView in view.subviews ) {
        if ( [childView respondsToSelector:@selector(isFirstResponder)] && [childView isFirstResponder] ) return childView;
        UIView *result = [self SwrveKeyboardAvoiding_findFirstResponderBeneathView:childView];
        if ( result ) return result;
    }
    return nil;
}

- (void)SwrveKeyboardAvoiding_findTextFieldAfterTextField:(UIView*)priorTextField beneathView:(UIView*)view minY:(CGFloat*)minY foundView:(UIView*__autoreleasing *)foundView {
    // Search recursively for text field or text view below priorTextField
    CGFloat priorFieldOffset = CGRectGetMinY([self convertRect:priorTextField.frame fromView:priorTextField.superview]);
    for ( UIView *childView in view.subviews ) {
        if ( childView.hidden ) continue;
        if ( ([childView isKindOfClass:[UITextField class]] || [childView isKindOfClass:[UITextView class]]) && childView.isUserInteractionEnabled) {
            CGRect frame = [self convertRect:childView.frame fromView:view];
            if ( childView != priorTextField
                    && CGRectGetMinY(frame) >= priorFieldOffset
                    && CGRectGetMinY(frame) < *minY &&
                    !(frame.origin.y == priorTextField.frame.origin.y
                      && frame.origin.x < priorTextField.frame.origin.x) ) {
                *minY = CGRectGetMinY(frame);
                *foundView = childView;
            }
        } else {
            [self SwrveKeyboardAvoiding_findTextFieldAfterTextField:priorTextField beneathView:childView minY:minY foundView:foundView];
        }
    }
}

- (void)SwrveKeyboardAvoiding_assignTextDelegateForViewsBeneathView:(UIView*)view {
    for ( UIView *childView in view.subviews ) {
        if ( ([childView isKindOfClass:[UITextField class]] || [childView isKindOfClass:[UITextView class]]) ) {
            [self SwrveKeyboardAvoiding_initializeView:childView];
        } else {
            [self SwrveKeyboardAvoiding_assignTextDelegateForViewsBeneathView:childView];
        }
    }
}

-(CGSize)SwrveKeyboardAvoiding_calculatedContentSizeFromSubviewFrames {

    BOOL wasShowingVerticalScrollIndicator = self.showsVerticalScrollIndicator;
    BOOL wasShowingHorizontalScrollIndicator = self.showsHorizontalScrollIndicator;

    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;

    CGRect rect = CGRectZero;
    for ( UIView *view in self.subviews ) {
        rect = CGRectUnion(rect, view.frame);
    }
    rect.size.height += kCalculatedContentPadding;

    self.showsVerticalScrollIndicator = wasShowingVerticalScrollIndicator;
    self.showsHorizontalScrollIndicator = wasShowingHorizontalScrollIndicator;

    return rect.size;
}


- (UIEdgeInsets)SwrveKeyboardAvoiding_contentInsetForKeyboard {
    SwrveKeyboardAvoidingState *state = self.keyboardAvoidingState;
    UIEdgeInsets newInset = self.contentInset;
    CGRect keyboardRect = state.keyboardRect;
    CGFloat ydiff = CGRectGetMaxY(keyboardRect) - CGRectGetMaxY(self.bounds);
    newInset.bottom = keyboardRect.size.height - ((ydiff > 0) ? ydiff : 0);
    return newInset;
}

-(CGFloat)SwrveKeyboardAvoiding_idealOffsetForView:(UIView *)view withViewingAreaHeight:(CGFloat)viewAreaHeight {
    CGSize contentSize = self.contentSize;
    CGFloat offset = 0.0;

    CGRect subviewRect = [view convertRect:view.bounds toView:self];

    // Attempt to center the subview in the visible space, but if that means there will be less than kMinimumScrollOffsetPadding
    // pixels above the view, then substitute kMinimumScrollOffsetPadding
    CGFloat padding = (viewAreaHeight - subviewRect.size.height) / 2;
    if ( padding < kMinimumScrollOffsetPadding ) {
        padding = kMinimumScrollOffsetPadding;
    }

    // Ideal offset places the subview rectangle origin "padding" points from the top of the scrollview.
    // If there is a top contentInset, also compensate for this so that subviewRect will not be placed under
    // things like navigation bars.
    offset = subviewRect.origin.y - padding - self.contentInset.top;

    // Constrain the new contentOffset so we can't scroll past the bottom. Note that we don't take the bottom
    // inset into account, as this is manipulated to make space for the keyboard.
    if ( offset > (contentSize.height - viewAreaHeight) ) {
        offset = contentSize.height - viewAreaHeight;
    }

    // Constrain the new contentOffset so we can't scroll past the top, taking contentInsets into account
    if ( offset < -self.contentInset.top ) {
        offset = -self.contentInset.top;
    }

    return offset;
}

- (void)SwrveKeyboardAvoiding_initializeView:(UIView*)view {
    if ( [view isKindOfClass:[UITextField class]]
            && ((UITextField*)view).returnKeyType == UIReturnKeyDefault
            && (![(UITextField*)view delegate] || [(UITextField*)view delegate] == (id<UITextFieldDelegate>)self) ) {
        [(UITextField*)view setDelegate:(id<UITextFieldDelegate>)self];
        UIView *otherView = nil;
        CGFloat minY = CGFLOAT_MAX;
        [self SwrveKeyboardAvoiding_findTextFieldAfterTextField:view beneathView:self minY:&minY foundView:&otherView];

        if ( otherView ) {
            ((UITextField*)view).returnKeyType = UIReturnKeyNext;
        } else {
            ((UITextField*)view).returnKeyType = UIReturnKeyDone;
        }
    }
}

@end


@implementation SwrveKeyboardAvoidingState

@synthesize priorContentSize;
@synthesize priorInset;
@synthesize priorScrollIndicatorInsets;
@synthesize keyboardRect;
@synthesize keyboardVisible;

@end
