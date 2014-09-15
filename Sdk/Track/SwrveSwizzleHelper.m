#import "SwrveSwizzleHelper.h"
#include <objc/runtime.h>

// Searches the whole hierarchy until the method is implemented
static Method _class_getInstanceMethodSelfOrParents(Class c, SEL selector) {
    Method m = class_getInstanceMethod(c, selector);
    
    while(!m && [c superclass]) {
        c = [c superclass];
        m = class_getInstanceMethod(c, selector);
    }
    
    return m;
}


@implementation SwrveSwizzleHelper

// Replaces the selector on oldObject with the same selector on newObject.
// Returns the implementation of the selector that was replaced, or NULL if
// no replacement was done.
+ (IMP) swizzleMethod:(SEL)selector inObject:(NSObject*)oldObject withImplementationIn:(NSObject*)newObject;
{
    Method originalMethod = _class_getInstanceMethodSelfOrParents([oldObject class], selector);
    IMP oldImplementation = method_getImplementation(originalMethod);
    
    Method newMethod = class_getInstanceMethod([newObject class], selector);
    if (!oldImplementation) {
        class_addMethod([oldObject class], selector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod));
    } else {
        IMP newImplementation = [newObject methodForSelector:selector];
        method_setImplementation(originalMethod, newImplementation);
        return oldImplementation;
    }
    return NULL;
}

+ (void) deswizzleMethod:(SEL)selector target:(id)target originalImplementation:(IMP)originalImplementation
{
    Method originalMethod = class_getInstanceMethod([target class], selector);
    if (originalImplementation == NULL) {
        method_setImplementation(originalMethod, NULL);
    } else {
        method_setImplementation(originalMethod, originalImplementation);
    }
}

@end
