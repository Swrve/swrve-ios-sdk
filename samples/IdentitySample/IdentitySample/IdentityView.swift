import SwiftUI
import SwrveSDK

/// What the screen shows. `sdkTracking` and `identified` answer different questions and can
/// disagree — a failed identify() leaves the SDK tracking the unidentified user.
struct IdentityUiState {
    var sdkTracking: Bool
    var identified: Bool
    /// The ID passed to identify(), for contrast with the Swrve one.
    var externalUserId: String
    var swrveUserId: String
    var status: String
}

struct IdentityView: View {

    @State private var state = IdentityView.initialState()
    @State private var busy = false
    @State private var typedUserId = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Identity Sample")
                    .font(.title2.bold())

                Image("mg-full-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 160)

                Text(verbatim: "Swrve SDK \(SwrveSDK.sdkVersion())")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(intro)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)

                // Stays available after identifying, so you can identify again as someone else.
                TextField("External user ID", text: $typedUserId)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .disabled(busy)

                Text("Your own ID for this user — what you pass to identify()")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button(busy ? "Identifying…" : "Identify") {
                        identify(typedUserId.trimmingCharacters(in: .whitespaces))
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(busy || typedUserId.trimmingCharacters(in: .whitespaces).isEmpty)

                    Button("Stop tracking") { stopTracking() }
                        .buttonStyle(.bordered)
                        .disabled(!state.sdkTracking)
                }

                statusPanel
            }
            .padding(24)
        }
    }

    /// `sdkTracking` and `identified` are shown together because they can legitimately disagree.
    private var statusPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            labelled("SDK tracking", state.sdkTracking ? "yes" : "no")
            labelled("Identified", state.identified ? "yes" : "no")
            labelled("External user ID", state.externalUserId.isEmpty ? "—" : state.externalUserId)

            // Swrve's own ID for the user it resolved to — not the ID you passed in.
            labelled("Swrve user ID", state.swrveUserId)

            Divider()

            // Wraps rather than scaling: some status values are full sentences.
            VStack(alignment: .leading, spacing: 2) {
                Text("Identify status")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(state.status)
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
    }

    private func labelled(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value)
                .font(.callout.monospaced())
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }

    /// Follows the config and the current state — "tracking anonymously" is only true before the
    /// first identify. After one, autoStartLastUser resumes as that user on the next launch.
    private var intro: String {
        let suffix = " Identify again with a different ID to switch user — no need to stop tracking first."
        if !SwrveSDK.config().autoStartLastUser {
            return "autoStartLastUser is false, so nothing is tracked until you identify." + suffix
        }
        if !state.sdkTracking {
            return "autoStartLastUser is true, but tracking is stopped until you identify or start again." + suffix
        }
        if state.identified {
            return "autoStartLastUser is true, so the SDK resumed tracking as the user identified previously — not anonymously." + suffix
        }
        return "autoStartLastUser is true, so the SDK is tracking anonymously until you identify." + suffix
    }

    /// Links this device to your own ID for the user. Called from a button rather than at startup,
    /// which is the point — call it when you actually learn who the user is.
    private func identify(_ externalUserId: String) {
        busy = true

        // Fired before identify so you can watch where it lands in Swrve. With
        // autoStartLastUser = false the SDK is not tracking yet, so this one is dropped.
        SwrveSDK.event(EVENT_BEFORE_IDENTIFY)

        SwrveSDK.identify(
            externalUserId,
            onSuccess: { status, swrveUserId in
                print("identify success: status=\(status ?? "") swrveId=\(swrveUserId ?? "")")

                // Remembered by the app, so the next launch can show it and re-identify.
                UserDefaults.standard.set(externalUserId, forKey: IdentityView.externalIdKey)

                // The SDK is now tracking, so this event is attributed to the identified user.
                SwrveSDK.event(EVENT_AFTER_IDENTIFY)

                // Callbacks arrive off the main thread, and only the UI state needs to be on it.
                DispatchQueue.main.async {
                    busy = false
                    state = IdentityView.readState(
                        identified: true,
                        externalUserId: externalUserId,
                        status: status ?? "Identified"
                    )
                }
            },
            onError: { httpCode, errorMessage in
                print("identify failed: \(httpCode) \(errorMessage ?? "")")
                DispatchQueue.main.async {
                    busy = false
                    // Not identified — but the SDK is now tracking the unidentified user, so
                    // started() would say true. Identity state has to be the app's own.
                    state = IdentityView.readState(
                        identified: false,
                        externalUserId: externalUserId,
                        status: "Error \(httpCode): \(errorMessage ?? "")"
                    )
                }
            }
        )
    }

    /// The SDK keeps the current user but sends nothing until start() or identify() is called.
    private func stopTracking() {
        SwrveSDK.stopTracking()
        state = IdentityView.readState(
            identified: false,
            externalUserId: state.externalUserId,
            status: "Stopped tracking"
        )
    }

    // MARK: - State

    private static let externalIdKey = "identity_sample_external_user_id"

    /// The ID comes from this app's own storage — your app knows who is signed in, Swrve does not.
    private static func initialState() -> IdentityUiState {
        let previous = UserDefaults.standard.string(forKey: externalIdKey) ?? ""
        // Started is not the same as identified: with autoStartLastUser = true the SDK is started
        // from launch even before anyone has identified.
        let identified = !previous.isEmpty && SwrveSDK.started()
        let status: String
        if identified {
            status = "Identified on a previous launch"
        } else if !previous.isEmpty {
            status = "Identified previously — identify again to resume tracking"
        } else {
            status = "Not identified yet"
        }
        return IdentityUiState(
            sdkTracking: SwrveSDK.started(),
            identified: identified,
            externalUserId: previous,
            swrveUserId: SwrveSDK.userID(),
            status: status
        )
    }

    /// `identified` is passed in rather than derived — a failed identify leaves the SDK tracking
    /// the unidentified user, so started() would say yes when nobody identified.
    private static func readState(identified: Bool, externalUserId: String, status: String) -> IdentityUiState {
        IdentityUiState(
            sdkTracking: SwrveSDK.started(),
            identified: identified,
            externalUserId: externalUserId,
            swrveUserId: SwrveSDK.userID(),
            status: status
        )
    }
}
