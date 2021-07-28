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
@synthesize trackingState = _trackingState;
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
        _trackingState = [SwrveLocalStorage trackingState];
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
            NSData *data = [self archiveSwrveUserArray:mArray];
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
    NSData *data = [self archiveSwrveUserArray:mArray];
    [SwrveLocalStorage saveSwrveUsers:data];
 }

- (void)removeSwrveUserWithId:(NSString *)aUserId {
    if (aUserId == nil) return;
    NSArray *swrveUsers = [self swrveUsers];
    NSMutableArray * mArray = [[NSMutableArray alloc]initWithArray:swrveUsers];
    for (SwrveUser *swrveUser in [mArray copy]) {
        if ([swrveUser.swrveId isEqualToString:aUserId] || [swrveUser.externalId isEqualToString:aUserId] ) {
            [mArray removeObject:swrveUser];
            NSData *data = [self archiveSwrveUserArray:mArray];
            [SwrveLocalStorage saveSwrveUsers:data];
            return;
        }
    }
}

- (NSData *)archiveSwrveUserArray:(NSArray *)array{
    NSData *data  = nil;
    if (@available(ios 11.0,tvos 11.0, *)) {
        NSError *error = nil;
        data = [NSKeyedArchiver archivedDataWithRootObject:array requiringSecureCoding:false error:&error];
        if (error) {
            [SwrveLogger error:@"Failed to archive swrve user: %@", [error localizedDescription]];
        }
    } else {
        // Fallback on earlier versions
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        data = [NSKeyedArchiver archivedDataWithRootObject:array];
        #pragma clang diagnostic pop
    }
    return data;
}

- (NSArray *)swrveUsers {
    NSData *encodedObject = [SwrveLocalStorage swrveUsers];
    NSArray *swrveUsers = nil;
    if (@available(ios 11.0,tvos 11.0, *)) {
        NSError *error = nil;
        NSSet *classes = [NSSet setWithArray:@[[NSArray class],[SwrveUser class]]];
        swrveUsers = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:encodedObject error:&error];
        if (error) {
            [SwrveLogger error:@"Failed to un archive swrve user: %@", [error localizedDescription]];
        }
    } else {
        // Fallback on earlier versions
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        swrveUsers = [NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];
        #pragma clang diagnostic pop
    }
    return swrveUsers;
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

- (enum SwrveTrackingState)trackingState {
    return _trackingState;
}

- (void)setTrackingState:(enum SwrveTrackingState)trackingState {
    _trackingState = trackingState;
    if (trackingState == EVENT_SENDING_PAUSED) {
        return; // never save EVENT_SENDING_PAUSED tracking state
    } else {
        [SwrveLocalStorage saveTrackingState:trackingState];
        [SwrveLogger debug:@"SwrveSDK: trackingState is set to: %ld", trackingState];
    }
}

@end
