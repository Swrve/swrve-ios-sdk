#import <Foundation/Foundation.h>

@protocol SwrveSignatureErrorDelegate <NSObject>
@required
- (void)signatureError:(NSURL*)file;
@end

/*! Used internally to protect the data written to the disk */
@interface SwrveSignatureProtectedFile : NSObject<SwrveSignatureErrorDelegate>

@property (atomic, retain)   NSURL* filename;
@property (atomic, retain)   NSURL* signatureFilename;
@property (atomic, readonly) NSString* key;
@property (atomic, retain)   id<SwrveSignatureErrorDelegate> signatureErrorDelegate;

- (id) protectedFileType:(int)fileType
                  userID:(NSString*)userID
            signatureKey:(NSString*)signatureKey
           errorDelegate:(id<SwrveSignatureErrorDelegate>)delegate;
    
- (id) initFile:(NSURL*)file signatureFilename:(NSURL*)signatureFile usingKey:(NSString*)signatureKey;
- (id) initFile:(NSURL*)file signatureFilename:(NSURL*)signatureFile usingKey:(NSString*)signatureKey signatureErrorDelegate:(id<SwrveSignatureErrorDelegate>)delegate;

/*! Write the data specified into the file and create a signature file for verification. */
- (void) writeToFile:(NSData*)content;
- (void) writeToDefaults:(NSData*)content;
- (void) writeWithRespectToPlatform:(NSData*)content;

/*! Read from the file, returning an error if file does not exist or signature is invalid. */
- (NSData*) readFromFile;
- (NSData*) readFromDefaults;
- (NSData*) readWithRespectToPlatform;

@end
