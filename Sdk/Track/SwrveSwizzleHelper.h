/*! Used internally to swizzle AppDelegate methods */
@interface SwrveSwizzleHelper : NSObject
+ (IMP) swizzleMethod:(SEL)selector inObject:(NSObject*)oldObject withImplementationIn:(NSObject*)newObject;
+ (void) deswizzleMethod:(SEL)selector target:(id)target originalImplementation:(IMP)originalImplementation;
@end
