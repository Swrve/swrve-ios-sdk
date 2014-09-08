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

/*! In-app message background image. */
@interface SwrveImage : NSObject

@property (nonatomic, retain) NSString* file;   /*!< Cached path of the image file on disk */
@property (atomic)            CGSize  size;     /*!< Size of the image */
@property (atomic)            CGPoint center;   /*!< Center of the image */

@end
