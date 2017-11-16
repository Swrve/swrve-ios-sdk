#import "SwrveCommon.h"
#import "SwrveSignatureProtectedFile.h"
#import <CommonCrypto/CommonHMAC.h>
#import "SwrveLocalStorage.h"

@implementation SwrveSignatureProtectedFile

@synthesize filename;
@synthesize signatureFilename;
@synthesize key;
@synthesize signatureErrorDelegate;
    
    
- (id) protectedFileType:(int)fileType
                  userID:(NSString*)userID
            signatureKey:(NSString*)signatureKey
           errorDelegate:(id<SwrveSignatureErrorDelegate>)delegate {
    
    NSString *filePath = nil;
    NSString *signatureFilePath = nil;
    
    switch (fileType)
    
    {
        case SWRVE_LOCATION_FILE:
        
        filePath = [SwrveLocalStorage locationCampaignFilePathForUserId:userID];
        signatureFilePath = [SwrveLocalStorage locationCampaignSignatureFilePathForUserId:userID];
        
        break;
        
        case SWRVE_RESOURCE_FILE:
        
        filePath = [SwrveLocalStorage userResourcesFilePathForUserId:userID];
        signatureFilePath = [SwrveLocalStorage userResourcesSignatureFilePathForUserId:userID];
        
        break;
            
        case SWRVE_RESOURCE_DIFF_FILE:
            
            filePath = [SwrveLocalStorage userResourcesDiffFilePathForUserId:userID];
            signatureFilePath = [SwrveLocalStorage userResourcesDiffSignatureFilePathForUserId:userID];
            
            break;
        
        case SWRVE_CAMPAIGN_FILE:
        
        filePath = [SwrveLocalStorage campaignsFilePathForUserId:userID];
        signatureFilePath = [SwrveLocalStorage campaignsSignatureFilePathForUserId:userID];
        
        break;
        
    }
    
    NSURL* fileURL = [NSURL fileURLWithPath:filePath];
    NSURL* signatureURL = [NSURL fileURLWithPath:signatureFilePath];
    
    return [self initFile:fileURL signatureFilename:signatureURL usingKey:signatureKey signatureErrorDelegate:delegate];
}

- (id) initFile:(NSURL*)file signatureFilename:(NSURL*)signatureFile usingKey:(NSString*)signatureKey
{
    return [self initFile:file signatureFilename:signatureFile usingKey:signatureKey signatureErrorDelegate:nil];
}

- (id) initFile:(NSURL*)file signatureFilename:(NSURL*)signatureFile usingKey:(NSString*)signatureKey signatureErrorDelegate:(id<SwrveSignatureErrorDelegate>)delegate
{
    if (self = [super init]) {
        key = signatureKey;
        self.filename = file;
        self.signatureFilename = signatureFile;
        
        if (delegate == nil) {
            self.signatureErrorDelegate = self;
        } else {
            self.signatureErrorDelegate = delegate;
        }
    }
    return self;
}

- (void) writeToFile:(NSData*)content
{
    if ([content writeToURL:[self filename] atomically:YES]) {
        NSData* signature = [self createHMACWithMD5:content];
        if (![signature writeToURL:[self signatureFilename] atomically:YES]) {
            DebugLog(@"Could not write to signature file: %@", [self signatureFilename]);
        }
    } else {
        DebugLog(@"Could not write to file: %@", [self filename]);
    }
}

- (NSData*) readFromFile
{
    NSData* content = [NSData dataWithContentsOfURL:[self filename]];
    
    if (content != nil) {
        NSData* actual_signature = [NSData dataWithContentsOfURL:[self signatureFilename]];
        
        if (actual_signature != nil) {
            // Check signature
            NSData* computed_signature = [self createHMACWithMD5:content];
            
            if ([actual_signature isEqualToData:computed_signature])
            {
                return content;
            } else {
                [[self signatureErrorDelegate] signatureError:[self filename]];
            }
        }
    }
    
    return nil;
}

- (NSData*) createHMACWithMD5:(NSData*)source
{
    const char* cKey = [self.key cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned char cHMAC[CC_MD5_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgMD5, cKey, strlen(cKey), [source bytes], [source length], cHMAC);
    NSData* hmac = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    
    return hmac;
}

- (void)signatureError:(NSURL*)file
{
    #pragma unused(file)
    DebugLog(@"Signature check failed for file %@", file);
}

@end
