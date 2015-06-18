#import "SwrveConversationUIButton.h"
#import <Foundation/Foundation.h>

@interface SwrveConversationStyler : NSObject

+ (void)styleView:(UIView *)uiView withStyle:(NSDictionary*)style;
+ (NSString *) convertContentToHtml:(NSString*)content withPageCSS:(NSString*)pageCSS withStyle:(NSDictionary*)style;
+ (UIColor *) convertToUIColor:(NSString*)color;
+ (void) styleButton:(SwrveConversationUIButton *)button withStyle:(NSDictionary*)style;

@end
