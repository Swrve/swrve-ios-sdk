#ifndef SwrveDemoFramework_SwrveConversationResource_h
#define SwrveDemoFramework_SwrveConversationResource_h

@interface SwrveConversationResource : NSObject

+(UIImage *) imageFromBundleNamed:(NSString *)imageName;
+(UIImage*) searchPaths:(NSArray*)paths forImageNamed:(NSString*)name withPrefix:(NSString*)prefix;
+(UIImage*) backgroundImage;

@end

#endif
