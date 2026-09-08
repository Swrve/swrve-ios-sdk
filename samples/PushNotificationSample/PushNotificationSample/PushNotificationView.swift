import SwiftUI
import SwrveSDK
import UserNotifications

struct PushNotificationView: View {

    @State private var permissionGranted = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Push Notification Sample")
                    .font(.title2.bold())

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

                Spacer().frame(height: 12)

                Text("Have a look at the code!")
                    .font(.subheadline)

                if permissionGranted {
                    Text("✓ Notification permission granted")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    // Sending an event named in pushNotificationPermissionEvents makes Swrve
                    // trigger the OS prompt. A shortcut for testing — a real app asks with a
                    // campaign instead, see the README.
                    Button("Request notification permission") {
                        _ = SwrveSDK.event(EVENT_REQUEST_PUSH_PERMISSION)
                    }
                    .buttonStyle(.borderedProminent)

                    // The OS shows the prompt once. After a decline the button does nothing, so say
                    // so rather than leaving it looking broken.
                    Text("If nothing happens, notifications were declined previously — enable them in Settings.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
        }
        // Re-read on appear and on foreground: the OS prompt and the Settings screen both leave
        // and return to the app.
        .task { await readPermission() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task { await readPermission() }
        }
    }

    private func readPermission() async {
        permissionGranted =
            await UNUserNotificationCenter.current()
            .notificationSettings().authorizationStatus == .authorized
    }
}
