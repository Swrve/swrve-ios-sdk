#import "Swrve.h"
#import "Demo.h"

/*
 * A demo of Swrve's track API.
 */
@interface TrackApiDemo : Demo {
    
    Swrve* swrve;
}

@property (atomic, retain) IBOutlet UILabel* labelMemory;

- (IBAction)onEvent:(id)sender;
- (IBAction)onPurchase:(id)sender;
- (IBAction)onCurrencyGiven:(id)sender;
- (IBAction)onUserUpdate:(id)sender;
- (IBAction)onFlushEvents:(id)sender;
- (IBAction)onSaveEvents:(id)sender;

@end
