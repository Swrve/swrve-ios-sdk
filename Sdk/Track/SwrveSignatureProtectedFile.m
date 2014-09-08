/*
 * SWRVE CONFIDENTIAL
 *
 * (c) Copyright 2010-2014 Swrve New Media, Inc. and its licensors.
 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is and remains the property of Swrve
 * New Media, Inc or its licensors.  The intellectual property and technical
 * concepts contained herein are proprietary to Swrve New Media, Inc. or its
 * licensors and are protected by trade secret and/or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from Swrve.
 */

#import "Swrve.h"
#import "SwrveSignatureProtectedFile.h"

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

- (void) writeToFile:(NSData*)content
{
    if ([content writeToURL:[self filename] atomically:YES]) {
        NSData* signature = [self createHMACWithMD5:content];
        if (![signature writeToURL:[self signatureFilename] atomically:YES]) {
            DebugLog(@"Coulxd not write to signature file: %@", [self signatureFilename]);
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
                [[self signatureErrorListener] signatureError:[self filename]];
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
