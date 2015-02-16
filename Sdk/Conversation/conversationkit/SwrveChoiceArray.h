/*******************************************************
 * Copyright (C) 2011-2012 Converser contact@converser.io
 *
 * This file is part of the Converser iOS SDK.
 *
 * This code may not be copied and/or distributed without the express
 * permission of Converser. Please email contact@converser.io for
 * all redistribution and reuse enquiries.
 *******************************************************/

#import <Foundation/Foundation.h>

@interface SwrveChoiceArray : NSObject

-(id) initWithArray:(NSArray *)choices andTitle:(NSString *)title;

@property(nonatomic, readonly) BOOL hasMore;
@property(nonatomic, assign) NSInteger selectedIndex;
@property(nonatomic, readonly, strong) NSArray *choices;
@property(nonatomic, readonly, strong) NSString *title;
@property(nonatomic, readonly) NSString *selectedItem;

-(NSDictionary *)userResponse;

@end
