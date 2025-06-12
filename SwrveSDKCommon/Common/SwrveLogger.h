#import <Foundation/Foundation.h>

/*! Swrve SDK logger class. Defaults to verbose on DEBUG builds and to none on release builds. You can change the level at runtime with setLogLevel */
typedef NS_ENUM(NSUInteger, SwrveLogLevel) {
    SwrveLogLevelNone,
    SwrveLogLevelError,
    SwrveLogLevelWarning,
    SwrveLogLevelVerbose
};

// Backward compatibility for old constant names
#define NONE SwrveLogLevelNone
#define ERROR SwrveLogLevelError
#define WARNING SwrveLogLevelWarning
#define VERBOSE SwrveLogLevelVerbose

@interface SwrveLogger : NSObject

+ (void)setLogLevel:(SwrveLogLevel)level;

+ (void)error:(NSString *)format, ...;
+ (void)warning:(NSString *)format, ...;
+ (void)debug:(NSString *)format, ...;

+ (void)logError:(NSString *)message;
+ (void)logWarning:(NSString *)message;
+ (void)logDebug:(NSString *)message;


@end
