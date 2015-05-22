#import <Foundation/Foundation.h>

@interface SwrveConversationStyler : NSObject

+ (void)styleView:(UIView *)uiView withStyle:(NSDictionary*)style;
+ (NSString *) convertContentToHtml:(NSString*)content withStyle:(NSDictionary*)style;
+ (UIColor *) convertToUIColor:(NSString*)color;
+(void) styleButton:(UIButton *)button withStyle:(NSDictionary*)style;

@end
