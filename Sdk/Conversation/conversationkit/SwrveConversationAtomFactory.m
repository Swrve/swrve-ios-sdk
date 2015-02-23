
/*******************************************************
 * Copyright (C) 2011-2012 Converser contact@converser.io
 *
 * This file is part of the Converser iOS SDK.
 *
 * This code may not be copied and/or distributed without the express
 * permission of Converser. Please email contact@converser.io for
 * all redistribution and reuse enquiries.
 *******************************************************/

#if !__has_feature(objc_arc)
#error ConverserSDK must be built with ARC.
// You can turn on ARC for only ConverserSDK files by adding -fobjc-arc to the build phase for each of its files.
#endif

#import "SwrveConversationAtomFactory.h"
#import "SwrveInputText.h"
#import "SwrveContentHTML.h"
#import "SwrveContentImage.h"
#import "SwrveContentVideo.h"
#import "SwrveConversationButton.h"
#import "SwrveInputMultiValue.h"
#import "SwrveInputMultiValueLong.h"
#import "SwrveSetup.h"

#define kSwrveKeyTag @"tag"
#define kSwrveKeyType @"type"
#define kSwrveKeyOptional @"optional"

@implementation SwrveConversationAtomFactory

+(NSString*)GUIDString {
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return (__bridge NSString *)string;
}

+(SwrveConversationAtom *) atomForDictionary:(NSDictionary *)dict {
    NSString *tag = [dict objectForKey:kSwrveKeyTag];
    NSString *type = [dict objectForKey:kSwrveKeyType];
    if(type == nil) {
        type = kSwrveControlTypeButton;
    }
    
    BOOL optional = [[dict objectForKey:kSwrveKeyOptional] isEqualToString:@"true"];
    

    // Create some resilience with defaults for tag and type.
    // the tag must be unique within the context of the page.
    if (tag == nil) {
        tag = [self GUIDString];
    }
    
    if(type == nil) {
        type = kSwrveInputTypeText;
    }
    
    if([type isEqualToString:kSwrveInputTypeText]) {
        SwrveInputText *vgInputText = [[SwrveInputText alloc] initWithTag:tag andDictionary:dict];
        [vgInputText setOptional:optional];
        return vgInputText;
    }
    if([type isEqualToString:kSwrveContentTypeHTML]) {
        SwrveContentHTML *vgContentHTML = [[SwrveContentHTML alloc] initWithTag:tag andDictionary:dict];
        return vgContentHTML;
    }
    if([type isEqualToString:kSwrveContentTypeImage]) {
        SwrveContentImage *vgContentImage = [[SwrveContentImage alloc] initWithTag:tag andDictionary:dict];
        return vgContentImage;
    }
    
    if([type isEqualToString:kSwrveContentTypeVideo]) {
        SwrveContentVideo *vgContentVideo = [[SwrveContentVideo alloc] initWithTag:tag andDictionary:dict];
        return vgContentVideo;
    }
    
    if([type isEqualToString:kSwrveControlTypeButton]) {
        SwrveConversationButton *vgConversationButton = [[SwrveConversationButton alloc] initWithTag:tag andDescription:[dict objectForKey:kSwrveKeyDescription]];
        vgConversationButton.actions = [dict objectForKey:@"action"];
        
        return vgConversationButton;
    }
    if([type isEqualToString:kSwrveInputMultiValueLong]) {
        SwrveInputMultiValueLong *vgInputMultivalueLong = [[SwrveInputMultiValueLong alloc] initWithTag:tag andDictionary:dict];
         [vgInputMultivalueLong setOptional:optional];
        return vgInputMultivalueLong;
    }
    if([type isEqualToString:kSwrveInputMultiValue]) {
        SwrveInputMultiValue *vgInputMultiValue = [[SwrveInputMultiValue alloc] initWithTag:tag andDictionary:dict];
         [vgInputMultiValue setOptional:optional];
        return vgInputMultiValue;
    }
    
    return nil;
}


@end
