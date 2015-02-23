/*******************************************************
 * Copyright (C) 2011-2012 Converser contact@converser.io
 *
 * This file is part of the Converser iOS SDK.
 *
 * This code may not be copied and/or distributed without the express
 * permission of Converser. Please email contact@converser.io for
 * all redistribution and reuse enquiries.
 *******************************************************/

#import "SwrveChoiceArray.h"
#import "SwrveSetup.h"

@implementation SwrveChoiceArray
@synthesize choices = _choices;
@synthesize selectedIndex = _selectedIndex;
@synthesize title = _title;
@synthesize hasMore = _hasMore;

// So, choices may be an array of strings...or an array of dictionaries.
// It it is an array of dictionaries, we effectively have to make more of ourselves....
-(id) initWithArray:(NSArray *)choices andTitle:(NSString *)title {
    self = [super init];
    if(self) {
        _title = [title copy];
        id obj = [choices objectAtIndex:0];
        if([obj isKindOfClass:[NSString class]]) {
            _choices = [choices copy];
            _hasMore = NO;
        } else {
            _hasMore = YES;
            NSMutableArray *inner = [[NSMutableArray alloc] initWithCapacity:choices.count];
            for(NSDictionary *dict in choices) {
                NSString *innerTitle = [dict objectForKey:@"title"];
                NSArray *innerOptions = [dict objectForKey:@"options"];
                SwrveChoiceArray *innerChoice = [[SwrveChoiceArray alloc] initWithArray:innerOptions andTitle:innerTitle];
                [inner addObject:innerChoice];
            }
            _choices = [[NSArray alloc] initWithArray:inner];
        }
        self.selectedIndex = -1;
    }
    return self;
}

-(NSString *)selectedItem {
    if(self.selectedIndex == -1) {
        return @"";
    }
    
    // TBD: c
    NSUInteger inx = (NSUInteger)self.selectedIndex;
    return [_choices objectAtIndex:inx];
}

-(NSDictionary *)userResponse {
    if(_hasMore) {
        NSMutableDictionary *ret = [[NSMutableDictionary alloc] init ];
        for(SwrveChoiceArray *innerChoice in _choices) {
            NSDictionary *innerResp = [innerChoice userResponse];
            [ret addEntriesFromDictionary:innerResp];
        }
        return ret;
    }
    return [NSDictionary dictionaryWithObject:self.selectedItem forKey:self.title];
}

@end
