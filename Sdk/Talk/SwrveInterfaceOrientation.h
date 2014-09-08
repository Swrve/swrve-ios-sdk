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

/*! Supported orientations for in-app messages. */
typedef enum {
    /*! App supports landscape only. */
    SWRVE_ORIENTATION_LANDSCAPE = 0x1,
    
    /*! App supports portrait only. */
    SWRVE_ORIENTATION_PORTRAIT  = 0x2,
    
    /*! App supports both landscape and portrait. */
    SWRVE_ORIENTATION_BOTH      = 0x3
} SwrveInterfaceOrientation;
