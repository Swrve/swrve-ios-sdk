#import "SwrveReceiptProvider.h"
#import "Swrve.h"

@implementation SwrveReceiptProviderResult

@synthesize encodedReceipt;
@synthesize transactionId;

- (id)init:(NSString *)_encodedReceipt withTransactionId:(NSString *)_transactionId {
    self = [super init];
    if (self) {
        self.encodedReceipt =  _encodedReceipt;
        self.transactionId = _transactionId;
    }
    return self;
}

@end

@implementation SwrveReceiptProvider

// Return the transaction receipt data stored in the main bundle of the app.
- (SwrveReceiptProviderResult *)receiptForTransaction:(SKPaymentTransaction *)transaction API_AVAILABLE(ios(12.0)) {
    NSData *receipt = [self readMainBundleAppStoreReceipt];
    if (!receipt) {
        [SwrveLogger error:@"Error reading receipt from device", nil];
        return nil;
    }
    NSString *encodedReceipt = [receipt base64EncodedStringWithOptions:0];
    return [[SwrveReceiptProviderResult alloc] init:encodedReceipt withTransactionId:transaction.transactionIdentifier];
}

- (NSData *)readMainBundleAppStoreReceipt API_AVAILABLE(ios(12.0)) {
    return [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
}

@end
