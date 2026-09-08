import Foundation
import SwrveSDK

/// Holds the inbox for the whole app.
///
/// The inbox belongs to the user rather than to any one screen, so it lives here and screens observe it.
final class InboxStore: NSObject, ObservableObject {

    static let shared = InboxStore()

    @Published private(set) var messages: [InboxMessage] = []
    @Published private(set) var userId: String = ""
    @Published private(set) var externalUserId: String = ""

    private override init() { super.init() }

    /// Re-reads the SDK's local state — no network. Expired messages are already filtered out, so whatever comes back is what should be shown.
    @MainActor
    func reload() {
        messages = SwrveSDK.pushInboxMessages().map(InboxMessage.init)
        userId = SwrveSDK.userID()
        externalUserId = SwrveSDK.externalUserId()
    }
}

extension InboxStore: SwrvePushInboxUpdateDelegate {
    /// The queue the SDK calls back on is not guaranteed, so this hops to the main actor rather than assuming — every published property here feeds the UI.
    func messagesUpdated() {
        Task { @MainActor in reload() }
    }
}

/// Reports the outcome of a read / engage / delete call, then refreshes the list.
///
/// Every one of those calls needs network, so failure is a real possibility rather than an edge case.
/// Reloading either way keeps the UI honest: on failure a message stays unread rather than the screen claiming otherwise.
final class InboxOperationLogger: NSObject, SwrvePushInboxDelegate {

    private let operation: String

    init(_ operation: String) {
        self.operation = operation
    }

    func onComplete(_ messageId: UInt64, result: SwrvePushInboxResult) {
        if result.resultCode == .SUCCESS {
            print("\(operation) \(messageId) succeeded")
        } else {
            print(
                "\(operation) \(messageId) failed: \(result.resultCode.description) "
                    + "http=\(result.httpResponseCode) \(result.errorMessage)")
        }
        Task { @MainActor in InboxStore.shared.reload() }
    }
}
