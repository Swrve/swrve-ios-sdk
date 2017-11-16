#import "SwrveProfileManager.h"
#import "SwrveCommon.h"
#import "SwrveLocalStorage.h"
#import <sys/time.h>
#import <sys/sysctl.h>
#import <CommonCrypto/CommonHMAC.h>

@interface SwrveProfileManager ()
@property(nonatomic, retain) ImmutableSwrveConfig *config;
@end

@implementation SwrveProfileManager

@synthesize config;
@synthesize userId;
@synthesize isNewUser;

- (id)initWithConfig:(ImmutableSwrveConfig *)swrveConfig {
    self = [super init];
    if (self) {
        self.config = swrveConfig;
        [self initUserId];
    }
    return self;
}

- (BOOL)isLoggedIn {
    return [userId length] > 0;
}

- (void)initUserId {
    NSString *swrveUserID = config.userId;
    if (!swrveUserID) {
        swrveUserID = [SwrveLocalStorage swrveUserId];
        if (!swrveUserID) {
            swrveUserID = [[NSUUID UUID] UUIDString]; // Auto generate user id if necessary
        }
    }
    [SwrveLocalStorage saveSwrveUserId:swrveUserID];
    userId = swrveUserID;
    DebugLog(@"Your user id is:%@", userId);
}

- (NSString*)sessionTokenFromAppId:(long)appID
                            apiKey:(NSString*)apiKey
                            userID:(NSString*)userID
                         startTime:(long)startTime {
    
    NSString * source = [self sourceFromUserID:userID
                                     startTime:startTime
                                        apiKey:apiKey];
    
    NSString * digest = [self md5FromSource:source];
    
    
    NSString * sessionToken = [self sessionTokenFromAppId:appID
                                                   userID:userID
                                                startTime:startTime
                                                   digest:digest];
    return sessionToken;
}

- (NSString*)sourceFromUserID:(NSString*)userID
                    startTime:(long)startTime
                       apiKey:(NSString*)apiKey {
    
    NSString *source = [NSString stringWithFormat:@"%@%ld%@", userID, startTime, apiKey];
    return source;
}

- (NSString*) md5FromSource:(NSString*)source {
    
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

- (NSString*)sessionTokenFromAppId:(long)appID
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
@end
