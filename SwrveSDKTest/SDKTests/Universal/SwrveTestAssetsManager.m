#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SwrveTestHelper.h"
#import "SwrveAssetsManager.h"
#import "SwrveUtils.h"

@interface SwrveTestAssetsManager : XCTestCase

@end

@implementation SwrveTestAssetsManager

- (void)setUp {
    [super setUp];
    [SwrveTestHelper setUp];
}

- (void)tearDown {
    [SwrveTestHelper tearDown];
    [super tearDown];
}

- (void)testFilesAlreadyDownloaded {
    
    NSString *asset1 = [SwrveUtils sha1:[@"Asset1" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    NSString *asset2 = [SwrveUtils sha1:[@"Asset2" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    NSString *asset3 = [SwrveUtils sha1:[@"Asset3" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    
    //set asset data to be already there
    [SwrveTestHelper createDummyAssets:@[asset1, asset2, asset3]];
    
    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
    id mockRestClient = OCMPartialMock(restClient);
    id mockResponse = OCMClassMock([NSHTTPURLResponse class]);
    OCMExpect([mockResponse statusCode]).andReturn(200);
    NSData *mockData = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];

    OCMStub([mockRestClient sendHttpGETRequest:OCMOCK_ANY
                          completionHandler:([OCMArg invokeBlockWithArgs:mockResponse, mockData, [NSNull null], nil])]);

    NSMutableDictionary *asset1QueueItem = [SwrveAssetsManager assetQItemWith:asset1 andDigest:asset1 andIsExternal:NO andIsImage:YES];
    NSMutableDictionary *asset2QueueItem = [SwrveAssetsManager assetQItemWith:asset2 andDigest:asset2 andIsExternal:NO andIsImage:YES];
    NSMutableDictionary *asset3QueueItem = [SwrveAssetsManager assetQItemWith:asset3 andDigest:asset3 andIsExternal:NO andIsImage:YES];
    NSMutableSet *testAssets = [[NSMutableSet alloc] initWithArray:@[asset1QueueItem, asset2QueueItem, asset3QueueItem]];
    
    SwrveAssetsManager *assetsManager = [[SwrveAssetsManager alloc] initWithRestClient:mockRestClient andCacheFolder:[SwrveTestHelper campaignCacheDirectory]];
    
    // we must set these or it won't progress to the point where sendHttpGETRequest could be called
    assetsManager.cdnImages = @"https://swrve.test.com/";
    assetsManager.cdnFonts = @"https://swrve.test.com/";

    [assetsManager downloadAssets:testAssets withCompletionHandler:^{
        // no downloads should have occured
        OCMVerify(never(), [mockRestClient sendHttpGETRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
    }];
}

- (void)testExternallySourcedFilesAlreadyDownloaded {
    NSString *asset1 = [SwrveUtils sha1:[@"Asset1" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    NSString *asset2 = [SwrveUtils sha1:[@"Asset2" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    NSString *externalAsset = [SwrveUtils sha1:[@"https://external.swrve.asset/hello.png" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    
    //set asset data to be already there
    [SwrveTestHelper createDummyAssets:@[asset1, asset2, externalAsset]];
    
    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
    id mockRestClient = OCMPartialMock(restClient);
    id mockResponse = OCMClassMock([NSHTTPURLResponse class]);
    OCMExpect([mockResponse statusCode]).andReturn(200);
    NSData *mockData = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];

    OCMStub([mockRestClient sendHttpGETRequest:OCMOCK_ANY
                          completionHandler:([OCMArg invokeBlockWithArgs:mockResponse, mockData, [NSNull null], nil])]);

    NSMutableDictionary *asset1QueueItem = [SwrveAssetsManager assetQItemWith:asset1 andDigest:asset1 andIsExternal:NO andIsImage:YES];
    NSMutableDictionary *asset2QueueItem = [SwrveAssetsManager assetQItemWith:asset2 andDigest:asset2 andIsExternal:NO andIsImage:YES];
    NSMutableDictionary *asset3QueueItem = [SwrveAssetsManager assetQItemWith:externalAsset andDigest:@"https://external.swrve.asset/hello.png" andIsExternal:YES andIsImage:YES];
    NSMutableSet *testAssets = [[NSMutableSet alloc] initWithArray:@[asset1QueueItem, asset2QueueItem, asset3QueueItem]];
    
    SwrveAssetsManager *assetsManager = [[SwrveAssetsManager alloc] initWithRestClient:mockRestClient andCacheFolder:[SwrveTestHelper campaignCacheDirectory]];
    
    // we must set these or it won't progress to the point where sendHttpGETRequest could be called
    assetsManager.cdnImages = @"https://swrve.test.com/";
    assetsManager.cdnFonts = @"https://swrve.test.com/";

    [assetsManager downloadAssets:testAssets withCompletionHandler:^{
        // no downloads should have occured
        OCMVerify(never(), [mockRestClient sendHttpGETRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
    }];
}

- (void)testSomeFilesAlreadyDownloaded {
    NSString *asset1 = [SwrveUtils sha1:[@"Asset1" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    NSString *asset2 = [SwrveUtils sha1:[@"Asset2" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    NSString *externalAsset = [SwrveUtils sha1:[@"https://external.swrve.asset/hello.png" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    
    // Do not add the externalAsset to the cache
    [SwrveTestHelper createDummyAssets:@[asset1, asset2]];
    
    // Mock RESTClient to do nothing and return 200
    SwrveRESTClient *restClient = [[SwrveRESTClient alloc] initWithTimeoutInterval:60];
    id mockRestClient = OCMPartialMock(restClient);
    id mockResponse = OCMClassMock([NSHTTPURLResponse class]);
    OCMExpect([mockResponse statusCode]).andReturn(200);
    NSData *mockData = [@"image" dataUsingEncoding:NSUTF8StringEncoding];
    OCMStub([mockRestClient sendHttpGETRequest:OCMOCK_ANY
                          completionHandler:([OCMArg invokeBlockWithArgs:mockResponse, mockData, [NSNull null], nil])]);
    
    NSMutableDictionary *asset1QueueItem = [SwrveAssetsManager assetQItemWith:asset1 andDigest:asset1 andIsExternal:NO andIsImage:YES];
    NSMutableDictionary *asset2QueueItem = [SwrveAssetsManager assetQItemWith:asset2 andDigest:asset2 andIsExternal:NO andIsImage:YES];
    NSMutableDictionary *asset3QueueItem = [SwrveAssetsManager assetQItemWith:externalAsset andDigest:@"https://external.swrve.asset/hello.png" andIsExternal:YES andIsImage:YES];
    NSMutableSet *testAssets = [[NSMutableSet alloc] initWithArray:@[asset1QueueItem, asset2QueueItem, asset3QueueItem]];
    
    SwrveAssetsManager *assetsManager = [[SwrveAssetsManager alloc] initWithRestClient:mockRestClient andCacheFolder:[SwrveTestHelper campaignCacheDirectory]];
    
    // we must set these or it won't progress to the point where sendHttpGETRequest could be called
    assetsManager.cdnImages = @"https://swrve.test.com/";
    assetsManager.cdnFonts = @"https://swrve.test.com/";
    
    [assetsManager downloadAssets:testAssets withCompletionHandler:^{
        // download should only have been called once
        OCMVerify(times(1), [mockRestClient sendHttpGETRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY]);
        
        // there should be all three items in the cache now
        NSSet *assetsDownloaded = assetsManager.assetsOnDisk;
        XCTAssertEqual([assetsDownloaded count], 3);
        XCTAssertTrue([assetsDownloaded containsObject:asset1]);
        XCTAssertTrue([assetsDownloaded containsObject:asset2]);
        XCTAssertTrue([assetsDownloaded containsObject:externalAsset]);
    }];
    
}


@end
