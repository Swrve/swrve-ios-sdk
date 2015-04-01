#import "DemoResourceManager.h"

@implementation DemoResource

@synthesize attributes;

- (id) init:(NSString *) _uniqueId
{
    self = [super init];
    if (self)
    {
        attributes = [[NSMutableDictionary alloc] init];
        [attributes setObject:_uniqueId forKey:@"uid"];
    }
    return self;
}

- (id) init:(NSString *) _uniqueId withAttributes:(NSDictionary *) _attributes
{
    self = [super init];
    if (self)
    {
        attributes = [[NSMutableDictionary alloc] initWithDictionary:_attributes];
        [attributes setObject:_uniqueId forKey:@"uid"];   
    }
    return self;
}

- (NSString *) getAttributeAsString:(NSString *) attributeId
{
    return [attributes objectForKey:attributeId];
}

- (int) getAttributeAsInt:(NSString *) attributeId
{
    NSString *attribute = [self getAttributeAsString:attributeId];
    return attribute.intValue;
}

- (void) setAttributeAsInt:(NSString *) attributeId withValue:(int) value
{
    [attributes setObject:[[NSNumber numberWithInt:value] stringValue] forKey:attributeId];
}

- (float) getAttributeAsFloat:(NSString *) attributeId
{
    NSString *attribute = [self getAttributeAsString:attributeId];
    return attribute.floatValue;
}

- (void) setAttributeAsFloat:(NSString *) attributeId withValue:(float) value
{
    [attributes setObject:[[NSNumber numberWithFloat:value] stringValue] forKey:attributeId];
}

- (BOOL) getAttributeAsBool:(NSString *) attributeId
{
    NSString *attribute = [self getAttributeAsString:attributeId];
    if( [attribute caseInsensitiveCompare:@"true"] || [attribute caseInsensitiveCompare:@"yes"] )
    {
        return YES;
    }
    return NO;
}

- (void) setAttributeAsBool:(NSString *) attributeId withValue:(bool) value
{
    if(value)
    {
        [attributes setObject:@"true" forKey:attributeId];
    }
    else
    {
        [attributes setObject:@"false" forKey:attributeId];   
    }
}

- (NSArray *) getAttributeAsArrayOfString:(NSString *) attributeId
{
    NSMutableString* attribute = [[NSMutableString alloc] initWithString:attributeId];
    [attribute appendString:@".count"];
    
    int arraySize = [self getAttributeAsInt:attribute];
    NSMutableArray* array = [[NSMutableArray alloc] initWithCapacity:(unsigned int)arraySize];
    for( int i = 0; i < arraySize; ++i )
    {
        NSMutableString* itemAttribute = [[NSMutableString alloc] initWithString:attributeId];
        [itemAttribute appendFormat:@".%d", i];
        [array addObject: [self getAttributeAsString:itemAttribute]];
    }
    
    return array;
}

@end

static void abTestCallback(Swrve* swrve, void* userData, CFStringRef jsonDiff);

@implementation DemoResourceManager

@synthesize delegate;
@synthesize userIdOverride;

-(id) init;
{
    self = [super init];
    if (self)
    {
        resources = [[NSMutableDictionary alloc] init];
        currentDiff = @"";
    }
    return self;
}

- (void) addResource:(DemoResource *)resource
{
    [resources setObject:resource forKey:[resource.attributes objectForKey:@"uid"] ];
}

- (DemoResource*) lookupResource:(NSString *) uniqueId
{
    return [resources valueForKey:uniqueId];
}

- (void) applyAbTestDifferencesAsync:(Swrve *) swrve
{
    DemoResourceManager * __weak weakSelf = self;
    [swrve getUserResourcesDiff:^(NSDictionary *oldResourcesValues, NSDictionary *newResourcesValues, NSString *resourcesAsJSON) {
        #pragma unused(oldResourcesValues, newResourcesValues)
        abTestCallback(swrve, (__bridge void *)(weakSelf), (__bridge CFStringRef)(resourcesAsJSON));
    }];
}

- (void) applyAllResourcesAsync:(Swrve *) swrve
{
    DemoResourceManager * __weak weakSelf = self;
    [swrve getUserResources:^(NSDictionary *resources, NSString *resourcesAsJSON) {
        #pragma unused(resources)
        downloadResourcesCallback(swrve, (__bridge void *)(weakSelf), (__bridge CFStringRef)(resourcesAsJSON));
    }];
}

- (void) applyAbTestDifferences:(NSString *) jsonDiff
{
    NSString *oldDiffSignature = [DemoResourceManager md5:currentDiff];
    NSString *newDiffSignature = [DemoResourceManager md5:jsonDiff];
    
    // Revert to pervious values if a new diff is served to the user
    if( [oldDiffSignature isEqualToString:newDiffSignature] == NO )
    {
        [self applyAbTestDifferences:currentDiff valueKey:@"old"];
    }
    
    // Remember the differences so they can be reverted when the test is over
    currentDiff = jsonDiff;
    
    // Apply latest diffs
    [self applyAbTestDifferences:currentDiff valueKey:@"new"];
    
    // Notify delegate
    if( self.delegate != nil && [self.delegate respondsToSelector:@selector(applyAbTestDifferencesAsyncIsComplete)])
    {
        [self.delegate applyAbTestDifferencesAsyncIsComplete];
    }
}

- (void) applyAbTestDifferences:(NSString *) jsonDiff valueKey:(NSString*) key
{
    NSData *data = [jsonDiff dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *diffs = [NSJSONSerialization
                                  JSONObjectWithData:data
                                  options:NSJSONReadingMutableContainers
                                  error:nil];
    
    // Apply changes for each resource that is different
    for(NSMutableDictionary *resource in diffs)
    {
        // Look up the local resource
        NSString *resourceId = [resource valueForKey:@"uid"];
        DemoResource* localResource = [self lookupResource:resourceId];
        
        // If the local resource doesn't exist move on to the next
        if( localResource == nil )
        {
            continue;
        }
        
        // Get the overrides Swrve wants to apply
        NSDictionary *newValuesFromABTests = [resource valueForKey:@"diff"];
        
        // Apply each override to the local resource
        for(id attributeId in newValuesFromABTests )
        {
            NSMutableDictionary *localAttributes = [localResource attributes];
            
            // Skip attribute if the local resource doesn't have it
            if( [localAttributes objectForKey:(NSString *)attributeId] == nil )
            {
                continue;
            }
            
            // Apply the value to the local resource
            NSDictionary* newAndOldValue = [newValuesFromABTests valueForKey:attributeId];
            [localAttributes setValue:[newAndOldValue valueForKey:key] forKey:attributeId];
        }
    }
}

- (void) overwriteResources:(NSString *) jsonResources
{
    NSData *data = [jsonResources dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *newResources = [NSJSONSerialization
                                         JSONObjectWithData:data
                                         options:NSJSONReadingMutableContainers
                                         error:nil];
    
    // Apply changes or add new resources
    for(NSMutableDictionary *resource in newResources)
    {
        // Look up the local resource
        NSString *resourceId = [resource valueForKey:@"uid"];
        DemoResource* localResource = [self lookupResource:resourceId];
        
        // If the local resource doesn't exist create a resource for it
        if( localResource == nil )
        {
            localResource = [[DemoResource alloc] init:resourceId];
            [self addResource:localResource];
        }
     
        // Copy attributes from remote to local
        for(NSString* key in resource)
        {            
            // Get the values for both local and remote resources
            NSString* remoteValue = [resource objectForKey:key];
            
            // Add the attribute.  If it's new it will be added, if it already
            // exists it will be overwritten.
            [localResource.attributes setObject:remoteValue forKey:key];
        }
        
        // Remove attributes that are in the local but not in remote
        NSMutableArray* attributesToRemove = [[NSMutableArray alloc] init];
        for(NSString* key in localResource.attributes)
        {
            // Skip uid
            if( [key isEqualToString:@"uid"] )
            {
                continue;
            }
            
            // Get the values for both local and remote resources
            NSString* remoteValue = [resource objectForKey:key];
            NSString* localValue = [localResource.attributes objectForKey:key];
            
            // Remove if not in remote but in local
            if(remoteValue == nil && localValue != nil)
            {
                [attributesToRemove addObject:key];
            }
        }
        [localResource.attributes removeObjectsForKeys:attributesToRemove];
    }
    
    // Remove resources that don't exist in the remote responsitory
    NSMutableArray* resourcesToRemove = [[NSMutableArray alloc] init];
    for(NSString* key in resources)
    {
        DemoResource* resource = [resources objectForKey:key];
        NSString* uid = [resource.attributes objectForKey:@"uid"];
        
        bool exists = false;
        for(NSMutableDictionary *newResource in newResources)
        {
            if( [[newResource valueForKey:@"uid"] isEqualToString:uid] )
            {
                exists = true;
                break;
            }
        }
        
        if( exists == false )
        {
            [resourcesToRemove addObject:uid];
        }
    }
    [resources removeObjectsForKeys:resourcesToRemove];
             
    // Notify delegate
    if( self.delegate != nil && [self.delegate respondsToSelector:@selector(applyAllResourcesAsyncComplete)])
    {
        [self.delegate applyAllResourcesAsyncComplete];
    }

}

static void abTestCallback(Swrve* swrve, void* userData, CFStringRef jsonDiff)
{
    #pragma unused(swrve)
    DemoResourceManager *resourceManager = (__bridge DemoResourceManager *)(userData);
    [resourceManager applyAbTestDifferences:(__bridge NSString *)(jsonDiff)];
}

static void downloadResourcesCallback(Swrve* swrve, void* userData, CFStringRef jsonResources)
{
    #pragma unused(swrve)
    DemoResourceManager *resourceManager = (__bridge DemoResourceManager *)(userData);
    [resourceManager overwriteResources:(__bridge NSString *)(jsonResources)];
}

+ (NSString *) md5:(NSString *) input
{
    const char *cStr = [input UTF8String];
    unsigned char digest[16];
    unsigned int length = (unsigned int)strlen(cStr);
    CC_MD5( cStr, length, digest );
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
    {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return  output;
}

- (long) pushResourceToDashboard:(Swrve*) swrve withApiKey:(NSString* ) apiKey withPersonalKey:(NSString* ) personalKey withResource:(DemoResource *) resource
{
    if(!swrve.talk.isQaUser){
        NSLog(@"You are not a QA user. You can only push resources to the dashboard if you are a QA user.");
        return -1;
    }
    
    // Convert the resources attributes into a dictionary
    NSString* data = @"{";
    for( NSString* attributeKey in resource.attributes )
    {
        if( [attributeKey isEqualToString:@"uid"] == NO )
        {
            data = [NSString stringWithFormat:@"%@ \'%@\' : \'%@\',", data, attributeKey, [resource getAttributeAsString:attributeKey]];
        }
    }
    data = [data substringToIndex:(data.length - 1)];
    data = [data stringByAppendingString:@" }"];
    
    NSString* itemsServerUrl = @"https://dashboard.swrve.com/api/1/items_bulk";
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:itemsServerUrl]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:10];
    
    data = [NSString stringWithFormat:@"api_key=%@&personal_key=%@&data=%@&item=%@", apiKey, personalKey, data, [resource getAttributeAsString:@"uid"]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[data dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSLog(@"Uploading item...");
    NSLog(@"url - %@", itemsServerUrl);
    NSLog(@"data - %@", data);
    
    NSURLResponse* urlResponse = nil;
    NSError* requestError;
    NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&requestError];
    long statusCode = [((NSHTTPURLResponse *)urlResponse) statusCode];
    
    if( statusCode != 200 )
    {
        NSString* responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        (void)responseString;
        NSLog(@"Error - %@", responseString);
    }
    return statusCode;
}

- (long) pushAllResourcesToDashboard:(Swrve*) swrve withApiKey:(NSString* ) apiKey withPersonalKey:(NSString*) personalKey
{
    if(!swrve.talk.isQaUser){
        NSLog(@"You are not a QA user. You can only push resources to the dashboard if you are a QA user.");
        return -1;
    }

    NSString* data = @"{";
    for(NSString* resourceKey in resources)
    {
        DemoResource* resource = [resources objectForKey:resourceKey];
        
        NSString* resourceData = @"{";
        for( NSString* attributeKey in resource.attributes )
        {
            if( [attributeKey isEqualToString:@"uid"] == NO )
            {
                resourceData = [NSString stringWithFormat:@"%@ \"%@\" : \"%@\",", resourceData, attributeKey, [resource getAttributeAsString:attributeKey]];
            }
        }
        resourceData = [resourceData substringToIndex:(resourceData.length - 1)];
        resourceData = [resourceData stringByAppendingString:@" }"];

        data = [NSString stringWithFormat:@"%@ \"%@\" : %@,", data, [resource getAttributeAsString:@"uid"], resourceData];
    }
    data = [data substringToIndex:(data.length - 1)];
    data = [data stringByAppendingString:@" }"];
    
    NSString* itemsServerUrl = @"https://dashboard.swrve.com/api/1/items_bulk";
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:itemsServerUrl]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:10];
    
    data = [NSString stringWithFormat:@"api_key=%@&personal_key=%@&data=%@", apiKey, personalKey, data];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[data dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSLog(@"Uploading item...");
    NSLog(@"url - %@", itemsServerUrl);
    NSLog(@"data - %@", data);
    
    NSError* requestError;
    NSURLResponse* urlResponse = nil;
    NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&requestError];
    long statusCode = [((NSHTTPURLResponse *)urlResponse) statusCode];

    if( statusCode != 200 )
    {
        NSString* responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        NSLog(@"Error - %@", responseString);
    }
    return statusCode;
}

@end


