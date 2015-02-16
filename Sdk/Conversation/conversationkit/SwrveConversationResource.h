//
//  SwrveConversationResource.h
//  SwrveDemoFramework
//
//  Created by Oisin Hurley on 16/02/2015.
//  Copyright (c) 2015 Swrve. All rights reserved.
//

#ifndef SwrveDemoFramework_SwrveConversationResource_h
#define SwrveDemoFramework_SwrveConversationResource_h

@interface SwrveConversationResource : NSObject

+(UIImage *) imageFromBundleNamed:(NSString *)imageName;
+(UIImage*) searchPaths:(NSArray*)paths forImageNamed:(NSString*)name withPrefix:(NSString*)prefix;
+(UIImage*) backgroundImage;

@end

#endif
