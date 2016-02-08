//
//  SwrveCommon.h
//  SwrveCommon
//
//  Created by seaders on 04/02/2016.
//  Copyright © 2016 Swrve. All rights reserved.
//

#import <UIKit/UIKit.h>

/*! Swrve SDK main class. */
@protocol ISwrveCommon <NSObject>

-(NSData*) getCampaignData:(int)category;
-(void) sendQueuedEvents;
-(int) eventInternal:(NSString*)eventName payload:(NSDictionary*)eventPayload triggerCallback:(bool)triggerCallback;
-(int) userUpdate:(NSDictionary*)attributes;
-(void) setLocationVersion:(NSString*)locationVersion;
+ (BOOL)processPermissionRequest:(NSString*)action;

@end

@interface SwrveCommon : NSObject

+ (id<ISwrveCommon>) getSwrveCommon;
+ (void) setSwrveCommon:(id<ISwrveCommon>)swrveCommon;

@end

#ifndef SWRVE_DISABLE_LOGS
#define DebugLog( s, ... ) NSLog(s, ##__VA_ARGS__)
#else
#define DebugLog( s, ... )
#endif

/*! Result codes for Swrve methods. */
enum
{
    SWRVE_SUCCESS = 0,  /*!< Method executed successfully. */
    SWRVE_FAILURE = -1  /*!< Method did not execute successfully. */
};

enum
{
    SWRVE_CAMPAIGN_LOCATION = 0
};

#ifndef DEBUG

#define DEBUG

#endif
