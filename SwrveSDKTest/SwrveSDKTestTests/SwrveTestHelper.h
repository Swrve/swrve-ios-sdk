#import <Foundation/Foundation.h>
#import <objc/NSObject.h>

@interface SwrveTestHelper : NSObject

+ (void)setUp;
+ (void)tearDown;
+ (void)destroySharedInstance;
+ (NSString *)fileContentsFromURL:(NSURL *)url;
+ (NSMutableArray *)stringArrayFromCachedContent:(NSString *)content;
+ (NSMutableArray *)dicArrayFromCachedFile:(NSURL *)file;


@end
