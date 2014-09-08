/*
 * SWRVE CONFIDENTIAL
 *
 * (c) Copyright 2010-2014 Swrve New Media, Inc. and its licensors.
 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is and remains the property of Swrve
 * New Media, Inc or its licensors.  The intellectual property and technical
 * concepts contained herein are proprietary to Swrve New Media, Inc. or its
 * licensors and are protected by trade secret and/or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from Swrve.
 */

#import "SwrveInterfaceOrientation.h"

@class SwrveMessage;
@class SwrveMessageController;

/*! In-app message format */
@interface SwrveMessageFormat : NSObject

@property (retain, nonatomic) NSArray* buttons;                        /*!< An array of SwrveButton objects */
@property (retain, nonatomic) NSArray* images;                         /*!< An array of SwrveImage objects */
@property (retain, nonatomic) NSArray* text;                           /*!< Currently not used */
@property (retain, nonatomic) NSString* name;                          /*!< The name of the format */
@property (retain, nonatomic) NSString* language;                      /*!< The language of the format */
@property (nonatomic)         SwrveInterfaceOrientation orientation;   /*!< The orientation of the format */
@property (nonatomic)         float scale;                             /*!< The scale that the format should render */
@property (atomic)            CGSize size;                             /*!< The size of the format */

/*! Create an in-app message format from the JSON content.
 *
 * \param json In-app message format JSON content.
 * \param controller Message controller.
 * \param campaign Parent in-app message.
 * \returns Parsed in-app message format.
 */
-(id)initFromJson:(NSDictionary*)json forController:(SwrveMessageController*)controller forMessage:(SwrveMessage*)message;

/*! Create a view to display this format.
 *
 * \param orientation Device orientation.
 * \param view Parent view.
 * \param delegate View delegate.
 * \param size Expected size of the view.
 * \returns View representing this in-app message format.
 */
-(UIView*)createViewWithOrientation:(UIInterfaceOrientation)orientation
                              toFit:(UIView*)view
                    thatDelegatesTo:(UIViewController*)delegate
                           withSize:(CGSize)size
                            rotated:(BOOL) rotated;

@end

