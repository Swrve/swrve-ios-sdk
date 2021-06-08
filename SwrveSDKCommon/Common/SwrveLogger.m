#import "SwrveLogger.h"

@implementation SwrveLogger : NSObject

#if DEBUG
static SwrveLogLevel logLevel = VERBOSE;
#else
static SwrveLogLevel logLevel = WARNING;
#endif

+ (void)setLogLevel:(SwrveLogLevel)level
{
    logLevel = level;
}

+ (void)error:(NSString *)format, ...
{
#ifndef SWRVE_DISABLE_LOGS
    if (logLevel == VERBOSE || logLevel == WARNING || logLevel == ERROR) {
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
    if (logLevel == VERBOSE || logLevel == WARNING) {
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
    if (logLevel == VERBOSE) {
        va_list args;
        va_start(args, format);
        NSString *formattedString = [[NSString alloc] initWithFormat:format
                                                           arguments:args];
        NSLog(@"[SwrveSDK Debug] %@", formattedString);
        va_end(args);
    }
#endif
}

@end
