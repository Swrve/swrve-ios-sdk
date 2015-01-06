//
//  SwrveConversation.h
//  swrvinator
//
//  Created by Oisin Hurley on 06/01/2015.
//  Copyright (c) 2015 Converser. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SwrveConversation : NSObject


@property (nonatomic, weak)              SwrveCampaign* campaign; /*!< Reference to parent campaign */
@property (nonatomic, retain)            NSNumber* conversationID;     /*!< Identifies the message in a campaign */
@property (nonatomic, retain)            NSString* title;          /*!< Name of the message */
@property (nonatomic, retain)            NSString* subtitle;          /*!< Name of the message */
@property (nonatomic, retain)            NSString* notification;          /*!< Name of the message */

/*! Create an in-app conversation from the JSON content.
 *
 * \param json In-app conversation JSON content.
 * \param campaign Parent in-app campaign.
 * \param controller Message controller.
 * \returns Parsed in-app conversation.
 */
+(SwrveConversation*)fromJSON:(NSDictionary*)json forCampaign:(SwrveCampaign*)campaign forController:(SwrveMessageController*)controller;

@end
