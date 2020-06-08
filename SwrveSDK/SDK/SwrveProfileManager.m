#import "SwrveProfileManager.h"
#if __has_include(<SwrveSDKCommon/SwrveLocalStorage.h>)
#import <SwrveSDKCommon/SwrveLocalStorage.h>
#import <SwrveSDKCommon/SwrveUser.h>
#import <SwrveSDKCommon/SwrveRESTClient.h>
#else
#import "SwrveLocalStorage.h"
#import "SwrveUser.h"
#import "SwrveRESTClient.h"
#endif
#import "Swrve.h"
#import <sys/time.h>

@interface SwrveUser()

@property (nonatomic, strong) NSString *swrveId;
@property (nonatomic, strong) NSString *externalId;
@property (nonatomic) BOOL verified;

@end

@interface SwrveProfileManager()

@property (strong, nonatomic) SwrveRESTClient *restClient;
@property (strong, nonatomic) NSURL *identityURL;
@property (strong, nonatomic) NSString *deviceUUID;

@property (nonatomic) long appId;
@property (strong, nonatomic) NSString *apiKey;

- (void)switchUser:(NSString*)userId;

@end

@implementation SwrveProfileManager

@synthesize userId = _userId;
@synthesize sessionToken = _sessionToken;
@synthesize isNewUser;
@synthesize restClient = _restClient;
@synthesize identityURL = _identityURL;
@synthesize deviceUUID = _deviceUUID;
@synthesize appId;
@synthesize apiKey;

#pragma mark - Init Setup

- (instancetype)initWithIdentityUrl:(NSString *)identityBaseUrl deviceUUID:(NSString *)deviceUUID restClient:(SwrveRESTClient *)restClient appId:(long)_appId apiKey:(NSString*)_apiKey {
    self = [super init];
    if (self) {
        self.restClient = restClient;
        self.identityURL = [NSURL URLWithString:identityBaseUrl];
        self.deviceUUID = deviceUUID;
        NSString* initialUser = [SwrveLocalStorage swrveUserId];
        if ((initialUser == nil) || [initialUser isEqualToString:@""]) {
            initialUser = [[NSUUID UUID] UUIDString];
        }
        self.appId = _appId;
        self.apiKey = _apiKey;

        [self switchUser:initialUser];
    }
    return self;
}

- (void)switchUser:(NSString*)userId {
    _userId = userId;
    [self createSessionToken];
}

- (void)persistUser {
    @synchronized (self) {
        [SwrveLocalStorage saveSwrveUserId:_userId];
    }
}

- (void)createSessionToken {
    // Get the time since the epoch in seconds
    struct timeval time;
    gettimeofday(&time, NULL);
    const long startTime = time.tv_sec;

    _sessionToken = [SwrveUser sessionTokenFromAppId:self.appId
                                             apiKey:self.apiKey
                                             userId:_userId
                                          startTime:startTime];
}


#pragma mark - Identify API

- (void)identify:(NSString *)externalUserId swrveUserId:(NSString *)swrveUserId
                                              onSuccess:(void (^)(NSString *status, NSString *swrveUserId))onSuccess
                                                onError:(void (^)(NSInteger httpCode, NSString *errorMessage))onError {

    NSDictionary *json = @{ @"swrve_id" : swrveUserId,
                             @"external_user_id" : externalUserId,
                             @"unique_device_id" : self.deviceUUID,
                             @"api_key" : [SwrveCommon sharedInstance].apiKey};

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];

    NSURL *identifyUrl = [self.identityURL URLByAppendingPathComponent:@"/identify"];

    [self.restClient sendHttpPOSTRequest:identifyUrl
                                jsonData:jsonData
                       completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {

                           NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                           NSInteger statusCode = 0;
                           if ([httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
                               statusCode = httpResponse.statusCode;
                           }

                           if (error != nil) {
                               onError(statusCode,error.localizedDescription);
                               return;
                           }

                           //success
                           if (statusCode >= 200 && statusCode < 300) {
                               NSString *verifiedSwrveUserId = nil;
                               NSString *status = nil;
                               if (data != nil) {
                                   NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                                   verifiedSwrveUserId = [responseDict objectForKey:@"swrve_id"];
                                   status = [responseDict objectForKey:@"status"];
                               }
                               onSuccess(status,verifiedSwrveUserId);
                               return;
                           }

                           //error either server / client / redirect
                           NSString *message = nil;
                           if (data != nil) {
                               NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                               // swrve error message
                               message = [responseDict objectForKey:@"message"];
                           }

                           if (message == nil) { message = @"An error occured";}
                           onError(statusCode,message);

     }];
}

#pragma mark - SwrveUser Helpers

- (void)updateSwrveUserWithId:(NSString *)swrveUserId externalUserId:(NSString *)externalUserId {
    if (swrveUserId == nil) return;
    NSArray *swrveUsers = [self swrveUsers];
    NSMutableArray * mArray = [[NSMutableArray alloc]initWithArray:swrveUsers];
    for (SwrveUser *swrveUser in mArray) {
        if ([swrveUser.swrveId isEqualToString:swrveUserId] || [swrveUser.externalId isEqualToString:externalUserId] ) {
            swrveUser.verified = true;
            swrveUser.swrveId = swrveUserId;
            NSError *error = nil;
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:mArray requiringSecureCoding:NO error:&error];
            NSAssert(!error, error.localizedDescription);
            [SwrveLocalStorage saveSwrveUsers:data];
            return;
        }
    }
}

- (void)saveSwrveUser:(SwrveUser *)swrveUser {
    if (swrveUser == nil) return;
    NSArray *swrveUsers = [self swrveUsers];
    NSMutableArray * mArray = [[NSMutableArray alloc]initWithArray:swrveUsers];
    if (![mArray containsObject:swrveUser]) {
        [mArray addObject:swrveUser];
    }
    NSError *error = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:mArray requiringSecureCoding:NO error:&error];
    NSAssert(!error, error.localizedDescription);
    [SwrveLocalStorage saveSwrveUsers:data];
 }

- (void)removeSwrveUserWithId:(NSString *)aUserId {
    if (aUserId == nil) return;
    NSArray *swrveUsers = [self swrveUsers];
    NSMutableArray * mArray = [[NSMutableArray alloc]initWithArray:swrveUsers];
    NSError *error = nil;
    for (SwrveUser *swrveUser in [mArray copy]) {
        if ([swrveUser.swrveId isEqualToString:aUserId] || [swrveUser.externalId isEqualToString:aUserId] ) {
            [mArray removeObject:swrveUser];
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:mArray requiringSecureCoding:NO error:&error];
            [SwrveLocalStorage saveSwrveUsers:data];
            NSAssert(!error, error.localizedDescription);
            return;
        }
    }
}

- (NSArray *)swrveUsers {
    NSData *encodedObject = [SwrveLocalStorage swrveUsers];
    NSError *error = nil;
    return [NSKeyedUnarchiver unarchivedObjectOfClass:NSArray.class fromData:encodedObject error:&error];
    NSAssert(!error, error.localizedDescription);
}

- (SwrveUser *)swrveUserWithId:(NSString *)aUserId {
    if (aUserId == nil) return nil;
    NSArray *swrveUsers = [self swrveUsers];
    for (SwrveUser *swrveUser in swrveUsers) {
        if ([swrveUser.externalId isEqualToString:aUserId]) {
            return swrveUser;
        }
        if ([swrveUser.swrveId isEqualToString:aUserId]) {
            return swrveUser;
        }
    }
    return nil;
}

@end
