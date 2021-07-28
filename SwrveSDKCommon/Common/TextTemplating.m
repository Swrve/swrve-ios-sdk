#import "TextTemplating.h"
#import "SwrveCommon.h"

@implementation TextTemplating

+ (NSString *)templatedTextFromString:(NSString *)text withProperties:(NSDictionary *)properties andError:(NSError **)error {

    NSRange searchedRange = NSMakeRange(0, [text length]);
    NSString *pattern = @"\\$\\{([^\\}]*)\\}";
    NSError *regExError = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&regExError];
    if (regExError) {
        [SwrveLogger error:@"Error applying NSRegularExpression pattern for text templating.\nError: %@\npattern: %@", regExError, pattern];
        return nil;
    } else {
        NSArray *matches = [regex matchesInString:text options:0 range:searchedRange];
        NSMutableDictionary *matchedStrings = [NSMutableDictionary new];
        for (NSTextCheckingResult *match in matches) {
            NSString *templateFullValue = [text substringWithRange:[match range]];
            NSString *fallback = [self fallbackFromString:templateFullValue];
            NSString *metaData = [text substringWithRange:[match rangeAtIndex:1]];
            if (fallback != nil) {
                NSRange range = [metaData rangeOfString:@"|fallback=\""];
                metaData = [metaData substringToIndex:range.location]; // remove fallback text
            }

            NSString *metaDataValue = [properties objectForKey:metaData];
            if (metaDataValue && [metaDataValue length] > 0) {
                [matchedStrings setObject:metaDataValue forKey:templateFullValue];
            } else if (fallback != nil) {
                [matchedStrings setObject:fallback forKey:templateFullValue];
            } else {
                *error = [NSError errorWithDomain:@"com.swrve.sdk" code:500 userInfo:@{@"Error reason": @"Missing property for text templating"}];
                return nil;
            }
        }

        for (id matchedString in matchedStrings) {
            text = [text stringByReplacingOccurrencesOfString:matchedString withString:[matchedStrings valueForKey:matchedString]];
        }
    }
    return text;
}

+ (NSString *)fallbackFromString:(NSString *)templateFullValue {
    NSRange searchedRange = NSMakeRange(0, [templateFullValue length]);
    NSString *pattern = @"\\|fallback=\"([^\\}]*)\"\\}";
    NSError *regExError = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&regExError];
    if (regExError) {
        [SwrveLogger error:@"Error applying NSRegularExpression pattern for text templating fallback.\nError: %@\npattern: %@", regExError, pattern];
        return nil;
    } else {
        NSArray *matches = [regex matchesInString:templateFullValue options:0 range:searchedRange];
        for (NSTextCheckingResult *match in matches) {
            NSRange group1 = [match rangeAtIndex:1];
            NSString *fallback = [templateFullValue substringWithRange:group1];
            return fallback;
        }
    }
    return nil;
}

+ (NSString *)templatedTextFromJSONString:(NSString *)json withProperties:(NSDictionary *)properties andError:(NSError **)error {

    NSRange searchedRange = NSMakeRange(0, [json length]);
    NSString *pattern = @"\\$\\{([^\\}]*)\\}";
    NSError *regExError = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&regExError];
    if (regExError) {
        [SwrveLogger error:@"Error applying NSRegularExpression pattern for text templating.\nError: %@\npattern: %@", regExError, pattern];
        return nil;
    } else {
        NSArray *matches = [regex matchesInString:json options:0 range:searchedRange];
        NSMutableDictionary *matchedStrings = [NSMutableDictionary new];
        for (NSTextCheckingResult *match in matches) {
            NSString *templateFullValue = [json substringWithRange:[match range]];
            NSString *fallback = [self fallbackFromJSONString:templateFullValue];
            NSString *metaData = [json substringWithRange:[match rangeAtIndex:1]];
            if (fallback != nil) {
                NSRange range = [metaData rangeOfString:@"|fallback=\\\""];
                metaData = [metaData substringToIndex:range.location]; // remove fallback text
            }

            NSString *metaDataValue = [properties objectForKey:metaData];
            if (metaDataValue && [metaDataValue length] > 0) {
                [matchedStrings setObject:metaDataValue forKey:templateFullValue];
            } else if (fallback != nil) {
                [matchedStrings setObject:fallback forKey:templateFullValue];
            } else {
                *error = [NSError errorWithDomain:@"com.swrve.sdk" code:500 userInfo:@{@"Error reason": @"Missing property for text templating"}];
                return nil;
            }
        }

        for (id matchedString in matchedStrings) {
            json = [json stringByReplacingOccurrencesOfString:matchedString withString:[matchedStrings valueForKey:matchedString]];
        }
    }
    return json;
}

+ (NSString *)fallbackFromJSONString:(NSString *)templateFullValue {
    NSRange searchedRange = NSMakeRange(0, [templateFullValue length]);
    NSString *pattern = @"\\|fallback=\\\\\"([^\\}]*)\\\\\"\\}";
    NSError *regExError = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&regExError];
    if (regExError) {
        [SwrveLogger error:@"Error applying NSRegularExpression pattern for text templating fallback.\nError: %@\npattern: %@", regExError, pattern];
        return nil;
    } else {
        NSArray *matches = [regex matchesInString:templateFullValue options:0 range:searchedRange];
        for (NSTextCheckingResult *match in matches) {
            NSRange group1 = [match rangeAtIndex:1];
            NSString *fallback = [templateFullValue substringWithRange:group1];
            return fallback;
        }
    }
    return nil;
}

@end
