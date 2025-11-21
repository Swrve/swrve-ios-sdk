#import "SwrveLogger.h"

@implementation SwrveLogger : NSObject

#if DEBUG
static SwrveLogLevel logLevel = SwrveLogLevelVerbose;
#else
static SwrveLogLevel logLevel = SwrveLogLevelWarning;
#endif

+ (void)setLogLevel:(SwrveLogLevel)level
{
    logLevel = level;
}

+ (void)error:(NSString *)format, ...
{
#ifndef SWRVE_DISABLE_LOGS
    if (logLevel == SwrveLogLevelVerbose || logLevel == SwrveLogLevelWarning || logLevel == SwrveLogLevelError) {
        va_list args;
        va_start(args, format);
        NSString *formattedString = [[NSString alloc] initWithFormat:format
                                                           arguments:args];
        NSLog(@"[SwrveSDK Error] %@", formattedString);
        va_end(args);
    }
#endif
}

+ (void)warning:(NSString *)format, ...
{
#ifndef SWRVE_DISABLE_LOGS
    if (logLevel == SwrveLogLevelVerbose || logLevel == SwrveLogLevelWarning) {
        va_list args;
        va_start(args, format);
        NSString *formattedString = [[NSString alloc] initWithFormat:format
                                                           arguments:args];
        NSLog(@"[SwrveSDK Warning] %@", formattedString);
        va_end(args);
    }
#endif
}

+ (void)debug:(NSString *)format, ...
{
#ifndef SWRVE_DISABLE_LOGS
    if (logLevel == SwrveLogLevelVerbose) {
        va_list args;
        va_start(args, format);
        NSString *formattedString = [[NSString alloc] initWithFormat:format
                                                           arguments:args];
        NSLog(@"[SwrveSDK Debug] %@", formattedString);
        va_end(args);
    }
#endif
}

// Swift compatible logs

+ (void)logError:(NSString *)message {
#ifndef SWRVE_DISABLE_LOGS
    if (logLevel == SwrveLogLevelVerbose || logLevel == SwrveLogLevelWarning || logLevel == SwrveLogLevelError) {
        NSLog(@"[SwrveSDK Error] %@", message);
    }
#endif
}

+ (void)logWarning:(NSString *)message {
#ifndef SWRVE_DISABLE_LOGS
    if (logLevel == SwrveLogLevelVerbose || logLevel == SwrveLogLevelWarning) {
        NSLog(@"[SwrveSDK Warning] %@", message);
    }
#endif
}

+ (void)logDebug:(NSString *)message {
#ifndef SWRVE_DISABLE_LOGS
    if (logLevel == SwrveLogLevelVerbose) {
        NSLog(@"[SwrveSDK Debug] %@", message);
    }
#endif
}

@end
