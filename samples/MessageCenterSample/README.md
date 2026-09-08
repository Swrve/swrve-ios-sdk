# Message Center Sample

Listing and managing Message Center in-app campaigns, in SwiftUI.

Message Center campaigns are in-app messages the SDK holds back rather than showing automatically, so your app can list them somewhere of its own and let the user open them when they choose.

## Why this exists

The list is not a feed you subscribe to — it is a snapshot you fetch. Campaigns appear once their assets have downloaded, they are filtered by device orientation, and marking one seen or removing it changes what the *next* fetch returns rather than mutating the list you are holding. Miss that and the UI silently stops matching the SDK's state.

## Setup

1. `pod install`, then open `MessageCenterSample.xcworkspace` (not the `.xcodeproj`).
2. In [`MessageCenterSampleApp.swift`](MessageCenterSample/MessageCenterSampleApp.swift), replace `YOUR_APP_ID` and `YOUR_API_KEY` with your own, from the Swrve dashboard under **Settings → Integration settings**.
3. Run the app.

To see anything in the list, create an in-app campaign with **Message Center** enabled and make sure it targets your test device.

## Key API calls

The SDK-facing code is in three small files:

| File | What it does |
| --- | --- |
| [`MessageCenterSampleApp.swift`](MessageCenterSample/MessageCenterSampleApp.swift) | Creates the SDK and registers the in-app message delegate |
| [`MessageCenterStore.swift`](MessageCenterSample/MessageCenterStore.swift) | Holds the campaigns, and re-reads them when one is shown or when the SDK reports a change |
| [`MessageCenterView.swift`](MessageCenterSample/MessageCenterView.swift) | The list, and the show / mark seen / remove calls |

**Fetch the list**, filtered to in-app campaigns for the current orientation:

```swift
let campaigns = SwrveSDK.inAppMessageCenterCampaignsWith(orientation, withPersonalization: [:])
```

**Act on a campaign** — display it, mark it seen without displaying, or remove it. Each takes either the campaign object or its ID; this sample uses IDs, because it keeps the mutable SDK objects out of its view state (see the last point below):

```swift
SwrveSDK.messageCenterCampaign(withID: id, andPersonalization: [:]).map { SwrveSDK.showMessageCenter($0) }
SwrveSDK.markMessageCenterCampaignAsSeen(id)
SwrveSDK.removeMessageCenterCampaign(id)
```

**Be told when campaigns change** — including once their assets have downloaded, and whenever a later content refresh brings new ones in:

```swift
SwrveSDK.campaignsUpdateListener(MessageCenterStore.shared)
```

Later calls mean the campaigns *may* have changed — the SDK does not compare against what you last read, so treat every call as "read again". Register it at SDK init rather than from a view: the first notification is sent once and never replayed, so a view registering later misses it. The SDK holds it weakly, so it has to be something that stays alive. It covers every campaign surface, not just Message Center.

It reports SDK-driven changes only. Your own `markMessageCenterCampaignAsSeen` and `removeMessageCenterCampaign` calls change what the getters return without firing it, which is why the re-fetch note below matters.

It says to read again, not that you must redraw immediately. This sample re-reads straight away, which is the simplest thing to show, but a list someone is mid-scroll through is a different case. Note it arrives with no user gesture: the SDK refreshes on its own schedule, so the callback can come while the screen is simply open — pull-to-refresh below is a separate, user-initiated path.

**Fetch new content on demand** — wired to pull-to-refresh in this sample — then re-read the list when it completes:

```swift
SwrveSDK.refreshContent(listener) // listener conforms to SwrveRefreshContentDelegate
```

## Good to know

- **A campaign is not listable until its assets have downloaded.** That happens *after* the content response arrives, so fetching once and reading immediately finds nothing on a fresh install. `SwrveCampaignsUpdateDelegate` exists for this: it fires once the SDK has finished attempting those downloads, so there is nothing to poll or delay. Individual downloads can still fail, so re-read the list rather than assuming every campaign is now present.
- **Re-fetch after every action.** The campaigns you hold are a snapshot. `markMessageCenterCampaignAsSeen` and `removeMessageCenterCampaign` change what the next `inAppMessageCenterCampaignsWith` call returns; they do not update your list.
- **`showMessageCenter` marks the campaign seen, but only once the message is displayed** — which is after the call returns. To keep a list in step, refresh when `SwrveInAppMessageDelegate` reports `.impression`, as [`MessageCenterStore`](MessageCenterSample/MessageCenterStore.swift) does. The separate `markMessageCenterCampaignAsSeen` is for marking one seen *without* displaying it.
- **Orientation filters the results.** A campaign with no format for the current orientation is omitted, so passing the wrong value makes campaigns look missing. This sample reads it from the active window scene.
- **`SwrveRefreshContentDelegate` is a protocol, not a closure.** It needs a small conforming object; the sample wraps one so the call can be awaited.
- **Do not hold campaign objects as view state.** Marking a campaign seen mutates the campaign in place, and the SDK returns the same instances each time — so a re-read yields a new array of identical references and SwiftUI sees no change. The status updates in the SDK and never reaches the screen. This sample copies the values it needs into an immutable `MessageCenterItem` instead.
- **This sample covers in-app campaigns only.** `inAppMessageCenterCampaignsWith` deliberately excludes embedded campaigns; for those see [SwrveEmbeddedSample](../SwrveEmbeddedSample).
- **Not every field is shown.** Subject and description are optional, so the sample falls back to the campaign name. `SwrveMessageCenterDetails` also carries `image`, `imageUrl` and `imageSha`, which this sample does not render.
- **Credentials here are sample-grade.** Hardcoding an API key in source is fine for a sample and wrong for a real app.
