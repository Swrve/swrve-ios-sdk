#import "SwrveResourceManager.h"

/*
 * SwrveResource: A collection of attributes
 */
@interface SwrveResource() {
    NSDictionary* attributes;
}

@end

@implementation SwrveResource

- (id) init:(NSDictionary*)resourceAttributes
{
    if (self = [super init]) {
        self->attributes = resourceAttributes;
    }
    return self;
}

- (NSArray*) attributeKeys {
    return [self->attributes allKeys];
}

- (NSString*) attributeAsString:(NSString*)attributeId withDefault:(NSString*)defaultValue
{
    NSString* attribute = [self->attributes objectForKey:attributeId];
    if (attribute != nil) {
        return attribute;
    }
    return defaultValue;
}

- (int) attributeAsInt:(NSString*)attributeId withDefault:(int)defaultValue
{
    NSString* attribute = [self->attributes objectForKey:attributeId];
    if (attribute != nil) {
        return attribute.intValue;
    }
    return defaultValue;
}

- (float) attributeAsFloat:(NSString*)attributeId withDefault:(float)defaultValue
{
    NSString* attribute = [self->attributes objectForKey:attributeId];
    if (attribute != nil) {
        return attribute.floatValue;
    }
    return defaultValue;
}

- (BOOL) attributeAsBool:(NSString*)attributeId withDefault:(BOOL)defaultValue
{
    NSString* attribute = [self->attributes objectForKey:attributeId];
    if (attribute != nil) {
        return (([attribute caseInsensitiveCompare:@"true"] == NSOrderedSame) || ([attribute caseInsensitiveCompare:@"yes"] == NSOrderedSame));
    }
    return defaultValue;
}

@end

/*
 * SwrveResource: A collection of attributes
 */
@implementation SwrveABTestDetails

@synthesize id;
@synthesize name;
@synthesize caseIndex;

- (id) initWithId:(NSString*)abTestId name:(NSString*)abTestName caseIndex:(int)abTestCaseIndex
{
    if (self = [super init]) {
        self.id = abTestId;
        self.name = abTestName;
        self.caseIndex = abTestCaseIndex;
    }
    return self;
}

@end

@interface SwrveResourceManager()
{
    NSArray* abTestDetails;
}
@end

@implementation SwrveResourceManager

@synthesize resources;

- (id) init
{
    if (self = [super init]) {
        resources = [NSDictionary new];
        abTestDetails = [NSArray new];
    }
    return self;
}

- (void)setResourcesFromArray:(NSArray*)resourcesArray
{
    NSMutableDictionary *resourcesDict = [NSMutableDictionary new];

    for (NSDictionary* obj in resourcesArray) {
        NSString* itemName = [obj objectForKey:@"uid"];
        [resourcesDict setObject:obj forKey:itemName];
    }

    resources = resourcesDict;
}

- (SwrveResource*) resourceWithId:(NSString*)resourceId
{
    NSDictionary* resourceDict = [[self resources] objectForKey:resourceId];
    if (resourceDict != nil) {
        return [[SwrveResource alloc] init:resourceDict];
    }
    return nil;
}

- (NSString*) attributeAsString:(NSString*)attributeId fromResourceWithId:(NSString*)resourceId withDefault:(NSString*)defaultValue
{
    SwrveResource* resource = [self resourceWithId:resourceId];
    if (resource != nil) {
        return [resource attributeAsString:attributeId withDefault:defaultValue];
    }
    return defaultValue;
}

- (int) attributeAsInt:(NSString*)attributeId fromResourceWithId:(NSString*)resourceId withDefault:(int)defaultValue
{
    SwrveResource* resource = [self resourceWithId:resourceId];
    if (resource != nil) {
        return [resource attributeAsInt:attributeId withDefault:defaultValue];
    }
    return defaultValue;
}

- (float) attributeAsFloat:(NSString*)attributeId fromResourceWithId:(NSString*)resourceId withDefault:(float)defaultValue
{
    SwrveResource* resource = [self resourceWithId:resourceId];
    if (resource != nil) {
        return [resource attributeAsFloat:attributeId withDefault:defaultValue];
    }
    return defaultValue;
}

- (BOOL) attributeAsBool:(NSString*)attributeId fromResourceWithId:(NSString*)resourceId withDefault:(BOOL)defaultValue
{
    SwrveResource* resource = [self resourceWithId:resourceId];
    if (resource != nil) {
        return [resource attributeAsBool:attributeId withDefault:defaultValue];
    }
    return defaultValue;
}

- (void)setABTestDetailsFromDictionary:(NSDictionary*)abTestDetailsListDic
{
    NSMutableArray *abTestDetailsArray = [NSMutableArray new];
    for(id abTestId in abTestDetailsListDic) {
        NSDictionary* abTestDetailsDic = [abTestDetailsListDic objectForKey:abTestId];
        NSString* abTestName = [abTestDetailsDic valueForKey:@"name"];
        NSNumber* abTestCaseIndex = [abTestDetailsDic valueForKey:@"case_index"];

        SwrveABTestDetails* abDetails = [[SwrveABTestDetails alloc] initWithId:(NSString*)abTestId name:abTestName caseIndex:abTestCaseIndex.intValue];
        [abTestDetailsArray addObject:abDetails];
    }
    abTestDetails = abTestDetailsArray;
}

- (NSArray*) abTestDetails {
    return abTestDetails;
}

@end
