Swrve SDK Samples
-----------------
Examples of usage of the Swrve SDK:

- [Push Notifications](PushNotificationSample)
- [Multiple Push Providers](MultiplePushProvidersSample)
- [Message Center API](MessageCenterSample)
- [User Identity](IdentitySample)
- [Push Inbox](PushInboxSample)
- [Embedded Campaigns](SwrveEmbeddedSample)

Each sample is a standalone Xcode project — open its `.xcodeproj`, not the SDK repo root. They
consume the published Swrve SDK through Swift Package Manager, and Xcode resolves the package when
the project opens, so no part of this repository needs to be built first.

The samples target a higher iOS version than the SDK does, so they can use SwiftUI. See each
sample's deployment target for its actual value, and the [iOS integration
guide](https://docs.swrve.com/developer-documentation/integration/ios/) for the SDK's own
supported versions.
