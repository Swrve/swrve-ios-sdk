import UIKit
import XCTest

@testable import SwrveSDKCommon

class SwrveTestCarouselItem: XCTestCase {

    private func swrvePayload(_ name: String) -> [AnyHashable: Any] {
        guard let filePath = Bundle.main.path(forResource: "carousel_payloads", ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
            let all = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let payload = all[name] as? [AnyHashable: Any]
        else {
            XCTFail("Missing carousel_payloads.json fixture: \(name)")
            return [:]
        }
        return payload
    }

    private func items(_ name: String) -> [SwrveCarouselItem]? {
        SwrveCarouselItem.items(fromSwrvePayload: swrvePayload(name))
    }

    func testCanonicalPayloadParses() {
        let items = items("canonical")
        XCTAssertEqual(items?.count, 2)

        XCTAssertEqual(items?[0].title, "$110 off")
        XCTAssertEqual(items?[0].body, "55-inch 4K LED television")
        XCTAssertEqual(items?[0].imageUrl, "https://cdn.example.com/carousel/item1.png")
        XCTAssertEqual(items?[0].actionType, .openUrl)
        XCTAssertEqual(items?[0].action, "https://www.example.com/")

        XCTAssertEqual(items?[1].actionType, .openApp)
        XCTAssertEqual(items?[1].action, "")
    }

    func testEmptyArrayIsNotACarousel() {
        XCTAssertNil(items("empty_array"))
    }

    func testSupersededObjectShapeIsNotACarousel() {
        XCTAssertNil(items("not_an_array"))
    }

    func testMissingCarouselKeyIsNotACarousel() {
        XCTAssertNil(SwrveCarouselItem.items(fromSwrvePayload: ["version": 1]))
    }

    func testNilPayloadIsNotACarousel() {
        XCTAssertNil(SwrveCarouselItem.items(fromSwrvePayload: nil))
    }

    func testItemMissingImageUrlIsNotACarousel() {
        XCTAssertNil(items("item_missing_image_url"))
    }

    func testItemWithEmptyImageUrlIsNotACarousel() {
        XCTAssertNil(items("item_empty_image_url"))
    }

    func testMalformedElementIsNotACarousel() {
        let payload: [AnyHashable: Any] = ["carousel": ["not an object"]]
        XCTAssertNil(SwrveCarouselItem.items(fromSwrvePayload: payload))
    }

    func testOptionalFieldsMayBeAbsent() {
        let items = items("optional_fields_absent")
        XCTAssertEqual(items?.count, 4)

        XCTAssertNil(items?[1].title)
        XCTAssertNil(items?[1].body)
        XCTAssertNil(items?[1].action)
        XCTAssertEqual(items?[1].actionType, .openApp)

        XCTAssertNil(items?[2].title)
        XCTAssertEqual(items?[2].body, "index 2 has no title")

        XCTAssertEqual(items?[3].action, "https://www.example.com/offers/3")
    }

    func testItemCountIsNotCapped() {
        XCTAssertEqual(items("seven_items_all_retained")?.count, 7)
    }

    func testActionTypeResolution() {
        let items = items("action_type_variants")
        XCTAssertEqual(items?[0].actionType, .openUrl)
        XCTAssertEqual(items?[1].actionType, .openApp)
        XCTAssertEqual(items?[2].actionType, .openApp)
        XCTAssertEqual(items?[3].actionType, .openApp)
        XCTAssertEqual(items?[4].actionType, .openApp)
    }

    func testStraySettingsKeysAreIgnored() {
        XCTAssertEqual(items("stray_settings_keys_are_ignored")?.count, 1)
    }

    func testNonStringOptionalFieldsCoerceToNil() {
        let payload: [AnyHashable: Any] = [
            "carousel": [
                [
                    "image_url": "https://cdn.example.com/carousel/0.png",
                    "title": 42,
                    "body": NSNull(),
                    "action_type": 7
                ]
            ]
        ]
        let items = SwrveCarouselItem.items(fromSwrvePayload: payload)
        XCTAssertEqual(items?.count, 1)
        XCTAssertNil(items?[0].title)
        XCTAssertNil(items?[0].body)
        XCTAssertEqual(items?[0].actionType, .openApp)
    }

    func testNonStringImageUrlIsNotACarousel() {
        let payload: [AnyHashable: Any] = ["carousel": [["image_url": 42]]]
        XCTAssertNil(SwrveCarouselItem.items(fromSwrvePayload: payload))
    }

    // MARK: - Item layout

    private let width: CGFloat = 400
    private var metrics = SwrveCarouselMetrics()

    private func image(width: CGFloat, height: CGFloat) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: width, height: height)).image { _ in }
    }

    private func itemController(
        title: String? = "Title", body: String? = "Body", image: UIImage?, icon: UIImage? = nil,
        imageHeightRatio: CGFloat = 0.5,
        loadImage: ((String, @escaping (UIImage?) -> Void) -> Void)? = nil
    ) -> SwrveCarouselItemViewController {
        var dictionary: [AnyHashable: Any] = ["image_url": "https://example.com/item.png"]
        dictionary["title"] = title
        dictionary["body"] = body
        let controller = SwrveCarouselItemViewController(
            item: SwrveCarouselItem(dictionary: dictionary)!,
            index: 0,
            metrics: metrics,
            leadingMargin: 63,
            topMargin: metrics.verticalSpacing,
            titleIcon: icon,
            imageHeightRatio: imageHeightRatio,
            loadImage: loadImage ?? { _, completion in completion(image) },
            onTap: { _ in })
        controller.loadImageIfNeeded()
        return controller
    }

    private func height(_ controller: SwrveCarouselItemViewController) -> CGFloat {
        controller.fittingHeight(forWidth: width)
    }

    private func imageArea(in controller: SwrveCarouselItemViewController) -> SwrveCarouselImageView {
        allSubviews(of: controller.view).compactMap { $0 as? SwrveCarouselImageView }.first!
    }

    private func imageAreaFrame(in controller: SwrveCarouselItemViewController) -> CGRect {
        let area = imageArea(in: controller)
        return area.convert(area.bounds, to: controller.view)
    }

    private func allSubviews(of view: UIView) -> [UIView] {
        view.subviews + view.subviews.flatMap { allSubviews(of: $0) }
    }

    /// Frames in the item's own coordinates, after it's been measured.
    private func frames<T: UIView>(of type: T.Type, in controller: SwrveCarouselItemViewController) -> [CGRect] {
        _ = height(controller)
        return allSubviews(of: controller.view).compactMap { $0 as? T }.filter { !$0.isHidden }
            .map { $0.convert($0.bounds, to: controller.view) }
    }

    func testImageAreaTakesTheGivenShapeWhateverTheImage() {
        for ratio: CGFloat in [1.0 / 3.0, 0.5, 1, 1.5] {
            let images: [UIImage?] = [image(width: 200, height: 100), image(width: 100, height: 200), image(width: 300, height: 100), nil]
            let controllers = images.map { itemController(image: $0, imageHeightRatio: ratio) }
            let heights = controllers.map { height($0) }
            XCTAssertEqual(Set(heights).count, 1, "the image must not change the item's height")
            for controller in controllers {
                let area = imageAreaFrame(in: controller)
                XCTAssertEqual(area.minX, 0)
                XCTAssertEqual(area.width, width)
                XCTAssertEqual(area.height, width * ratio, accuracy: 0.5)
            }
        }
    }

    func testImageAreaStopsAtMaximumHeight() {
        let controller = itemController(image: image(width: 200, height: 300), imageHeightRatio: 1.5)
        _ = controller.fittingHeight(forWidth: 500)
        XCTAssertEqual(imageAreaFrame(in: controller).height, metrics.maximumImageHeight, accuracy: 0.5)
    }

    private func layOut(
        _ controllers: [SwrveCarouselItemViewController], maximumHeight: CGFloat, imageHeightRatio: CGFloat
    ) -> CGFloat {
        SwrveCarouselItemViewController.layOut(
            controllers, forWidth: width, maximumHeight: maximumHeight, imageHeightRatio: imageHeightRatio,
            minimumImageHeightRatio: metrics.minimumImageHeightRatio)
    }

    func testImageAreaKeepsTheFirstImageShapeWhenItFits() {
        let controllers = [itemController(image: nil), itemController(body: "A longer body that wraps onto a second line", image: nil)]
        let height = layOut(controllers, maximumHeight: 1000, imageHeightRatio: 1)
        XCTAssertLessThan(height, 1000)
        for controller in controllers {
            XCTAssertEqual(imageAreaFrame(in: controller).height, width, accuracy: 0.5)
        }
    }

    func testImageAreaIsShortenedSoItemsFitTheSpaceAvailable() {
        let controllers = [itemController(image: nil), itemController(body: "A longer body that wraps onto a second line", image: nil)]
        let height = layOut(controllers, maximumHeight: 500, imageHeightRatio: 1.5)
        XCTAssertEqual(height, 500, accuracy: 0.5, "items fill the space available, so nothing scrolls")
        let imageHeights = controllers.map { imageAreaFrame(in: $0).height }
        XCTAssertLessThan(imageHeights[0], width * 1.5)
        XCTAssertEqual(imageHeights[0], imageHeights[1], accuracy: 0.5, "every image area keeps the same shape")
    }

    func testImageAreaIsShortenedAgainWhenTheSpaceAvailableShrinks() {
        let controller = itemController(image: nil)
        _ = layOut([controller], maximumHeight: 600, imageHeightRatio: 1.5)
        let tallerImage = imageAreaFrame(in: controller).height
        XCTAssertEqual(layOut([controller], maximumHeight: 400, imageHeightRatio: 1.5), 400, accuracy: 0.5)
        XCTAssertEqual(imageAreaFrame(in: controller).height, tallerImage - 200, accuracy: 0.5)
    }

    func testImageAreaIsShortenedNoFurtherThanTheMinimumShape() {
        let controller = itemController(image: nil)
        // a 3:1 image area just fits under the text
        let heightWithMinimumShape = layOut([controller], maximumHeight: 1000, imageHeightRatio: metrics.minimumImageHeightRatio)
        XCTAssertEqual(layOut([controller], maximumHeight: heightWithMinimumShape, imageHeightRatio: 1), heightWithMinimumShape, accuracy: 0.5)
        XCTAssertEqual(imageAreaFrame(in: controller).height, width * metrics.minimumImageHeightRatio, accuracy: 0.5)
    }

    func testImageAreaKeepsTheFirstImageShapeWhenItemsCannotFit() {
        // As in landscape: even a 3:1 image area doesn't fit, so cropping wouldn't stop the item scrolling
        let controller = itemController(image: nil)
        let height = layOut([controller], maximumHeight: 150, imageHeightRatio: 1)
        XCTAssertEqual(imageAreaFrame(in: controller).height, width, accuracy: 0.5, "the whole image can be scrolled to")
        XCTAssertGreaterThan(height, 150, "an item that doesn't fit scrolls")
    }

    private let textTooLongToFit = String(repeating: "A body long enough to wrap onto several lines at this width. ", count: 20)

    func testItemWithTextTooLongToFitScrollsWithoutPushingOtherImagesDown() {
        let controllers = [
            itemController(body: textTooLongToFit, image: nil),
            itemController(body: nil, image: nil),
            itemController(body: "A longer body that wraps onto a second line", image: nil)
        ]
        let laidOutHeight = layOut(controllers, maximumHeight: 500, imageHeightRatio: 1)
        XCTAssertEqual(laidOutHeight, 500, accuracy: 0.5)
        XCTAssertGreaterThan(height(controllers[0]), 500, "the item that doesn't fit scrolls")
        XCTAssertEqual(height(controllers[1]), 500, accuracy: 0.5, "items that fit fill the space available")
        XCTAssertEqual(height(controllers[2]), 500, accuracy: 0.5)

        let imageAreas = controllers.map { imageAreaFrame(in: $0) }
        XCTAssertGreaterThan(imageAreas[0].minY, imageAreas[1].minY)
        XCTAssertEqual(imageAreas[1].minY, imageAreas[2].minY, accuracy: 0.5, "items that fit still line up their images")
        XCTAssertLessThan(imageAreas[1].height, width, "shortened so the items that fit fit")
        for area in imageAreas {
            XCTAssertEqual(area.height, imageAreas[1].height, accuracy: 0.5, "every image area keeps the same shape")
        }
    }

    func testItemsThatFitWithoutShorteningSizeTheCarouselNotTheItemThatScrolls() {
        let controllers = [itemController(body: nil, image: nil), itemController(body: textTooLongToFit, image: nil)]
        let laidOutHeight = layOut(controllers, maximumHeight: 700, imageHeightRatio: 1)
        XCTAssertLessThan(laidOutHeight, 700)
        XCTAssertEqual(laidOutHeight, height(controllers[0]), accuracy: 0.5, "no gap under the image of an item that fits")
        XCTAssertGreaterThan(height(controllers[1]), 700)
        XCTAssertEqual(imageAreaFrame(in: controllers[0]).height, width, accuracy: 0.5)
    }

    func testItemWithLongTextDoesNotPushOtherImagesDownWhenNoItemFits() {
        // As in landscape: even a 3:1 image area doesn't fit under the shortest text
        let controllers = [itemController(body: textTooLongToFit, image: nil), itemController(body: nil, image: nil)]
        let laidOutHeight = layOut(controllers, maximumHeight: 200, imageHeightRatio: 1)
        XCTAssertGreaterThan(laidOutHeight, 200, "items that don't fit scroll")
        XCTAssertEqual(laidOutHeight, height(controllers[1]), accuracy: 0.5)
        let imageAreas = controllers.map { imageAreaFrame(in: $0) }
        XCTAssertLessThan(imageAreas[1].minY, 100, "the short item's image starts where it can be seen")
        XCTAssertGreaterThan(imageAreas[0].minY, imageAreas[1].minY)
        XCTAssertEqual(imageAreas[0].height, width, accuracy: 0.5, "the whole image can be scrolled to")
        XCTAssertEqual(imageAreas[1].height, width, accuracy: 0.5)
    }

    func testItemFitsWhenTheMaximumImageHeightIsBelowTheMinimumShape() {
        metrics.maximumImageHeight = 80
        let longer = itemController(body: String(repeating: "A body that wraps onto several lines. ", count: 10), image: nil)
        _ = longer.textAreaFittingHeight(forWidth: width)
        let heightWithoutImage = height(longer) - imageAreaFrame(in: longer).height
        // Room for the capped image area, though not for a 3:1 one
        let maximumHeight = heightWithoutImage + 100
        let controllers = [itemController(body: nil, image: nil), longer]
        _ = layOut(controllers, maximumHeight: maximumHeight, imageHeightRatio: 1)
        XCTAssertLessThanOrEqual(height(longer), maximumHeight, "the item fits, so it doesn't scroll")
        XCTAssertEqual(imageAreaFrame(in: controllers[0]).minY, imageAreaFrame(in: longer).minY, accuracy: 0.5)
    }

    func testItemsAreAllMatchedWhenEveryItemsTextIsLong() {
        let controllers = [
            itemController(body: textTooLongToFit, image: nil),
            itemController(body: textTooLongToFit + textTooLongToFit, image: nil)
        ]
        _ = layOut(controllers, maximumHeight: 500, imageHeightRatio: 1)
        let imageAreas = controllers.map { imageAreaFrame(in: $0) }
        XCTAssertEqual(imageAreas[0].minY, imageAreas[1].minY, accuracy: 0.5)
        XCTAssertEqual(imageAreas[0].height, width, accuracy: 0.5)
    }

    func testImageAreaShapeFollowsTheFirstImage() {
        XCTAssertEqual(metrics.imageHeightRatio(forFirstImageRatio: 0.5), 0.5)
        XCTAssertEqual(metrics.imageHeightRatio(forFirstImageRatio: 1), 1)
        XCTAssertEqual(metrics.imageHeightRatio(forFirstImageRatio: 1.25), 1.25)
    }

    func testImageAreaShapeIsLimitedToBannerAndPortrait() {
        XCTAssertEqual(metrics.imageHeightRatio(forFirstImageRatio: 0.1), metrics.minimumImageHeightRatio)
        XCTAssertEqual(metrics.imageHeightRatio(forFirstImageRatio: 16.0 / 9.0), metrics.maximumImageHeightRatio)
        XCTAssertEqual(metrics.minimumImageHeightRatio, 1.0 / 3.0, accuracy: 0.001, "3:1")
        XCTAssertEqual(metrics.maximumImageHeightRatio, 1.5, accuracy: 0.001, "2:3")
    }

    func testImageAreaShapeIsThreeToTwoWithoutAnImage() {
        XCTAssertEqual(metrics.imageHeightRatio(forFirstImageRatio: nil), 2.0 / 3.0, accuracy: 0.001)
        XCTAssertEqual(metrics.imageHeightRatio(forFirstImageRatio: 0), 2.0 / 3.0, accuracy: 0.001)
    }

    // An iPhone 17 Pro's screen, in points
    private let phonePortrait = CGSize(width: 402, height: 874)
    private let phoneLandscape = CGSize(width: 874, height: 402)

    func testSpaceAvailableIsAFractionOfThePortraitScreen() {
        let height = metrics.maximumContentHeight(screenSize: phonePortrait, isPhone: true, systemContentHeight: 0)
        XCTAssertEqual(height, 874 * metrics.maximumHeightScreenFraction, accuracy: 0.5)
    }

    func testSpaceAvailableInPhoneLandscapeIsWhatIOSLeavesTheCard() {
        let height = metrics.maximumContentHeight(screenSize: phoneLandscape, isPhone: true, systemContentHeight: 0)
        XCTAssertEqual(height, 402 - metrics.systemVerticalSpace, accuracy: 0.5, "as tall as a rich push gets")
        XCTAssertGreaterThan(height, 402 * metrics.maximumHeightScreenFraction)
    }

    func testSpaceAvailableInPhoneLandscapeLeavesRoomForTheSystemBanner() {
        let height = metrics.maximumContentHeight(screenSize: phoneLandscape, isPhone: true, systemContentHeight: 60)
        XCTAssertEqual(height, 402 - metrics.systemVerticalSpace - 60, accuracy: 0.5)
    }

    func testSpaceAvailableOnALandscapeIPadIsStillAFractionOfTheScreen() {
        let height = metrics.maximumContentHeight(
            screenSize: CGSize(width: 1024, height: 768), isPhone: false, systemContentHeight: 0)
        XCTAssertEqual(height, 768 * metrics.maximumHeightScreenFraction, accuracy: 0.5)
    }

    func testSpaceAvailableNeverDropsBelowTheMinimum() {
        let height = metrics.maximumContentHeight(
            screenSize: phoneLandscape, isPhone: true, systemContentHeight: 400)
        XCTAssertEqual(height, metrics.minimumContentHeight)
    }

    func testPlaceholderShowsUntilImageLoadsWithoutChangingHeight() {
        var completeLoad: ((UIImage?) -> Void)?
        let controller = itemController(image: nil, loadImage: { _, completion in completeLoad = completion })
        let heightWhileLoading = height(controller)
        XCTAssertTrue(imageArea(in: controller).isShowingPlaceholder)

        completeLoad?(image(width: 100, height: 300))
        XCTAssertFalse(imageArea(in: controller).isShowingPlaceholder)
        XCTAssertEqual(height(controller), heightWhileLoading)
    }

    func testFailedImageKeepsPlaceholder() {
        let failed = itemController(image: nil)
        XCTAssertTrue(imageArea(in: failed).isShowingPlaceholder)
        XCTAssertEqual(height(failed), height(itemController(image: image(width: 200, height: 100))))
    }

    func testTallerImageIsCroppedFromTheBottom() {
        let area = CGRect(x: 0, y: 0, width: 400, height: 200)
        let frame = SwrveCarouselImageView.fillFrame(forImageSize: CGSize(width: 100, height: 200), in: area)
        XCTAssertEqual(frame, CGRect(x: 0, y: 0, width: 400, height: 800))
    }

    func testWiderImageIsCroppedFromTheSides() {
        let area = CGRect(x: 0, y: 0, width: 400, height: 200)
        let frame = SwrveCarouselImageView.fillFrame(forImageSize: CGSize(width: 400, height: 100), in: area)
        XCTAssertEqual(frame, CGRect(x: -200, y: 0, width: 800, height: 200))
    }

    func testImageIsOnlyLoadedWhenRequested() {
        var loads = 0
        let controller = SwrveCarouselItemViewController(
            item: SwrveCarouselItem(dictionary: ["image_url": "https://example.com/item.png", "title": "Title"])!,
            index: 0, metrics: metrics, leadingMargin: 63, topMargin: metrics.verticalSpacing, titleIcon: nil,
            imageHeightRatio: 0.5, loadImage: { _, _ in loads += 1 }, onTap: { _ in })
        _ = SwrveCarouselItemViewController.matchTextAreas(of: [controller], forWidth: width)
        XCTAssertEqual(loads, 0, "measuring an item must not decode its image")
        controller.loadImageIfNeeded()
        controller.loadImageIfNeeded()
        XCTAssertEqual(loads, 1)
    }

    func testItemsMatchTheTallestTextAndLineUpTheirImages() {
        let image = image(width: 200, height: 100)
        let controllers = [
            itemController(body: nil, image: image),
            itemController(body: "A body long enough to wrap onto several lines at this width, so it is the tallest", image: image),
            itemController(title: nil, body: nil, image: image)
        ]
        let tallest = controllers.map { height($0) }.max()!
        let matched = SwrveCarouselItemViewController.matchTextAreas(of: controllers, forWidth: width)
        XCTAssertEqual(matched, tallest, accuracy: 0.5)
        XCTAssertEqual(Set(controllers.map { height($0) }).count, 1)
        let imageTops = controllers.map { imageAreaFrame(in: $0).minY }
        XCTAssertEqual(Set(imageTops).count, 1, "the image must sit in the same place on every item")
        let shortText = frames(of: UILabel.self, in: controllers[0])[0]
        XCTAssertEqual(shortText.minY, metrics.verticalSpacing, accuracy: 0.5, "shorter text stays at the top")
    }

    func testShorterTextKeepsBodyDirectlyUnderTitle() {
        let image = image(width: 200, height: 100)
        let controllers = [
            itemController(body: "Short body", image: image),
            itemController(body: "A body long enough to wrap onto several lines at this width, so it is the tallest", image: image)
        ]
        _ = SwrveCarouselItemViewController.matchTextAreas(of: controllers, forWidth: width)
        _ = height(controllers[0])
        let labels = allSubviews(of: controllers[0].view).compactMap { $0 as? UILabel }.filter { !$0.isHidden }
        XCTAssertEqual(labels.count, 2)
        for label in labels {
            let fitting = label.sizeThatFits(CGSize(width: label.bounds.width, height: .greatestFiniteMagnitude)).height
            XCTAssertEqual(label.bounds.height, fitting, accuracy: 0.5, "\(label.text ?? "") must not stretch into the spare space")
        }
        let title = labels[0].convert(labels[0].bounds, to: controllers[0].view)
        let body = labels[1].convert(labels[1].bounds, to: controllers[0].view)
        XCTAssertEqual(body.minY, title.maxY + metrics.titleBodySpacing, accuracy: 0.5)
    }

    func testImageOnlyItemsHaveNoTextArea() {
        let image = image(width: 200, height: 100)
        let controllers = [itemController(title: nil, body: nil, image: image), itemController(title: nil, body: nil, image: image)]
        let matched = SwrveCarouselItemViewController.matchTextAreas(of: controllers, forWidth: width)
        XCTAssertEqual(matched, width / 2 + metrics.pageControlReservedHeight, accuracy: 1)
        XCTAssertEqual(imageAreaFrame(in: controllers[0]).minY, 0)
    }

    func testImageOnlyItemHasNoTextBlock() {
        let controller = itemController(title: nil, body: nil, image: image(width: 200, height: 100))
        XCTAssertEqual(height(controller), width / 2 + metrics.pageControlReservedHeight, accuracy: 1)
        XCTAssertTrue(frames(of: UILabel.self, in: controller).isEmpty)
    }

    func testImageOnlyItemShowsIconAboveImage() {
        let controller = itemController(title: nil, body: nil, image: image(width: 200, height: 100), icon: image(width: 35, height: 35))
        let iconRow = metrics.verticalSpacing + metrics.titleIconSize + metrics.verticalSpacing
        XCTAssertEqual(height(controller), iconRow + width / 2 + metrics.pageControlReservedHeight, accuracy: 1)
        let icon = frames(of: UIImageView.self, in: controller).first { $0.width == metrics.titleIconSize }
        XCTAssertEqual(icon?.minX ?? -1, metrics.titleIconLeadingMargin, accuracy: 0.5)
        XCTAssertEqual(icon?.minY ?? -1, metrics.verticalSpacing, accuracy: 0.5)
        XCTAssertTrue(frames(of: UILabel.self, in: controller).isEmpty)
    }

    func testContentScrollsAbovePageControlWhenItDoesNotFit() {
        let controller = itemController(image: image(width: 100, height: 200))
        let needed = height(controller)
        controller.view.bounds.size.height = needed - 100
        controller.view.layoutIfNeeded()
        let scrollView = allSubviews(of: controller.view).compactMap { $0 as? UIScrollView }.first!
        XCTAssertEqual(scrollView.frame.maxY, controller.view.bounds.height - metrics.pageControlReservedHeight, accuracy: 0.5)
        XCTAssertGreaterThan(scrollView.contentSize.height, scrollView.bounds.height)
        XCTAssertTrue(scrollView.isScrollEnabled)
        XCTAssertFalse(scrollView.bounces)
    }

    func testItemThatFitsDoesNotScroll() {
        let controller = itemController(image: image(width: 200, height: 100))
        controller.view.bounds.size.height = height(controller)
        controller.view.layoutIfNeeded()
        let scrollView = allSubviews(of: controller.view).compactMap { $0 as? UIScrollView }.first!
        XCTAssertFalse(scrollView.isScrollEnabled)
    }

    private func iconAndText(_ controller: SwrveCarouselItemViewController) -> (icon: CGRect, text: [CGRect]) {
        let icon = frames(of: UIImageView.self, in: controller).first { $0.width == metrics.titleIconSize }!
        return (icon, frames(of: UILabel.self, in: controller))
    }

    func testIconIsCentredOnTitleAndBody() {
        let controller = itemController(
            title: "A title long enough to wrap onto a second line at this width", image: nil, icon: image(width: 35, height: 35))
        let layout = iconAndText(controller)
        let textCentre = (layout.text.map { $0.minY }.min()! + layout.text.map { $0.maxY }.max()!) / 2
        XCTAssertEqual(layout.icon.midY, textCentre, accuracy: 1)
        XCTAssertEqual(layout.icon.minX, metrics.titleIconLeadingMargin, accuracy: 0.5)
    }

    func testIconIsCentredOnTitleWhenThereIsNoBody() {
        let layout = iconAndText(itemController(body: nil, image: nil, icon: image(width: 35, height: 35)))
        XCTAssertEqual(layout.text.count, 1)
        XCTAssertEqual(layout.icon.midY, layout.text[0].midY, accuracy: 1)
    }
}
