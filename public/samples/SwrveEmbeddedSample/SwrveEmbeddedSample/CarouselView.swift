import SwiftUI
import SwrveSDK
import UIKit

// Shared sizing for non-image text area below the 2:1 image
private let kCarouselTextHeight: CGFloat = 80
// How much of the screen each card should occupy (so the next card peeks)
private let kCarouselCardWidthFactor: CGFloat = 0.88
// Horizontal gutter between cards (visible as white space)
private let kCarouselCardHorizontalSpacing: CGFloat = 12

struct CarouselView: View {
    var body: some View {
        DemoShellView(homeContent: AnyView(SwrveEmbeddedCarousel()))
            .navigationTitle("Carousel")
    }
}

// MARK: - Inline demo component specific to Carousel sample
private struct SwrveEmbeddedCarousel: View {
    @Environment(\.openURL) private var openURL
    @State private var entries: [CarouselEntry] = []
    @State private var hideWhenNoCarouselCampaigns: Bool = false

    // Ensure the carousel container gets an explicit height so it doesn't collapse inside scroll containers
    private var carouselHeight: CGFloat {
        // Match the computation used for cardWidth so the placeholder height equals the real card height.
        // Use the first entry's layout to decide if the carousel should reserve only the image height
        // (for image-only cards) or image + text area (for tall cards). This is safe because payloads
        // are expected not to mix layouts in a single carousel.
        let containerPadding: CGFloat = 16
        let contentWidth = UIScreen.main.bounds.width - (containerPadding * 2)
        let cardWidth = contentWidth * kCarouselCardWidthFactor
        let imageHeight = cardWidth / 2  // 2:1 image

        guard let first = entries.first else {
            // Default to tall card height until we have entries
            return imageHeight + kCarouselTextHeight
        }

        let layout = first.card.layout?.lowercased() ?? "tall_card"
        if layout == "image_only_card" { return imageHeight }
        return imageHeight + kCarouselTextHeight
    }

    var body: some View {
        Group {
            if hideWhenNoCarouselCampaigns {
                EmptyView()  // Hide entirely when the SDK explicitly returned no embedded campaigns of type carousel
            } else {
                CarouselCollectionViewRepresentable(
                    entries: entries,
                    cardWidthFactor: kCarouselCardWidthFactor,
                    carouselHeight: carouselHeight,
                    horizontalSpacing: kCarouselCardHorizontalSpacing,
                    openURL: openURL
                )
                .frame(height: carouselHeight)
                .padding(.horizontal, -16)  // Counter the shell overlay's horizontal padding so the carousel cards can extend closer to screen edges
            }
        }
        .onAppear(perform: loadCarouselCampaigns)
    }

    private func loadCarouselCampaigns() {
        // Fetch all embedded Message Center campaigns and use only those that are carousel type
        let embeddedMessages = SwrveSDK.embeddedMessageCenterCampaigns()
        let decoder = JSONDecoder()

        var items: [CarouselEntry] = []
        for embeddedMessage in embeddedMessages {
            guard let dataString = embeddedMessage.data, let jsonData = dataString.data(using: .utf8) else { continue }
            guard let card = try? decoder.decode(EmbeddedData.self, from: jsonData) else { continue }
            guard (card.version ?? 1) <= EMBEDDED_SCHEMA_VERSION else { continue }
            guard card.type == "carousel" else { continue }
            guard let img = card.image, !img.isEmpty else { continue }

            items.append(CarouselEntry(card: card, message: embeddedMessage))
        }

        if items.isEmpty {
            hideWhenNoCarouselCampaigns = true  // If there are no carousel-type embedded campaigns, hide the carousel so it doesn't take space
            entries = []
            return
        }
        hideWhenNoCarouselCampaigns = false
        // Order by displayOrder (lower numeric value == earlier in carousel)
        items.sort { ($0.card.displayOrder ?? Int.max) < ($1.card.displayOrder ?? Int.max) }
        entries = items
    }
}

// MARK: - Rendering
private struct CarouselCardView: View {
    let card: EmbeddedData
    let message: SwrveEmbeddedMessage
    let openURL: OpenURLAction

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let imageHeight = width / 2  // 2:1 width:height ratio
            Group {
                let layout = card.layout?.lowercased() ?? "tall_card"
                switch layout {
                case "tall_card":
                    VStack(spacing: 0) {
                        RemoteImage(urlString: card.image ?? "")
                            .frame(width: width, height: imageHeight)
                            .clipped()

                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                if let title = card.title?.text, !title.isEmpty {
                                    Text(title)
                                        .font(.headline)
                                        .foregroundColor(card.title?.color.colorOr(.primary))
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                                if let body = card.body?.text, !body.isEmpty {
                                    Text(body)
                                        .font(.subheadline)
                                        .foregroundColor(card.body?.color.colorOr(.secondary))
                                        .lineLimit(2)
                                        .truncationMode(.tail)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            if let cta = card.cta, let text = cta.text, !text.isEmpty {
                                Text(text)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(cta.color.colorOr(.white))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(cta.backgroundColor.colorOr(.blue))
                                    .cornerRadius(8)
                            }
                        }
                        // Reserve a fixed text/info area (kCarouselTextHeight) to avoid layout shift when text is short; text is truncated to the specified line limits
                        .frame(height: kCarouselTextHeight)
                        .padding(.horizontal, 10)
                    }
                    // Ensure the tall card reserves image + text area (image is 2:1)
                    .frame(width: width, height: imageHeight + kCarouselTextHeight)

                case "image_only_card":
                    RemoteImage(urlString: card.image ?? "")
                        .frame(width: width, height: imageHeight)
                        .clipped()
                default:
                    RemoteImage(urlString: card.image ?? "")
                        .frame(width: width, height: imageHeight)
                        .clipped()
                }
            }
        }
        .modifier(CarouselModifier(card: card, message: message, openURL: openURL))
    }

    private struct CarouselModifier: ViewModifier {
        let card: EmbeddedData
        let message: SwrveEmbeddedMessage
        let openURL: OpenURLAction

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
}

// MARK: - Models
private struct CarouselEntry {
    let card: EmbeddedData
    let message: SwrveEmbeddedMessage
}

// MARK: - UICollectionView-based carousel UIViewRepresentable
private struct CarouselCollectionViewRepresentable: UIViewRepresentable {
    let entries: [CarouselEntry]
    let cardWidthFactor: CGFloat
    let carouselHeight: CGFloat
    let horizontalSpacing: CGFloat
    let openURL: OpenURLAction

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UICollectionView {
        let layout = UICollectionViewCompositionalLayout { _, environment in
            let containerWidth = environment.container.effectiveContentSize.width
            let itemWidth = containerWidth * self.cardWidthFactor

            // Item
            let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(itemWidth), heightDimension: .absolute(self.carouselHeight))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            // Group
            let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(itemWidth), heightDimension: .absolute(self.carouselHeight))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            group.interItemSpacing = .fixed(self.horizontalSpacing)

            // Section with paging behavior aligned to leading edge (no left gap on first item)
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .groupPaging
            section.interGroupSpacing = self.horizontalSpacing
            // remove leading/trailing insets so first item sits flush to collection view edge
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

            return section
        }

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = .fast
        collectionView.register(CarouselCollectionViewCell.self, forCellWithReuseIdentifier: CarouselCollectionViewCell.reuseIdentifier)
        collectionView.dataSource = context.coordinator
        collectionView.delegate = context.coordinator
        collectionView.isPagingEnabled = false  // using groupPaging
        collectionView.contentInsetAdjustmentBehavior = .never
        return collectionView
    }

    func updateUIView(_ uiView: UICollectionView, context: Context) {
        context.coordinator.parent = self
        // Only scroll to the first item when we previously had zero items and now have items
        let previousCount = context.coordinator.previousItemCount
        uiView.reloadData()
        let newCount = uiView.numberOfItems(inSection: 0)
        if previousCount == 0 && newCount > 0 {
            uiView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .left, animated: false)
        }
        context.coordinator.previousItemCount = newCount
    }

    class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
        var parent: CarouselCollectionViewRepresentable
        private var reportedMessageIds: Set<AnyHashable> = []
        var previousItemCount: Int = 0  // Track previous item count to avoid resetting scroll position on every SwiftUI update

        init(_ parent: CarouselCollectionViewRepresentable) { self.parent = parent }

        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            parent.entries.count
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            guard
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CarouselCollectionViewCell.reuseIdentifier, for: indexPath)
                    as? CarouselCollectionViewCell
            else {
                return UICollectionViewCell()
            }
            let entry = parent.entries[indexPath.item]
            cell.host(rootView: CarouselCardView(card: entry.card, message: entry.message, openURL: parent.openURL))
            cell.clearVisuals()
            return cell
        }

        // Use willDisplay to report impressions reliably when cell becomes visible
        func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
            guard indexPath.item < parent.entries.count else { return }
            let entry = parent.entries[indexPath.item]
            guard let rawMessageId = entry.message.messageID else { return }
            let messageId = AnyHashable(rawMessageId)
            if !reportedMessageIds.contains(messageId) {
                reportedMessageIds.insert(messageId)
                SwrveSDK.embeddedMessageWasShown(toUser: entry.message)
            }
        }
    }
}

// UICollectionViewCell that hosts a SwiftUI view
private class CarouselCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "CarouselCollectionViewCell"
    private var hostingController: UIHostingController<AnyView>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func host<Content: View>(rootView: Content) {
        if let host = hostingController {
            host.rootView = AnyView(rootView)
            return
        }

        // Create and attach hosting controller once
        let host = UIHostingController(rootView: AnyView(rootView))
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear
        contentView.addSubview(host.view)

        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        hostingController = host
    }

    func clearVisuals() {
        layer.shadowOpacity = 0
        layer.shadowRadius = 0
        layer.shadowOffset = .zero
        layer.shadowColor = nil
        contentView.layer.shadowOpacity = 0
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
}
