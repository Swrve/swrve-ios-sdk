#import "SwrveCommon.h"
#import "SwrveSignatureProtectedFile.h"
#import <CommonCrypto/CommonHMAC.h>

@implementation SwrveSignatureProtectedFile

@synthesize filename;
@synthesize signatureFilename;
@synthesize key;
@synthesize signatureErrorListener;

- (id) initFile:(NSURL*)file signatureFilename:(NSURL*)signatureFile usingKey:(NSString*)signatureKey
{
    return [self initFile:file signatureFilename:signatureFile usingKey:signatureKey signatureErrorListener:nil];
}

- (id) initFile:(NSURL*)file signatureFilename:(NSURL*)signatureFile usingKey:(NSString*)signatureKey signatureErrorListener:(id<SwrveSignatureErrorListener>)listener
{
    if (self = [super init]) {
        key = signatureKey;
        self.filename = file;
        self.signatureFilename = signatureFile;
        
        if (listener == nil) {
            self.signatureErrorListener = self;
        } else {
            self.signatureErrorListener = listener;
        }
    }
    return self;
}

- (NSString*) stringFromData:(NSData*)data
{
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (void) writeToFile:(NSData*)content
{
    if ([content writeToURL:[self filename] atomically:YES]) {
        NSData* signature = [self createHMACWithMD5:content];
//        NSLog(@"\n\nwriteToFile with key: %@, sig: ...%@...\n\n...%@",
//              self.key,
//              [signature base64Encoding],
//              [self stringFromData:content]);
        
        NSError* error;
        if (![[signature base64Encoding] writeToURL:[self signatureFilename]
                                         atomically:YES
                                           encoding:NSUTF8StringEncoding
                                              error:&error]) {
            DebugLog(@"Could not write to signature file: %@", [self signatureFilename]);
        }
    } else {
        DebugLog(@"Could not write to file: %@", [self filename]);
    }
}

- (NSData*) readFromFile
{
    NSData* file_content = [NSData dataWithContentsOfURL:self.filename];
    
    if (file_content != nil) {
        NSString* file_signature = [self stringFromData:[NSData dataWithContentsOfURL:[self signatureFilename]]];
//        NSLog(@"\n\nreadFromFile with key: %@, sig: ...%@...\n\n...%@\n\n%@",
//              self.key, file_signature,
//              [self stringFromData:file_content],
//              self.filename);

        if (file_signature != nil) {
            NSString* computed_signature = [[self createHMACWithMD5:file_content] base64Encoding];
            if ([file_signature isEqualToString:computed_signature])
            {
                return file_content;
            } else {
                [[self signatureErrorListener] signatureError:[self filename]];
            }
        }
    }
    
    return nil;
}

-(NSData*) createHMACWithMD5:(NSData*)source
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
