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

/*! Used internally to swizzle AppDelegate methods */
@interface SwrveSwizzleHelper : NSObject
+ (IMP) swizzleMethod:(SEL)selector inObject:(NSObject*)oldObject withImplementationIn:(NSObject*)newObject;
+ (void) deswizzleMethod:(SEL)selector target:(id)target originalImplementation:(IMP)originalImplementation;
@end
