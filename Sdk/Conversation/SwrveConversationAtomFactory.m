#if !__has_feature(objc_arc)
#error ConverserSDK must be built with ARC.
// You can turn on ARC for only ConverserSDK files by adding -fobjc-arc to the build phase for each of its files.
#endif

#import "SwrveConversationAtomFactory.h"
#import "SwrveContentHTML.h"
#import "SwrveContentImage.h"
#import "SwrveContentVideo.h"
#import "SwrveContentSpacer.h"
#import "SwrveConversationButton.h"
#import "SwrveInputMultiValue.h"
#import "SwrveInputMultiValueLong.h"

#define kSwrveKeyTag @"tag"
#define kSwrveKeyType @"type"
#define kSwrveKeyOptional @"optional"

@implementation SwrveConversationAtomFactory

+(SwrveConversationAtom *) atomForDictionary:(NSDictionary *)dict {
    NSString *tag = [dict objectForKey:kSwrveKeyTag];
    NSString *type = [dict objectForKey:kSwrveKeyType];
    if(type == nil) {
        type = kSwrveControlTypeButton;
    }
    
    BOOL optional = [[dict objectForKey:kSwrveKeyOptional] boolValue];

    // Create some resilience with defaults for tag and type.
    // the tag must be unique within the context of the page.
    if (tag == nil) {
        tag = [[NSUUID UUID] UUIDString];
    }
    
    if([type isEqualToString:kSwrveContentTypeHTML]) {
        SwrveContentHTML *swrveContentHTML = [[SwrveContentHTML alloc] initWithTag:tag andDictionary:dict];
        swrveContentHTML.style = [dict objectForKey:@"style"];
        return swrveContentHTML;
    } else if([type isEqualToString:kSwrveContentTypeImage]) {
        SwrveContentImage *swrveContentImage = [[SwrveContentImage alloc] initWithTag:tag andDictionary:dict];
        swrveContentImage.style = [dict objectForKey:@"style"];
        return swrveContentImage;
    } else if([type isEqualToString:kSwrveContentTypeVideo]) {
        SwrveContentVideo *swrveContentVideo = [[SwrveContentVideo alloc] initWithTag:tag andDictionary:dict];
        swrveContentVideo.style = [dict objectForKey:@"style"];
        return swrveContentVideo;
    } else if([type isEqualToString:kSwrveControlTypeButton]) {
        SwrveConversationButton *swrveConversationButton = [[SwrveConversationButton alloc] initWithTag:tag andDescription:[dict objectForKey:kSwrveKeyDescription]];
        swrveConversationButton.actions = [dict objectForKey:@"action"];
        swrveConversationButton.style = [dict objectForKey:@"style"];
        NSString *target = [dict objectForKey:@"target"]; // Leave the target nil if this a conversation ender (i.e. no following state)
        if (target && ![target isEqualToString:@""]) {
            swrveConversationButton.target = target;
        }
        return swrveConversationButton;
    } else if([type isEqualToString:kSwrveInputMultiValueLong]) {
        SwrveInputMultiValueLong *swrveInputMultiValueLong = [[SwrveInputMultiValueLong alloc] initWithTag:tag andDictionary:dict];
        [swrveInputMultiValueLong setOptional:optional];
        swrveInputMultiValueLong.style = [dict objectForKey:@"style"];
        return swrveInputMultiValueLong;
    } else if([type isEqualToString:kSwrveInputMultiValue]) {
        SwrveInputMultiValue *swrveInputMultiValue = [[SwrveInputMultiValue alloc] initWithTag:tag andDictionary:dict];
        [swrveInputMultiValue setOptional:optional];
        swrveInputMultiValue.style = [dict objectForKey:@"style"];
        return swrveInputMultiValue;
    } else if ([type isEqualToString:kSwrveContentSpacer]) {
        SwrveContentSpacer* swrveContentSpacer = [[SwrveContentSpacer alloc] initWithTag:tag andDictionary:dict];
        swrveContentSpacer.style = [dict objectForKey:@"style"];
        return swrveContentSpacer;
    }
    
    return nil;
}

@end
