
/*******************************************************
 * Copyright (C) 2011-2012 Converser contact@converser.io
 *
 * This file is part of the Converser iOS SDK.
 *
 * This code may not be copied and/or distributed without the express
 * permission of Converser. Please email contact@converser.io for
 * all redistribution and reuse enquiries.
 *******************************************************/

#import "SwrveInputText.h"
#import "SwrveConversationResource.h"
#import "SwrveSetup.h"

#define kSwrveKeyPlaceHolder @"placeholder"
#define kSwrveKeyLines @"lines"
#define kSwrveKeyDescription @"description"
#define kKeyboard @"kbd"
#define urlKeyboard @"url"
#define emailKeyboard @"email"
#define numberKeyboard @"number"
#define phoneKeyboard @"phone"

@interface SwrveInputText () 
{
    UILabel *placeHolderLabel;
    NSString *keyboardTag;
    UIColor *defaultBorderColor;
}
@end


@implementation SwrveInputText

@synthesize placeHolder = _placeHolder;
@synthesize numberOfLines = _numberOfLines;
@synthesize descriptiveText = _descriptiveText;

@synthesize fieldAccessoryView;

-(void) resignFirstResponder {
    UITextView *tv = (UITextView *)[_view viewWithTag:1];
    if([tv isFirstResponder]) {
        [tv resignFirstResponder];
    }
}

-(BOOL) isFirstResponder {
    UITextView *tv = (UITextView *)[_view viewWithTag:1];
    return [tv isFirstResponder];
}

-(id) initWithTag:(NSString *)tag placeHolder:(NSString *)placeHolder numberOfLines:(NSUInteger) numberOfLines descriptiveText:(NSString *)descriptiveText {
    self = [super initWithTag:tag andType:kSwrveInputTypeText];
    if(self) {
        _placeHolder = placeHolder;
        _numberOfLines = numberOfLines;
        _descriptiveText = descriptiveText;
    }
    return self;
}

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict {
    NSString *placeholder = [dict objectForKey:kSwrveKeyPlaceHolder];  // Optional, can be not present
    NSNumber *num = [dict objectForKey:kSwrveKeyLines];
    keyboardTag = [dict objectForKey:kKeyboard];
    NSUInteger numberOfLines;
    if(num == nil) {
        numberOfLines = 4;
    } else {
        numberOfLines = (NSUInteger)[num integerValue];
    }
    NSString *descriptiveText = [dict objectForKey:kSwrveKeyDescription];
    defaultBorderColor = [UIColor lightGrayColor];
    self = [self initWithTag:tag placeHolder:placeholder numberOfLines:numberOfLines descriptiveText:descriptiveText];
    return self;
}

-(BOOL) isValid:(NSError *__autoreleasing *)error {
#pragma unused (error)
    if ([keyboardTag isEqualToString:emailKeyboard]) {
        NSString *email = [self value];

        if ([email length]==0){
            return NO;
        }
        
        NSString *regExPattern = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
        
        NSRegularExpression *regEx = [[NSRegularExpression alloc] initWithPattern:regExPattern options:NSRegularExpressionCaseInsensitive error:nil];
        NSUInteger regExMatches = [regEx numberOfMatchesInString:email options:0 range:NSMakeRange(0, [email length])];
        
        if (regExMatches == 0) {
            return NO;
        } else {
            return YES;
        }
    }
    return YES;
}

-(void) loadView {
    CGFloat xOffset = 10.0, yOffset = 2.0;
    CGFloat inputWidth = [SwrveConversationAtom widthOfContentView] - (xOffset*2);
    if(self.descriptiveText) {
        SwrveLogIt(@"loadView :: [SwrveConversationAtom widthOfContentView]: %f", [SwrveConversationAtom widthOfContentView]);
        UILabel *descLabel = [[UILabel alloc] initWithFrame:CGRectMake(xOffset, 2, inputWidth, 9999)];
        descLabel.backgroundColor = [UIColor clearColor];
        descLabel.font = [UIFont boldSystemFontOfSize:20.0];
        descLabel.lineBreakMode = NSLineBreakByWordWrapping;
        descLabel.numberOfLines = 0;
        descLabel.adjustsFontSizeToFitWidth = NO;
        descLabel.text = self.descriptiveText;
        [descLabel sizeToFit];
        
        _view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [SwrveConversationAtom widthOfContentView], descLabel.frame.size.height + 14 * (_numberOfLines + 2))];
        [_view addSubview:descLabel];
        yOffset += descLabel.frame.size.height;
    }else {
        SwrveLogIt(@"loadView :: [SwrveConversationAtom widthOfContentView]: %f", [SwrveConversationAtom widthOfContentView]);
        _view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [SwrveConversationAtom widthOfContentView], 14 * (_numberOfLines + 2))];
    }

    _view.backgroundColor = [UIColor clearColor];
    UITextView *tv = [[UITextView alloc] initWithFrame:CGRectMake(xOffset, yOffset, inputWidth, _view.frame.size.height-yOffset-2)];
    tv.font = [UIFont boldSystemFontOfSize:18.0];
    tv.delegate = self;
    tv.backgroundColor = [UIColor clearColor];
    tv.tag = 1;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        tv.backgroundColor = [UIColor whiteColor];
    } else {
        tv.backgroundColor = [UIColor colorWithRed:1.000f green:0.984f blue:0.984f alpha:1.000f];
    }
    
    if ([keyboardTag isEqualToString:urlKeyboard]) {
        [tv setKeyboardType:UIKeyboardTypeURL];
    } else if ([keyboardTag isEqualToString:emailKeyboard]) {
        [tv setKeyboardType:UIKeyboardTypeEmailAddress];
    } else if ([keyboardTag isEqualToString:phoneKeyboard]) {
        [tv setKeyboardType:UIKeyboardTypePhonePad];
    } else if ([keyboardTag isEqualToString:numberKeyboard]) {
        [tv setKeyboardType:UIKeyboardTypeNumberPad];
    }

    placeHolderLabel = [[UILabel alloc] initWithFrame:CGRectMake(xOffset, 2, [SwrveConversationAtom widthOfContentView]-(xOffset*2), 30.0)];
    placeHolderLabel.font = tv.font;
    placeHolderLabel.backgroundColor = [UIColor clearColor];
    placeHolderLabel.text = self.placeHolder;
    placeHolderLabel.textColor = [UIColor grayColor];
    // We should probably act as a controller/delegate for this.  At the very least, we'll need to delete the placeholder once a person starts typing.
    // ..or not; going to be difficult to replicate text field behaviour in a text view;
    [tv.layer setCornerRadius:8.0];
    [tv.layer setBorderWidth:0.5];
    [tv.layer setBorderColor:defaultBorderColor.CGColor];
    tv.clipsToBounds = YES;

    // Automatically resize width based on container, the _view itself responds based on NSNotification
    tv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    placeHolderLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;

    // Toolbar
    [self createAccessoryView];
    [tv setInputAccessoryView:fieldAccessoryView];

    [_view addSubview:tv];
    [tv addSubview:placeHolderLabel];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSwrveNotificationViewReady object:nil];
    // Get notified if the view should change dimensions
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:kSwrveNotifyOrientationChange object:nil];
}

-(void) deviceOrientationDidChange {
    _view.frame = [self newFrameForOrientationChange];
}

-(UIView *)view {
    if(_view == nil) {
        [self loadView];
    }
    return _view;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSwrveNotifyOrientationChange object:nil];
}

-(NSString *)value {
    UITextView *tv = (UITextView *)[_view viewWithTag:1];
    return tv.text;
}

-(NSString *)userResponse {
    return self.value;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
#pragma unused (textView)
    placeHolderLabel.hidden = YES;
    return YES;
}

-(BOOL) textViewShouldEndEditing:(UITextView *)textView {
    if(textView.text.length == 0) {
        placeHolderLabel.hidden = NO;
    }
    NSError *err = nil;
    if (![self isValid:&err]) {
        [self highlight];
    } else {
        [self unhighlight];
    }
    return YES;
}

-(BOOL)isComplete {
    return [[self value] length] > 0;
}

-(void)highlight {
    UITextView *tv = (UITextView *)[_view viewWithTag:1];
    [tv.layer setBorderColor:[UIColor redColor].CGColor];
}

-(void)unhighlight {
    UITextView *tv = (UITextView *)[_view viewWithTag:1];
    [tv.layer setBorderColor:defaultBorderColor.CGColor];
}

- (void)createAccessoryView
{
    CGRect frame = CGRectMake(0.0, self.view.bounds.size.height, self.view.bounds.size.width, 44.0);
    fieldAccessoryView = [[UIToolbar alloc] initWithFrame:frame];
    fieldAccessoryView.tag = 200;
    //
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        fieldAccessoryView.barStyle = UIBarStyleDefault;
    } else {
        fieldAccessoryView.barStyle = UIBarStyleBlackTranslucent;
        fieldAccessoryView.backgroundColor = [UIColor colorWithRed:0.49f green:0.52f blue:0.57f alpha:1.0f];
        UIImage *backgroundImage = [SwrveConversationResource imageFromBundleNamed:@"keyboardBackground.png"];
        if( [backgroundImage respondsToSelector:@selector(resizableImageWithCapInsets:resizingMode:)] ) {
            backgroundImage = [backgroundImage resizableImageWithCapInsets:UIEdgeInsetsMake(2, 0, 0, 0 ) resizingMode:UIImageResizingModeStretch];
        } else {
            backgroundImage = [backgroundImage resizableImageWithCapInsets:UIEdgeInsetsMake(2, 0, 0, 0 )];
        }
        //
        [fieldAccessoryView setBackgroundImage:backgroundImage forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    }

    //
    UIBarButtonItem *spaceButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                 target:nil
                                                                                 action:nil];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self
                                                                                action:@selector(doneButtonTapped)];
    //
    [fieldAccessoryView setItems:[NSArray arrayWithObjects:spaceButton, doneButton, nil] animated:NO];
}

-(void) doneButtonTapped {
    [self resignFirstResponder];
}

@end
