#if __has_include(<SwrveSDKCommon/SwrveCommon.h>)
#import <SwrveSDKCommon/SwrveCommon.h>
#else
#import "SwrveCommon.h"
#endif
#import "SwrveMessageEventHandler.h"
#import "SwrveContentItem.h"
#import "SwrveBaseConversation.h"
#import "SwrveConversationPane.h"
#import "SwrveContentHTML.h"
#import "SwrveContentStarRating.h"
#import "SwrveInputMultiValue.h"
#import "SwrveConversationButton.h"

@interface SwrveBaseConversation()

@property (nonatomic, weak)     id<SwrveMessageEventHandler> controller;

@end

@implementation SwrveBaseConversation

@synthesize controller, conversationID, name, pages;

- (SwrveBaseConversation *)updateWithJSON:(NSDictionary *)json forController:(id <SwrveMessageEventHandler>)_controller {
    self.controller = _controller;
    self.conversationID = [json objectForKey:@"id"];
    self.name = [json objectForKey:@"name"];

    NSArray *jsonPages = [json objectForKey:@"pages"];
    NSMutableArray *loadedPages = [NSMutableArray new];
    for (NSDictionary *pageJson in jsonPages) {
        [loadedPages addObject:[[SwrveConversationPane alloc] initWithDictionary:pageJson]];
    }
    self.pages = loadedPages;
    return self;
}

+(SwrveBaseConversation*) fromJSON:(NSDictionary*)json
                       forController:(id<SwrveMessageEventHandler>)controller
{
    SwrveBaseConversation* conversation = [[[SwrveBaseConversation alloc] init] updateWithJSON:json forController:controller];

    if((nil == controller) || (nil == conversation.conversationID) || (nil == conversation.name) || (nil == conversation.pages)) {
        return nil;
    }

    return conversation;
}

-(BOOL)assetsReady:(NSSet*)assets {
    for (SwrveConversationPane* page in self.pages) {

        // check font and images from content
        for (SwrveContentItem* contentItem in page.content) {
            if([contentItem.type isEqualToString:kSwrveContentTypeImage]) {
                if (![assets containsObject:contentItem.value]) {
                    [SwrveLogger error:@"Conversation asset not yet downloaded: %@", contentItem.value];
                    return false;
                }

            }
#if TARGET_OS_IOS /** exclude tvOS **/
            else if ([contentItem isKindOfClass:
                        [SwrveContentHTML class]] || [contentItem isKindOfClass:[SwrveContentStarRating class]]) {
                if([self isFontAssetMissing:contentItem.style inCache: assets]) {
                    [SwrveLogger error:@"Conversation asset not yet downloaded: %@", contentItem.style];
                    return false;
                }
            }
#endif
            else if ([contentItem isKindOfClass:[SwrveInputMultiValue class]]) {
                SwrveInputMultiValue *inputMultiValue = (SwrveInputMultiValue*) contentItem;
                if([self isFontAssetMissing:inputMultiValue.style inCache: assets]) {
                    [SwrveLogger error:@"Conversation asset not yet downloaded: %@", inputMultiValue.style];
                    return false;
                }

                for (NSDictionary *value in inputMultiValue.values) {
                    NSDictionary *style = [value objectForKey:@"style"];
                    if([self isFontAssetMissing:style inCache: assets]) {
                        [SwrveLogger error:@"Conversation asset not yet downloaded: %@", style];
                        return false;
                    }
                }
            }
        }

        // check font asset in button
        for (SwrveConversationButton *button in page.controls) {
            if([self isFontAssetMissing:button.style inCache: assets]) {
                [SwrveLogger error:@"Conversation asset not yet downloaded: %@", button.style];
                return false;
            }
        }
    }

    return true;
}

- (BOOL)isFontAssetMissing:(NSDictionary *)style inCache:(NSSet *)assets {
    BOOL isFontAssetMissing = YES;
    if ([SwrveBaseConversation isSystemFont:style]) {
        isFontAssetMissing = NO; // doesn't need a font asset
    } else if (!style || ![style objectForKey:kSwrveKeyFontFile]) {
        isFontAssetMissing = NO; // doesn't need a font asset
    } else {
        NSString *fontFile = [style objectForKey:kSwrveKeyFontFile];
        if (fontFile && [fontFile isEqualToString:kSwrveDefaultMultiValueCellFontName]) {
            isFontAssetMissing = NO;
        } else if (fontFile && fontFile.length == 0) {
            isFontAssetMissing = NO; // System font can be empty
        } else if (fontFile && [assets containsObject:fontFile]) {
            isFontAssetMissing = NO;
        }
    }
    return isFontAssetMissing;
}

-(void)wasShownToUser {
    id<SwrveMessageEventHandler> c = self.controller;
    if (c != nil) {
        [c conversationWasShownToUser:self];
    }
}

-(SwrveConversationPane*)pageAtIndex:(NSUInteger)index {
    if (index > self.pages.count - 1) {
        return nil;
    } else {
        return [self.pages objectAtIndex:index];
    }
}

-(SwrveConversationPane*)pageForTag:(NSString*)tag {
    for (SwrveConversationPane *page in self.pages) {
        if ([tag isEqualToString:page.tag]) {
            return page;
        }
    }
    return nil;
}

+(BOOL)isSystemFont:(NSDictionary *)style {
    BOOL isSystemFont = NO;
    if(style && [style objectForKey:kSwrveKeyFontFile]) {
        NSString *fontFile = [style objectForKey:kSwrveKeyFontFile];
        if([fontFile isEqualToString:@"_system_font_"]) {
            isSystemFont = YES;
        }
    }
    return isSystemFont;
}

@end
