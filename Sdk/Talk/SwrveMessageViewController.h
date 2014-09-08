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

#import "SwrveMessage.h"

@class SwrveMessage;

/*! Manage a in-app message on screen */
@interface SwrveMessageViewController : UIViewController

@property (nonatomic, retain) SwrveMessage*      message;   /*!< Message to render. */
@property (nonatomic, copy)   SwrveMessageResult block;     /*!< Custom code to execute when a button is tapped or a message is dismissed by a user. */

/*! Called by the view when a button is pressed */
-(IBAction)onButtonPressed:(id)sender;

@end
