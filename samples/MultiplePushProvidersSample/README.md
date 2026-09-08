# Multiple Push Providers Sample

How to integrate Swrve push when your app already uses another push provider, in SwiftUI.

## Why this exists

The difficulty is not any single API call — it is *ownership*. Two SDKs both want the device token, both want to be told when a notification is tapped, and both want to modify rich content, and iOS gives each of those to exactly one owner. Get it wrong and there is no error: registration succeeds, the app runs, and Swrve pushes simply never arrive or never record an engagement.

**Mostly you relay rather than decide.** The token and taps go to Swrve unconditionally, because it ignores payloads that are not its own. The extension is the exception: it gates on `SwrvePush.isSwrvePush`, not for Swrve's sake — it returns foreign payloads untouched — but because the other provider may mishandle a payload it does not recognise.

## Setup

1. `pod install`, then open `MultiplePushProvidersSample.xcworkspace` (not the `.xcodeproj`).
2. In [`MultiplePushProvidersSampleApp.swift`](MultiplePushProvidersSample/MultiplePushProvidersSampleApp.swift), replace `YOUR_APP_ID` and `YOUR_API_KEY` with your own, from the Swrve dashboard under **Settings → Integration settings**.
3. Replace the identifiers with your own. Both targets ship ours — `swrve.RichPushSample` and `swrve.RichPushSample.ServiceExtension` — because they are registered in our Apple portal, so signing fails until you change them. Your App IDs need the **Push Notifications** capability, and your app group must be registered to your team.
4. Set your app group to the same value in **four** places:
   - `APP_GROUP` in [`MultiplePushProvidersSampleApp.swift`](MultiplePushProvidersSample/MultiplePushProvidersSampleApp.swift)
   - `APP_GROUP` in [`NotificationService.swift`](MultiplePushProvidersSampleServiceExtension/NotificationService.swift)
   - `com.apple.security.application-groups` in [`MultiplePushProvidersSample.entitlements`](MultiplePushProvidersSample/MultiplePushProvidersSample.entitlements)
   - `com.apple.security.application-groups` in [`MultiplePushProvidersSampleServiceExtension.entitlements`](MultiplePushProvidersSampleServiceExtension/MultiplePushProvidersSampleServiceExtension.entitlements)

   A real app might share one constant across targets — the samples repeat the value so each file stands alone.
5. Run the app and grant notification permission. The button appears only while the permission is outstanding — once granted it is replaced by a confirmation. A physical device is the surest test, though an Apple Silicon simulator on macOS 13+ can register for real push too.
6. Send yourself a push. The **Push activity** panel shows the relays firing; the device token is shown separately above it.

## Key API calls

The app side is in [`MultiplePushProvidersSampleApp.swift`](MultiplePushProvidersSample/MultiplePushProvidersSampleApp.swift); the extension is [`NotificationService.swift`](MultiplePushProvidersSampleServiceExtension/NotificationService.swift). Three relays, marked `RELAY 1 of 3` and so on in the code.

**Stop Swrve collecting the token**, because the other provider registers and owns it:

```swift
config.pushEnabled = true
config.autoCollectDeviceToken = false
```

**Relay 1 — hand Swrve the token yourself**, from `didRegisterForRemoteNotificationsWithDeviceToken`:

```swift
SwrveSDK.setDeviceToken(deviceToken)
// your other provider gets the same token here
```

**Relay 2 — tell Swrve about taps**, from your `UNUserNotificationCenterDelegate`:

```swift
SwrveSDK.processNotificationResponse(response)
// your other provider's equivalent here
```

**Relay 3 — chain the handlers in the service extension:**

```swift
guard SwrvePush.isSwrvePush(request.content.userInfo) else {
    // your other provider's handler goes here; it calls deliver when done
    deliver(request.content)
    return
}

SwrvePush.handle(request.content, withAppGroupIdentifier: APP_GROUP) { content in
    self.deliver(content)
}
```

## Good to know

- **Everything else matches [PushNotificationSample](../PushNotificationSample).** Rich content, influence tracking and asking for permission with a campaign all work identically, so this sample deliberately does not repeat that material. Read that one first.
- **Register your other provider's dependency.** The commented-out line in the [`Podfile`](Podfile) shows where it goes, and each relay point is marked so adding the second call is obvious.
- **Permission is requested by the app here, not by Swrve.** Whoever owns registration owns the prompt, and in this pattern that is the app or the other provider — so `pushNotificationPermissionEvents` is not used. It sits behind a button because iOS shows the alert once per install: asking at first launch, before the user knows what the app is, is how you get declined permanently. A real app asks at a moment that makes sense, or with a campaign that can also send already-declined users to Settings.
- **`autoCollectDeviceToken = false` is the line that matters.** Leave it at its default `true` and both providers race to own registration. Setting it makes the app responsible for the token, which is why `setDeviceToken` exists.
- **A missed `setDeviceToken` fails silently.** Everything compiles, the SDK starts, events flow — and no push ever arrives, because Swrve has no token to send to.
- **Swrve can own the notification delegate instead — and should, when it can.** If Swrve is the only SDK that needs `UNUserNotificationCenter.current().delegate`, let it have it and use `config.pushResponseDelegate` to coordinate, as [PushNotificationSample](../PushNotificationSample) does. That is less code. This sample owns the delegate in the app because that is the configuration that survives when the other provider will not cooperate: many push SDKs claim the delegate in their own init, so whichever runs last wins, and Swrve-owned coordination only works if the other SDK exposes a way to hand it a response. App-ownership removes the ordering race and is the only shape that scales past two providers.
- **Take the delegate *after* `SwrveSDK.sharedInstance`.** The SDK assigns itself as `UNUserNotificationCenter.current().delegate` during initialisation, so assigning yours first means Swrve quietly takes it back — your relay never runs and the other provider never hears about taps. Nothing errors.
- **`processNotificationResponse` is the alternative to `SwrvePushResponseDelegate`, not an addition to it.** The delegate has Swrve own the tap callback, which it cannot do when a second provider needs the same callback. Use one or the other.
- **Relay unconditionally for the token and taps.** Swrve ignores payloads that are not its own, so telling it about every one is correct and simpler than branching. The extension is the one place this sample does decide, using `SwrvePush.isSwrvePush`.
- **The extension is where both providers most obviously collide.** Every notification for the app reaches it, whichever provider sent it, and there is only one extension. This sample sends each payload to one handler only, chosen on `SwrvePush.isSwrvePush`. Swrve would tolerate being called for a foreign payload — it returns them unmodified — but the other provider may not, which is why the gate is here rather than nowhere.
- **In the extension, the content handler must be called exactly once, and chaining makes that your problem.** A provider that never calls back leaves `serviceExtensionTimeWillExpire` to deliver; one that calls back late would deliver a second time. This sample funnels both paths through a `deliver` helper that clears the handler, so whichever arrives first wins. Apple's own extension template omits that guard, which is fine with a single handler and not once you chain.
- **It shares `PushNotificationSample`'s bundle identifier**, so the two samples cannot be installed on a device at the same time.
- **The entitlements set `aps-environment` to `development`.** A production build needs `production`; see `PushNotificationSample` for how to wire that per build configuration.
- **Credentials here are sample-grade.** Hardcoding an API key in source is fine for a sample and wrong for a real app.
