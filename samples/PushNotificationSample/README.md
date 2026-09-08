# Push Notification Sample

Baseline Swrve SDK integration with push notifications, including rich push, in SwiftUI.

This is the smallest complete push setup: create the SDK with push enabled, share an app group with a notification service extension, trigger the permission prompt, and handle notification responses.

## Why this exists

Push is the most common reason to integrate the SDK, and it is the part with the most moving pieces — an app group that must match in five places, a service extension for rich content, a permission prompt the OS shows only once per install, and entitlements. Getting any of them wrong fails quietly: no crash, just plain-text notifications, missing influence data, or nothing at all.

## Setup

1. `pod install`, then open `PushNotificationSample.xcworkspace` (not the `.xcodeproj`).
2. In [`PushNotificationSampleApp.swift`](PushNotificationSample/PushNotificationSampleApp.swift), replace the app IDs and API keys with your own, from the Swrve dashboard under **Settings → Integration settings**. There are two pairs — see the `#if DEBUG` note below. The same values can go in both if you use one app for both.
3. Replace the identifiers with your own. Both targets ship ours — `swrve.RichPushSample` and `swrve.RichPushSample.ServiceExtension` — because they are registered in our Apple portal, so signing fails until you change them. Your App IDs need the **Push Notifications** capability, and your app group must be registered to your team.
4. Set your app group to the same value in **five** places:
   - `APP_GROUP` in [`PushNotificationSampleApp.swift`](PushNotificationSample/PushNotificationSampleApp.swift)
   - `APP_GROUP` in [`NotificationService.swift`](PushNotificationSampleServiceExtension/NotificationService.swift)
   - `com.apple.security.application-groups` in [`PushNotificationSampleDebug.entitlements`](PushNotificationSample/PushNotificationSampleDebug.entitlements)
   - `com.apple.security.application-groups` in [`PushNotificationSampleRelease.entitlements`](PushNotificationSample/PushNotificationSampleRelease.entitlements)
   - `com.apple.security.application-groups` in [`PushNotificationSampleServiceExtension.entitlements`](PushNotificationSampleServiceExtension/PushNotificationSampleServiceExtension.entitlements)

   A real app might share one constant across targets — the samples repeat the value so each file stands alone.
5. Run the app and grant notification permission. The button appears only while the permission is outstanding — once granted it is replaced by a confirmation. A physical device is the surest test, though an Apple Silicon simulator on macOS 13+ can register for real push too.
6. Send yourself a push from a campaign in the dashboard.

## Key API calls

Setup is in [`PushNotificationSampleApp.swift`](PushNotificationSample/PushNotificationSampleApp.swift); the extension is [`NotificationService.swift`](PushNotificationSampleServiceExtension/NotificationService.swift).

**Enable push and share the app group:**

```swift
let config = SwrveConfig()
config.pushEnabled = true
config.appGroupIdentifier = "group.your.app"
config.pushNotificationPermissionEvents = ["push_permission_request"]
config.notificationCategories = [category]   // optional interactive buttons
config.pushResponseDelegate = self           // set before initialisation

#if DEBUG
    SwrveSDK.sharedInstance(withAppID: DEBUG_APP_ID, apiKey: DEBUG_API_KEY, config: config)
#else
    SwrveSDK.sharedInstance(withAppID: PRODUCTION_APP_ID, apiKey: PRODUCTION_API_KEY, config: config)
#endif
```

**Trigger the OS permission prompt** by sending one of the events named above:

```swift
SwrveSDK.event("push_permission_request")
```

**Handle rich content in the extension:**

```swift
SwrvePush.handle(request.content, withAppGroupIdentifier: "group.your.app") { content in
    contentHandler(content)
}
```

## Good to know

- **The app group must match in five places.** `APP_GROUP` in each of the two targets, and all three `.entitlements` files — the app has one per build configuration. A mismatch compiles and runs — you simply lose rich content and influence tracking, with no error.
- **The SDK never asks for permission on its own.** Without `pushNotificationPermissionEvents`, no prompt appears and no push arrives.
- **You get one chance to ask.** iOS shows the authorization alert once per install; after that, requesting again returns the existing status and shows nothing. A denial is effectively permanent, recoverable only in Settings.
- **Which is why permission is usually asked for with an in-app message rather than app code.** A campaign can ask at a moment that makes sense, in your own words, with a button that requests notification permission — and a later campaign can send users who have already denied straight to their notification settings, since iOS will not show the prompt again. Both are configured in the dashboard, so your app needs no permission handling of its own. The button in this sample is a shortcut so you can test push without setting up a campaign.
- **Deeplinks are handled for you.** Swrve opens any deeplink in the payload when the notification is tapped, and sends the engaged event with the campaign's tracking data. Set `config.deeplinkDelegate` if you would rather route it yourself.
- **`pushResponseDelegate` must be set before initialisation**, and initialisation must happen before the app finishes launching. That is why this sample keeps a `UIApplicationDelegate` alongside the SwiftUI `App`.
- **Without the service extension push still arrives**, but only as plain text — no images, no buttons, no influence tracking.
- **Influence tracking needs the app group**, which is what the extension writes through. It is how Swrve attributes an app open to a notification the user saw but did not tap.
- **Silent push is not covered by any sample.** Swrve's [iOS integration guide](https://docs.swrve.com/developer-documentation/integration/ios/) has you enable the **Remote notifications** background mode and implement `didReceiveRemoteNotification` to refresh app data in the background. The samples cover display push only, so neither declares that capability.
- **Simulators can receive push, with caveats.** An Apple Silicon simulator on macOS 13+ registers for real push and receives it from APNs; older or Intel simulators do not. You can also drag a `.apns` payload file onto any simulator to test rendering without APNs at all. A physical device remains the surest test.
- **The identifiers here are the ones this sample has always used**, because they are registered in our Apple portal — hence the note in setup about signing.
- **Debug and Release use separate entitlements, and that is what makes the `#if DEBUG` split meaningful.** `PushNotificationSampleDebug.entitlements` sets `aps-environment` to `development` and `PushNotificationSampleRelease.entitlements` sets it to `production`, wired per build configuration. The two are different APNS environments with different device tokens, so each configuration also selects its own Swrve credentials. Sharing one entitlements file across both would leave a Release build registering a sandbox token while reporting to your production app — pushes would simply never arrive.
- **Credentials here are sample-grade.** Hardcoding an API key in source is fine for a sample and wrong for a real app.
