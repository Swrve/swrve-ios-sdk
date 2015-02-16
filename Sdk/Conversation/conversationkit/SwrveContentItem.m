
/*******************************************************
 * Copyright (C) 2011-2012 Converser contact@converser.io
 *
 * This file is part of the Converser iOS SDK.
 *
 * This code may not be copied and/or distributed without the express
 * permission of Converser. Please email contact@converser.io for
 * all redistribution and reuse enquiries.
 *******************************************************/

#import "SwrveContentItem.h"
#import "SwrveSetup.h"

@implementation SwrveContentItem
@synthesize value = _value;

#define kSwrveKeyValue @"value" 

-(id) initWithTag:(NSString *)tag type:(NSString *)type andDictionary:(NSDictionary *)dict {
    self = [super initWithTag:tag andType:type];
    if(self) {
        _value = [dict objectForKey:kSwrveKeyValue];
    }
    return self;
}

+(UIScrollView*) scrollView:(UIWebView*)web {
    if ([web respondsToSelector:@selector(scrollView)]) {
        return [web scrollView];
    } else {
        UIScrollView *v = nil;
        for (UIView* subview in [web subviews]) {
            if ([subview isKindOfClass:[UIScrollView class]]) {
                v = (UIScrollView*)subview;
                break;
            }
        }
        return v;
    }
}
@end
