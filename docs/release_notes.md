Swrve iOS SDK Release Notes
=

- [Release 4.1.1](#release-411)
- [Release 4.1](#release-41)
- [Release 4.0.5](#release-405)
- [Release 4.0.4](#release-404)
- [Release 4.0.3](#release-403)
- [Release 4.0.2](#release-402)
- [Release 4.0.1](#release-401)
- [Release 4.0](#release-40)
- [Release 3.4](#release-34)
- [Release 3.3.1](#release-331)
- [Release 3.3](#release-33)
- [Release 3.2](#release-32)
- [Release 3.1.3](#release-313)
- [Release 3.1.2 Beta](#release-312-beta)
- [Release 3.1.1 Beta](#release-311-beta)
- [Release 3.1](#release-31)
- [Release 3.0.2](#release-302)
- [Release 3.0.1](#release-301)
- [Release 3.0](#release-30)
- [Release 2.2.1](#release-221)
- [Release 2.2](#release-22)
- [Release 2.1](#release-21)
- [Release 2.0.1](#release-201)
- [Release 2.0](#release-20)
- [Release 1.13](#release-113)
- [Previous Releases Summary](#previous-releases-summary)


Release 4.1.1
-
Release Date: December 3, 2015

iOS SDK release 4.1.1 includes the following bug fix:

* Restored backwards compatibility with iOS SDK 4.0.X.

Release 4.1
-
Release Date: November 30, 2015

iOS SDK release 4.1 is focused on the following:

* Custom events beginning with `Swrve.` or `swrve.` are now blocked and no longer sent by the SDK.
* It is now easier to configure the SDK for EU data storage. For more information see [How Do I Configure the Swrve SDK for EU Data Storage?](http://docs.swrve.com/faqs/sdk-integration/configure-sdk-for-eu-data-storage/)
* It is now possible to turn off the Swrve SDK logs. For more information, see [How Do I Disable SDK Device Logging?](http://docs.swrve.com/faqs/sdk-integration/disable-sdk-device-logging/)
* It is now possible to log IDFA and IDFV as user properties. For more information, see [How Do I Log Advertising and Vendor IDs?](http://docs.swrve.com/faqs/app-integration/log-advertising-and-vendor-ids/)
* New flag added to control the status bar when displaying in-app messages.
* The SDK now uses new Contacts and Photos frameworks on iOS9.
* Easier push engagement integration. For more information, see [Integrating Push Notifications](http://docs.swrve.com/developer-documentation/advanced-integration/integrating-push-notifications/).

iOS SDK release 4.1 includes the following bug fixes:

* Fixed issue with message rules so that resetting rules for QA users now only occurs once.
* The button name is now sent as part of the payload in the click event for in-app messages.

Release 4.0.5
-
Release Date: October 9, 2015

iOS SDK release 4.0.5 is focused on the following:

* The SDK now retries downloading assets on app resume.

iOS SDK release 4.0.5 includes the following bug fixes:

* Fixed an issue where single orientation in-app messages were causing iOS 9 apps with a fixed orientation to crash.
* Use of the ViewController container removes the ‘Unbalanced calls’ warning from the logs.

Release 4.0.4
-
Release Date: October 1, 2015

iOS SDK release 4.0.4 includes the following bug fix:

* Fixed issues with full screen video in Conversations on iOS6 and iOS7.

Release 4.0.3
-
Release Date: September 17, 2015

iOS SDK release 4.0.3 is focused on the following:

* The HTTP default timeout has been increased.
* The SDK uses a new UIWindow when displaying Conversations.

iOS SDK release 4.0.3 includes the following bug fix:

* Fixed an issue that prevented the SDK from compiling when using the use_frameworks! option with CocoaPods.

Release 4.0.2
-
Release Date: August 21, 2015

iOS SDK release 4.0.2 includes the following bug fix:

* Removal of the Contacts.framework to allow compilation with Xcode 6 until Xcode 7 is out of pre-release.

Release 4.0.1
-
Release Date: August 18, 2015

iOS SDK release 4.0.1 is focused on the following:

* Added support for iOS 9.
* You can now customize the New Session Interval property. For more information, see [How Do I Configure the New Session Interval?](http://docs.swrve.com/faqs/sdk-integration/how-do-i-configure-the-new-session-interval/)
* The SDK now logs device region (for example: IE, GB or FR) using the new swrve.device_region property.

iOS SDK release 4.0.1 includes the following bug fix:

* The SDK now tracks the full device name and model (for example, iPad1,2; not simply iPad) to the existing `swrve.device_name` property.
* Fixed the bold and italic text styles in the Conversations editor.

Release 4.0
-
Release Date: July 7, 2015

iOS SDK release 4.0 is focused on the following:

* Added support for Conversations. For more information, see [Intro to Conversations](http://docs.swrve.com/user-documentation/conversations/intro-to-conversations/).
* Added support for requesting device permissions.

iOS SDK release 4.0 includes the following bug fix:

* The device screen width and height user properties are now independent of screen orientation.

Release 3.4
-
Release Date: April 8, 2015

iOS SDK release 3.4 is focused on the following:

* The default background for in-app messages has been changed from solid black to transparent. You can configure the background color in the code, or contact your Customer Success Manager to configure it in the in-app message wizard template.

iOS SDK release 3.4 includes the following bug fixes:

* Support for displaying messages outside the UI thread.
* Prevent sending multiple impression events in `viewDidAppear`.

Release 3.3.1
-
Release Date: January 21, 2015

iOS SDK release 3.3.1 is focused on the following:

* The SDK now pulls campaigns and resources only when events are sent.

iOS SDK release 3.3.1 includes the following bug fixes:

* `unvalidatedIAP` is now sent immediately.
* The SDK now asks for a device token on first session start and sends it immediately.
* Compile issues with new versions of Xcode have been resolved.
* IDFV notes have been removed from the code docs.

Release 3.3
-
Release Date: November 11, 2014

iOS SDK release 3.3 is focused on the following:

* The SDK now logs mobile carrier information by default. Swrve tracks the name, country ISO code and carrier code of the registered SIM card. You can use the country ISO code to track and target users by country location.
* Added support for iOS 8 interactive push notifications. When initializing the Swrve SDK, you must now provide any custom action categories you may want to use with interactive push notifications managed from the dashboard. For more information, see [Integrating Push Notifications](http://docs.swrve.com/developer-documentation/advanced-integration/integrating-push-notifications/).

iOS SDK release 3.3 includes the following bug fixes:

* Better error notification when an empty response is received by the server.
* `getAttributeAsBool` fix.
* Sends IAP product ID as part of the event payload.
* Added application state check when processing push notifications.

Release 3.2
-
Release Date: October 21, 2014

iOS SDK release 3.2 is focused on the following:

* Added CocoaPod support. You can now use pod 'SwrveSDK' to install the latest Swrve SDK.
* SDKs no longer use ID for Vendor as device ids. The SDK now generates a random unique user id if no custom user id is provided at initialization.
* Deprecated cross application install tracking.
* Deprecated `iapWithRawParameters`. Replaced with `unvalidatedIap`.
* Use http for in-app campaigns requests.

iOS SDK release 3.2 includes the following bug fixes:

* In-app message interval is also calculated from when the message is dismissed.
* Avoid crashing when a QA user goes back to being a normal user.
* Correctly put back events in the queue when there is a network problem.

Release 3.1.3
-
Release Date: September 12, 2014

Upgrade Instructions: None - all updates have been done internally so no code changes are required to upgrade to this version of the SDK.

iOS SDK release 3.1.3 includes support for devices running the Golden Master (GM) version of iOS 8 and is focused on the following:

* Support for iOS 8 push notification token registration.
* Support for iOS 8 screen rotation API.

Please note that SDK release 3.1.3 replaces previous Beta versions of the SDK for use in preparing your app for iOS 8.

Release 3.1.2 Beta
-
Release Date: August 29, 2014

Upgrade Instructions: None - no code changes are required to upgrade to this version of the SDK.

iOS SDK release 3.1.2 Beta is focused on the following:

* Includes support for testing devices running iOS 8 Beta 5.

Please note iOS 8 is not released yet, so SDK release 3.1.2 is a beta only. Use the SDK to test for iOS 8 readiness but do not submit until iOS 8 is officially released and your app has been built using production tools.

Release 3.1.1 Beta
-
Release Date: August 8, 2014

Upgrade Instructions: None - no code changes are required to upgrade to this version of the SDK.

iOS SDK release 3.1.1 Beta is focused on the following:

* Using new push registration method from iOS 8 when available.
* Using new rotation APIs for Talk messages when available.

Please note iOS 8 is not released yet, so SDK release 3.1.1 is a beta only. Use the SDK to test for iOS 8 readiness but do not integrate it into your production apps. SDK release 3.1.1 Beta is not available for general download; see above.

Release 3.1
-
Release Date: July 30, 2014

iOS SDK release 3.1 is focused on the following:

* Support for in-app message delivery at session start has been enhanced.
* The `iapWithRawParameters` method has been reintroduced.

iOS SDK release 3.1 includes the following bug fixes:

* Swizzling now respects `AppDelegate`’s class hierarchy.
* The in-app messages are now displayed using an `UIWindow`.
* An issue whereby an attempt was made to send logging data to QA devices despite logging being disabled has been fixed.
* There is no longer a delay in displaying messages upon trigger of the `Swrve.Messages.Campaigns_downloaded` event.

Release 3.0.2
-
Release Date: May 30, 2014

iOS SDK release 3.0.2 includes the following bug fix:

* The IAP listener has been removed to prevent issues with the payment queue. A new method is available to call the SDK when IAP purchases are made.

Release 3.0.1
-
Release Date: May 27, 2014

iOS SDK release 3.0.1 includes the following bug fixes:

* An error whereby the shutdown process was not stopping the automatic reload of campaigns and resources has been corrected.
* In-app campaigns which contain the set of automatic triggers now display when they have been completely downloaded.

Release 3.0
-
Release Date: May 15, 2014

iOS SDK release 3.0 is focused on real-time targeting enhancements - Swrve now automatically downloads user resources and campaign messages and keeps them up to date in near real-time during each session in order to reflect the latest segment membership. This is useful for time-sensitive A/B tests and messaging campaigns.

iOS SDK release 3.0 includes the following bug fixes:

* An error whereby the SDK incorrectly raised a version error when there were no campaigns downloaded has been corrected.
* An issue with swizzeling has been corrected.

Release 2.2.1
-
Release Date: April 18, 2014

Upgrade Instructions: None - no code changes are required to upgrade to this version of the SDK.

iOS SDK release 2.2.1 addresses two issues which occurred in release builds only:

* A bug relating to automatically collecting push device tokens has been fixed. This issue only occurred if your app:

 * Enables `SwrveConfig.pushEnabled` (off by default).
 * Enables `SwrveConfig.autoCollectDeviceToken` (on by default).
 * Has an implementation of `didRegisterForRemoteNotificationsWithDeviceToken`.
* A bug relating to requesting resource content for A/B tests has been fixed.

Release 2.2
-
Release Date: April 1, 2014

iOS SDK release 2.2 is focused on the following:

* The IAP function is deprecated; an app no longer needs to explicitly call the SDK when IAP purchases are made as the Swrve iOS SDK automatically listens for IAP events between the app and Apple.
* The iOS receipt validation process has been updated to handle iOS7 receipts directly. To enable validation of IAP receipts against an app, Swrve now requires the Apple bundle ID of the app.
* iOS6 sandbox and production receipts are now treated equally; a valid sandbox receipt is considered as valid and contributes to revenue.
* Performance metrics have now been added to HTTP requests in the iOS SDK.
* Processing of the Install and Deep Link in-app message actions has been simplified.
* Registration of QA devices has been simplified.
* If push notifications are enabled, the default time to request push notification permission is now at session start.

iOS SDK release 2.2 includes the following bug fixes:

* In-app messaging orientation issues have been fixed.
* An error with `_swrve_http_get_fire_forget` function has been fixed.
* An error that occurred when running com.swrve.qaapp.App has been fixed.
* An issue whereby the SDK failed to compile with Objective C++ in Xcode has been fixed.

Release 2.1
-
Release Date: March 4, 2014

iOS SDK release 2.1 is focused on the following:

* The automatic campaign event is now changed to swrve.messages_downloaded.
* Campaign, user resources and saved events signing processes have been added.
* GZIP support for campaigns and user resources has been added.

iOS SDK release 2.1 includes the following bug fixes:

* The iOS SDK now compiles without warnings.
* The correct quantity of virtual items is sent when users make in-app purchases.
* The device’s push notification token is auto-collected correctly by default.
* Calling the `[Swrve sharedInstance]` methods repeatedly no longer results in incorrect behaviour.

Release 2.0.1
-
iOS SDK release 2.0.1 is focused on the following:

* An issue relating to the scaling of interstitial images for iPads has now been corrected.
* All references to IDfA have been removed from Swrve’s iOS SDK.
* Cross-company install tracking for cross promotions on iOS now only works for apps that are from the same company.

Release 2.0
-
iOS SDK release 2.0 is focused on the following:

* iOS SDK now uses an Objective-C interface.
* Default initialization has been simplified.
* There is a single configuration object for changing analytics and in-app messaging settings.
* There is now an optional `SharedInstance` Singleton.
* In-app messaging is now available as a property of Swrve object.
* User updates are now merged when possible.
* User resources callbacks now include `NSDictionaries`.
* Events and userUpdates now take `NSDictionaries` as parameters.
* Session Start and Session End events are automatically sent.
* Save Events to Disk is now automatically called by default.
* Send Queued Events is now automatically sent by default.
* Default link token values are now created.
* Support for pending user IDs has been removed.
* The device friendly name is no longer logged as a user property.
* Swrve’s in-app message format rules are now enforced.
* iOS SDK can now write the user ID to the user preferences.

For information about upgrading to iOS SDK v2.0, see [Swrve iOS SDK Upgrade Guide](/docs/upgrade_guides.md).

Release 1.13
-
iOS SDK release 1.13 is focused on push notification changes and the correction of minor bugs. It includes the following:

* Significant push notification SDK enhancements have been made.
* Specification of a link token is no longer required to initialize the SDK.
* An exception error which occurred on http_read_callback in `swrve.m` has now been fixed.
* An unhandled exception in `_swrve_get_bytes_from_string` has now been fixed.

Previous Releases Summary
-
* Nov 12, 2013 - v1.12 - Added support for extended IAP event and bug fixes.
* Oct 18, 2013 - v1.11.1 - Bug fixes.
* Oct 16, 2013 - v1.11 - Added support for in-app messaging per campaign dismissal rules and bug fixes.
* Sep 18, 2013 - v1.10.1 - Bug fixes.
* Sep 17, 2013 - v1.10 - Added support for in-app messaging QA logging.
* Aug 20, 2013 - v1.9 - Added support for in-app messaging QA users.
* July 26, 2013 - v 1.8 - Added support for server side IAP validation.
* July 2nd, 2013 - v 1.7 - Added support for app store filtering in in-app messaging.
* May 8, 2013 - v1.6 - Removed UDID system calls from `libReceiptVerification.multi.a` library. You must use this library if submitting to Apple after May 1, 2013. This library is compatible with the v1.4 SDK.
* April 15, 2013 - v1.5 - Major update - in-app messaging added.
* March 19, 2013 - v1.4 - Added client-side IAP validation and third-party ID tracking.
* Nov 8, 2012 - Fix bug where `user_resources` call returned incorrect results when called with no network connection.
* Nov 2, 2012 - Add `user_resources` call (in parallel to& `user_resources_diff`).
* Aug 24, 2012 - Fixing a small timestamp bug effecting session length and playtime.
* Apr 17, 2012 - Add support for joined field to A/B Test call in iOS SDK.
* Dec 1, 2011 - Adding `currency_given` API support.
* Sept 30, 2011 - First public release.