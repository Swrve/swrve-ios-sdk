# Push Inbox Sample

Building an inbox screen from Push Inbox messages, in SwiftUI.

Push Inbox pairs a push notification with a copy of its content kept in the app, so a user who missed or dismissed the notification can still find the message later.

## Why this exists

The SDK deliberately ships no UI for this. `customerJson` is handed to you untouched and you build the screen, which means every app adopting Push Inbox writes this from scratch with nothing to copy. This sample is that reference.

The API is small — four calls and a delegate. Most of what is worth knowing is in the behaviour around them: which calls send events, which need network, and what the payload does and does not guarantee. That is what [Good to know](#good-to-know) covers.

## Setup

1. `pod install`, then open `PushInboxSample.xcworkspace` (not the `.xcodeproj`).
2. In [`PushInboxSampleApp.swift`](PushInboxSample/PushInboxSampleApp.swift), replace `YOUR_APP_ID` and `YOUR_API_KEY` with your own, from the Swrve dashboard under **Settings → Integration settings**.
3. Run the app, enter an external user ID on the **Home** tab, and press **Identify**.
4. Open the **Inbox** tab.

No push setup is needed — no push capability, no notification permission, no service extension. There are no identifiers to change either, so this runs as-is.

## Seeing real messages

Inbox content arrives in the same content response as campaigns, **not** in the notification. So the inbox fills up whether or not this app can receive push — and whether or not the user has granted notification permission.

The quickest way to see a message:

1. Run the app and copy the user ID from the **Home** tab.
2. Send a campaign with inbox content to that user.
3. Reopen the app.

**To see the state sync**, identify as one of your own users first and send the campaign to that external ID instead. Identify as the same user on a second device and the messages you have already read are already read there.

Either way, send to whichever user the app is currently acting as — the ID on the Home tab. Send to a different one and the inbox simply looks empty.

## Key API calls

The SDK-facing code is in four small files, so it is worth reading all of them:

| File | What it does |
| --- | --- |
| [`PushInboxSampleApp.swift`](PushInboxSample/PushInboxSampleApp.swift) | Creates the SDK and registers the update delegate |
| [`InboxStore.swift`](PushInboxSample/InboxStore.swift) | Holds the inbox for the whole app |
| [`InboxMessage.swift`](PushInboxSample/InboxMessage.swift) | Parses `customerJson` into something the UI can render |
| [`PushInboxView.swift`](PushInboxSample/PushInboxView.swift) | Identify, and the read / engage / delete calls |

**Fetch the list.** No network — this reads what the SDK already holds:

```swift
let messages = SwrveSDK.pushInboxMessages()
```

Each message carries a `state` of `.READ` or `.UNREAD` — that is what a row branches on to show unread differently.

**Be told when it changes** — including when a content refresh brings new messages in while the app is open:

```swift
SwrveSDK.pushInboxUpdateListener(InboxStore.shared)
```

**Act on a message.** Each takes a delegate that reports the outcome:

```swift
SwrveSDK.readPushInboxMessage(messageId, listener: delegate)    // the user opened it
SwrveSDK.engagePushInboxMessage(messageId, listener: delegate)  // the user followed its action
SwrveSDK.deletePushInboxMessage(messageId, listener: delegate)  // the user dismissed it
```

**Parse your own payload.** `customerJson` is the inbox content carried by the campaign that sent the message, so it is defined where you compose the campaign rather than in your app. The SDK passes it through untouched, so modelling and parsing it is yours to do; see [`InboxMessage.swift`](PushInboxSample/InboxMessage.swift). Example below:

```json
{
  "subject": "Your order has shipped",
  "message": "Track your package and estimated delivery date.",
  "thumbnail": "https://example.com/shipped.png",
  "action_type": "deeplink",
  "action_value": "myapp://orders/48213",
  "advancedOptions": { }
}
```

## Good to know

- **`read` and `engage` mean different things.** `read` is the message being opened; `engage` is the user following its action — the **Open** button here. This sample puts them on separate gestures so both are visible: opening the detail screen reads, the button engages.
- **`read` and `delete` send an event only when they change something**, so marking an already-read message as read sends nothing. `engage` records a user action, so it fires every time.
- **Every call needs network, so failure is normal rather than exceptional.** The delegate tells you the outcome, and this sample re-reads the list on success and failure alike — so a failed `read` leaves the message unread on screen instead of lying about it.
- **The inbox belongs to the user, not to a screen.** So this sample keeps it in [`InboxStore`](PushInboxSample/InboxStore.swift) and registers the update delegate at app start. Screens observe the store rather than owning the state, and the delegate outlives any of them — which is what a singleton guarantees.
- **Everything but `message` is optional, so a row has to look right without it** — and `customerJson` itself may be absent entirely. This sample falls back to the body text as the title when there is no subject, and simply omits the thumbnail and the button. Anything app-specific belongs in `advancedOptions`.
- **`action_type` and `action_value` are part of your payload, so what they mean is yours to decide.** `action_type` varies with how the campaign was composed, so this sample keys off the value instead: if there is a URL, the **Open** button opens it. Expect nothing to handle it here, since your campaigns point at your app rather than this one.
- **Expiry is handled for you.** Each message carries an `endDate` set by the sender, and the SDK filters out anything past it before you see the list — so no expiry checks of your own are needed.
- **Read and delete state lives on the server, not the device.** So identify as the same user on another device and the messages you have already read are already read there too. That is why identify is here at all — it is not needed to receive messages, and a campaign can target the Swrve user ID this app shows on its own.
- **Identify is kept to one field and one button**, since the inbox is the subject here. [IdentitySample](../IdentitySample) covers it properly, including what a failed identify leaves the SDK doing.
- **The detail screen can show the raw `customerJson`.** Collapsed behind a toggle, and a debug aid for this sample only — a real inbox renders the payload rather than displaying it. Seeing it next to the screen built from it makes the mapping concrete.
- **Credentials here are sample-grade.** Hardcoding an API key in source is fine for a sample and wrong for a real app.
