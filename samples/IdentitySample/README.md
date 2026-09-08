# Identity Sample

Linking a device to your own user ID with `identify()`, in SwiftUI.

`identify()` is called when the user signs in rather than at startup — the point at which a real app first learns who they are. The form stays available afterwards, so you can identify again as someone else and watch the user switch.

## Why this exists

Swrve gives every device its own anonymous user ID. `identify()` links that device to an ID of your own, so the same person is one user across their devices and across reinstalls. Getting the timing wrong is the usual mistake: called on every launch it is mostly a wasted round trip, and called too late it leaves activity attributed to the wrong user.

## Setup

1. `pod install`, then open `IdentitySample.xcworkspace` (not the `.xcodeproj`).
2. In [`IdentitySampleApp.swift`](IdentitySample/IdentitySampleApp.swift), replace `YOUR_APP_ID` and `YOUR_API_KEY` with your own, from the Swrve dashboard under **Settings → Integration settings**.
3. Run the app, enter any external user ID and tap **Identify**.

## Key API calls

Everything is in [`IdentitySampleApp.swift`](IdentitySample/IdentitySampleApp.swift) and [`IdentityView.swift`](IdentitySample/IdentityView.swift).

**Hold tracking until the user is known.** With this set, the SDK sends nothing until `start()` or `identify()` is called:

```swift
config.autoStartLastUser = false
```

**Identify the user**, once you know who they are:

```swift
SwrveSDK.identify(externalUserId,
                  onSuccess: { status, swrveUserId in /* now tracking */ },
                  onError:   { httpCode, errorMessage in /* not identified */ })
```

**Ask whether the SDK is tracking:**

```swift
SwrveSDK.started()
```

**Stop sending**, until the next `identify()` or `start()`:

```swift
SwrveSDK.stopTracking()
```

## Good to know

- **Call `identify()` when you learn who the user is, not on every launch.** Sign-in, or restoring a session from your own store. This sample uses a button for that reason.
- **You can identify again without stopping tracking.** Calling `identify()` with a different ID switches to that user directly; `stopTracking()` is for signing out, not a prerequisite for switching.
- **Retrying a failed `identify()` is your responsibility — the SDK does not.** The usual cause is no or poor network. Decide your own policy: retry on a timer, on the next app foreground, or the next time the user acts. This sample deliberately does not retry; it shows the error and leaves the next attempt to you.
- **Identify results are cached, so repeat calls do not hit the network.** Once an ID has been identified successfully on this device it is stored locally, and identifying as that user again resolves from the cache — the callback reports that it was loaded from cache. So the network dependency applies to the *first* successful identify for a user on a device.
- **`stopTracking()` does not clear the user.** The SDK keeps the last user ID and simply stops sending; this sample keeps showing it for that reason. Calling `start()` resumes with that same user.
- **`autoStartLastUser` decides what happens at launch.** `false` (used here) means nothing is tracked until `identify()` or `start()`, on every launch. The default `true` starts tracking immediately — anonymously the first time, but as the **last identified user** on any launch after a successful `identify()`, not anonymously again. Flip the line in `IdentitySampleApp.swift` to compare; the sample sends an event either side of `identify()` so you can see where each lands, and its on-screen text reports which case applies.
- **Anonymous activity is only kept for a user Swrve has not seen before.** If the ID you pass is new, the anonymous user becomes the identified user and everything it did carries over. If Swrve already knows that ID — signed in on another device, or a reinstall — the SDK switches to the existing user, and activity recorded anonymously before sign-in stays behind. The `status` argument tells you which happened.
- **`swrveUserId` is not the external user ID you passed in.** It is Swrve's own ID for the user it resolved to — the sample shows both, side by side. Identifying as a *new* ID usually adopts the current anonymous Swrve ID, but if that one is already claimed by an earlier identify a fresh one is generated. So two new IDs in a row give two unrelated Swrve IDs, neither resembling what you typed.
- **`started()` means "the SDK is sending data", not "this user is identified".** A failed `identify()` is the clearest case: the error path switches back to the anonymous user and *starts* tracking it, so `started()` returns true when nobody identified. Keep your own flag, as this sample does, and handle the error rather than assuming success.
- **With `autoStartLastUser = false`, tracking does not resume on a later launch**, even for a previously identified user — the app has to call `identify()` (or `start()`) again. Keep the external user ID in your own storage for that. `SwrveSDK.externalUserId()` would also answer here — it does not need the SDK started — but your app already knows who is signed in, and that is what it passes to `identify()`. Your own auth state is the source of truth; the SDK's copy is a mirror of the last `identify()`. The sample uses `UserDefaults` to stand in.
- **External user IDs should not be personal information.** No email addresses or phone numbers; the API may reject them.
- **MANAGED mode is not covered.** `identify()` is for AUTO mode, the default. MANAGED mode uses `start(withUserId:)` instead and the two cannot be mixed in one app. Talk to your Swrve contact if you think you need MANAGED.
- **Credentials here are sample-grade.** Hardcoding an API key in source is fine for a sample and wrong for a real app.
