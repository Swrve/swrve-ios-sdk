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

#import "SwrveReceiptProvider.h"
#import "Swrve.h"

@implementation SwrveReceiptProviderResult

@synthesize encodedReceipt;
@synthesize transactionId;

-(id) init:(NSString*)_encodedReceipt withTransactionId:(NSString*)_transactionId
{
    self = [super init];
    if (self) {
        self.encodedReceipt =  _encodedReceipt;
        self.transactionId = _transactionId;
    }
    return self;
}

@end

@implementation SwrveReceiptProvider

+(BOOL) SwrveSystemVersionGreaterOrEqualThan:(NSString*) desired {
    NSString* currentVersion = [[UIDevice currentDevice] systemVersion];
    return [currentVersion compare:desired options:NSNumericSearch] != NSOrderedAscending;
}

// Return the transaction receipt data from a device running iOS7.
// In this case the data is in a file stored in the main bundle of the app.
static SwrveReceiptProviderResult* receipt_ios7(SKPaymentTransaction* transaction) {
    NSData* receipt = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
    if (!receipt) {
        DebugLog(@"Error reading receipt from iOS7 device", nil);
        return nil;
    }
    NSString* encodedReceipt = [receipt base64EncodedStringWithOptions:0];
    return [[SwrveReceiptProviderResult alloc] init:encodedReceipt withTransactionId:transaction.transactionIdentifier];
}

// Return the transaction receipt data from a device that is running iO6.
// This requires a reference to the SKPaymentTransaction, since the receipt data
// is embedded inside it.
static SwrveReceiptProviderResult* receipt_ios6(SKPaymentTransaction* transaction) {
    NSData* receipt = [transaction transactionReceipt];
    if (!receipt) {
        DebugLog(@"Error reading receipt from iOS6 device", nil);
        return nil;
    }
    NSString* encodedReceipt = [receipt base64Encoding];
    return [[SwrveReceiptProviderResult alloc] init:encodedReceipt withTransactionId:nil];
}

- (SwrveReceiptProviderResult*)obtainReceiptForTransaction:(SKPaymentTransaction*)transaction {
    // Do things differently on iOS7+ devices
    if ([SwrveReceiptProvider SwrveSystemVersionGreaterOrEqualThan:@"7.0"]) {
        SwrveReceiptProviderResult* iOS7result = receipt_ios7(transaction);
        if (iOS7result) {
            return iOS7result;
        }
    }
    // Fallback to iOS6 receipt if there is none or we are running in iOS 6.1 or lower
    return receipt_ios6(transaction);
}

- (NSString*)base64encode:(NSData*)receipt {
    if ([SwrveReceiptProvider SwrveSystemVersionGreaterOrEqualThan:@"7.0"]) {
        return [receipt base64EncodedStringWithOptions:0];
    }
    
    return [receipt base64Encoding];
}

@end
