iOS SDK Upgrade Guide
=

- [Upgrading to iOS SDK v4.1.1](#upgrading-to-ios-sdk-v411)
- [Upgrading to iOS SDK v4.1](#upgrading-to-ios-sdk-v41)
  - [Custom Events Starting with `Swrve.`](#custom-events-starting-with-swrve)
  - [Custom User ID](#custom-user-id)
  - [Add Photos and Contacts Frameworks](#add-photos-and-contacts-frameworks)
- [Upgrading to iOS SDK v4.0.5](#upgrading-to-ios-sdk-v405)
- [Upgrading to iOS SDK v4.0.4](#upgrading-to-ios-sdk-v404)
- [Upgrading to iOS SDK v4.0.3](#upgrading-to-ios-sdk-v403)
- [Upgrading to iOS SDK v4.0.2](#upgrading-to-ios-sdk-v402)
  - [`Contacts.framework`](#contactsframework)
  - [Conversations video support for iOS 9](#conversations-video-support-for-ios-9)
- [Upgrading to iOS SDK v4.0.1](#upgrading-to-ios-sdk-v401)
  - [iOS 9 Support](#ios-9-support)
  - [Conversations video support for iOS 9](#conversations-video-support-for-ios-9-1)
- [Upgrading to iOS SDK v4.0](#upgrading-to-ios-sdk-v40)
  - [Conversations](#conversations)
  - [Requestion Device Permissions](#requestion-device-permissions)
- [Upgrading to iOS SDK v3.4](#upgrading-to-ios-sdk-v34)
  - [In-app message background color default](#in-app-message-background-color-default)
- [Upgrading to iOS SDK v3.3.1](#upgrading-to-ios-sdk-v331)
- [Upgrading to iOS SDK v3.3](#upgrading-to-ios-sdk-v33)
  - [iOS 8 interactive push notifications](#ios-8-interactive-push-notifications)

This guide provides information about how you can upgrade to the latest Swrve iOS SDK. For information about the changes that have been made in each iOS SDK release, see [iOS SDK Release Notes](/docs/release_notes.md).

Upgrading to iOS SDK v4.1.1
-
No code changes are required to upgrade to Swrve iOS SDK v4.1.1 from v4.1. If you are upgrading from a previous version, complete the steps below for v4.1.

Upgrading to iOS SDK v4.1
-
This section provides information to enable you to upgrade to Swrve iOS SDK v4.1.

### Custom Events Starting with `Swrve.` ###

* Custom events that start with `Swrve.*` or `swrve.*` are now restricted. You need to rename any custom `Swrve.` events or they won’t be sent.

### Custom User ID ###

If you are using a custom user ID and upgrading to iOS SDK 4.1, you need to move the configuration to the SwrveConfig object:

From

```
[Swrve sharedInstanceWithAppID:<app_id>
       apiKey:@"<api_key>"
       userId:@”<your_custom_user_id>”];
```

To

```
SwrveConfig* config = [[SwrveConfig alloc] init];
config.userId = @”<your_custom_user_id>”;
[Swrve sharedInstanceWithAppID:<app_id>
       apiKey:@"<api_key>"
       config:config
       launchOptions:launchOptions];
```

### Add Photos and Contacts Frameworks ###

iOS9 has deprecated several APIs in favor of the new Photos and Contacts frameworks. Please add them to your project:

* `Contacts.framework`
* `Photos.framework`

Upgrading to iOS SDK v4.0.5
-
No code changes are required to upgrade to Swrve iOS SDK v4.0.5.

Upgrading to iOS SDK v4.0.4
-
No code changes are required to upgrade to Swrve iOS SDK v4.0.4.

Upgrading to iOS SDK v4.0.3
-
No code changes are required to upgrade to Swrve iOS SDK v4.0.3.

Upgrading to iOS SDK v4.0.2
-
This section provides information to enable you to upgrade to Swrve iOS SDK v4.0.2.

### `Contacts.framework` ###

If you upgraded to SDK v4.0.1, remove the Contacts.framework from your project.

### Conversations video support for iOS 9 ###

If you are upgrading from SDK v4.0 or prior, follow the instructions for v4.0.1 below regarding Conversations video support for iOS 9.

Upgrading to iOS SDK v4.0.1
-

This section provides information to enable you to upgrade to Swrve iOS SDK v4.0.1.

### iOS 9 Support ###

To upgrade the SDK to include support for iOS 9, include the `Contacts.framework` framework in your project and build your app using Xcode 7. If you are not using Xcode 7, then you need to exclude the Contacts.framework from your project and be aware that Conversation Campaigns aimed at asking users for permission to access their Contacts will use a deprecated API on iOS 9 devices and so may not work for much longer.

### Conversations video support for iOS 9 ###

With iOS 9, by default all communications between the app and its backend or the web should use HTTPS. (See the App Transport Security section in Apple’s What’s New in iOS 9.0 guide.) Swrve’s API URL endpoints are now all HTTPS-capable and the API calls default to HTTPS. However, if you’re planning to use YouTube videos as content in your Conversations, add an Application Transport Security exception to your <App>.plist.

```
<key>NSAppTransportSecurity</key>
<dict>
 <key>NSAllowsArbitraryLoads</key>
 <true/>
</dict>
```

This is needed, as even HTTPS YouTube links use non-secure endpoints that keep changing over time.

Upgrading to iOS SDK v4.0
-
This section provides information to enable you to upgrade to Swrve iOS SDK v4.0.

### Conversations ###
To upgrade the SDK for Swrve’s new Conversations feature, add the following frameworks to your project:

* `MessageUI.framework`
* `CoreLocation.framework`
* `AddressBook.framework`
* `AVFoundation.framework`
* `AssetsLibrary.framework`

### Requestion Device Permissions ###

If you are planning to use or ask for location tracking permission, add the following keys to your `<App>-Info.plist` if not already there (edit the Value message to whatever text you want):

* `NSLocationAlwaysUsageDescription`. Value: `"Location is needed to offer all functionality in this app"`.
* `NSLocationWhenInUseUsageDescription`. Value: `"Location is needed to offer all functionality in this app"`.

Upgrading to iOS SDK v3.4
-
This section provides information to enable you to upgrade to Swrve iOS SDK v3.4.

### In-app message background color default ###

The in-app message background color is now transparent by default. If you want to maintain a solid black background, you must configure it before initializing the SDK as follows:

```
config.defaultBackgroundColor = [UIColor blackColor];
```

Upgrading to iOS SDK v3.3.1
-
No code changes are required to upgrade to Swrve iOS SDK v3.3.1.

Upgrading to iOS SDK v3.3
-
This section provides information to enable you to upgrade to Swrve iOS SDK v3.3.

### iOS 8 interactive push notifications ###

If your application already makes use of iOS 8 interactive push notifications, add the following snippet to your SDK initialization code:

````
NSSet* pushCategories = [NSSet setWithObjects:YOUR_CATEGORY, nil];
// Let the SDK know about your interactive categories
config.pushCategories = pushCategories;
// Initialize passing a configuration object
[Swrve sharedInstanceWithAppID:... config:config];
```

Upgrading to iOS SDK v3.2
-
This section provides information to enable you to upgrade to Swrve iOS SDK v3.2.

### Notify the SDK of push notifications only when opened or running in background ###

To avoid notifying the SDK of push notifications that the app receives while open, change your AppDelegate `didRecieveRemoteNotification` method to:

```
- (void) application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary *)userInfo {    
   UIApplicationState swrveState = [application applicationState];
   if (swrveState == UIApplicationStateInactive || swrveState == UIApplicationStateBackground) {
      [[Swrve sharedInstance].talk pushNotificationReceived:userInfo];
   }
}
```

### iapWithRawParameters becomes unvalidatedIap ###

Change any calls in your code from iapWithRawParameters to unvalidatedIap:

```
-(int) unvalidatedIap:(SwrveIAPRewards*)rewards localCost:(double)localCost
                                                localCurrency:(NSString*) localCurrency
                                                productId:(NSString*)productId
                                                productIdQuantity:(int)productIdQuantity;
```

### Link token and link server deprecated ###

Cross application install tracking has been deprecated. Please remove any reference to these attributes or methods:

* `SwrveConfig.linkToken`
* `SwrveConfig.linkServer`
* `Swrve.clickThruForTargetGame:(long)targetApp source:(NSString*)source;`

Upgrading to iOS SDK v3.1.3
-
No code changes are required to upgrade to Swrve iOS SDK v3.1.3.

Upgrading to iOS SDK v3.1
-
This section provides information to enable you to upgrade to Swrve iOS SDK v3.1.

IN-APP MESSAGES AT SESSION START
The Session Start check box has been added to the Set Target screen of the in-app message wizard to enable you to configure in-app message display at session start. If you were previously using the following code for that purpose, you must now remove it:

```
config.autoShowMessageAfterDownloadEventNames
```

The session start timeout (the time that messages have to load and display after the session has started) is set to 5,000 milliseconds (5 seconds) by default. You can modify the timeout value using the following:

```
[config setAutoShowMessagesMaxDelay:5000]; // milliseconds
```

If the user is on a slow network and the images cannot be downloaded within the timeout period you specify, they are not displayed in that session. They are instead cached and shown at the next session start for that user.

For more information about targeting in-app messages, see Creating In-App Messages.

Upgrading to iOS SDK v3.0.2
-
This section provides information to enable you to upgrade to Swrve iOS SDK v3.0.2.

The IAP listener has been removed to avoid issues with customers' listeners. The following configuration parameters haven been removed:

* `config.transactionCompleteCallback`
* `config.reportInAppPurchases`

The following new methods have been added to notify the SDK when a purchase has been made:

* `(int) iap:(SKPaymentTransaction*) transaction product:(SKProduct*) product;`
* `(int) iap:(SKPaymentTransaction*) transaction product:(SKProduct*) product rewards:(SwrveIAPRewards*)rewards;`

Call this function in the method where you process your transactions:

```
- (void) processTransactions:(NSArray *)transactions onQueue:(SKPaymentQueue *)queue {    
   for (SKPaymentTransaction *transaction in transactions)
   - (void) processTransactions:(NSArray *)transactions onQueue:(SKPaymentQueue *)queue {
      SKProduct* product = .... obtain the product ......
      [[Swrve sharedInstance] iap:transaction product:product];
   }
}
```

Upgrading to iOS SDK v3.0
-
This section provides information to enable you to upgrade to Swrve iOS SDK v3.0.

### Real-time targeting ###
Swrve has the ability to update segments on a near real-time basis. Swrve now automatically downloads user resources and campaign messages and keeps them up to date in near real-time during each session in order to reflect the latest segment membership. This is useful for time-sensitive A/B tests and messaging campaigns. These updates are only run if there has been a change in the segment membership of the user, therefore resulting in minimal impact on bandwidth.

Real-time refresh is enabled by default and, if you want to avail of it, you must perform the upgrade tasks detailed below.

**Configuration**

`config.autoDownload`, which was used to indicate whether campaigns should be downloaded automatically upon app start-up has been replaced with the following:

```
config.autoDownloadCampaignsAndResources
```

By default, `config.autoDownloadCampaignsAndResources` is set to `YES`; as a result, Swrve automatically keeps campaigns and resources up to date.

If you decide to set it to NO, campaigns and resources are always set to cached values at app start-up and it’s up to you to call the following function to update them; for example, at session start or at a key moment in your app flow:

```
[swrve refreshUserResourcesAndCampaigns];
```

If you disable `config.autoDownloadCampaignsAndResources`, the existing `getUserResources` function no longer works as resources are read from the cache and no longer updated.
Campaigns

Campaign messages are now downloaded automatically as soon as the user becomes eligible for them (even on an intra-session basis). Therefore, the following functions have been removed:

```
-(void)downloadCampaigns;
-(void)downloadCampaignsWithCallback:(SwrveCampaignDownloadedCallback)callback;
```

**User Resources**

Swrve now automatically downloads user resources and keeps them up to date with any changes. Swrve supplies a Resource Manager to enable you to retrieve the most up-to-date values for resources at all times; you no longer need to explicitly tell Swrve when you want updates.

If you use Swrve’s new Resource Manager, you no longer need to use the following two functions:

```
-(void) getUserResourcesDiff:(SwrveUserResourcesDiffCallback)callbackBlock;
-(void) getUserResources:(SwrveUserResourcesCallback)callbackBlock;
```

The new resource manager behaves like `getUserResources`; it returns the value of the attribute for the current user. If the value in the Swrve service is changed, the Resource Manager reflects that straight away.

To call the Resource Manager from the Swrve object, use the following:

```
SwrveResourceManager* resourceManager = [swrve getSwrveResourceManager];
```

The `SwrveResourceManager` class has a number of methods to retrieve attribute values for specific resources, depending on the expected value type:

```
(NSString*) getAttributeAsString:(NSString*)attributeId
            ofResource:(NSString*)resourceId
            withDefault:(NSString*)defaultValue;

(int) getAttributeAsInt:(NSString*)attributeId
      ofResource:(NSString*)resourceId
      withDefault:(int)defaultValue;

(float) getAttributeAsFloat:(NSString*)attributeId
        ofResource:(NSString*)resourceId
        withDefault:(float)defaultValue;

(BOOL) getAttributeAsBool:(NSString*)attributeId
       ofResource:(NSString*)resourceId
       withDefault:(BOOL)defaultValue;
```

Note that all these methods take default values that are returned when either the resource or the attribute doesn’t exist. For example, to get the price of a sword you might call the following:

```
float price = [resourceManager getAttributeAsFloat:@"price"
                               ofResource:@"sword"
                               withDefault:nil];
```

These methods always return the most up-to-date value for the attribute.

Optionally, you can set up a callback function that is called every time updated resources are available. Use this if you want to implement your own resource manager, for example. You can set this as follows as part of `SwrveConfig`:

```
SwrveConfig* config = [[SwrveConfig alloc] init];
config.resourcesUpdatedCallback = ^() {
  // Callback functionality
};
```

The callback function takes no arguments, it just lets you know resources have been updated. You must then use the Resource Manager to get the new values. You can store all resources locally and keep them up to date using the following:

```
config.resourcesUpdatedCallback = ^() {
   self.resources = [resourceManager getResources];
};
```

The callback is called if there is a change in the user resources and also at the start as soon as resources have been loaded from cache.

Upgrading to iOS SDK v2.2
-
This section provides information to enable you to upgrade to Swrve iOS SDK v2.2.

### Push Notifications disabled by default ###

Push notifications are now disabled by default. If you enable them with the code below, push permission is requested at the start of the session:

```
swrveConfig.pushEnabled = YES;
```

You can time the push permission request according to your own requirements. For more information, see [Integrating Push Notifications](http://docs.swrve.com/developer-documentation/advanced-integration/integrating-push-notifications/).

### User resources and user resources diff callback ###

The user resources and user resources diff callbacks now return `NSData` instead of a `CFString`. You must change any references from the following:

```
PrivateUserResourcesCallback privateCallback = ^(CFStringRef resourcesString) {
}
```

to the following:

```
PrivateUserResourcesCallback privateCallback = ^(NSData* jsonData) {
}
```

### IAP Method ###

You must remove all calls to the IAP method as the SDK now hooks into your purchases and sends this data automatically.

### Custom action (deep link) processing ###

Following previous versions of the in-app messaging integration documentation, you may have used code similar to the following. You must now remove this code:

```
- (void)showMessage:(SwrveMessage *)message
{
   UIViewController* view = [message createViewControllerThatCalls:^(SwrveActionType type, NSString* action, NSInteger appId)
   {
      float discount = 1.0;
      switch(type)
      {
            case kSwrveActionDismiss:
               break;

            case kSwrveActionInstall:
               // Navigate to the app store
               [[UIApplication sharedApplication] openURL:[NSURL URLWithString: action]];
               break;

            case kSwrveActionCustom:
            {
               // Parse the discount amount.
               NSError* error;
               NSData* actionAsData = [action dataUsingEncoding:NSUTF8StringEncoding];
               NSDictionary* actionAsJson = [NSJSONSerialization JSONObjectWithData:actionAsData options:NSJSONReadingMutableContainers error:&error];
               if( [actionAsJson objectForKey:@"currencyMultiplier"])
               {
                  discount = ((NSString*)[actionAsJson objectForKey:@"currencyMultiplier"]).floatValue;
               }
            }
            break;
      } 

      // Dismiss the controller and optionally show the store front if needed

      [self dismissViewControllerAnimated:YES completion:^(void)
      {
         if(discount != 1.0)
         {
            [self showStoreFrontWithDiscount:discount];
         }
      }];
   }];

   if(view) {
      if ([self respondsToSelector:@selector(presentViewController:animated:completion:)]){
          [self presentViewController:view animated:YES completion:nil];
      }
      else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
      [self presentModalViewController:view animated:YES];
#pragma clang diagnostic pop
      }
   }
}
```

You must also remove the following code:

```
[Swrve sharedInstance].talk.showMessageDelegate = self;
```

Replace both snippets above with the following to introduce your custom button processing logic:

```
[Swrve sharedInstance].talk.customButtonCallback = ^(NSString* action)
{
   // Process the custom action. For example:

   float discount = 1.0;
   NSError* error;
   NSData* actionAsData = [action dataUsingEncoding:NSUTF8StringEncoding];
   NSDictionary* actionAsJson = [NSJSONSerialization JSONObjectWithData:actionAsData options:NSJSONReadingMutableContainers error:&error
   if([actionAsJson objectForKey:@"currencyMultiplier"])   
   {
      discount = ((NSString*)[actionAsJson objectForKey:@"currencyMultiplier"]).floatValue;
      if(discount != 1.0)
      {
          [self showStoreFrontWithDiscount:discount];
      }
   }
}
```

Upgrading to iOS SDK v2.1
-
No code changes are required to upgrade to Swrve iOS SDK v2.1.

Upgrading to iOS SDK v2.0
-
This section provides information to enable you to upgrade to Swrve iOS SDK v2.0.

The new iOS SDK has been ported to Objective-C. You must now access all objects using messages instead of C functions.

### Initialization ###

The initialization function has been simplified. The SDK now provides some static functions to initialize the SDK in a single line.

```
// Configure the SDK
SwrveConfig* config = swrve_config_init(appId, (__bridge CFStringRef)(apiKey), (__bridge CFStringRef)(userId));
// Create the SDK
swrve = swrve_init(config);
```

now becomes:

```
// Create the SDK
[Swrve sharedInstanceWithAppID:appId apiKey:apiKey userId:userId];
```

### Session start and session end ###

The SDK attaches itself to the application life cycle so there is no need to call these two methods. Remove any references to session start and session end.

### Custom events ###

Wherever your app sends a custom event you must update the code. For example:

```
swrve_event(swrve, (CFStringRef)@"Swrve.Demo.Gameplay.Player_Died", (CFStringRef)
@"{ "enemy_name" : "slug", "player_level" : "5" }");
```

now becomes:

```
[swrve event:@"Swrve.Demo.Gameplay.Player_Died" payload: [NSDictionary dictionaryWithObjectsAndKeys:
  @"slug", @"enemy_name",
  @"5", @"player_level",
  nil]];
```

The event method can now be called without a payload:

```
[swrve event:@"Swrve.Demo.Gameplay.Player_Died"];
```

### User update event ###

Wherever your app sends a user update event you must update the code. For example:

```
swrve_user_update(swrve, CFSTR("{"health" : 100, "gold" : 20 }"));
```

now becomes:

```
[swrve userUpdate:[NSDictionary dictionaryWithObjectsAndKeys:
  [NSNumber numberWithInt:100], @"health",
  [NSNumber numberWithInt:20], @"gold",
  nil]];
```

### In-app purchases ###

In-app purchases have been simplified. There are now two functions. The first function reads the properties from the SKProduct and sends the receipt from the `SKPaymentTransaction` for validation to Swrve’s servers if necessary.

```
SwrveIAPRewards* rewards = [[SwrveIAPRewards alloc] initWithRewardCurrency:@"gold"
                                                    andAmount:10];
[swrve iap:rewards transaction:transaction product:product];
```

The second function provides a manual way of specifying the parameters of the purchase:

```
[swrve iapWithRawParameters:rewards
       localCost:10.0
       localCurrency:@"USD" 
       productId:@"com.swrve.small_currency_pack"
       productIdQuantity:1
       receipt:receiptData];
```

### Currency given ###

Wherever your app sends a currency given event you must update the code. For example:

```
swrve_currency_given(swrve, CFSTR("gold"), 20);
```

now becomes:

```
[swrve currencyGiven:@"gold" givenAmount:20];
```

### Purchase Item ###

Wherever your app sends a purchase item event you must update the code. For example:

```
swrve_purchase(swrve, CFSTR("someItem"), CFSTR("gold"), 20, 1);
```

now becomes:

```
[swrve purchaseItem:@"someItem" currency:@"gold" cost:20 quantity:1];
```

### Send queued events ###

Wherever your app sends queued events you must update the code. For example:

```
swrve_send_queued_events(swrve);
```

now becomes:

```
[swrve sendQueuedEvents];
```

### Flush to disk ###

Wherever your app saves events to disk you must update the code. For example:

```
swrve_save_events_to_disk(swrve);
```

now becomes:

```
[swrve saveEventsToDisk];
```

### A/B Test resources ###

Wherever your app asks for user resources or user resources diffs, you must update the code. For example:

```
swrve_get_user_resource_diff(swrve, (__bridge void *)(self), abTestCallback_diffs);
swrve_get_user_resources(swrve, (__bridge void *)(self), abTestCallback);
```

now becomes:

```
[swrve getUserResourcesDiff:^(NSDictionary *oldResourcesValues, NSDictionary *newResourcesValues, NSString *resourcesAsJSON) {
  // Custom code
}];

[swrve getUserResources:^(NSDictionary *resources, NSString *resourcesAsJSON) {
  // Custom code
}];
```

### In-app messaging and push notifications changes ###

In-app messaging and push notifications are enabled by default in the new SDK. By just initializing the SDK you enable these features.

To obtain a reference to the in-app messaging SDK, access the talk property of the main SDK:

```
SwrveMessageController * talk = swrve.talk;
```

If you want to disable in-app messaging or push notifications in your app, use the following snippet:

```
SwrveConfig* config = [[SwrveConfig alloc] init];

// Disable Push
config.autoCollectDeviceToken = NO;
config.pushNotificationEvents = nil;

// Disable Talk
config.talkEnabled = false;
swrveTrack = [[Swrve alloc] initWithAppID:swrveAppId
                            apiKey:swrveApiKey
                            userID:userId
                            config:config];
swrveTalk = swrveTrack.talk;
```

Upgrading to iOS SDK v1.13
-
This section provides information to enable you to upgrade to Swrve iOS SDK v1.13.

### Auto-generation of link token ###

You no longer need to specify a link token to initialize the SDK; the SDK generates a link token for cross-promotion if required. The configuration method is as follows:

```
#import "swrve.h"
SwrveConfig* config = swrve_config_init(appId,
                                        (__bridge CFStringRef)(apiKey),
                                        (__bridge CFStringRef)(userId));
```

Upgrading to iOS SDK v1.12
-
This section provides information to enable you to upgrade to Swrve iOS SDK v1.12.

### Deprecation of the `swrve_buy_in` function ###

The old buy_in function was used to record purchases of in-app currency that were paid for with real-world money:

```
int swrve_buy_in (Swrve* swrve,
                  CFStringRef reward_currency,
                  int reward_amount,
                  double local_cost,
                  CFStringRef local_currency);
```

This can be replaced by creating a `SwrveIAPRewards` object with the in-app currency details, and a call to `swrve_iap_with_rewards`.

```
SwrveIAPRewards* rewards = [[SwrveIAPRewards alloc] initWithRewardCurrency:<reward_currency> 
                                                    andAmount:<reward_amount>];
swrve_iap_with_rewards(swrve,
                       <local_cost>,
                       <local_currency>,
                       paymentTransaction,
                       rewards);
```
where `paymentTransaction` is the `SDKPaymentTransaction` return from the iTunes Store after purchase has been made.

### Deprecation of the old IAP function ###

The old `swrve_iap` function was a replacement for the deprecated buy-in function. It was also used to record purchases of in-app currency that were paid for with real money, except it included receipt validation:

```
int swrve_iap (Swrve* swrve,
               CFStringRef reward_currency,
               int reward_amount,
               double local_cost,
               CFStringRef local_currency,
               SKPaymentTransaction* transaction);
```
It can be replaced in a similar way by the new `swrve_iap_with_rewards` function:


```
SwrveIAPRewards* rewards = [[SwrveIAPRewards alloc] initWithRewardCurrency:<reward_currency> 
                                                    andAmount:<reward_amount>];
swrve_iap_with_rewards(swrve,
                       <local_cost>,
                       <local_currency>,
                       <transaction>,
                       rewards);
```
Note: Base64 encoding is performed by the Swrve SDK to avoid duplication of event encoding, pass the unencoded receipt from the Apple IAP transactions through to the IAP function.
