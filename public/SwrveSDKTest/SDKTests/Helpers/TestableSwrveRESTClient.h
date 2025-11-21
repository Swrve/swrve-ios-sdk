#import "SwrveRESTClient.h"
#import "SwrvePrivateAccess.h"

@interface TestableSwrveRESTClient : SwrveRESTClient

@property (atomic) NSMutableDictionary* savedRequests;
@property (atomic) NSMutableDictionary* savedResponses;
@property (atomic) BOOL failPostRequests;

- (NSArray*) eventRequests;
- (void)initializeRequests;

@end
