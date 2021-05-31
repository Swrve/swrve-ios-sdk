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

        case SWRVE_AD_CAMPAIGN_FILE:
            filePath = [SwrveLocalStorage campaignsAdFilePathForUserId:userID];
            signatureFilePath = [SwrveLocalStorage campaignsAdSignatureFilePathForUserId:userID];
            break;

        case SWRVE_NOTIFICATION_CAMPAIGN_FILE_DEBUG:
            filePath = [SwrveLocalStorage debugCampaignsNoticationFilePathForUserId:userID];
            signatureFilePath = [SwrveLocalStorage debugCampaignsNotificationSignatureFilePathForUserId:userID];
            break;
            
        case SWRVE_NOTIFICATION_CAMPAIGNS_FILE:
            filePath = [SwrveLocalStorage offlineCampaignsFilePathForUserId:userID];
            signatureFilePath = [SwrveLocalStorage offlineCampaignsSignatureFilePathForUserId:userID];
            break;
            
        case SWRVE_REAL_TIME_USER_PROPERTIES_FILE:
            filePath = [SwrveLocalStorage realTimeUserPropertiesFilePathForUserId:userID];
            signatureFilePath = [SwrveLocalStorage offlineRealTimeUserPropertiesSignatureFilePathForUserId:userID];
            break;
    }

    if (filePath != nil) {
        NSURL* fileURL = [NSURL fileURLWithPath:filePath];
        NSURL* signatureURL = [NSURL fileURLWithPath:signatureFilePath];
        return [self initFile:fileURL signatureFilename:signatureURL usingKey:signatureKey signatureErrorDelegate:delegate];
    } else {
        return nil;
    }
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

- (void)writeToFile:(NSData *)content {
    NSError *error;
    BOOL successFileWrite = [content writeToURL:[self filename] options:NSDataWritingFileProtectionNone error:&error];
    if (successFileWrite) {
        NSData *signature = [self createHMACWithMD5:content];
        BOOL successSignatureFileWrite = [signature writeToURL:[self signatureFilename] options:NSDataWritingFileProtectionNone error:&error];
        if (!successSignatureFileWrite) {
            [SwrveLogger error:@"Could not write to signature file: %@", [self signatureFilename]];
        }
    } else {
        [SwrveLogger error:@"Could not write to file: %@", [self filename]];
    }
}

- (void) writeToDefaults:(NSData*)content {
    NSData* signature = [self createHMACWithMD5:content];
    [[NSUserDefaults standardUserDefaults] setValue:content forKey:self.filename.lastPathComponent];
    [[NSUserDefaults standardUserDefaults] setValue:signature forKey:self.signatureFilename.lastPathComponent];
    [[NSUserDefaults standardUserDefaults]  synchronize];
}

- (void) writeWithRespectToPlatform:(NSData*)content {
#if TARGET_OS_IOS
    [self writeToFile:content];
#elif TARGET_OS_TV
    // tvOS has a much more aggressive cache than iOS, which means most things have to be stored to the tvOS defaults rather than the cache
    [self writeToDefaults:content];
#endif
}

- (NSData*) readFromFile {
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

- (NSData*) readFromDefaults {
    NSURL *filePath = [self filename];
    NSURL *sigFilePath = [self signatureFilename];

    NSData* content = [[NSUserDefaults standardUserDefaults] dataForKey:filePath.lastPathComponent];

    if (content != nil) {
        NSData* actual_signature = [[NSUserDefaults standardUserDefaults] dataForKey:sigFilePath.lastPathComponent];

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

- (NSData*) readWithRespectToPlatform {
#if TARGET_OS_IOS
    return [self readFromFile];
#elif TARGET_OS_TV
    // tvOS has a much more aggressive cache than iOS, which means most things have to be stored to the tvOS defaults rather than the cache
    return [self readFromDefaults];
#endif
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
    [SwrveLogger error:@"Signature check failed for file %@", file];
}

@end
