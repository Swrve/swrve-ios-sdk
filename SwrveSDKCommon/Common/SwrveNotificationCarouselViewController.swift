#if os(iOS)

import UIKit
import UserNotifications
import UserNotificationsUI

enum SwrveCarouselFont {

    /// Returns a font that scales with the content size category but never exceeds `maximumPointSize`.
    ///
    /// `UIFont.preferredFont(forTextStyle:)` is already scaled for the current category, so it is
    /// taken at the default `.large` category first — passing an already-scaled font to
    /// `UIFontMetrics` scales it twice.
    static func scaled(
        _ style: UIFont.TextStyle,
        maximumPointSize: CGFloat,
        compatibleWith traitCollection: UITraitCollection? = nil
    ) -> UIFont {
        let baseFont = unscaled(style)
        return UIFontMetrics(forTextStyle: style).scaledFont(
            for: baseFont,
            maximumPointSize: maximumPointSize,
            compatibleWith: traitCollection)
    }

    private static func unscaled(_ style: UIFont.TextStyle) -> UIFont {
        let defaultCategoryTraits = UITraitCollection(preferredContentSizeCategory: .large)
        return UIFont.preferredFont(forTextStyle: style, compatibleWith: defaultCategoryTraits)
    }
}

enum SwrveCarouselPalette {

    /// `UIColor.label` where available, so the carousel adapts to light and dark. The deployment
    /// target is iOS 12, which predates it.
    static var label: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.label
        }
        return UIColor.black
    }

    /// Behind an image until it loads, or if it fails.
    static var placeholderFill: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor.tertiarySystemFill
        }
        return UIColor(white: 0.5, alpha: 0.12)
    }
}

/// Layout constants. Subclasses override them via the controller's `metrics` property.
public struct SwrveCarouselMetrics {
    /// Every item's image area runs edge to edge in the shape of the first image, up to this height, and
    /// shorter where needed so items fit in the space available. Images fill it: a taller image is cropped
    /// from the bottom, a wider one from the sides.
    public var maximumImageHeight: CGFloat = 640
    /// The widest and tallest shapes, as height over width, the first image can give the image area. A
    /// first image outside them is cropped to the nearest. 3:1 and 2:3 by default. The image area is made
    /// shorter than the first image's shape when that lets items fit, but never wider than the minimum. When
    /// even the minimum doesn't fit, as in landscape, the image area keeps the first image's shape and items
    /// scroll, so the whole image can be seen. An item whose text leaves less room than the minimum, or than
    /// `maximumImageHeight`, keeps its own text area and scrolls, so it doesn't push other items' images down.
    public var minimumImageHeightRatio: CGFloat = 1.0 / 3.0
    public var maximumImageHeightRatio: CGFloat = 1.5
    /// The image area's shape when no image has been downloaded yet. 3:2 by default.
    public var defaultImageHeightRatio: CGFloat = 2.0 / 3.0
    /// The space allowed for the carousel never drops below this, however little is left on screen, so a
    /// tall item still has room to scroll. An item shorter than this is shown at its own height.
    public var minimumContentHeight: CGFloat = 120
    /// Space between the items edge and the content, wherever there's nothing to line up with.
    public var edgeMargin: CGFloat = 16
    /// Where the system's notification text starts. Items line up with it when iOS shows its own content
    /// above the carousel
    public var systemTextLeadingMargin: CGFloat = 63
    /// The app's icon beside each title when the system's content is hidden, placed like the system's own
    /// icon so the carousel starts where a normal push does.
    public var titleIconSize: CGFloat = 35
    public var titleIconCornerRadius: CGFloat = 8
    public var titleIconLeadingMargin: CGFloat = 17
    public var titleIconSpacing: CGFloat = 11
    /// Top margin when the system's content is hidden, matching where a normal push's icon and title start.
    public var hiddenContentTopMargin: CGFloat = 13
    public var verticalSpacing: CGFloat = 8
    /// Between title and body, close together as in iOS's own banner.
    public var titleBodySpacing: CGFloat = 2
    public var pageControlReservedHeight: CGFloat = 40
    public var titleFontCap: CGFloat = 28
    public var bodyFontCap: CGFloat = 28

    /// Height iOS keeps clear above and below an expanded notification. What's left of the screen is the
    /// most the whole card can be, which is the limit on a phone in landscape.
    public var systemVerticalSpace: CGFloat = 133
    /// Space around the title and body in iOS's own banner, shown above the carousel unless the system's
    /// content is hidden.
    public var systemContentPadding: CGFloat = 37
    /// Room iOS keeps beside its banner title for the time.
    public var systemTitleTrailingSpace: CGFloat = 40

    /// Upper bound on total height, as a fraction of screen height. Taller items scroll. In portrait iOS
    /// shows about 65% of the screen for an expanded notification, and scrolls the whole card, page
    /// control included, when asked for more. Not applied on a phone in landscape, where
    /// `systemVerticalSpace` is the limit and this would only make the carousel shorter than a rich push.
    public var maximumHeightScreenFraction: CGFloat = 0.63

    public init() {}

    /// The image area's shape for a first image of the given shape, or the default without one.
    func imageHeightRatio(forFirstImageRatio ratio: CGFloat?) -> CGFloat {
        guard let ratio = ratio, ratio > 0 else { return defaultImageHeightRatio }
        return min(max(ratio, minimumImageHeightRatio), maximumImageHeightRatio)
    }

    /// The most height the carousel can have and still fit in the expanded card: the screen's height less
    /// what iOS keeps clear, less iOS's own banner when it's shown, and no more than
    /// `maximumHeightScreenFraction` of the screen except on a phone in landscape.
    func maximumContentHeight(screenSize: CGSize, isPhone: Bool, systemContentHeight: CGFloat) -> CGFloat {
        var available = screenSize.height - systemVerticalSpace - systemContentHeight
        let isPhoneLandscape = isPhone && screenSize.width > screenSize.height
        if !isPhoneLandscape {
            available = min(available, screenSize.height * maximumHeightScreenFraction)
        }
        return max(available, minimumContentHeight)
    }
}

/// Base view controller for a push carousel content extension.
///
/// Customers subclass this in Swift and set the subclass as their extension's `NSExtensionPrincipalClass`.
/// Use a subclass rather than this class directly: `appGroupIdentifier` has no default, and without it
/// carousel taps and events don't reach the app.
open class SwrveNotificationCarouselViewController: UIViewController, UNNotificationContentExtension {

    open var metrics = SwrveCarouselMetrics()

    public private(set) var items: [SwrveCarouselItem] = []

    /// App Group shared with the host app. Required for carousel taps and events to reach the app, and for
    /// the service extension's image downloads to be used: without it the first expansion has no image to
    /// take its shape from, so it uses `metrics.defaultImageHeightRatio`, and later expansions the first
    /// image's shape.
    /// Subclasses override this; there is no default, matching how the service extension takes it
    /// as an explicit parameter rather than reading it from Info.plist.
    open var appGroupIdentifier: String? { nil }

    /// Shown beside each item's title when the extension hides the system's notification content
    /// (`UNNotificationExtensionDefaultContentHidden`), so the carousel still shows the app's icon.
    /// Ignored when the system's content is shown, as it already includes the app icon.
    open var titleIcon: UIImage? { nil }

    private lazy var isDefaultContentHidden: Bool = {
        let extensionInfo = Bundle.main.object(forInfoDictionaryKey: "NSExtension") as? [String: Any]
        let attributes = extensionInfo?["NSExtensionAttributes"] as? [String: Any]
        return attributes?["UNNotificationExtensionDefaultContentHidden"] as? Bool ?? false
    }()

    private var notification: UNNotification?

    /// Built once per extension instance so every item shares one cache and one session.
    private lazy var imageLoader = SwrveCarouselImageLoader(appGroupIdentifier: appGroupIdentifier)

    /// Items already reported during *this* expansion. The App Group record is only written once a
    /// send succeeds, so without this a fast swipe back and forth would re-POST an item whose first
    /// request is still in flight.
    private var reportedItems = Set<Int>()

    private var pageViewController: UIPageViewController?
    private let pageControl = UIPageControl()
    private var itemControllers: [SwrveCarouselItemViewController] = []
    /// Every item's height, measured again only when the width or text size changes.
    private var itemHeight: CGFloat = 0
    private var itemHeightMeasuredFor: (width: CGFloat, contentSize: UIContentSizeCategory, maximumHeight: CGFloat)?
    /// The first downloaded image's shape, which every image area takes when there's room for it.
    private var firstImageHeightRatio: CGFloat = 0

    // MARK: - UNNotificationContentExtension

    open func didReceive(_ notification: UNNotification) {
        self.notification = notification
        let userInfo = notification.request.content.userInfo
        let swrvePayload = userInfo[SwrveNotificationContentIdentifierKey] as? [AnyHashable: Any]
        items = SwrveCarouselItem.items(fromSwrvePayload: swrvePayload) ?? []

        guard !items.isEmpty else {
            preferredContentSize = .zero
            return
        }

        buildCarousel()
        updatePreferredContentSize()
        reportPageView(at: 0)
    }

    // MARK: - Build

    private func buildCarousel() {
        let paging = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil)
        paging.dataSource = self
        paging.delegate = self

        addChild(paging)
        paging.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(paging.view)
        paging.didMove(toParent: self)

        let icon = isDefaultContentHidden ? titleIcon : nil
        let leadingMargin: CGFloat
        if !isDefaultContentHidden {
            leadingMargin = metrics.systemTextLeadingMargin
        } else if icon != nil {
            leadingMargin = metrics.titleIconLeadingMargin + metrics.titleIconSize + metrics.titleIconSpacing
        } else {
            leadingMargin = metrics.edgeMargin
        }

        // Every item takes the shape of the first downloaded image, as a rich push takes its image's
        firstImageHeightRatio = metrics.imageHeightRatio(
            forFirstImageRatio: imageLoader.cachedImageHeightRatio(forUrls: items.map { $0.imageUrl }))

        // New items, so measure again even when the width and text size haven't changed
        itemHeightMeasuredFor = nil
        itemControllers = items.enumerated().map { index, item in
            SwrveCarouselItemViewController(
                item: item,
                index: index,
                metrics: metrics,
                leadingMargin: leadingMargin,
                topMargin: isDefaultContentHidden ? metrics.hiddenContentTopMargin : metrics.verticalSpacing,
                titleIcon: icon,
                imageHeightRatio: firstImageHeightRatio,
                loadImage: { [weak self] url, completion in
                    guard let self = self else {
                        completion(nil)
                        return
                    }
                    self.imageLoader.loadImage(fromUrl: url, completion: completion)
                },
                onTap: { [weak self] index in
                    self?.carouselItemTapped(at: index)
                })
        }

        loadItems(around: 0)

        if let first = itemControllers.first {
            paging.setViewControllers([first], direction: .forward, animated: false, completion: nil)
        }

        // The page control is always shown — there is no payload flag controlling it.
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.numberOfPages = items.count
        pageControl.currentPage = 0
        pageControl.isUserInteractionEnabled = false
        pageControl.hidesForSinglePage = false
        // Set explicitly: the default indicator tint is a low-alpha grey that is effectively
        // invisible against the light material a notification is drawn on. `.label` adapts to
        // light and dark automatically.
        pageControl.pageIndicatorTintColor = pageIndicatorTintColor
        pageControl.currentPageIndicatorTintColor = currentPageIndicatorTintColor
        view.addSubview(pageControl)

        NSLayoutConstraint.activate([
            paging.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            paging.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            paging.view.topAnchor.constraint(equalTo: view.topAnchor),
            paging.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pageControl.heightAnchor.constraint(equalToConstant: metrics.pageControlReservedHeight)
        ])

        pageViewController = paging
    }

    // MARK: - Height

    /// The item on screen and its neighbours are loaded, which starts their image downloads, so the next
    /// item is usually ready before it's swiped to.
    private func loadItems(around index: Int) {
        guard !itemControllers.isEmpty else { return }
        for offset in -1...1 {
            itemControllers[wrappedIndex(index + offset)].loadImageIfNeeded()
        }
    }

    /// With three or more items, swiping wraps around: past the last item comes the first, and before the
    /// first comes the last.
    private func wrappedIndex(_ index: Int) -> Int {
        (index % itemControllers.count + itemControllers.count) % itemControllers.count
    }

    /// One height for every item, so the notification doesn't resize as images load or the user swipes. The
    /// image area is made shorter, cropping the first image, so items fit in the space available. An item
    /// whose text leaves no room for the image, or every item in landscape, scrolls above the page control.
    private func updatePreferredContentSize() {
        guard !itemControllers.isEmpty else { return }
        let width = view.bounds.width > 0 ? view.bounds.width : screenBounds.width
        let contentSize = traitCollection.preferredContentSizeCategory
        let maximumHeight = maximumContentHeight(forWidth: width)
        if itemHeightMeasuredFor?.width != width || itemHeightMeasuredFor?.contentSize != contentSize
            || itemHeightMeasuredFor?.maximumHeight != maximumHeight
        {
            itemHeight = SwrveCarouselItemViewController.layOut(
                itemControllers, forWidth: width, maximumHeight: maximumHeight,
                imageHeightRatio: firstImageHeightRatio, minimumImageHeightRatio: metrics.minimumImageHeightRatio)
            itemHeightMeasuredFor = (width, contentSize, maximumHeight)
        }
        let height = min(itemHeight, maximumHeight).rounded(.up)
        if preferredContentSize.width != width || preferredContentSize.height != height {
            preferredContentSize = CGSize(width: width, height: height)
        }
    }

    /// Follows the orientation, so landscape gets its own, much shorter, height.
    private var screenBounds: CGRect {
        if #available(iOS 13.0, *), let screen = view.window?.windowScene?.screen {
            return screen.bounds
        }
        return UIScreen.main.bounds
    }

    private func maximumContentHeight(forWidth width: CGFloat) -> CGFloat {
        metrics.maximumContentHeight(
            screenSize: screenBounds.size, isPhone: UIDevice.current.userInterfaceIdiom == .phone,
            systemContentHeight: isDefaultContentHidden ? 0 : systemContentHeight(forWidth: width))
    }

    /// Estimates iOS's own banner above the carousel, which grows with longer push text.
    private func systemContentHeight(forWidth width: CGFloat) -> CGFloat {
        guard let content = notification?.request.content else { return 0 }
        let textWidth = width - metrics.systemTextLeadingMargin - metrics.edgeMargin
        let titleWidth = textWidth - metrics.systemTitleTrailingSpace
        let texts: [(String, UIFont.TextStyle, CGFloat)] = [
            (content.title, .headline, titleWidth), (content.subtitle, .headline, textWidth), (content.body, .body, textWidth)
        ]
        let textHeight = texts.filter { !$0.0.isEmpty }.reduce(CGFloat(0)) { total, text in
            let font = UIFont.preferredFont(forTextStyle: text.1)
            let size = (text.0 as NSString).boundingRect(
                with: CGSize(width: text.2, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font],
                context: nil)
            return total + size.height.rounded(.up)
        }
        return textHeight + metrics.systemContentPadding
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // The width can settle after didReceive, and rotation changes the space available even when the
        // width stays the same; unchanged sizes aren't reassigned
        updatePreferredContentSize()
    }

    open override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        guard !items.isEmpty else { return }
        if previous?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            // Pages that aren't on screen don't get the trait change themselves
            itemControllers.forEach { $0.applyFonts() }
            updatePreferredContentSize()
        }
    }

    // MARK: - Subclass hooks

    /// Colour of the inactive page indicator dots.
    open var pageIndicatorTintColor: UIColor { SwrveCarouselPalette.label.withAlphaComponent(0.3) }

    /// Colour of the dot for the item currently on screen.
    open var currentPageIndicatorTintColor: UIColor { SwrveCarouselPalette.label }

    /// Handles a tap on a carousel item.
    ///
    /// A content extension has no `UIApplication` and the system will not hand off to another app
    /// while the device is locked, so `extensionContext.open(_:)` silently fails from the lock
    /// screen. Instead the tap is recorded in the App Group and the default action is performed,
    /// which launches the app; `SwrveNotificationManager.notificationResponseReceived` then
    /// resolves it.
    ///
    /// Both action types take this path. `open_url` records its url; `open_app` records no url but
    /// still writes the record, so the index reaches the engaged event.
    open func carouselItemTapped(at index: Int) {
        defer {
            // Always hand off, even if the record could not be written — a tap must never be a
            // dead end. Worst case the app launches without the per-item deeplink.
            extensionContext?.performNotificationDefaultAction()
        }

        guard index >= 0, index < items.count else { return }
        let item = items[index]

        guard let appGroupIdentifier = appGroupIdentifier else {
            SwrveLogger.logError(
                "SwrveNotificationCarouselViewController: no appGroupIdentifier, carousel tap cannot be attributed. Override appGroupIdentifier in your subclass."
            )
            return
        }
        // Matched on the per-delivery request identifier, not the push id `_p` — `_p` is
        // campaign-level, so two notifications from the same campaign share it and a stale tap
        // could be attributed to the wrong one.
        guard let requestId = notification?.request.identifier, !requestId.isEmpty else {
            SwrveLogger.logError("SwrveNotificationCarouselViewController: no notification request id, carousel tap cannot be attributed.")
            return
        }

        let action = (item.actionType == .openUrl) ? item.action : nil
        SwrveSEConfig.saveCarouselItemTap(
            appGroupIdentifier,
            requestId: requestId,
            itemIndex: index,
            action: action)
    }

    /// Reports that a carousel item was seen.
    ///
    /// De-duplication lives in the App Group rather than in memory: the extension is re-instantiated
    /// when a notification is collapsed and re-expanded, so item 0 would otherwise re-report on
    /// every expansion. This is the only carousel event sent from the extension — the engaged event
    /// comes from the app, because the tap launches it (F2).
    private func reportPageView(at index: Int) {
        guard let appGroupIdentifier = appGroupIdentifier else {
            SwrveLogger.logError(
                "SwrveNotificationCarouselViewController: no appGroupIdentifier, carousel page views cannot be reported. Override appGroupIdentifier in your subclass."
            )
            return
        }
        guard let notification = notification else { return }
        let requestId = notification.request.identifier
        guard !requestId.isEmpty else { return }

        guard reportedItems.insert(index).inserted else { return }

        let userInfo = notification.request.content.userInfo
        let delivery = SwrveCampaignDelivery(appGroupId: appGroupIdentifier)
        delivery.sendCarouselPageView(userInfo, requestId: requestId, itemIndex: index)
    }

    func index(of controller: UIViewController) -> Int? {
        itemControllers.firstIndex { $0 === controller }
    }
}

// MARK: - Paging

extension SwrveNotificationCarouselViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        neighbour(of: viewController, offset: -1)
    }

    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        neighbour(of: viewController, offset: 1)
    }

    /// Two items don't wrap: the item either side would be the same controller, which the scrolling pager
    /// doesn't support.
    private func neighbour(of viewController: UIViewController, offset: Int) -> UIViewController? {
        guard itemControllers.count > 1, let current = index(of: viewController) else { return nil }
        let next = current + offset
        if itemControllers.count > 2 {
            return itemControllers[wrappedIndex(next)]
        }
        return itemControllers.indices.contains(next) ? itemControllers[next] : nil
    }

    public func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed,
            let visible = pageViewController.viewControllers?.first,
            let current = index(of: visible)
        else { return }
        pageControl.currentPage = current
        loadItems(around: current)
        reportPageView(at: current)
    }
}

#endif
