import SwiftUI
import SwrveSDK

struct OffersView: View {
    var body: some View {
        DemoShellView(offersContent: AnyView(SwrveEmbeddedOffers()), selectedTab: .offers)
            .navigationTitle("Offers")
    }
}

private struct SwrveEmbeddedOffers: View {
    @Environment(\.openURL) private var openURL
    @State private var entries: [OfferEntry] = []
    @State private var hideWhenNoOffersCampaigns: Bool = false
    @State private var reportedMessageIds: Set<AnyHashable> = []

    var body: some View {
        Group {
            if hideWhenNoOffersCampaigns {
                VStack {
                    Image(systemName: "tag")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .foregroundColor(.secondary)
                    Text("No offers available")
                        .font(.title3.weight(.semibold))
                    Text("Check back later for personalized offers.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(entries, id: \.message.messageID) { entry in
                            OfferRowView(card: entry.card, message: entry.message, openURL: openURL)
                                .onAppear {
                                    if let rawId = entry.message.messageID {
                                        let hid = AnyHashable(rawId)
                                        if !reportedMessageIds.contains(hid) {
                                            reportedMessageIds.insert(hid)
                                            SwrveSDK.embeddedMessageWasShown(toUser: entry.message)
                                        }
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }
            }
        }
        .onAppear(perform: loadOfferCampaigns)
    }

    private func loadOfferCampaigns() {
        // Fetch all embedded Message Center campaigns and use only those that are offer type
        let embeddedMessages = SwrveSDK.embeddedMessageCenterCampaigns()
        let decoder = JSONDecoder()

        var items: [OfferEntry] = []
        for embeddedMessage in embeddedMessages {
            guard let dataString = embeddedMessage.data, let jsonData = dataString.data(using: .utf8) else { continue }
            guard let card = try? decoder.decode(EmbeddedData.self, from: jsonData) else { continue }
            guard (card.version ?? 1) <= EMBEDDED_SCHEMA_VERSION else { continue }
            guard card.type == "offer" else { continue }
            guard let layout = card.layout?.lowercased(), ["tall_card", "compact_card"].contains(layout) else { continue }
            guard let img = card.image, !img.isEmpty else { continue }

            items.append(OfferEntry(card: card, message: embeddedMessage))
        }

        if items.isEmpty {
            hideWhenNoOffersCampaigns = true
            entries = []
            return
        }
        hideWhenNoOffersCampaigns = false
        items.sort { ($0.card.displayOrder ?? Int.max) < ($1.card.displayOrder ?? Int.max) }
        entries = items
    }
}

// MARK: - Models
private struct OfferEntry {
    let card: EmbeddedData
    let message: SwrveEmbeddedMessage
}

// MARK: - Layout dispatch
private struct OfferRowView: View {
    let card: EmbeddedData
    let message: SwrveEmbeddedMessage
    let openURL: OpenURLAction

    var body: some View {
        let layout = card.layout?.lowercased() ?? "tall_card"
        switch layout {
        case "compact_card":
            CompactCardView(card: card, message: message, openURL: openURL)
        default:
            TallCardView(card: card, message: message, openURL: openURL)
        }
    }
}

// MARK: - Compact Offer View
private struct CompactCardView: View {
    let card: EmbeddedData
    let message: SwrveEmbeddedMessage
    let openURL: OpenURLAction

    var body: some View {
        HStack(spacing: 12) {
            // Square thumbnail on the left
            RemoteImage(urlString: card.image ?? "")
                .frame(width: 72, height: 72)
                .clipped()
                .cornerRadius(6)

            // Title and body stack
            VStack(alignment: .leading, spacing: 6) {
                if let title = card.title?.text, !title.isEmpty {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(card.title?.color.colorOr(.primary))
                }
                if let body = card.body?.text, !body.isEmpty {
                    Text(body)
                        .font(.caption)
                        .foregroundColor(card.body?.color.colorOr(.secondary))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Optional CTA (render as styled text; whole card will handle tap if CTA has a URL)
            if let cta = card.cta, let text = cta.text, !text.isEmpty {
                OfferCTA(text: text, cta: cta)
            }
        }
        .padding(6)
        .modifier(OfferModifier(card: card, message: message, openURL: openURL))
    }
}

// MARK: - Tall Card View
private struct TallCardView: View {
    let card: EmbeddedData
    let message: SwrveEmbeddedMessage
    let openURL: OpenURLAction

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let imageHeight = width / 2
            VStack(spacing: 0) {
                RemoteImage(urlString: card.image ?? "")
                    .frame(width: width, height: imageHeight)
                    .clipped()

                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        if let title = card.title?.text, !title.isEmpty {
                            Text(title)
                                .font(.title3.weight(.semibold))
                                .foregroundColor(card.title?.color.colorOr(.primary))
                                .truncationMode(.tail)
                        }
                        if let body = card.body?.text, !body.isEmpty {
                            Text(body)
                                .font(.caption)
                                .foregroundColor(card.body?.color.colorOr(.secondary))
                                .truncationMode(.tail)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if let cta = card.cta, let text = cta.text, !text.isEmpty {
                        OfferCTA(text: text, cta: cta)
                    }
                }
                .frame(height: 80)
                .padding(.horizontal, 6)
            }
            .modifier(OfferModifier(card: card, message: message, openURL: openURL))
            .frame(width: width, height: imageHeight + 80)
        }
        .frame(height: (UIScreen.main.bounds.width - 32) / 2 + 80)  // approximate intrinsic height for list layout
    }
}

// ViewModifier that centralizes card behavior
private struct OfferModifier: ViewModifier {
    let card: EmbeddedData
    let message: SwrveEmbeddedMessage
    let openURL: OpenURLAction

    init(card: EmbeddedData, message: SwrveEmbeddedMessage, openURL: OpenURLAction) {
        self.card = card
        self.message = message
        self.openURL = openURL
    }

    func body(content: Content) -> some View {
        content
            .background(card.backgroundColor.colorOr(.white))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.12), Color.black.opacity(0.04)]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.2
                    )
            )
            .contentShape(Rectangle())
            .onTapGesture { handleTap(card.cta) }
    }

    private func handleTap(_ cta: EmbeddedDataCTA?) {
        guard let cta = cta, let urlString = cta.url, let url = URL(string: urlString) else { return }
        SwrveSDK.embeddedButtonWasPressed(message, buttonName: cta.text ?? "Unknown")
        openURL(url)
    }
}

private struct OfferCTA: View {
    let text: String
    let cta: EmbeddedDataCTA

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundColor(cta.color.colorOr(.white))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minWidth: 80, minHeight: 36)
            .background(cta.backgroundColor.colorOr(.blue))
            .cornerRadius(8)
            .accessibilityAddTraits(.isButton)
    }
}
