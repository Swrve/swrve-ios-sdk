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

#include <CommonCrypto/CommonHMAC.h>

@protocol SwrveSignatureErrorListener <NSObject>
@required
- (void)signatureError:(NSURL*)file;
@end

/*! Used internally to protect the data written to the disk */
@interface SwrveSignatureProtectedFile : NSObject<SwrveSignatureErrorListener>

@property (atomic, retain)   NSURL* filename;
@property (atomic, retain)   NSURL* signatureFilename;
@property (atomic, readonly) NSString* key;
@property (atomic, retain)   id<SwrveSignatureErrorListener> signatureErrorListener;

- (id) initFile:(NSURL*)file signatureFilename:(NSURL*)signatureFile usingKey:(NSString*)signatureKey;
- (id) initFile:(NSURL*)file signatureFilename:(NSURL*)signatureFile usingKey:(NSString*)signatureKey signatureErrorListener:(id<SwrveSignatureErrorListener>)listener;

/*! Write the data specified into the file and create a signature file for verification. */
- (void) writeToFile:(NSData*)content;

/*! Read from the file, returning an error if file does not exist or signature is invalid. */
- (NSData*) readFromFile;

@end
