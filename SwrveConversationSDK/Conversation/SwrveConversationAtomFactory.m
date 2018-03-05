#import "SwrveConversationAtomFactory.h"
#import "SwrveContentHTML.h"
#import "SwrveContentImage.h"
#import "SwrveContentVideo.h"
#import "SwrveContentSpacer.h"
#import "SwrveConversationButton.h"
#import "SwrveContentStarRating.h"
#import "SwrveInputMultiValue.h"

@implementation SwrveConversationAtomFactory

#if TARGET_OS_IOS /** exclude tvOS **/
+ (NSMutableArray <SwrveConversationAtom *> *) atomsForDictionary:(NSDictionary *)dict {

    NSString *tag = [dict objectForKey:kSwrveKeyTag];
    NSString *type = [dict objectForKey:kSwrveKeyType];
    
    NSMutableArray<SwrveConversationAtom *> *atomArray = [NSMutableArray array];
    
    if(type == nil) {
        type = kSwrveControlTypeButton;
    }

    // Create some resilience with defaults for tag and type.
    // the tag must be unique within the context of the page.
    if (tag == nil) {
        tag = [[NSUUID UUID] UUIDString];
    }
    
    if([type isEqualToString:kSwrveContentTypeHTML]) {
        SwrveContentHTML *swrveContentHTML = [[SwrveContentHTML alloc] initWithTag:tag andDictionary:dict];
        [atomArray addObject:swrveContentHTML];
    }
    else if([type isEqualToString:kSwrveContentTypeImage]) {
        SwrveContentImage *swrveContentImage = [[SwrveContentImage alloc] initWithTag:tag andDictionary:dict];
        swrveContentImage.style = [dict objectForKey:kSwrveKeyStyle];
        [atomArray addObject:swrveContentImage];
    } else if([type isEqualToString:kSwrveContentTypeVideo]) {
        SwrveContentVideo *swrveContentVideo = [[SwrveContentVideo alloc] initWithTag:tag andDictionary:dict];
        swrveContentVideo.style = [dict objectForKey:kSwrveKeyStyle];
        [atomArray addObject:swrveContentVideo];
    } else if([type isEqualToString:kSwrveControlTypeButton]) {
        SwrveConversationButton *swrveConversationButton = [[SwrveConversationButton alloc] initWithTag:tag andDictionary:dict];
        [atomArray addObject:swrveConversationButton];
    } else if([type isEqualToString:kSwrveInputMultiValue]) {
        SwrveInputMultiValue *swrveInputMultiValue = [[SwrveInputMultiValue alloc] initWithTag:tag andDictionary:dict];
        [atomArray addObject:swrveInputMultiValue];
    } else if ([type isEqualToString:kSwrveContentSpacer]) {
        SwrveContentSpacer* swrveContentSpacer = [[SwrveContentSpacer alloc] initWithTag:tag andDictionary:dict];
        swrveContentSpacer.style = [dict objectForKey:kSwrveKeyStyle];
        [atomArray addObject:swrveContentSpacer];
    }
    else if ([type isEqualToString:kSwrveContentStarRating]) {
        SwrveContentHTML *swrveContentHTML = [[SwrveContentHTML alloc] initWithTag:tag andDictionary:dict];
        [atomArray addObject:swrveContentHTML];
        SwrveContentStarRating *swrveConversationStarRating = [[SwrveContentStarRating alloc] initWithTag:tag andDictionary:dict];
        swrveConversationStarRating.style = [dict objectForKey:kSwrveKeyStyle];
        [atomArray addObject:swrveConversationStarRating];
    }
    else {
        SwrveContentItem *swrveContentItem = [[SwrveContentItem alloc] initWithTag:tag type:kSwrveContentUnknown andDictionary:dict];
        [atomArray addObject:swrveContentItem];
    }

    return atomArray;
}
#else
+ (NSMutableArray <SwrveConversationAtom *> *) atomsForDictionary:(NSDictionary *)dict {
    /** if we're not using a supported platform then return nothing **/
    return nil;
}
#endif

@end
