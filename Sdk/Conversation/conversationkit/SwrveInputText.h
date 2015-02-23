
/*******************************************************
 * Copyright (C) 2011-2012 Converser contact@converser.io
 *
 * This file is part of the Converser iOS SDK.
 *
 * This code may not be copied and/or distributed without the express
 * permission of Converser. Please email contact@converser.io for
 * all redistribution and reuse enquiries.
 *******************************************************/

#import "SwrveInputItem.h"
#import <QuartzCore/QuartzCore.h>

@interface SwrveInputText : SwrveInputItem <UITextViewDelegate>

@property(nonatomic, readonly) NSString *placeHolder;
@property(nonatomic, readonly) NSUInteger numberOfLines;
@property(nonatomic, readonly) NSString *descriptiveText;
@property (strong, nonatomic) UIToolbar *fieldAccessoryView;

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict;
@end
