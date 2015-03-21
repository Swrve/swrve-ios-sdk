
/*******************************************************
 * Copyright (C) 2011-2012 Converser contact@converser.io
 *
 * This file is part of the Converser iOS SDK.
 *
 * This code may not be copied and/or distributed without the express
 * permission of Converser. Please email contact@converser.io for
 * all redistribution and reuse enquiries.
 *******************************************************/

#import "SwrveConversationButton.h"
#import "SwrveSetup.h"

@implementation SwrveConversationButton

@synthesize description = _description;
@synthesize actions = _actions;
@synthesize target = _target;

-(id) initWithTag:(NSString *)tag andDescription:(NSString *)description {
    self = [super initWithTag:tag andType:kSwrveControlTypeButton];
    if(self) {
        _description = description;
        _target = nil;
    }
    return self;
}

-(BOOL) endsConversation {
    return _target==nil;
}

-(UIView *)view {
    if(_view == nil) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
        [button setTitle:_description forState:UIControlStateNormal];
        _view = button;
    }
    return _view;
}

@end
