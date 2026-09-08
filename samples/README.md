Swrve SDK Samples
-----------------
Examples of usage of the Swrve SDK:

- [Push Notifications](PushNotificationSample)
- [Multiple Push Providers](MultiplePushProvidersSample)
- [Message Center API](MessageCenterSample)
- [User Identity](IdentitySample)
- [Push Inbox](PushInboxSample)
- [Embedded Campaigns](SwrveEmbeddedSample)

Each sample is a standalone Xcode project — open its `.xcworkspace` after running `pod install`,
not the SDK repo root. They consume the published Swrve SDK from CocoaPods, so no part of this
repository needs to be built first.

The samples target a higher iOS version than the SDK does, so they can use SwiftUI. See each
sample's Podfile for its actual value, and the [iOS integration
guide](https://docs.swrve.com/developer-documentation/integration/ios/) for the SDK's own
supported versions.

To build a sample against local SDK source instead of the published pod,
comment out `pod 'SwrveSDK'` in that sample's Podfile and uncomment the two `:path` lines below it.
