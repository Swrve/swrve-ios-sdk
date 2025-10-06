import SwiftUI
import SwrveSDK

struct SetupView: View {
    @State private var appIdString: String = ""
    @State private var apiKey: String = ""
    @State private var stack: String = "us"
    @State private var didLoad = false
    @State private var feedbackMessage: String? = nil
    @State private var isRefreshing = false
    @State private var isIdentifying = false
    @State private var refreshMessage: String? = nil
    @State private var userPropKey: String = ""
    @State private var userPropValue: String = ""
    @State private var userPropFeedback: String? = nil
    @State private var currentUserId: String = ""
    @State private var identifyInput: String = ""
    @State private var embeddedCampaignCount: Int = 0
    @State private var offlineMode: Bool = SwrveCredentialStore.isOfflineMode()

    private var liveContentButtonBackground: Color { Color(.secondarySystemFill) }
    private var liveContentButtonBorder: Color { Color(.tertiaryLabel).opacity(0.14) }

    var body: some View {
        VStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Setup")
                    .font(.largeTitle.weight(.bold))
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("User Id: \(currentUserId)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if !currentUserId.isEmpty {
                        Button(action: copyCurrentUserId) {
                            HStack(spacing: 2) {
                                Image(systemName: "doc.on.doc")
                                Text("Copy")
                            }
                            .font(.caption2)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 6)
                            .background(Color(.tertiarySystemFill))
                            .foregroundColor(.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Copy user id")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Section: Content Mode + Credentials + Save
            VStack(alignment: .leading, spacing: 20) {
                // Content Mode toggle (Live / Offline Demo)
                HStack(spacing: 12) {
                    Text("Content Mode").font(.caption.weight(.medium))
                    Spacer()
                    Picker("", selection: $offlineMode) {
                        Text("Live").tag(false)
                        Text("Offline").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 180)
                }
                .padding(.horizontal, 4)

                // Credentials row (AppID, API Key, Stack)
                if !offlineMode {
                    credentialsSection()
                }

                // Save button
                Button(action: save) {
                    Text("Save - requires restart")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.gradient)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .shadow(color: Color.accentColor.opacity(0.25), radius: 4, x: 0, y: 2)
            }
            .animation(.easeInOut, value: offlineMode)
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            // Identify row + Refresh Content + User Property Sender (hide when offline)
            if !offlineMode {
                identifySection()
                refreshButtonSection()
                userPropertySection()
            }

            Group {
                if let userPropFeedback { Text(userPropFeedback) }
                if let refreshMessage { Text(refreshMessage) }
                if let feedbackMessage { Text(feedbackMessage) }
            }
            .font(.footnote)
            .foregroundColor(.secondary)
            .transition(.opacity)

            Spacer()
        }
        .padding()
        .onAppear(perform: load)
    }

    private func load() {
        guard !didLoad else { return }
        let creds = SwrveCredentialStore.load()
        appIdString = String(creds.appId)
        apiKey = creds.apiKey
        if let storedStack = UserDefaults.standard.string(forKey: "SwrveSample_Stack"), ["us", "eu", "fs"].contains(storedStack) {
            stack = storedStack
        }
        offlineMode = SwrveCredentialStore.isOfflineMode()
        didLoad = true
        currentUserId = SwrveSDK.userID()
        identifyInput = SwrveSDK.externalUserId()
        updateEmbeddedCampaignCount()
    }

    private func save() {
        let trimmedAppIdString = appIdString.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedApiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedAppIdString.count > 2,
            let appId = Int(trimmedAppIdString), appId > 0,
            trimmedApiKey.count > 2
        else {
            feedbackMessage = "Invalid values"
            return
        }
        SwrveCredentialStore.save(appId: appId, apiKey: apiKey)
        if ["us", "eu", "fs"].contains(stack) {
            UserDefaults.standard.set(stack, forKey: "SwrveSample_Stack")
        } else {
            stack = "us"
            UserDefaults.standard.set(stack, forKey: "SwrveSample_Stack")
        }
        SwrveCredentialStore.setOfflineMode(offlineMode)
        feedbackMessage = "Saved. Restart app to fully apply."
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { feedbackMessage = nil }
    }

    private func refreshContent() {
        let inUseAppId = SwrveSDK.appID()
        let inUseApiKey = SwrveSDK.apiKey()
        refreshMessage = "Refreshing content using creds \(inUseAppId)/\(inUseApiKey)\n"
        isRefreshing = true
        let listener = RefreshListener { result in
            DispatchQueue.main.async {
                isRefreshing = false
                switch result.resultCode {
                case .SUCCESS:
                    refreshMessage! += "Refresh succeeded for appId \(inUseAppId) (HTTP \(result.httpResponseCode))"
                case .ERROR, .ERROR_UNKNOWN:
                    let codeDesc = result.resultCode.description
                    var parts: [String] = ["Refresh failed ("]
                    parts.append(codeDesc)
                    if !result.errorMessage.isEmpty { parts.append(": \(result.errorMessage)") }
                    parts.append(") HTTP \(result.httpResponseCode)")
                    refreshMessage! += parts.joined()
                @unknown default:
                    refreshMessage! += "Refresh completed with unknown state"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { if !isRefreshing { refreshMessage = nil } }
                updateEmbeddedCampaignCount()
            }
        }
        SwrveSDK.refreshContent(listener)
    }

    private func identify() {
        let text = identifyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        isIdentifying = true
        guard !text.isEmpty else {
            feedbackMessage = "External user id required"
            isIdentifying = false
            return
        }
        SwrveSDK.identify(
            text,
            onSuccess: { (status, swrveUserId) in
                self.currentUserId = swrveUserId ?? self.currentUserId
                feedbackMessage = "Identified user \(text) with Swrve ID \(swrveUserId)"
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    if feedbackMessage?.contains("Identified") == true { feedbackMessage = nil }
                }
                isIdentifying = false
                updateEmbeddedCampaignCount()
            },
            onError: { (httpCode, errorMessage) in
                feedbackMessage = "Identify failed (HTTP \(httpCode)): \(errorMessage)"
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    if feedbackMessage?.contains("Identify failed") == true { feedbackMessage = nil }
                }
                isIdentifying = false
            })
    }

    private func updateEmbeddedCampaignCount() {
        embeddedCampaignCount = SwrveSDK.embeddedMessageCenterCampaigns().count
    }

    private func sendUserProperty() {
        let key = userPropKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let value = userPropValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, !value.isEmpty else {
            userPropFeedback = "Key and value required"
            return
        }
        isRefreshing = true
        _ = SwrveSDK.userUpdate([key: value])
        SwrveSDK.sendQueuedEvents()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let listener = RefreshListener { result in
                DispatchQueue.main.async {
                    isRefreshing = false
                    switch result.resultCode {
                    case .SUCCESS:
                        refreshMessage = "Post-userUpdate refresh succeeded (HTTP \(result.httpResponseCode))"
                    case .ERROR, .ERROR_UNKNOWN:
                        let codeDesc = result.resultCode.description
                        var parts: [String] = ["Post-userUpdate refresh failed ("]
                        parts.append(codeDesc)
                        if !result.errorMessage.isEmpty { parts.append(": \(result.errorMessage)") }
                        parts.append(") HTTP \(result.httpResponseCode)")
                        refreshMessage = parts.joined()
                    @unknown default:
                        refreshMessage = "Post-userUpdate refresh unknown state"
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) { if !isRefreshing { refreshMessage = nil } }
                    updateEmbeddedCampaignCount()
                }
            }
            SwrveSDK.refreshContent(listener)
        }
        userPropFeedback = "Sent user property \(key)=\(value) to Swrve"
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { if userPropFeedback?.contains(key) == true { userPropFeedback = nil } }
    }

    // MARK: - View builders for offline-only sections
    @ViewBuilder
    private func credentialsSection() -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text("App ID").font(.caption.weight(.medium))
                TextField("1234", text: $appIdString)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
            }
            .frame(minWidth: 65, maxWidth: 70)

            VStack(alignment: .leading, spacing: 4) {
                Text("API Key").font(.caption.weight(.medium))
                TextField("your_api_key_here", text: $apiKey)
                    .autocapitalization(.none)
                    .textFieldStyle(.roundedBorder)
            }
            .frame(maxWidth: .infinity)
            .layoutPriority(2)

            VStack(alignment: .leading, spacing: 4) {
                Text("Stack").font(.caption.weight(.medium))
                Picker("", selection: $stack) {
                    Text("US").tag("us")
                    Text("EU").tag("eu")
                    Text("FS").tag("fs")
                }
                .pickerStyle(.segmented)
                .frame(width: 90)
            }
            .layoutPriority(0)
        }
        .transition(
            .asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .move(edge: .top).combined(with: .opacity)))
    }

    @ViewBuilder
    private func refreshButtonSection() -> some View {
        HStack(spacing: 12) {
            Button(action: refreshContent) {
                HStack(spacing: 6) {
                    if isRefreshing { ProgressView().progressViewStyle(.circular) }
                    Text("Refresh Content")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(liveContentButtonBackground)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(liveContentButtonBorder))
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(isRefreshing)
            .buttonStyle(.plain)
            .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)

            Text("Embedded Campaigns: \(embeddedCampaignCount)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .move(edge: .top).combined(with: .opacity)))
        .animation(.easeInOut, value: offlineMode)
    }

    @ViewBuilder
    private func identifySection() -> some View {
        HStack(spacing: 12) {
            TextField("External User ID", text: $identifyInput)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 140, maxWidth: 280)
                .autocapitalization(.none)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .disabled(isIdentifying)

            Button(action: identify) {
                HStack(spacing: 6) {
                    if isIdentifying { ProgressView().progressViewStyle(.circular) }
                    Text("Identify")
                        .font(.subheadline.weight(.semibold))
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(liveContentButtonBackground)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(liveContentButtonBorder))
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(isIdentifying)
            .buttonStyle(.plain)
            .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
        }
        .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .move(edge: .top).combined(with: .opacity)))
        .animation(.easeInOut, value: offlineMode)
    }

    @ViewBuilder
    private func userPropertySection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("User Property").font(.caption.weight(.medium))
            HStack(spacing: 8) {
                presetButton("carousel_layout=tall") {
                    userPropKey = "carousel_layout"
                    userPropValue = "tall"
                }

                presetButton("carousel_layout=image") {
                    userPropKey = "carousel_layout"
                    userPropValue = "image"
                }

                Spacer()
            }
            HStack(spacing: 8) {
                presetButton("banner_location=top") {
                    userPropKey = "banner_location"
                    userPropValue = "top"
                }

                presetButton("banner_location=bottom") {
                    userPropKey = "banner_location"
                    userPropValue = "bottom"
                }

                Spacer()
            }
            HStack(spacing: 12) {
                TextField(
                    "key",
                    text: Binding(
                        get: { userPropKey },
                        set: { userPropKey = $0.lowercased() }
                    )
                )
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 90, maxWidth: 140)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)

                TextField(
                    "value",
                    text: Binding(
                        get: { userPropValue },
                        set: { userPropValue = $0.lowercased() }
                    )
                )
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            }
            Button(action: sendUserProperty) {
                HStack(spacing: 6) {
                    if isRefreshing { ProgressView().progressViewStyle(.circular) }
                    Text("Send User Property and Refresh Content")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(liveContentButtonBackground)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(liveContentButtonBorder))
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(isRefreshing)
            .buttonStyle(.plain)
            .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .move(edge: .top).combined(with: .opacity)))
        .animation(.easeInOut, value: offlineMode)
    }

    @ViewBuilder
    private func presetButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption2)
                .padding(.vertical, 5)
                .padding(.horizontal, 5)
                .background(Color(.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Copy Helper
extension SetupView {
    fileprivate func copyCurrentUserId() {
        guard !currentUserId.isEmpty else { return }
        #if canImport(UIKit)
        UIPasteboard.general.string = currentUserId
        #endif
        feedbackMessage = "Copied User Id"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if feedbackMessage == "Copied User Id" { feedbackMessage = nil }
        }
    }
}

// MARK: - Refresh Listener Wrapper
private final class RefreshListener: NSObject, SwrveRefreshContentDelegate {
    private let completion: (SwrveRefreshContentResult) -> Void
    init(completion: @escaping (SwrveRefreshContentResult) -> Void) { self.completion = completion }
    func onComplete(_ result: SwrveRefreshContentResult) { completion(result) }
}
