#include <UIKit/UIKit.h>
#import "SwrveInterfaceOrientation.h"
#import "SwrveInAppMessageConfig.h"

@class SwrveMessage;
@class SwrveMessageController;

/*! In-app message format */
@interface SwrveMessageFormat : NSObject

@property (retain, nonatomic) NSArray* buttons;                             /*!< An array of SwrveButton objects */
@property (retain, nonatomic) NSArray* images;                              /*!< An array of SwrveImage objects */
@property (retain, nonatomic) NSArray* text;                                /*!< Currently not used */
@property (retain, nonatomic) NSString* name;                               /*!< The name of the format */
@property (retain, nonatomic) NSString* language;                           /*!< The language of the format */
@property (nonatomic, retain) UIColor* backgroundColor;                     /*!< Background color of the format */
@property (nonatomic, retain) SwrveInAppMessageConfig* inAppConfig;         /*!< Configuration for personalised text, colors and styling */
@property (nonatomic)         SwrveInterfaceOrientation orientation;        /*!< The orientation of the format */
@property (nonatomic)         float scale;                                  /*!< The scale that the format should render */
@property (atomic)            CGSize size;                                  /*!< The size of the format */

/*! Create an in-app message format from the JSON content.
 *
 * \param json In-app message format JSON content.
 * \param controller Message controller.
 * \param message Parent in-app message.
 * \returns Parsed in-app message format.
 */
-(id)initFromJson:(NSDictionary*)json forController:(SwrveMessageController*)controller forMessage:(SwrveMessage*)message;

/*! Create a view to display this format.
 *
 * \param view Parent view.
 * \param delegate View delegate.
 * \param size Expected size of the view.
 * \returns View representing this in-app message format.
 */
-(UIView*)createViewToFit:(UIView*)view
          thatDelegatesTo:(UIViewController*)delegate
                 withSize:(CGSize)size
                  rotated:(BOOL)rotated;

/*! Create a view to display this format.
 *
 * \param view Parent view.
 * \param delegate View delegate.
 * \param sizeParent Expected size of the view.
 * \returns View representing this in-app message format.
 */
-(UIView*)createViewToFit:(UIView*)view
          thatDelegatesTo:(UIViewController*)delegate
                 withSize:(CGSize)sizeParent;

/*! Create a view to display this format (with personalisation)
 *
 * \param view Parent view.
 * \param delegate View delegate.
 * \param size Expected size of the view.
 * \param personalisation Dictionary of personalisation for text type items
 * \returns View representing this in-app message format.
 */
-(UIView*)createViewToFit:(UIView*)view
          thatDelegatesTo:(UIViewController*)delegate
                 withSize:(CGSize)size
                  rotated:(BOOL)rotated
          personalisation:(NSDictionary *)personalisation;

/*! Create a view to display this format (with personalisation)
 *
 * \param view Parent view.
 * \param delegate View delegate.
 * \param sizeParent Expected size of the view.
 * \param personalisation Dictionary of personalisation for text type items
 * \returns View representing this in-app message format.
 */
-(UIView*)createViewToFit:(UIView*)view
          thatDelegatesTo:(UIViewController*)delegate
                 withSize:(CGSize)sizeParent
          personalisation:(NSDictionary *)personalisation;

@end
