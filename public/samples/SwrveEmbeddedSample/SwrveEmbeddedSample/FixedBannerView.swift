import SwiftUI
import SwrveSDK

struct FixedBannerView: View {
    var body: some View {
        DemoShellView(homeContent: AnyView(SwrveEmbeddedBanner()))
            .navigationTitle("Fixed Banner")
    }
}

private struct SwrveEmbeddedBanner: View {
    @State private var hasBanner: Bool = false
    @State private var embeddedData: EmbeddedData? = nil
    @State private var swrveMessage: SwrveEmbeddedMessage? = nil
    @Environment(\.openURL) private var openURL

    var body: some View {
        Group {
            if hasBanner {
                BannerCard(embeddedData: embeddedData, swrveMessage: swrveMessage, openURL: openURL)
                    .transition(.move(edge: .top).combined(with: .opacity))
            } else {
                Color.clear.frame(height: 1)  // Reserve a tiny clear frame so overlay/layout attaches and onAppear fires
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                _ = SwrveSDK.event("banner")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .SwrveEmbeddedMessageReceived)) { note in
            guard let userInfo = note.userInfo else { return }

            if let dataString = userInfo["data"] as? String, let jsonData = dataString.data(using: .utf8) {
                let decoder = JSONDecoder()
                do {
                    let parsed = try decoder.decode(EmbeddedData.self, from: jsonData)
                    guard (parsed.version ?? 1) <= EMBEDDED_SCHEMA_VERSION else { return }
                    guard parsed.type?.lowercased() == "banner" else { return }
                    DispatchQueue.main.async {
                        embeddedData = parsed
                        if let msg = userInfo["message"] as? SwrveEmbeddedMessage {
                            swrveMessage = msg
                        }
                        if !hasBanner {
                            withAnimation(.spring()) { hasBanner = true }
                            if let msg = swrveMessage {
                                SwrveSDK.embeddedMessageWasShown(toUser: msg)
                            }
                        }
                    }
                } catch {
                    print("FixedBannerView: failed to decode EmbeddedData banner: \(error)")
                }
            }
        }
    }

}

private struct BannerCard: View {
    var embeddedData: EmbeddedData?
    var swrveMessage: SwrveEmbeddedMessage?
    let openURL: OpenURLAction

    var body: some View {
        Group {
            if let p = embeddedData, let bg = p.image, let url = URL(string: bg) {
                ZStack(alignment: .center) {
                    // Background image
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Color.gray.opacity(0.08)
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure:
                            Color.gray.opacity(0.1)
                        @unknown default:
                            Color.gray.opacity(0.1)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(2.0, contentMode: .fill)
                    .clipped()

                    // Overlay content
                    VStack(alignment: p.hStackAlignment, spacing: 8) {
                        if let title = p.title?.text {
                            Text(title)
                                .font(.title)
                                .bold()
                                .foregroundColor(Color(hex: p.title?.color ?? "#FFFFFF"))
                                .multilineTextAlignment(p.textAlignment)
                        }
                        if let body = p.body?.text {
                            Text(body)
                                .font(.subheadline)
                                .foregroundColor(Color(hex: p.body?.color ?? "#FFFFFF"))
                                .multilineTextAlignment(p.textAlignment)
                        }
                        if let cta = p.cta, let ctaText = cta.text {
                            // Render CTA as styled text (looks like a button).
                            Text(ctaText)
                                .foregroundColor(Color(hex: cta.color ?? "#FFFFFF"))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(hex: cta.backgroundColor ?? "#000000"))
                                .cornerRadius(8)
                        }
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: p.layout?.lowercased().contains("left") == true
                            ? .leading : (p.layout?.lowercased().contains("right") == true ? .trailing : .center)
                    )
                    .padding(.leading, p.layout?.lowercased().contains("left") == true ? 20 : 16)
                    .padding(.trailing, p.layout?.lowercased().contains("right") == true ? 20 : 16)
                    .padding(.vertical, 12)
                }
                .modifier(BannerModifier(data: p, swrveMessage: swrveMessage, openURL: openURL))
            } else {
                Color.clear.frame(height: 1)  // fallback empty placeholder
            }
        }
    }

    // Centralized modifier for banner
    private struct BannerModifier: ViewModifier {
        let data: EmbeddedData
        let swrveMessage: SwrveEmbeddedMessage?
        let openURL: OpenURLAction

        func body(content: Content) -> some View {
            content
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                .padding(.horizontal, -16)
                .contentShape(Rectangle())
                .onTapGesture { handleTap(data.cta) }
        }

        private func handleTap(_ cta: EmbeddedDataCTA?) {
            guard let cta = cta, let urlStr = cta.url, let url = URL(string: urlStr) else { return }
            if let msg = swrveMessage {
                SwrveSDK.embeddedButtonWasPressed(msg, buttonName: cta.text ?? "Unknown")
            }
            openURL(url)
        }
    }
}

// Alignment helpers derived from EmbeddedData layout
extension EmbeddedData {
    fileprivate var hStackAlignment: HorizontalAlignment {
        switch layout?.lowercased() {
        case let s where s?.contains("left") == true: return .leading
        case let s where s?.contains("right") == true: return .trailing
        default: return .center
        }
    }
    fileprivate var textAlignment: TextAlignment {
        switch layout?.lowercased() {
        case let s where s?.contains("left") == true: return .leading
        case let s where s?.contains("right") == true: return .trailing
        default: return .center
        }
    }
}
