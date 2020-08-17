#import "SwrveUser.h"
#import "SwrveRESTClient.h"
#import "SwrveLocalStorage.h"
#import <sys/time.h>
#import <sys/sysctl.h>
#import <CommonCrypto/CommonHMAC.h>

@interface SwrveUser ()

@property (nonatomic, strong) NSString *swrveId;
@property (nonatomic, strong) NSString *externalId;
@property (nonatomic) BOOL verified;

@end

@implementation SwrveUser

@synthesize swrveId = _swrveId;
@synthesize externalId = _externalId;
@synthesize verified = _verified;

- (instancetype)initWithExternalId:(NSString *)externalId
                           swrveId:(NSString *)swrveId
                          verified:(BOOL)verified {
    
    if ((self = [super init])) {
        
        self.externalId = externalId;
        self.swrveId = swrveId;
        self.verified = verified;
    }
    return self;
}

- (NSUInteger)hash {
    return [self.externalId hash];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[SwrveUser class]]) {
        return NO;
    }
    
    SwrveUser *o = (SwrveUser *)object;
    return([self.externalId isEqualToString:o.externalId] && [self.swrveId isEqualToString:o.swrveId]);
}


#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.swrveId = [decoder decodeObjectForKey:@"swrveId"];
    self.externalId = [decoder decodeObjectForKey:@"externalId"];
    self.verified = [decoder decodeBoolForKey:@"verified"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.swrveId forKey:@"swrveId"];
    [encoder encodeObject:self.externalId forKey:@"externalId"];
    [encoder encodeBool:self.verified forKey:@"verified"];
}

#pragma mark - Session Token Helpers

+ (NSString*)sessionTokenFromAppId:(long)appId
                            apiKey:(NSString*)apiKey
                            userId:(NSString*)userId
                         startTime:(long)startTime {
    
    NSString * source = [self sourceFromUserID:userId
                                     startTime:startTime
                                        apiKey:apiKey];
    
    NSString * digest = [self md5FromSource:source];
    
    
    NSString * sessionToken = [self sessionTokenFromAppId:appId
                                                   userID:userId
                                                startTime:startTime
                                                   digest:digest];
    return sessionToken;
}

+ (NSString*)sourceFromUserID:(NSString*)userID
                    startTime:(long)startTime
                       apiKey:(NSString*)apiKey {
    
    NSString *source = [NSString stringWithFormat:@"%@%ld%@", userID, startTime, apiKey];
    return source;
}

+ (NSString*) md5FromSource:(NSString*)source {
    
#define C "%02x"
#define CCCC C C C C
#define DIGEST_FORMAT CCCC CCCC CCCC CCCC
    
    NSString* digestFormat = [NSString stringWithFormat:@"%s", DIGEST_FORMAT];
    
    NSData* buffer = [source dataUsingEncoding:NSUTF8StringEncoding];
    
    unsigned char digest[CC_MD5_DIGEST_LENGTH] = {0};
    unsigned int length = (unsigned int)[buffer length];
    CC_MD5_CTX context;
    CC_MD5_Init(&context);
    CC_MD5_Update(&context, [buffer bytes], length);
    CC_MD5_Final(digest, &context);
    
    NSString* result = [NSString stringWithFormat:digestFormat,
                        digest[ 0], digest[ 1], digest[ 2], digest[ 3],
                        digest[ 4], digest[ 5], digest[ 6], digest[ 7],
                        digest[ 8], digest[ 9], digest[10], digest[11],
                        digest[12], digest[13], digest[14], digest[15]];
    return result;
}

+ (NSString*)sessionTokenFromAppId:(long)appID
                            userID:(NSString*)userID
                         startTime:(long)startTime
                            digest:(NSString*)digest {
    
    NSString* sessionToken = [NSString stringWithFormat:@"%ld=%@=%ld=%@",
                              appID,
                              userID,
                              startTime,
                              digest];
    return sessionToken;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end
