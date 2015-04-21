#import <Foundation/Foundation.h>

/*! Used internally to offer permission request support */
@interface SwrvePermissions : NSObject

+ (BOOL)checkLocation;
+ (void)requestLocation;

+ (BOOL)checkPhotoLibrary;
+ (void)requestPhotoLibrary;

+ (BOOL)checkCamera;
+ (void)requestCamera;

+ (BOOL)checkContacts;
+ (void)requestContacts;

+ (BOOL)checkPushNotifications;
+ (void)requestPushNotifications;

@end
