import SwiftUI
import SwrveSDK

struct FloatingBannerView: View {
    var body: some View {
        DemoShellView(floatingContent: AnyView(SwrveEmbeddedBanner()))
            .navigationTitle("Floating Banner")
    }
}

private struct SwrveEmbeddedBanner: View {
    @Environment(\.openURL) private var openURL
    @State private var entry: FloatingBannerEntry? = nil
    @State private var isVisible: Bool = false
    @State private var isExpanded: Bool = false
    @State private var reportedMessageIds: Set<AnyHashable> = []
    @Namespace private var bannerNamespace
    @State private var imageTask: URLSessionDataTask? = nil
    @State private var prefetchedImage: UIImage? = nil
    private let expandCollapseAnimation = Animation.spring(response: 0.6, dampingFraction: 0.98, blendDuration: 0)
    @State private var iconFade: Bool = false
    @State private var showCollapsedText: Bool = true

    var body: some View {
        Group {
            if let entry = entry, isVisible {
                let isTop = (entry.floatingBanner.location ?? "top").lowercased() != "bottom"
                if isTop {
                    VStack(spacing: 0) {
                        bannerContent(for: entry)
                        Spacer()
                    }
                    .frame(maxHeight: .infinity)
                    .transition(.move(edge: .top))
                } else {
                    VStack(spacing: 0) {
                        Spacer()
                        bannerContent(for: entry)
                            .padding(.bottom, 12)  // small offset above tab bar
                    }
                    .frame(maxHeight: .infinity)
                    .transition(.move(edge: .bottom))
                }
            } else {
                Color.clear.frame(height: 1)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                loadFloatingBannerCampaign()
            }
        }
    }

    private func loadFloatingBannerCampaign() {
        // Fetch all embedded Message Center campaigns and use only those that are floating_banner type
        let embeddedMessages = SwrveSDK.embeddedMessageCenterCampaigns()
        let decoder = JSONDecoder()

        var candidates: [FloatingBannerEntry] = []
        for embeddedMessage in embeddedMessages {
            guard let dataString = embeddedMessage.data, let jsonData = dataString.data(using: .utf8) else { continue }
            guard let floatingBanner = try? decoder.decode(EmbeddedDataFloatingBanner.self, from: jsonData) else { continue }
            guard (floatingBanner.version ?? 1) <= EMBEDDED_SCHEMA_VERSION else { continue }
            guard floatingBanner.type == "floating_banner" else { continue }

            candidates.append(FloatingBannerEntry(floatingBanner: floatingBanner, message: embeddedMessage))
        }

        if candidates.isEmpty {
            // no candidates found; fall through to hiding below
        } else {
            // sort by priority asc (lower numeric => higher priority), then by downloadDate desc (more recent wins)
            let orderedCandidates = candidates.sorted(by: { a, b in
                let da = a.floatingBanner.displayOrder ?? Int.max
                let db = b.floatingBanner.displayOrder ?? Int.max
                if da != db { return da < db }
                let dca = a.message.campaign?.downloadDate() ?? Date.distantPast
                let dcb = b.message.campaign?.downloadDate() ?? Date.distantPast
                if dca != dcb { return dca.compare(dcb) == .orderedDescending }
                // final stable tie-breaker by id (string compare) to ensure deterministic order
                let ida = String(describing: a.message.messageID ?? 0)
                let idb = String(describing: b.message.messageID ?? 0)
                return ida < idb
            })

            if let best = orderedCandidates.first {
                DispatchQueue.main.async {
                    showEntryWithPrefetch(best)
                }
                return
            }
        }

        DispatchQueue.main.async {
            self.entry = nil
            self.isVisible = false
        }
    }

    private func showEntryWithPrefetch(_ be: FloatingBannerEntry) {
        // Cancel previous tasks
        imageTask?.cancel()

        // If there's an image icon URL, start fetching it, then reveal the banner when ready.
        if let urlString = be.floatingBanner.image, let url = URL(string: urlString) {
            let req = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 8)
            let task = URLSession.shared.dataTask(with: req) { data, _, _ in
                if let d = data, let ui = UIImage(data: d) {
                    DispatchQueue.main.async {
                        self.prefetchedImage = ui
                        self.entry = be
                        self.showCollapsedText = true
                        withAnimation(.spring()) { self.isVisible = true }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.entry = be
                        self.showCollapsedText = true
                        withAnimation(.spring()) { self.isVisible = true }
                    }
                }
            }
            imageTask = task
            task.resume()
        } else {
            // No image icon to fetch — show immediately
            self.prefetchedImage = nil
            self.entry = be
            withAnimation(.spring()) { self.isVisible = true }
        }
    }

    private func bannerContent(for entry: FloatingBannerEntry) -> some View {
        ZStack {
            // background
            RoundedRectangle(cornerRadius: 14)
                .fill(entry.floatingBanner.backgroundColor.colorOr(Color(UIColor.systemBackground)))

            // choose collapsed vs expanded rendering
            if !isExpanded {
                collapsedView(banner: entry.floatingBanner)
            } else {
                expandedView(entry: entry)
            }
        }
        .frame(height: isExpanded ? UIScreen.main.bounds.height / 3 : 72)
        .padding(.horizontal, 2)
        .transition(.move(edge: .top))
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

    private func closeBanner() {
        withAnimation(.easeInOut) { isVisible = false }
        // If you want to remove the campaign from the message center when the banner closes,
        // uncomment the following lines. Keep in mind this prevents users from re-opening it.
        // if let campaignID = entry?.message.campaignID, campaignID != 0 {
        //     SwrveSDK.removeMessageCenterCampaign(campaignID)
        // }
    }

    // MARK: - Smaller banner pieces
    private func collapsedView(banner: EmbeddedDataFloatingBanner) -> some View {
        HStack(spacing: 6) {
            // Render an image only when we have a prefetched UIImage or a non-empty image icon URL.
            if let ui = prefetchedImage {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipped()
                    .cornerRadius(8)
                    .matchedGeometryEffect(id: "bannerIcon", in: bannerNamespace)

            } else if let icon = banner.image, !icon.isEmpty {
                RemoteImage(urlString: icon)
                    .frame(width: 48, height: 48)
                    .clipped()
                    .cornerRadius(8)
                    .matchedGeometryEffect(id: "bannerIcon", in: bannerNamespace)
            }
            VStack(alignment: .leading, spacing: 4) {
                if let t = banner.collapsed?.title?.text {
                    Text(t).font(.headline).foregroundColor(banner.collapsed?.title?.color.colorOr(.primary))
                }
                if let b = banner.collapsed?.body?.text {
                    Text(b).font(.caption).foregroundColor(banner.collapsed?.body?.color.colorOr(.secondary))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // When no leading image exists, add a small leading inset so text doesn't sit flush against the left edge of the rounded background.
            .padding(.leading, ((banner.image ?? "").isEmpty ? 8 : 0))
            .opacity(showCollapsedText ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.16), value: showCollapsedText)

            Button(action: { closeBanner() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(banner.collapsed?.title?.color.colorOr(.primary))
                    .padding(4)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.linear(duration: 0.12)) { showCollapsedText = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(expandCollapseAnimation) { isExpanded = true }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private func expandedView(entry: FloatingBannerEntry) -> some View {
        let banner = entry.floatingBanner
        return VStack(spacing: 6) {
            Spacer()  // Center the entire content block vertically by placing Spacers above and below.

            if let ui = prefetchedImage {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 96, height: 96)
                    .clipped()
                    .cornerRadius(12)
                    .opacity(iconFade ? 0.0 : 1.0)
                    .matchedGeometryEffect(id: "bannerIcon", in: bannerNamespace)
            } else if let icon = banner.image, !icon.isEmpty {
                RemoteImage(urlString: icon)
                    .frame(width: 96, height: 96)
                    .clipped()
                    .cornerRadius(12)
                    .opacity(iconFade ? 0.0 : 1.0)
                    .matchedGeometryEffect(id: "bannerIcon", in: bannerNamespace)
            }

            if let t = banner.expanded?.title?.text {
                Text(t).font(.title2.weight(.semibold))
                    .foregroundColor(banner.expanded?.title?.color.colorOr(.primary))
            }

            if let b = banner.expanded?.body?.text {
                Text(b).font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(banner.expanded?.body?.color.colorOr(.secondary))
                    .padding(.horizontal, 24)
            }

            if let helper = banner.expanded?.helperText?.text {
                Text(helper).font(.caption)
                    .foregroundColor(banner.expanded?.helperText?.color.colorOr(.secondary))
            }

            if let cta = banner.expanded?.cta, let text = cta.text {
                Button(action: {
                    if let urlString = cta.url, let url = URL(string: urlString) {
                        SwrveSDK.embeddedButtonWasPressed(entry.message, buttonName: text)
                        openURL(url)
                        withAnimation(.easeInOut) { isVisible = false }
                    }
                }) {
                    Text(text)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(cta.color.colorOr(.white))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(cta.backgroundColor.colorOr(.blue))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal)
        .contentShape(Rectangle())
        .onTapGesture {
            // tapping the expanded area collapses (CTA and chevron are Buttons and will intercept taps)
            collapseWithAnimation()
        }
        .overlay(
            Button(action: { collapseWithAnimation() }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(banner.collapsed?.title?.color.colorOr(.primary))
                    .padding(8)
            }
            .buttonStyle(.plain)
            .padding(EdgeInsets(top: 22, leading: 0, bottom: 0, trailing: 6)), alignment: .topTrailing
        )
    }

    private func collapseWithAnimation() {
        // fade then collapse using the main animation
        withAnimation(.linear(duration: 0.12)) {
            iconFade = true
        }
        // after the quick pre-animation, perform the geometry collapse
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(expandCollapseAnimation) {
                iconFade = false
                isExpanded = false
            }
            // restore collapsed text after collapse completes (give a touch of time for layout)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.12)) { showCollapsedText = true }
            }
        }
    }
}

// MARK: - Models
private struct FloatingBannerEntry {
    let floatingBanner: EmbeddedDataFloatingBanner
    let message: SwrveEmbeddedMessage
}
