#if os(iOS)

import UIKit

class SwrveCarouselItemViewController: UIViewController {

    let item: SwrveCarouselItem
    let index: Int

    private let scrollView = FittedScrollView()
    private let contentStack = UIStackView()
    private let textContainer = UIView()
    private let textStack = UIStackView()
    private let imageView = SwrveCarouselImageView()
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()

    private let metrics: SwrveCarouselMetrics
    private let leadingMargin: CGFloat
    private let topMargin: CGFloat
    private let titleIcon: UIImage?
    /// Height over width of the image area. Set again by `layOut` once the space available is known.
    var imageHeightRatio: CGFloat {
        didSet {
            guard imageHeightRatio != oldValue, let oldShape = imageShapeConstraint else { return }
            oldShape.isActive = false
            imageShapeConstraint = makeImageShapeConstraint()
            imageShapeConstraint?.isActive = true
        }
    }
    private let loadImage: (String, @escaping (UIImage?) -> Void) -> Void
    private let onTap: (Int) -> Void

    private var textAreaHeightConstraint: NSLayoutConstraint?
    private var imageShapeConstraint: NSLayoutConstraint?
    private var isImageRequested = false

    init(
        item: SwrveCarouselItem,
        index: Int,
        metrics: SwrveCarouselMetrics,
        leadingMargin: CGFloat,
        topMargin: CGFloat,
        titleIcon: UIImage?,
        imageHeightRatio: CGFloat,
        loadImage: @escaping (String, @escaping (UIImage?) -> Void) -> Void,
        onTap: @escaping (Int) -> Void
    ) {
        self.item = item
        self.index = index
        self.metrics = metrics
        self.leadingMargin = leadingMargin
        self.topMargin = topMargin
        self.titleIcon = titleIcon
        self.imageHeightRatio = imageHeightRatio
        self.loadImage = loadImage
        self.onTap = onTap
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildHierarchy()
        applyFonts()
        applyContent()
    }

    private func buildHierarchy() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        // A drag down at the top goes to the system's dismiss gesture rather than rubber-banding against it
        scrollView.bounces = false
        // Otherwise the safe area, large in landscape, is added to the margins as extra space
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = metrics.verticalSpacing
        contentStack.alignment = .fill
        scrollView.addSubview(contentStack)

        // Text above an image that runs edge to edge, like a rich push
        contentStack.addArrangedSubview(textContainer)
        if hasTitle || hasBody {
            addText()
        } else if let titleIcon = titleIcon {
            addIconOnly(titleIcon)
        }
        // Raised to the text area it shares with other items, and otherwise as short as its content
        let textAreaHeight = textContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)
        textAreaHeightConstraint = textAreaHeight
        let textAreaHug = textContainer.heightAnchor.constraint(equalToConstant: 0)
        textAreaHug.priority = .defaultLow
        setTextAreaHeight(0)

        contentStack.addArrangedSubview(imageView)

        // The same on every item and known before any image loads, so the height never changes
        let imageShape = makeImageShapeConstraint()
        imageShapeConstraint = imageShape
        NSLayoutConstraint.activate([
            // The bottom strip is kept for the page control, so content scrolls above it, never under it
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -metrics.pageControlReservedHeight),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            textAreaHeight,
            textAreaHug,
            imageShape,
            imageView.heightAnchor.constraint(lessThanOrEqualToConstant: metrics.maximumImageHeight)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tap)
        view.isUserInteractionEnabled = true
    }

    /// Below required so the maximum height wins
    private func makeImageShapeConstraint() -> NSLayoutConstraint {
        let shape = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: imageHeightRatio)
        shape.priority = UILayoutPriority(999)
        return shape
    }

    private var hasTitle: Bool { !(item.title?.isEmpty ?? true) }
    private var hasBody: Bool { !(item.body?.isEmpty ?? true) }

    /// Only added when there's a title or body, so an image-only item has no empty text block to size.
    /// The icon-only row takes its place on an image-only item.
    private func addText() {
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.spacing = metrics.titleBodySpacing
        titleLabel.numberOfLines = 0
        bodyLabel.numberOfLines = 0
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(bodyLabel)
        textContainer.addSubview(textStack)

        // Not pinned to the bottom: when another item's text is taller, the spare space goes below the
        // text, rather than stretching a label and opening a gap between the title and body
        NSLayoutConstraint.activate([
            textStack.topAnchor.constraint(equalTo: textContainer.topAnchor, constant: topMargin),
            textStack.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor, constant: leadingMargin),
            textStack.trailingAnchor.constraint(equalTo: textContainer.trailingAnchor, constant: -metrics.edgeMargin),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: textContainer.bottomAnchor)
        ])
        if let titleIcon = titleIcon {
            addTitleIcon(titleIcon)
        }
    }

    /// Sits beside the title and body like the system's app icon, in the margin the text starts after,
    /// centred on the text so it stays centred when the title or body wraps.
    private func addTitleIcon(_ icon: UIImage) {
        let iconView = makeIconView(icon)
        textContainer.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.centerYAnchor.constraint(equalTo: textStack.centerYAnchor),
            iconView.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor, constant: metrics.titleIconLeadingMargin),
            iconView.widthAnchor.constraint(equalToConstant: metrics.titleIconSize),
            iconView.heightAnchor.constraint(equalToConstant: metrics.titleIconSize),
            iconView.bottomAnchor.constraint(lessThanOrEqualTo: textContainer.bottomAnchor)
        ])
    }

    /// An item with no text still shows the app's icon, where it sits on other items, so the notification
    /// always shows whose it is.
    private func addIconOnly(_ icon: UIImage) {
        let iconView = makeIconView(icon)
        textContainer.addSubview(iconView)
        // Lets the text area grow to match other items' text
        let iconBottom = iconView.bottomAnchor.constraint(equalTo: textContainer.bottomAnchor)
        iconBottom.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: textContainer.topAnchor, constant: topMargin),
            iconView.bottomAnchor.constraint(lessThanOrEqualTo: textContainer.bottomAnchor),
            iconBottom,
            iconView.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor, constant: metrics.titleIconLeadingMargin),
            iconView.widthAnchor.constraint(equalToConstant: metrics.titleIconSize),
            iconView.heightAnchor.constraint(equalToConstant: metrics.titleIconSize)
        ])
    }

    private func makeIconView(_ icon: UIImage) -> UIImageView {
        let iconView = UIImageView(image: icon)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFill
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = metrics.titleIconCornerRadius
        if #available(iOS 13.0, *) {
            iconView.layer.cornerCurve = .continuous
        }
        return iconView
    }

    private func applyContent() {
        titleLabel.text = item.title
        titleLabel.isHidden = !hasTitle
        bodyLabel.text = item.body
        bodyLabel.isHidden = !hasBody
    }

    /// Started for the item on screen and its neighbours, not when the item is measured, so only those
    /// images are decoded.
    func loadImageIfNeeded() {
        loadViewIfNeeded()
        guard !isImageRequested else { return }
        isImageRequested = true
        loadImage(item.imageUrl) { [weak self] image in
            self?.apply(image: image)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadImageIfNeeded()
    }

    /// A failed image leaves the placeholder in place.
    private func apply(image: UIImage?) {
        guard let image = image, image.size.width > 0, image.size.height > 0 else { return }
        imageView.image = image
    }

    /// Height this item needs at the given extension width, including the strip kept for the page control.
    /// Pages that aren't on screen have no size yet, so they're sized to the width before measuring.
    func fittingHeight(forWidth width: CGFloat) -> CGFloat {
        layout(forWidth: width)
        return contentStack.frame.height + metrics.pageControlReservedHeight
    }

    /// Height of this item's text, or its icon, at the given width, before it is matched to other items.
    func textAreaFittingHeight(forWidth width: CGFloat) -> CGFloat {
        setTextAreaHeight(0)
        layout(forWidth: width)
        return textContainer.isHidden ? 0 : textContainer.frame.height
    }

    /// Items given the same text area height have their images in the same place.
    func setTextAreaHeight(_ height: CGFloat) {
        loadViewIfNeeded()
        textAreaHeightConstraint?.constant = height
        // Takes no space, or stack spacing, while no item has text or an icon
        textContainer.isHidden = textContainer.subviews.isEmpty && height == 0
    }

    /// Gives every item the tallest item's text area and returns the height they then all need.
    static func matchTextAreas(of controllers: [SwrveCarouselItemViewController], forWidth width: CGFloat) -> CGFloat {
        let textAreaHeight = controllers.map { $0.textAreaFittingHeight(forWidth: width) }.max() ?? 0
        controllers.forEach { $0.setTextAreaHeight(textAreaHeight) }
        return controllers.map { $0.fittingHeight(forWidth: width) }.max() ?? 0
    }

    /// Items whose text leaves room for an image share the tallest of their text areas, so their images line
    /// up. An item with longer text keeps its own text area and scrolls, so it doesn't push the other items'
    /// images down; if every item's text is long, they're all matched. Every image area takes the given shape,
    /// made shorter where needed so the sharing items fit in `maximumHeight`, though never wider than
    /// `minimumImageHeightRatio`. When even that doesn't fit, as in landscape, the image area keeps the given
    /// shape and the items scroll, so the whole image can be seen. Returns the height the sharing items need,
    /// which is more than `maximumHeight` only in that case.
    static func layOut(
        _ controllers: [SwrveCarouselItemViewController], forWidth width: CGFloat, maximumHeight: CGFloat,
        imageHeightRatio: CGFloat, minimumImageHeightRatio: CGFloat
    ) -> CGFloat {
        guard let metrics = controllers.first?.metrics, width > 0 else {
            return matchTextAreas(of: controllers, forWidth: width)
        }
        let measured = controllers.map { controller in
            let textArea = controller.textAreaFittingHeight(forWidth: width)
            let heightWithoutImage = controller.fittingHeight(forWidth: width) - controller.imageView.frame.height
            return (textArea: textArea, heightWithoutImage: heightWithoutImage)
        }
        // In landscape even the widest image area is taller than the space available, so text is long when it
        // leaves less than half of what can be seen
        let imageRoom = min(
            width * minimumImageHeightRatio, metrics.maximumImageHeight,
            (maximumHeight - metrics.pageControlReservedHeight) / 2)
        let leavesImageRoom = measured.map { maximumHeight - $0.heightWithoutImage >= imageRoom }
        let sharing = leavesImageRoom.contains(true) ? leavesImageRoom : leavesImageRoom.map { _ in true }
        let shared = zip(measured, sharing).filter { $0.1 }.map { $0.0 }
        let sharedTextAreaHeight = shared.map { $0.textArea }.max() ?? 0
        for (index, controller) in controllers.enumerated() {
            controller.setTextAreaHeight(sharing[index] ? sharedTextAreaHeight : measured[index].textArea)
        }
        let fittingRatio = (maximumHeight - (shared.map { $0.heightWithoutImage }.max() ?? 0)) / width
        // Cropping the image only helps if it stops the item scrolling
        let ratio = fittingRatio < minimumImageHeightRatio ? imageHeightRatio : min(imageHeightRatio, fittingRatio)
        controllers.forEach { $0.imageHeightRatio = ratio }
        let heights = controllers.map { $0.fittingHeight(forWidth: width) }
        return zip(heights, sharing).filter { $0.1 }.map { $0.0 }.max() ?? 0
    }

    private func layout(forWidth width: CGFloat) {
        loadViewIfNeeded()
        let textWidth = width - leadingMargin - metrics.edgeMargin
        titleLabel.preferredMaxLayoutWidth = textWidth
        bodyLabel.preferredMaxLayoutWidth = textWidth
        if view.bounds.width != width {
            view.bounds.size = CGSize(width: width, height: max(view.bounds.height, 1))
        }
        view.layoutIfNeeded()
    }

    // MARK: - Accessible text

    func applyFonts() {
        titleLabel.font = SwrveCarouselFont.scaled(.headline, maximumPointSize: metrics.titleFontCap)
        bodyLabel.font = SwrveCarouselFont.scaled(.body, maximumPointSize: metrics.bodyFontCap)
        // Scaling is owned here, not by UIKit — see applyFonts re-application below.
        titleLabel.adjustsFontForContentSizeCategory = false
        bodyLabel.adjustsFontForContentSizeCategory = false
    }

    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        if previous?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            applyFonts()
        }
    }

    @objc private func handleTap() {
        onTap(index)
    }
}

/// Shows a placeholder until its image arrives, and keeps it if the image fails. The image fills the
/// area: a taller image is cropped from the bottom, a wider one from the sides.
final class SwrveCarouselImageView: UIView {

    var image: UIImage? {
        didSet {
            imageView.image = image
            placeholderView.isHidden = image != nil
            // Clear behind a loaded image, which may have transparency
            backgroundColor = image == nil ? SwrveCarouselPalette.placeholderFill : nil
            setNeedsLayout()
        }
    }

    var isShowingPlaceholder: Bool { !placeholderView.isHidden }

    private let imageView = UIImageView()
    private let placeholderView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        backgroundColor = SwrveCarouselPalette.placeholderFill
        addSubview(imageView)

        if #available(iOS 13.0, *) {
            placeholderView.image = UIImage(
                systemName: "photo", withConfiguration: UIImage.SymbolConfiguration(pointSize: 32, weight: .regular))
            placeholderView.tintColor = UIColor.tertiaryLabel
        }
        placeholderView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(placeholderView)
        NSLayoutConstraint.activate([
            placeholderView.centerXAnchor.constraint(equalTo: centerXAnchor),
            placeholderView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        // The image's own size must not fight the width and shape constraints
        setContentHuggingPriority(.defaultLow, for: .vertical)
        setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = Self.fillFrame(forImageSize: image?.size ?? .zero, in: bounds)
    }

    /// Aspect fill anchored to the top, centred horizontally.
    static func fillFrame(forImageSize imageSize: CGSize, in bounds: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return bounds }
        let scale = max(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(origin: CGPoint(x: bounds.midX - size.width / 2, y: bounds.minY), size: size)
    }
}

/// Scrolls only when its content doesn't fit, so an item that fits never competes with the system's gestures.
private final class FittedScrollView: UIScrollView {
    override func layoutSubviews() {
        super.layoutSubviews()
        isScrollEnabled = contentSize.height > bounds.height + 0.5
    }
}

#endif
