#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SwrveInAppMessageConfig : NSObject

/*! in-app background color used for the area behind the message*/
@property (nonatomic, retain) UIColor *backgroundColor;

/*! in-app background color used for all personalised text*/
@property (nonatomic, retain) UIColor *personalisationBackgroundColor;

/*! in-app text color used for all personalised text*/
@property (nonatomic, retain) UIColor *personalisationForegroundColor;

/*! in-app text font used for all personalised text*/
@property (nonatomic, retain) UIFont *personalisationFont;

@end
