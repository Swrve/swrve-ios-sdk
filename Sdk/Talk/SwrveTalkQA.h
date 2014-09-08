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

#import "Swrve.h"

/*! Used internally to offer QA user functionality */
@interface SwrveTalkQA : NSObject

    @property (atomic) BOOL resetDevice;
    @property (atomic) BOOL logging;

    -(id)initWithJSON:(NSDictionary*)qaJson withAnalyticsSDK:(Swrve*)sdk;
    -(void)talkSession:(NSDictionary*)campaignsDownloaded;
    -(void)triggerFailure:(NSString*)event withReason:(NSString*)globalReason;
    -(void)trigger:(NSString*)event withMessage:(SwrveMessage*)messageShown withReason:(NSDictionary*)campaignReasons withMessages:(NSDictionary*)campaignMessages;
    -(void)updateDeviceInfo;
    -(void)pushNotification:(NSDictionary*)notification;

@end
