import SwrveSDKCommon
import UserNotifications

/// Rich push — images, buttons and influence tracking — needs this extension. Without it the
/// notification still arrives, but only as plain text.
class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler

        // Set before the async work: if media download runs past the extension's time limit,
        // serviceExtensionTimeWillExpire still has something to deliver.
        bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent

        // Must match config.appGroupIdentifier and the entitlements, or influence tracking
        // silently stops working.
        SwrvePush.handle(request.content, withAppGroupIdentifier: APP_GROUP) { content in
            self.bestAttemptContent = content
            contentHandler(content)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler, let bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}

/// Shared with the app, which declares its own copy. Both must match the
/// `com.apple.security.application-groups` entry in all three `.entitlements` files.
let APP_GROUP = "group.swrve.RichPushSample"
