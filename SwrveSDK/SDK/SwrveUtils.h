#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <sys/time.h>
#import <sys/sysctl.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

@interface SwrveUtils : NSObject

/**
 Get the bounds for the screen
 
 @return Device screen bounds CGRect
*/
+ (CGRect) deviceScreenBounds;

/**
  Get an estimate for the dpi of the device
 
  @return dpi as float
 */
+ (float) estimate_dpi;

/**
  Get the machine namne for the device
 
  @return Machine name string
*/
+ (NSString *) hardwareMachineName;

/**
  CTCarrier info
 
  @return CTCarrier object
*/
+ (CTCarrier*) carrierInfo;

@end
