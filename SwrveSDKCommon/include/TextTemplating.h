#import <Foundation/Foundation.h>

@interface TextTemplating : NSObject

+ (NSString *)templatedTextFromString:(NSString *)text withProperties:(NSDictionary *)properties andError:(NSError **)error;

@end
