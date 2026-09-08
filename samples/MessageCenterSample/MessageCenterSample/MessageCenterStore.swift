import SwiftUI
import SwrveSDK

/// What one row shows, copied out of the SDK's campaign object. A value type, so SwiftUI can see that a campaign became Seen.
struct MessageCenterItem: Identifiable {
    let id: UInt
    let title: String
    let description: String?
    let unseen: Bool
}

/// Holds the Message Center campaigns for the whole app.
///
/// Also the SDK's in-app message delegate: showing a campaign marks it Seen only once the SDK displays the message, not when `showMessageCenter` returns,
/// so the delegate is the point at which a re-read sees the change. The SDK holds it weakly, so this has to be something that stays alive.
final class MessageCenterStore: NSObject, ObservableObject {

    static let shared = MessageCenterStore()

    @Published private(set) var campaigns: [MessageCenterItem] = []

    private override init() { super.init() }

    /// Re-reads the SDK's local state — no network. Needed after every action: the campaigns returned are a snapshot, so marking one seen or removing it changes what the *next* call returns.
    /// Orientation filters them too, hence reading it here.
    @MainActor
    func reload() {
        let orientation =
            UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.interfaceOrientation }
            .first ?? .portrait

        campaigns = SwrveSDK.inAppMessageCenterCampaignsWith(orientation, withPersonalization: [:])
            .map { campaign in
                // Subject and description are optional dashboard fields, so fall back to the name.
                MessageCenterItem(
                    id: campaign.ID,
                    title: campaign.messageCenterDetails?.subject ?? campaign.name,
                    description: campaign.messageCenterDetails?.descriptionText,
                    unseen: campaign.state.status != .seen
                )
            }
    }
}

extension MessageCenterStore: SwrveCampaignsUpdateDelegate {
    /// Fires after the initial content load attempt, and again when fetched content may have changed the campaigns — including once the SDK has attempted their asset downloads, which is what makes the list populate on a fresh install without polling for it.
    func campaignsUpdated() {
        Task { @MainActor in reload() }
    }
}

extension MessageCenterStore: SwrveInAppMessageDelegate {
    /// Can be called more than once per message. Only the impression changes campaign state — the rest are listed so it is clear what else this delegate reports.
    func onAction(
        _ messageAction: SwrveMessageAction,
        messageDetails: SwrveMessageDetails,
        selectedButton: SwrveMessageButtonDetails?
    ) {
        switch messageAction {
        case .impression:
            // Displaying the message is what marks the campaign Seen.
            Task { @MainActor in reload() }
        case .custom:
            // A custom action or deeplink. The SDK opens the URL unless a SwrveDeeplinkDelegate is set.
            break
        case .clipboard, .dismiss:
            break
        }
    }
}
