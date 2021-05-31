#import <Foundation/Foundation.h>

/*! Swrve SDK logger class. Defaults to verbose on DEBUG builds and to none on release builds. You can change the level at runtime with setLogLevel */
typedef enum SwrveLogLevel : NSUInteger {
    NONE,
    ERROR,
    WARNING,
    VERBOSE
} SwrveLogLevel;

@interface SwrveLogger : NSObject

+ (void)setLogLevel:(SwrveLogLevel)level;

+ (void)error:(NSString *)format, ...;
+ (void)warning:(NSString *)format, ...;
+ (void)debug:(NSString *)format, ...;

@end
