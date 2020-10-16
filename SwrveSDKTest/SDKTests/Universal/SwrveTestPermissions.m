#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SwrveSDK.h"
#import "SwrveTestHelper.h"
#import <AppTrackingTransparency/ATTrackingManager.h>

@interface Swrve ()
- (void)mergeWithCurrentDeviceInfo:(NSDictionary *)attributes;
@end

@interface SwrveTestPermissions : XCTestCase <SwrvePermissionsDelegate>

@end

@implementation SwrveTestPermissions

- (void)testAdTrackingPermission {
    if (@available(iOS 14,tvOS 14, *)) {
        id mockManager = OCMClassMock([ATTrackingManager class]);
        OCMStub(ClassMethod([mockManager requestTrackingAuthorizationWithCompletionHandler:([OCMArg invokeBlockWithArgs:@3, nil])]));
        OCMStub(ClassMethod([mockManager trackingAuthorizationStatus])).andReturn(ATTrackingManagerAuthorizationStatusAuthorized);
        id swrveMock = [SwrveTestHelper swrveMockWithMockedRestClient];
        SwrveConfig *config = [SwrveConfig new];
        config.permissionsDelegate = self;
        (void)[swrveMock initWithAppID:572 apiKey:@"SomeAPIKey" config:config];
        
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            
        }];

        NSDictionary *deviceInfo = [swrveMock deviceInfo];
        XCTAssertEqualObjects(deviceInfo[@"swrve.permission.ios.ad_tracking"], @"authorized");
    }
}

- (SwrvePermissionState)adTrackingPermissionState {
    if (@available(iOS 14, tvOS 14, *)) {
        ATTrackingManagerAuthorizationStatus authStatus = [ATTrackingManager trackingAuthorizationStatus];
        switch (authStatus) {
            case ATTrackingManagerAuthorizationStatusAuthorized:
                return SwrvePermissionStateAuthorized;
            case ATTrackingManagerAuthorizationStatusDenied:
            case ATTrackingManagerAuthorizationStatusRestricted:
                return SwrvePermissionStateDenied;
            case ATTrackingManagerAuthorizationStatusNotDetermined:
                return SwrvePermissionStateUnknown;
        }
    }
    return SwrvePermissionStateUnsupported;
}


@end
