#import <Foundation/Foundation.h>
#import "Swrve.h"

/*! Used internally to offer permission request support */
@interface SwrvePermissions : NSObject

+ (NSDictionary*) currentStatus;

+ (BOOL)checkLocationAlways;
+ (void)requestLocationAlways:(Swrve*)swrve;

+ (BOOL)checkPhotoLibrary;
+ (void)requestPhotoLibrary:(Swrve*)swrve;

+ (BOOL)checkCamera;
+ (void)requestCamera:(Swrve*)swrve;

+ (BOOL)checkContacts;
+ (void)requestContacts:(Swrve*)swrve;

+ (BOOL)checkPushNotifications;
+ (void)requestPushNotifications:(Swrve*)swrve;

@end
