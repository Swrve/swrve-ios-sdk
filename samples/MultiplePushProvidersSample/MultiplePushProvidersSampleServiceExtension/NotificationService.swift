import SwrveSDKCommon
import UserNotifications

/// Every notification for the app arrives here, whichever provider sent it, and there is only one extension — so this is where the two providers most directly collide.
class NotificationService: UNNotificationServiceExtension {

    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler

        // Set before the async work: if media download runs past the extension's time limit, serviceExtensionTimeWillExpire still has something to deliver.
        bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent

        // RELAY 3 of 3, and the one place worth deciding rather than telling both. Swrve is safe to call either way, but the other provider may mishandle a payload it does not recognise.
        guard SwrvePush.isSwrvePush(request.content.userInfo) else {
            PushActivityLog.record("Extension: not a Swrve push → other provider")

            // Your other provider's handler goes here; it calls deliver when it is done.
            deliver(request.content)
            return
        }

        PushActivityLog.record("Extension: Swrve push → SwrvePush.handle")
        SwrvePush.handle(request.content, withAppGroupIdentifier: APP_GROUP) { content in
            self.bestAttemptContent = content
            self.deliver(content)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let bestAttemptContent {
            deliver(bestAttemptContent)
        }
    }

    /// Must be called exactly once. A provider that never calls back leaves the timeout to deliver; one that calls back late would deliver twice. Whichever path arrives first wins.
    private func deliver(_ content: UNNotificationContent) {
        guard let handler = contentHandler else { return }
        contentHandler = nil
        handler(content)
    }
}

/// Shared with the app, which declares its own copy. Both must match the `com.apple.security.application-groups` entry in both `.entitlements` files.
let APP_GROUP = "group.swrve.RichPushSample"
