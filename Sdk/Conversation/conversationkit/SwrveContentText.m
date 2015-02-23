
/*******************************************************
 * Copyright (C) 2011-2012 Converser contact@converser.io
 *
 * This file is part of the Converser iOS SDK.
 *
 * This code may not be copied and/or distributed without the express
 * permission of Converser. Please email contact@converser.io for
 * all redistribution and reuse enquiries.
 *******************************************************/

#import "SwrveContentText.h"
#import "SwrveSetup.h"

@implementation SwrveContentText

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict {
    self = [super initWithTag:tag type:kSwrveContentTypeText andDictionary:dict];
    return self;
}

-(void) loadView {
    // Create _view
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [SwrveConversationAtom widthOfContentView], 32)];
    label.backgroundColor = [UIColor clearColor];

    label.font = [UIFont boldSystemFontOfSize:14.0];
#pragma deploymate push "ignored-api-availability"
    label.textAlignment = NSTextAlignmentCenter;
#pragma deploymate pop
    label.textColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0];
    label.shadowColor = [UIColor whiteColor];
    label.shadowOffset = CGSizeMake(0.0, 1.0);
#pragma deploymate push "ignored-api-availability"
    label.lineBreakMode = NSLineBreakByWordWrapping;
#pragma deploymate pop
    CGSize maxSize = CGSizeMake(label.frame.size.width, 9999);
    CGSize sizeIneed = [self.value sizeWithFont:label.font constrainedToSize:maxSize lineBreakMode:label.lineBreakMode];
    CGRect rect = label.frame;
    rect.size = sizeIneed;
    label.frame = rect;
    label.text = self.value;
    label.numberOfLines = 0;
    _view = label;
    [[NSNotificationCenter defaultCenter] postNotificationName:kSwrveNotificationViewReady object:nil];
}

-(UIView *)view {
    if(!_view) {
        [self loadView];
    }
    return _view;
}


@end
