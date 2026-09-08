import SwiftUI
import SwrveSDK

struct MessageCenterView: View {

    @StateObject private var store = MessageCenterStore.shared

    @State private var didInitialFetch = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    header
                }

                if store.campaigns.isEmpty {
                    Text(
                        "No Message Center campaigns.\n\nCreate an in-app campaign in Swrve, tick "
                            + "\"Message Center\", and make yourself a QA user. Pull down to refresh."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                } else {
                    ForEach(store.campaigns) { item in
                        row(item)
                    }
                }
            }
            .listStyle(.plain)
            .refreshable { await refreshContent() }
            .task {
                guard !didInitialFetch else { return }
                didInitialFetch = true
                await refreshContent()
            }
            .onAppear { store.reload() }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Message Center Sample")
                .font(.title2.bold())

            Image("mg-full-logo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 140)

            Text(verbatim: "Swrve SDK \(SwrveSDK.sdkVersion())")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(verbatim: "User ID: \(SwrveSDK.userID())")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Text("\(store.campaigns.count) IAM\(store.campaigns.count == 1 ? "" : "s") · \(store.campaigns.filter(\.unseen).count) unseen")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .listRowSeparator(.hidden)
    }

    private func row(_ item: MessageCenterItem) -> some View {
        HStack(spacing: 10) {
            // Stripe, bold title and accessibility value together: colour alone reaches neither screen readers nor colour-blind users.
            Rectangle()
                .fill(item.unseen ? Color.accentColor : Color.clear)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.headline)
                    .fontWeight(item.unseen ? .bold : .regular)
                    .lineLimit(1)

                if let description = item.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack {
                    // verbatim: SwiftUI localises interpolated numbers; an ID is not a quantity.
                    Text(verbatim: "ID \(item.id)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Mark seen") { markSeen(item.id) }
                    Button("Remove") { remove(item.id) }
                }
                .font(.caption)
                .buttonStyle(.borderless)
            }
            .padding(.vertical, 4)
        }
        .padding(.trailing, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        // Tapping the row shows the in-app message.
        .contentShape(Rectangle())
        .onTapGesture { open(item.id) }
        // Combining reads the row as one item but swallows the buttons, so each operation is re-exposed as a named action below.
        .accessibilityElement(children: .combine)
        .accessibilityValue(item.unseen ? "Unseen" : "Seen")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { open(item.id) }
        .accessibilityAction(named: "Mark seen") { markSeen(item.id) }
        .accessibilityAction(named: "Remove") { remove(item.id) }
    }

    // MARK: - SDK calls

    /// Asks the server for new content. The SDK also refreshes on its own schedule, so an app does not have to call this.
    private func refreshContent() async {
        await withCheckedContinuation { continuation in
            SwrveSDK.refreshContent(RefreshListener { continuation.resume() })
        }
        store.reload()
    }

    /// Displays the in-app message, which marks the campaign Seen as a side effect. No reload here — that has not happened yet, and the store handles it when the SDK reports the action.
    private func open(_ id: UInt) {
        if let campaign = SwrveSDK.messageCenterCampaign(withID: id, andPersonalization: [:]) {
            _ = SwrveSDK.showMessageCenter(campaign)
        }
    }

    private func markSeen(_ id: UInt) {
        SwrveSDK.markMessageCenterCampaignAsSeen(id)
        store.reload()
    }

    private func remove(_ id: UInt) {
        SwrveSDK.removeMessageCenterCampaign(id)
        store.reload()
    }
}

/// `SwrveRefreshContentDelegate` is a protocol, not a closure, so it needs a conforming object.
private final class RefreshListener: NSObject, SwrveRefreshContentDelegate {
    private let onDone: () -> Void

    init(_ onDone: @escaping () -> Void) {
        self.onDone = onDone
    }

    func onComplete(_ result: SwrveRefreshContentResult) {
        print("refreshContent finished: \(result.resultCode) \(result.errorMessage)")
        onDone()
    }
}
