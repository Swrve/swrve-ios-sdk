import SwiftUI
import SwrveSDK
import UserNotifications

@MainActor
final class PushActivity: ObservableObject {
    static let shared = PushActivity()

    @Published private(set) var entries: [String] = PushActivityLog.entries
    @Published private(set) var deviceToken: String? = SwrveSDK.deviceToken()

    func record(_ message: String) {
        Task { @MainActor in
            PushActivityLog.record(message)
            reload()
        }
    }

    func clear() {
        PushActivityLog.clear()
        reload()
    }

    /// Picks up anything the extension wrote while the app was not running.
    func reload() {
        entries = PushActivityLog.entries
        deviceToken = SwrveSDK.deviceToken()
    }

    /// Called when relay 1 completes — without this the screen would keep saying there is no token until something else redraws it.
    func tokenRegistered() {
        Task { @MainActor in deviceToken = SwrveSDK.deviceToken() }
    }
}

struct MultiplePushProvidersView: View {

    @ObservedObject private var log = PushActivity.shared
    @State private var permissionGranted = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Multiple Push Providers Sample")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Image("mg-full-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 160)

                Text(verbatim: "Swrve SDK \(SwrveSDK.sdkVersion())")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(verbatim: "User ID: \(SwrveSDK.userID())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer().frame(height: 8)

                Text("Swrve runs alongside another push provider. The app owns registration and the notification callbacks, then relays to Swrve.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Text("Send yourself a push and watch where it goes. Have a look at the code!")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)

                if permissionGranted {
                    Text("✓ Notification permission granted")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Button("Request notification permission") {
                        AppDelegate.requestPermissionAndRegister()
                    }
                    .buttonStyle(.borderedProminent)

                    Text("If nothing happens, notifications were declined previously — enable them in Settings.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                tokenStatus

                activityPanel
            }
            .padding(24)
        }
        .task { await readPermission() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            log.reload()
            Task { await readPermission() }
        }
    }

    // Main-actor isolated: the await resumes off the main thread and this assigns to @State.
    @MainActor
    private func readPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        permissionGranted = settings.authorizationStatus == .authorized
    }

    /// Read back from the SDK, so it also confirms `setDeviceToken` reached Swrve.
    private var tokenStatus: some View {
        Text(
            log.deviceToken.map { "Swrve has the device token (\($0.prefix(8))…)" }
                ?? "No device token yet — grant permission"
        )
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var activityPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Push activity — most recent at top")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                if !log.entries.isEmpty {
                    Button("Clear") { log.clear() }
                        .font(.caption)
                        .buttonStyle(.borderless)
                }
            }

            if log.entries.isEmpty {
                Text(
                    "Nothing yet. Send a push with \"mutable-content\": 1 to see the extension run, or tap a notification to see the response relayed."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            } else {
                ForEach(Array(log.entries.enumerated()), id: \.offset) { _, entry in
                    Text(entry)
                        .font(.caption.monospacedDigit())
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
