Swrve
=
Swrve is a single integrated platform delivering everything you need to drive mobile engagement and create valuable consumer relationships on mobile.

This iOS SDK will enable your app to use all of these features.

- [Getting started](#getting-started)
  - [Requirements](#requirements)
    - [Xcode (latest)](#xcode-latest)
    - [Frameworks](#frameworks)
    - [Automatic reference counting](#automatic-reference-counting)
- [Installation Instructions](#installation-instructions)
  - [In-App Messaging](#in-app-messaging)
    - [In-App Messaging Deeplinks](#in-app-messaging-deeplinks)
  - [Push Notifications](#push-notifications)
    - [Timing the device token (push permission) request](#timing-the-device-token-push-permission-request)
    - [Processing custom payload](#processing-custom-payload)
    - [Disabling method swizzling](#disabling-method-swizzling)
    - [Creating and uploading your iOS Certificate](#creating-and-uploading-your-ios-certificate)
    - [Provisioning your app](#provisioning-your-app)
  - [Sending Events](#sending-events)
    - [Sending Named Events](#sending-named-events)
    - [Event Payloads](#event-payloads)
    - [Send User Properties](#send-user-properties)
    - [Sending Virtual Economy Events](#sending-virtual-economy-events)
    - [Sending IAP Events and IAP Validation](#sending-iap-events-and-iap-validation)
    - [Enabling IAP Receipt Validation](#enabling-iap-receipt-validation)
    - [Verifying IAP Receipt Validation](#verifying-iap-receipt-validation)
    - [Unvalidated IAP](#unvalidated-iap)
  - [Integrating Resource A/B Testing](#integrating-resource-ab-testing)
  - [Automatic Reference Counting](#automatic-reference-counting)
  - [Testing your integration](#testing-your-integration)
- [Upgrade Instructions](#upgrade-instructions)
- [How to run the demo](#how-to-run-the-demo)
- [Contributing](#contributing)
- [License](#license)


Getting started
=

Requirements
-
### Xcode (latest)
The SDK supports iOS 6+ and the latest version of Xcode (Xcode 6, as the time of writing).

### Frameworks

* `CFNetwork.framework`
* `StoreKit.framework`
* `Security.framework`
* `QuartzCore.framework`
* `CoreTelephony.framework`
* `UIKit.framework`
* `MessageUI.framework`
* `CoreLocation.framework`
* `AddressBook.framework`
* `AVFoundation.framework`
* `AssetsLibrary.framework`
* `Photos.framework`
* `Contacts.framework`

### Automatic reference counting

If your XCode project does not use Automatic Reference Counting (ARC), you must enable ARC for each file in the Swrve SDK. To enable ARC for each file.

Installation Instructions
=
The easiest path to install the Swrve SDK is to use Cocoapads to automatically download the Swrve SDK and add it to your project: add `pod 'SwrveSDK'` to your Podfile.

It is also possible to add the SDK by:
* Downloading the [latest release](https://github.com/Swrve/swrve-ios-sdk/releases/latest)

If you are using Cocoapods, add `pod 'SwrveSDK'` to your Podfile and run `pod install`.

If you are not using the Cocoapods, you'll need to: unzip the iOS SDK, copy the contents of the SDK folder into your project and add the frameworks listed in the requirement section above.

Add one of the code snippets below to the didFinishLaunchingWithOptions method of your AppDelegate, depending on whether your data will be stored in our US or EU data center.

By default, Swrve stores all customer data and content in our US data center. If you require EU-only data storage, you must configure the SDK to point to Swrve’s EU-based URL endpoints.

US Data Storage

```
#import "swrve.h"
- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
   [Swrve sharedInstanceWithAppID:<app_id> apiKey:@"<api_key>" launchOptions:launchOptions];
}
```

EU Data Storage

```
#import "swrve.h"
- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
   SwrveConfig* config = [[SwrveConfig alloc] init];
   config.selectedStack = SWRVE_STACK_EU;
   [Swrve sharedInstanceWithAppID:<app_id> apiKey:@"<api_key>" config:config launchOptions:launchOptions];
}
```

For more information, see [How Do I Configure the Swrve SDK for EU Data Storage?](http://docs.swrve.com/faqs/sdk-integration/configure-sdk-for-eu-data-storage/) If you have any questions or need assistance configuring the SDK for EU data storage, please contact support@swrve.com.

Replace `<app_id>` and `<api_key>` with your Swrve app ID and Swrve API key.

* (Optional): With iOS 9, by default all communications between the app and its backend or the web should use HTTPS. (See the App Transport Security section in Apple’s [What’s New in iOS 9.0](https://developer.apple.com/library/prerelease/ios/releasenotes/General/WhatsNewIniOS/Articles/iOS9.html) guide.) Swrve’s API URL endpoints are now all HTTPS-capable and the API calls default to HTTPS. However, if you’re planning to use YouTube videos as content in your Conversations, add an Application Transport Security exception to your `<App>-Info.plist`.

  ```
  <key>NSAppTransportSecurity</key>
  <dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
  </dict>
  ```

  This is needed, as even HTTPS YouTube links use non-secure endpoints that keep changing over time.

* (Optional): If you are planning to use or ask for location tracking permission, add the following keys to your `<App>-Info.plist` if not already there (edit the Value message to whatever text you want):

  * `NSLocationAlwaysUsageDescription`. Value: "Location is needed to offer all functionality in this app".
  * `NSLocationWhenInUseUsageDescription`. Value: "Location is needed to offer all functionality in this app".


In-App Messaging
-
Integrate the in-app messaging functionality so you can use Swrve to send personalized messages to your app users while they’re using your app. If you’d like to find out more about in-app messaging, see [Intro to In-App Messages](http://docs.swrve.com/user-documentation/in-app-messaging/intro-to-in-app-messages/).

Before you can test the in-app message feature in your game, you need to create an In App Message campaign in the Swrve Dashboard.

If you want to display an in-app message as soon as your view is ready, you must trigger the display event when the view controller is in the `viewDidAppear` state and not in `viewDidLoad` state.

### In-App Messaging Deeplinks

When creating in-app messages in Swrve, you can configure message buttons to direct users to perform a custom action when clicked. For example, you might configure a button to direct the app user straight to your app store. To enable this feature, you must configure deeplinks by performing the actions outlined below. For more information about creating in-app messages in Swrve, see [Creating In-App Messages](http://docs.swrve.com/user-documentation/in-app-messaging/creating-in-app-messages/).

Swrve's default deeplink behaviour is to treat custom actions as URLs and therefore use your existing custom URL scheme. Before handling deeplinks in Swrve, you’ll need to register a [custom URL scheme with iOS](https://developer.apple.com/library/ios/featuredarticles/iPhoneURLScheme_Reference/Introduction/Introduction.html).

Once the custom URL scheme is set, your app can receive and direct users from outside of the app.

It is also possible to override this behavior and integrate custom actions to direct users to a sale, website or other target when they click on an in-app message. For example, if you would like to handle additional swrve query parameters from this URL, you must implement this within the app.


```
[Swrve sharedInstance].talk.customButtonCallback = ^(NSString* action) {
   // Process the custom action
   // ...
}
```

For example, if you'd like to send Swrve events using custom actions, you could add a customButtonCallback like this:

```
[Swrve sharedInstance].talk.customButtonCallback = ^(NSString* action) {
    NSURL *url = [NSURL URLWithString:action];
    double delayInSeconds = 0.25;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {

        if ([url.scheme isEqualToString:@"swrve"]) {
            NSArray *pairs = [url.query componentsSeparatedByString:@"&"];
            for(NSString *pair in pairs){
                NSString key = [[pair componentsSeparatedByString:@"="] objectAtIndex:0];
                NSString value = [[pair componentsSeparatedByString:@"="] objectAtIndex:1];

                if ([key isEqualToString:@"event"]) {
                    [[Swrve sharedInstance] event:value];
                }
            }
            [[Swrve sharedInstance] sendQueuedEvents];
        }
        else {
            [[UIApplication sharedApplication] openURL:url];
        }
    });
}
```


Push Notifications
-

Push notifications are disabled by default. To enable them, set `SwrveConfig.pushEnabled` to `YES`. In addition, you must tell the Swrve SDK when your app receives a push notification (this is required for push notification reporting in the Swrve service). If you are using iOS 8 Interactive Notifications, you must also declare the custom action categories to the Swrve SDK (see example below).

Your app must also handle the following two situations:

* The app is launched from a push notification.
* The app receives the push notification while running.

```
- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  // Initialize Swrve with custom events that will trigger the push
  // notification dialog

  SwrveConfig* config = [[SwrveConfig alloc] init];
  config.pushEnabled = YES;

  // Let the SDK know about your iOS8 Interactive Notifications if you have
  // any in your app
  config.pushCategories = [NSSet setWithObjects:YOUR_CATEGORY, nil];

  [Swrve sharedInstanceWithAppID:your_app_id
         apiKey:@"your_api_key"
         config:config
         launchOptions:launchOptions];

  // ...
}

-(void) application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
  // by default - no action if the user gets a push while the app is running.
}
```

The remainder of the initialization process depends on how you want to request permission from the user to accept push notifications.

### Timing the device token (push permission) request

When a user first installs a push-enabled app, the latest device token for push notifications is requested, which triggers a permission request to the user to accept push notifications from the app. Swrve has built-in functionality to manage the timing of this request—you can time it to one of the following options:

* Request permission at the start of the session. This is the default configuration.
* Request permission when one of a list of events is triggered.

For more information about uploading device tokens, see [How Do I Upload Push Device Tokens?](http://docs.swrve.com/faqs/push-notifications/upload-push-device-tokens/)

Apple only asks for permission to receive push notifications once per app, under normal circumstances. As a result, when you want to test your push notification integration on a QA device, you must reset the iOS push permissions to test the different timing configurations for push permissions outlined above. For more information, see [How Do I Reset iOS Permissions?](http://docs.swrve.com/faqs/push-notifications/reset-ios-permissions-for-push-notifications/)

1. Request Push Permission at Start of Session (Default)

  By default, the Swrve SDK requests push permission from the user on their first session. This is the simplest option and requires no additional code changes.

2. Request Push Permission when Certain Events are Triggered

  If you want to request push permission upon the triggering of certain events, add the event names to SwrveConfig.pushNotificationEvents when you initialize the SDK.

  ```
  // Initialize Swrve with custom events that will trigger the push notification dialog
  SwrveConfig* config = [[SwrveConfig alloc] init];
  config.pushEnabled = YES;
  config.pushNotificationEvents = [[NSSet alloc] initWithArray:@[@"tutorial.complete", @"subscribe"]];
  [Swrve sharedInstanceWithAppID:your_app_id apiKey:@"your_api_key" config:config launchOptions:launchOptions];
  // Initialize Swrve with custom events that will trigger the push notification dialog
  ```

  If a user never triggers these events, they will never be available for push notifications. So select events that are most likely to be triggered by all but the most transient of users.

### Processing custom payload

If you want to capture any custom key/value pairs passed with the push notification, capture the notification data in both of your application’s `didFinishLaunchingWithOptions` and `didReceiveRemoteNotification` methods this:

```
- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
   // Capture the notification data that opened the app
   NSDictionary * remoteNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
   if (remoteNotification) {
      // Do something with remoteNotification
   }
}

-(void) application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    // Do something with userInfo
}
```

The method above enables you specify any launch parameters that you want to capture and take action on. For more information, see [Configuring the Launch Screen](http://docs.swrve.com/faqs/push-notifications/configure-launch-screen-from-push-notification/).

### Disabling method swizzling

The SDK uses method swizzling by default. Method Swizzling of Push Notification methods means that fewer code changes are required to enable push notifications. Use the following code if you want to disable method swizzling:

```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    SwrveConfig* config = [[SwrveConfig alloc] init];
    config.pushEnabled = YES;
    config.autoCollectDeviceToken = NO;
    [[Swrve sharedInstance] initWithAppID:customerAppId apiKey:customerApiKey config:config launchOptions:launchOptions];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    if ([Swrve sharedInstance].talk != nil) {
        [[Swrve sharedInstance].talk setDeviceToken:deviceToken];
    }
}

-(void) application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [[Swrve sharedInstance].talk pushNotificationReceived:userInfo];
}
```

### Creating and uploading your iOS Certificate

To enable your app to send push notifications to iOS devices, you require a push certificate. A push certificate authorizes an app to receive push notifications and authorizes a service to send push notifications to an app. For more information, see [How Do I Manage iOS Push Certificates?](http://docs.swrve.com/faqs/push-notifications/manage-ios-push-certificates-for-push-notifications/)

### Provisioning your app

Each time your app is published for distribution, you must provision it against the push certificate that has been created for the app. To do this, perform the following steps:

1. In Xcode, on the Product menu, click Archive.

2. On the Organizer, select Archives and then select the latest archive you want to distribute.

3. Select the distribution for ad-hoc deployment.

4. On the provisioning screen, select the development push certificate created for this app.



Sending Events
-

### Sending Named Events

```
[[Swrve sharedInstance] event:@"custom.event_name"];
```

Rules for sending events:

* Do not send the same named event in differing case. For example, if you send `tutorial.start`, then you should ensure you never send `Tutorial.Start`.

* Use '.'s in your event name to organize their layout in the Swrve dashboard. Each '.' creates a new tree in the UI which groups your events so they are easy to locate.

* Do not send more than 1000 unique named events.
 * Do not add unique identifiers to event names. For example, `Tutorial.Start.ServerID-ABDCEFG`
 * Do not add timestamps to event names. For example, `Tutorial.Start.1454458885`

* When creating custom events, do not use the `swrve.*` or `Swrve.*` namespace for your own events. This is reserved for Swrve use only. Custom event names beginning with `Swrve.` are restricted and cannot be sent.

### Event Payloads

An event payload can be added and sent with every event. This allows for more detailed reporting around events and funnels. 

Notes on associated payloads:
* The associated payload should be a dictionary of key/value pairs; it is restricted to string and integer keys and values. 
* There is a maximum cardinality of 500 key-value pairs for this payload per event. This parameter is optional, but only the first 500 payloads will be seen in the dashboard. The data is still available in raw event logs.
* It is not currently possible to use payloads as triggers or for filters in the dashboard. Events should be used for these purposes. 


```
[[Swrve sharedInstance] event:@"custom.event_name" payload:@{
  @"key1": @"value1",
  @"key2": @"value2"
}];
```

For example, if you want to track when a user starts the tutorial experience it might make sense to send an event `tutorial.start` and add a payload `time` which captures how long the user spent starting the tutorial.

```
[[Swrve sharedInstance] event:@"tutorial.start" payload:@{
  @"time": @"100",
  @"step": @"5"
}];
```

### Send User Properties

Assign user properties to send the status of the user. For example create a custom user property called `premium`, and then target non-premium users and premium users in the dashboard.

When configuring custom properties for iOS, you can use a variety of data types (integers, boolean, strings) which the SDK then converts to an integer (for number-based values) or string (in the case of boolean, "true/false") before sending the data to Swrve. When creating segments or campaign audiences, depending on which data type the property is converted to, you must then select the correct operator (equals for numbers, is for strings) for the property to be properly returned.

```
[[Swrve sharedInstance] userUpdate:@{
  @"premium": true,
  @"level": @12,
  @"balance": @999
}];
```

### Sending Virtual Economy Events

To ensure virtual currency events are not ignored by the server, make sure the currency name configured in your app matches exactly the Currency Name you enter in the App Currencies section on the App Settings screen (including case-sensitive). If there is any difference, or if you haven’t added the currency in Swrve, the event will be ignored and return an error event called Swrve.error.invalid_currency. Additionally, the ignored events will not be included in your KPI reports. For more information, see [Add Your App](http://docs.swrve.com/getting-started/add-your-app/).

If your app has a virtual economy, send the purchase event when users purchase in-app items with virtual currency.

```
[[Swrve sharedInstance] purchaseItem:@"gold_card_pack" currency:@"gold" cost:50 quantity:1];
```

Send the currency given event when you give users virtual currency. Examples include initial currency balances, retention bonuses and level-complete rewards.

```
[[Swrve sharedInstance] currencyGiven:@"coins" givenAmount:25];
```

### Sending IAP Events and IAP Validation

You must notify Swrve when an in-app purchase occurs as follows:

```
- (void) onTransactionProcessed:(SKPaymentTransaction*) transaction productBought:(SKProduct*) product {
   // Tell Swrve what was purchased.
   SwrveIAPRewards* rewards = [[SwrveIAPRewards alloc] init];
 
   // You can track the purchase of virtual items
   [rewards addItem:@"com.myapp.item_sku" withQuantity:1];
   // Or virtual currency or both.
   [rewards addCurrency:@"coins" withAmount:100];
 
   // Send the IAP event to Swrve.
   [[Swrve sharedInstance] iap:transaction product:product rewards:rewards];
}
```

### Enabling IAP Receipt Validation

Swrve automatically validates iOS in-app purchases and ignores any events that are considered fraudulent as per [Apple guidelines](https://developer.apple.com/library/ios/releasenotes/General/ValidateAppStoreReceipt/Introduction.html).

To enable validation of IAP receipts against your app:

1. On the Setup menu, click Integration Settings.

2. Under IAP Validation, in the iTunes App Bundle Identifier section, enter your Apple Bundle Id.

3. Click Save.

Although Swrve can validate IAP receipts without this identifier, providing it enables Swrve to verify a receipt against the app itself for greater precision during validation. Swrve checks that the bundle ID included in an in-app purchase receipt corresponds to your bundle ID before calculating your revenue KPIs. This ensures that your revenue figures are as accurate as possible (ignoring pirates and cheaters).

Generally, you enter the Apple bundle ID when configuring the Integration Settings screen as part of the Swrve onboarding process. You can edit the settings on this screen at any time.

To access your bundle ID, access the information property list file (`<App>-Info.plist`) in your Xcode project.

### Verifying IAP Receipt Validation

Use the following events to monitor the success of IAP receipt validation:

* `swrve.valid_iap` – fired if receipt verification has been successful and the receipt is valid.
* `swrve.invalid_iap` – fired if receipt verification has been successful and the receipt is invalid.

### Unvalidated IAP

If you want to build revenue reports for your app but don’t have or want the receipt being validated by our servers, use the function below. This might be required for any purchases made from the app not via apple - this revenue should be validated before this function is called, as any revenue sent by this event will automatically count in the Swrve dashboard.

```
// Tell Swrve what was purchased.
SwrveIAPRewards* rewards = [[SwrveIAPRewards alloc] init];
 
// You can track the purchase of virtual items
[rewards addItem:@"com.myapp.item_sku" withQuantity:1];
// Or virtual currency or both.
[rewards addCurrency:@"coins" withAmount:100];
 
// Send the IAP event to Swrve. Won’t be validated in our servers.
[[Swrve sharedInstance] unvalidatedIap:rewards localCost:10 localCurrency:@”USD” productId:@”sword” productIdQuantity:1]
```


Integrating Resource A/B Testing
-

To get the latest version of a resource from Swrve using the Resource Manager, use the following:

```
// Get the SwrveResourceManager which holds all resources
SwrveResourceManager* resourceManager = [[Swrve sharedInstance] getSwrveResourceManager];
// Then, wherever you need to use a resource, pull it from SwrveResourceManager. For example:
NSString *welcome_string = [resourceManager getAttributeAsString:@"welcome_string"
                                            ofResource:@"new_app_config"
                                            withDefault:@"Welcome!"];
```

If you want to be notified whenever resources change, you can add a callback function as follows:

```
SwrveConfig* config = [[SwrveConfig alloc] init];
config.resourcesUpdatedCallback = ^() {
  // Callback functionality
};
```

Automatic Reference Counting
-

Enable Automatic Reference Counting (ARC) for Each File in the Swrve SDK

If your project has Automatic Reference Counting (ARC) enabled, you can skip this section. However, if your project does not have ARC enabled, you must enable it for each file in the Swrve SDK. To enable ARC, perform the following actions:

* Select your project in XCode.

* Select the Build Phases section.

* Expand the Compile Sources section.

* Select all files in the Swrve SDK (that is, select all files in `/Sdk`).

* Add `-fobjc-arc` to the Compiler Flags of each selected file.

  ![Automatic Reference Counting](/docs/images/arc.jpg)

Testing your integration
-
When you have completed the steps above, the next step is to test the integration. See [Testing Your Integration](http://docs.swrve.com/developer-documentation/advanced-integration/testing-your-integration/) for more details.

Upgrade Instructions
=
If you’re moving from an earlier version of the iOS SDK to the current version, see the [iOS SDK Upgrade Guide](/docs/upgrade_guide.md) for upgrade instructions.

How to run the demo
=
- Open the project located under `SwrveDemo/SwrveDemoFramework.xcodeproj`
- Run on your device or on the emulator.
- Change the App ID and Api Key in the Settings with the values provided by Swrve.

Contributing
=
We would love to see your contributions! Follow these steps:

1. Fork this repository.
2. Create a branch (`git checkout -b my_awesome_feature`)
3. Commit your changes (`git commit -m "Awesome feature"`)
4. Push to the branch (`git push origin my_awesome_feature`)
5. Open a Pull Request.

License
=
© Copyright Swrve Mobile Inc or its licensors. Distributed under the [Apache 2.0 License](LICENSE).
