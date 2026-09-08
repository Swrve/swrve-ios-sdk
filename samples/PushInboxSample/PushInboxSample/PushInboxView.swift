import SwiftUI
import SwrveSDK

struct PushInboxView: View {

    @StateObject private var store = InboxStore.shared

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }

            InboxListView()
                .tabItem { Label("Inbox", systemImage: "envelope") }
                .badge(store.messages.filter(\.unread).count)
        }
        .onAppear { store.reload() }
    }
}

// MARK: - Home

struct HomeView: View {

    @StateObject private var store = InboxStore.shared

    @State private var externalUserId = ""
    @State private var busy = false
    @State private var error: String?
    @State private var copied = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Push Inbox Sample")
                    .font(.title2.bold())

                Image("mg-full-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 160)
                    .padding(.top, 8)

                Text(verbatim: "Swrve SDK \(SwrveSDK.sdkVersion())")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Text(verbatim: "User ID: \(store.userId)")
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Button {
                        UIPasteboard.general.string = store.userId
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
                    } label: {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Copy user ID")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Text(verbatim: "Identified as: \(store.externalUserId.isEmpty ? "—" : store.externalUserId)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer().frame(height: 24)

                Text(
                    "This sample has no push integration — see PushNotificationSample for that. "
                        + "It does not need one: inbox messages arrive with the regular content fetch, "
                        + "not with the notification."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

                Spacer().frame(height: 24)

                Text("Identify as the user your campaign was sent to, then open the Inbox tab.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)

                TextField("External user ID", text: $externalUserId)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .disabled(busy)
                    .onSubmit(identify)

                Button(busy ? "Identifying…" : "Identify", action: identify)
                    .buttonStyle(.borderedProminent)
                    .disabled(busy || externalUserId.trimmingCharacters(in: .whitespaces).isEmpty)

                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }

    /// Inbox messages belong to a user, so the sample has to be that user before anything appears.
    ///
    /// Kept to one field and one button deliberately — IdentitySample covers identify properly, including what a failure leaves the SDK doing.
    private func identify() {
        let id = externalUserId.trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty else { return }

        busy = true
        error = nil

        SwrveSDK.identify(
            id,
            onSuccess: { status, _ in
                print("identify success: \(status ?? "")")
                // A cached identify completes on the main queue and a network one does not, so dispatch
                // either way rather than depending on it.
                DispatchQueue.main.async {
                    busy = false
                    // The new user's inbox arrives with the next content fetch and the update delegate
                    // fires then. This just clears the previous user's messages in the meantime.
                    InboxStore.shared.reload()
                }
            },
            onError: { code, message in
                print("identify failed: \(code) \(message ?? "")")
                // A failed identify does not leave the SDK where it was — it switches to the
                // unidentified user. Reloading picks that up, so the screen stops claiming a user the
                // SDK is no longer on.
                DispatchQueue.main.async {
                    busy = false
                    error = "Identify failed: \(message ?? "unknown error")"
                    InboxStore.shared.reload()
                }
            })
    }
}

// MARK: - Inbox list

struct InboxListView: View {

    @StateObject private var store = InboxStore.shared

    @State private var path: [InboxMessage] = []

    var body: some View {
        // Path-driven rather than wrapping each row in a NavigationLink: a link swallows taps on the
        // Delete button inside it, so the row handles its own tap and pushes the detail screen.
        NavigationStack(path: $path) {
            Group {
                if store.messages.isEmpty {
                    Text(
                        "No messages for this user.\n\nSend a push with inbox content to them and "
                            + "reopen the app, or identify on the Home tab as the user your campaign targeted."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(32)
                } else {
                    List(store.messages) { message in
                        row(message)
                            .contentShape(Rectangle())
                            .onTapGesture { path.append(message) }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: InboxMessage.self) { message in
                MessageDetailView(message: message)
            }
        }
    }

    private func row(_ message: InboxMessage) -> some View {
        HStack(spacing: 0) {
            // Stripe, bold subject and accessibility value together: colour alone reaches neither
            // screen readers nor colour-blind users.
            Rectangle()
                .fill(message.unread ? Color.accentColor : Color.clear)
                .frame(width: 4)

            content(message)
                .padding(.leading, 12)
                .padding(.vertical, 8)
        }
        .padding(.trailing, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .accessibilityElement(children: .combine)
        .accessibilityValue(message.unread ? "Unread" : "Read")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { path.append(message) }
        .accessibilityAction(named: "Delete") { delete(message) }
    }

    private func content(_ message: InboxMessage) -> some View {
        HStack(spacing: 10) {
            // thumbnail is optional in the schema, so the row has to look right without one.
            if let url = message.thumbnailUrl {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color(.secondarySystemBackground)
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            VStack(alignment: .leading, spacing: 2) {
                // subject is optional too; the body is the only field guaranteed to be there.
                Text(message.subject ?? message.body)
                    .font(.subheadline.weight(message.unread ? .bold : .regular))
                    .lineLimit(1)

                if message.subject != nil {
                    Text(message.body)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Text(message.sentDate, format: .dateTime.day().month().year().hour().minute())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Delete") { delete(message) }
                .font(.caption)
                .buttonStyle(.borderless)
        }
    }

    private func delete(_ message: InboxMessage) {
        SwrveSDK.deletePushInboxMessage(message.id, listener: InboxOperationLogger("delete"))
    }
}

// MARK: - Detail

struct MessageDetailView: View {

    let message: InboxMessage

    @State private var showRawPayload = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let url = message.thumbnailUrl {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color(.secondarySystemBackground)
                    }
                    .frame(height: 160)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                if let subject = message.subject {
                    Text(subject).font(.title3.bold())
                }

                Text(message.sentDate, format: .dateTime.day().month().year().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(message.body).font(.body)

                // Engaging is the user acting on the message, which is why it lives on this button rather than on opening the screen.
                // Keyed on action_value, not action_type: the type varies with how the campaign was composed, while the value is a URL either way.
                if let actionValue = message.actionValue, let url = URL(string: actionValue) {
                    Button("Open") {
                        SwrveSDK.engagePushInboxMessage(message.id, listener: InboxOperationLogger("engage"))
                        // The link is followed regardless of whether engage succeeds — the user
                        // asked to go somewhere, and analytics failing is no reason to refuse.
                        UIApplication.shared.open(url)
                    }
                    .buttonStyle(.borderedProminent)
                }

                rawPayloadPanel
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .navigationTitle("Message")
        .navigationBarTitleDisplayMode(.inline)
        // Opening a message is where `read` belongs — distinct from `engage`, which is the user following its action. Skipped when the message
        // is already read, so the call says what it means rather than relying on the SDK treating it as a no-op.
        .task {
            guard message.unread else { return }
            SwrveSDK.readPushInboxMessage(message.id, listener: InboxOperationLogger("read"))
        }
    }

    /// Debug aid for this sample only — a real inbox renders the payload rather than displaying it.
    /// Seeing it next to the screen built from it makes the mapping concrete.
    private var rawPayloadPanel: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(showRawPayload ? "Hide customer_json" : "Show customer_json") {
                showRawPayload.toggle()
            }
            .font(.caption)

            if showRawPayload {
                Text(message.rawCustomerJson)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 6))
            }
        }
    }
}
