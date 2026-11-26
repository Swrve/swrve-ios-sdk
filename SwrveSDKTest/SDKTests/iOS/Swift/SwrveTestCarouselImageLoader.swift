import ImageIO
import UIKit
import XCTest

@testable import SwrveSDKCommon

class SwrveTestCarouselImageLoader: XCTestCase {

    /// Port 1 refuses immediately, so the download-failure tests need no network and no DNS.
    private let unreachableUrl = "http://127.0.0.1:1/swrve-carousel-unreachable.png"
    private let cachedUrl = "https://example.com/swrve-carousel-cached.png"
    private let downloadUrl = "https://example.com/swrve-carousel-downloaded.png"

    private func cacheFileUrl(for urlString: String) -> URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let directory = caches.appendingPathComponent("com.swrve.carousel", isDirectory: true)
        let urlData = Data(urlString.utf8)
        guard let sha1 = SwrveUtils.sha1(urlData) else {
            XCTFail("SwrveUtils.sha1 returned nil")
            return directory
        }
        return directory.appendingPathComponent(sha1)
    }

    override func tearDown() {
        for url in [unreachableUrl, cachedUrl, downloadUrl] {
            try? FileManager.default.removeItem(at: cacheFileUrl(for: url))
        }
        SwrveStubURLProtocol.responseData = nil
        SwrveStubURLProtocol.resetRequestedUrls()
        super.tearDown()
    }

    private func writeToCache(_ data: Data, for urlString: String) {
        let file = cacheFileUrl(for: urlString)
        try? FileManager.default.createDirectory(
            at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        XCTAssertNoThrow(try data.write(to: file))
    }

    private func pngData(width: Int, height: Int) -> Data {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let size = CGSize(width: width, height: height)
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return image.pngData() ?? Data()
    }

    private func load(
        _ urlString: String,
        maximumPixelDimension: Int? = nil,
        stubbing stubbedResponse: Data? = nil
    ) -> UIImage? {
        let loader: SwrveCarouselImageLoader
        if let stubbedResponse = stubbedResponse {
            SwrveStubURLProtocol.responseData = stubbedResponse
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [SwrveStubURLProtocol.self]
            loader = SwrveCarouselImageLoader(appGroupIdentifier: nil, configuration: configuration)
        } else {
            loader = SwrveCarouselImageLoader(appGroupIdentifier: nil)
        }
        if let maximumPixelDimension = maximumPixelDimension {
            loader.maximumPixelDimension = maximumPixelDimension
        }

        var result: UIImage?
        let loaded = expectation(description: "loadImage")
        loader.loadImage(fromUrl: urlString) { image in
            XCTAssertTrue(Thread.isMainThread, "completion must be called on the main queue")
            result = image
            loaded.fulfill()
        }
        waitForExpectations(timeout: 10)
        return result
    }

    /// A 60 x 20 photo stored with EXIF orientation 6, so it displays as 20 x 60.
    private func rotatedJpegData() -> Data {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 60, height: 20), format: format).image { _ in }
        let data = NSMutableData()
        guard let cgImage = image.cgImage,
            let destination = CGImageDestinationCreateWithData(data, "public.jpeg" as CFString, 1, nil)
        else { return Data() }
        CGImageDestinationAddImage(destination, cgImage, [kCGImagePropertyOrientation: 6] as CFDictionary)
        CGImageDestinationFinalize(destination)
        return data as Data
    }

    func testFirstCachedImageGivesTheShape() {
        writeToCache(pngData(width: 40, height: 20), for: cachedUrl)
        writeToCache(pngData(width: 20, height: 40), for: downloadUrl)
        let loader = SwrveCarouselImageLoader(appGroupIdentifier: nil)
        XCTAssertEqual(loader.cachedImageHeightRatio(forUrls: [cachedUrl, downloadUrl]) ?? 0, 0.5, accuracy: 0.001)
    }

    func testShapeComesFromTheNextCachedImageWhenTheFirstIsMissing() {
        writeToCache(pngData(width: 20, height: 40), for: downloadUrl)
        let loader = SwrveCarouselImageLoader(appGroupIdentifier: nil)
        XCTAssertEqual(loader.cachedImageHeightRatio(forUrls: [unreachableUrl, downloadUrl]) ?? 0, 2, accuracy: 0.001)
    }

    func testShapeComesFromTheNextImageWhenTheFirstCannotBeRead() {
        writeToCache(Data("not an image".utf8), for: cachedUrl)
        writeToCache(pngData(width: 30, height: 20), for: downloadUrl)
        let loader = SwrveCarouselImageLoader(appGroupIdentifier: nil)
        XCTAssertEqual(loader.cachedImageHeightRatio(forUrls: [cachedUrl, downloadUrl]) ?? 0, 2.0 / 3.0, accuracy: 0.001)
    }

    func testNoShapeWhenNothingIsCached() {
        let loader = SwrveCarouselImageLoader(appGroupIdentifier: nil)
        XCTAssertNil(loader.cachedImageHeightRatio(forUrls: [cachedUrl, downloadUrl]))
    }

    func testRotatedPhotoGivesItsDisplayedShape() {
        writeToCache(rotatedJpegData(), for: cachedUrl)
        let loader = SwrveCarouselImageLoader(appGroupIdentifier: nil)
        XCTAssertEqual(loader.cachedImageHeightRatio(forUrls: [cachedUrl]) ?? 0, 3, accuracy: 0.001)
    }

    func testCachedImageIsReturnedWithoutDownloading() {
        writeToCache(pngData(width: 40, height: 20), for: cachedUrl)

        let image = load(cachedUrl)

        // example.com is never reached — a cache miss here would fail or hang rather than succeed.
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.size.width, 40)
        XCTAssertEqual(image?.size.height, 20)
    }

    func testLargeImageIsDownscaledToMaximumPixelDimension() {
        writeToCache(pngData(width: 2000, height: 1000), for: cachedUrl)

        let image = load(cachedUrl, maximumPixelDimension: 100)

        XCTAssertNotNil(image)
        XCTAssertEqual(image?.size.width, 100)
        XCTAssertEqual(image?.size.height, 50, "aspect ratio should be preserved")
    }

    func testUnreachableImageReturnsNil() {
        XCTAssertNil(load(unreachableUrl))
    }

    func testSuccessfulDownloadReturnsImageAndPopulatesCache() {
        let cacheFile = cacheFileUrl(for: downloadUrl)
        XCTAssertFalse(FileManager.default.fileExists(atPath: cacheFile.path), "precondition: cold cache")

        let image = load(downloadUrl, stubbing: pngData(width: 60, height: 30))

        XCTAssertNotNil(image)
        XCTAssertEqual(image?.size.width, 60)
        XCTAssertEqual(image?.size.height, 30)
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: cacheFile.path),
            "a successful download should be written to the cache")
    }

    func testDownloadedImageIsServedFromCacheOnSecondLoad() {
        XCTAssertNotNil(load(downloadUrl, stubbing: pngData(width: 60, height: 30)))

        // No stub this time: a cache miss would go to the real example.com and not return this image.
        let second = load(downloadUrl)

        XCTAssertNotNil(second)
        XCTAssertEqual(second?.size.width, 60)
    }

    func testOversizedDownloadIsRejected() {
        SwrveStubURLProtocol.responseData = pngData(width: 60, height: 30)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [SwrveStubURLProtocol.self]
        let loader = SwrveCarouselImageLoader(appGroupIdentifier: nil, configuration: configuration)
        loader.maximumDownloadBytes = 1

        var result: UIImage?
        let loaded = expectation(description: "loadImage")
        loader.loadImage(fromUrl: downloadUrl) { image in
            result = image
            loaded.fulfill()
        }
        waitForExpectations(timeout: 10)

        XCTAssertNil(result)
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: cacheFileUrl(for: downloadUrl).path),
            "an oversized download should not be cached")
    }

    // MARK: - Service extension

    private let secondDownloadUrl = "https://example.com/swrve-carousel-downloaded-2.png"

    /// Stands in for the App Group container, which the test host doesn't have.
    private let sharedContainer = FileManager.default.temporaryDirectory
        .appendingPathComponent("SwrveTestCarouselImageLoader", isDirectory: true)

    private func sharedCacheDirectory() -> URL {
        sharedContainer.appendingPathComponent("Library/Caches/com.swrve.carousel", isDirectory: true)
    }

    private func sharedCacheFileUrl(for urlString: String) -> URL? {
        guard let sha1 = SwrveUtils.sha1(Data(urlString.utf8)) else { return nil }
        return sharedCacheDirectory().appendingPathComponent(sha1)
    }

    private func clearSharedCache() {
        try? FileManager.default.removeItem(at: sharedContainer)
    }

    private func carouselPayload(_ imageUrls: [String]) -> [AnyHashable: Any] {
        ["carousel": imageUrls.map { ["image_url": $0] }]
    }

    /// Without `shared`, the loader has no App Group, as in an app that hasn't set one up.
    private func downloadCarouselMedia(_ imageUrls: [String], shared: Bool = true, stubbing stubbedResponse: Data? = nil) {
        let configuration = URLSessionConfiguration.ephemeral
        if let stubbedResponse = stubbedResponse {
            SwrveStubURLProtocol.responseData = stubbedResponse
            configuration.protocolClasses = [SwrveStubURLProtocol.self]
        }
        let loader = SwrveCarouselImageLoader(sharedContainer: shared ? sharedContainer : nil, configuration: configuration)
        let downloaded = expectation(description: "downloadCarouselMedia")
        loader.downloadCarouselMedia(fromSwrvePayload: carouselPayload(imageUrls)) {
            downloaded.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    private func setModificationDate(_ date: Date, of file: URL) {
        XCTAssertNoThrow(try FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: file.path))
    }

    private func modificationDate(of file: URL) -> Date? {
        try? FileManager.default.attributesOfItem(atPath: file.path)[.modificationDate] as? Date
    }

    func testDownloadCarouselMediaDownloadsEveryImageIntoTheSharedCache() throws {
        clearSharedCache()
        defer { clearSharedCache() }
        let first = try XCTUnwrap(sharedCacheFileUrl(for: downloadUrl))
        let second = try XCTUnwrap(sharedCacheFileUrl(for: secondDownloadUrl))

        downloadCarouselMedia([downloadUrl, secondDownloadUrl, downloadUrl], stubbing: pngData(width: 60, height: 30))

        XCTAssertTrue(FileManager.default.fileExists(atPath: first.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: second.path))
        let requested = SwrveStubURLProtocol.requestedUrls.map { $0.absoluteString }
        XCTAssertEqual(requested.filter { $0 == downloadUrl }.count, 1, "a repeated url should be downloaded once")
        XCTAssertEqual(requested.filter { $0 == secondDownloadUrl }.count, 1)
    }

    func testDownloadedCarouselMediaIsLoadedFromCacheWithoutDownloading() throws {
        clearSharedCache()
        defer { clearSharedCache() }
        downloadCarouselMedia([downloadUrl], stubbing: pngData(width: 60, height: 30))
        SwrveStubURLProtocol.responseData = nil

        // No stub this time: a cache miss would go to the real example.com and not return this image.
        let loader = SwrveCarouselImageLoader(sharedContainer: sharedContainer, configuration: .ephemeral)
        var result: UIImage?
        let loaded = expectation(description: "loadImage")
        loader.loadImage(fromUrl: downloadUrl) { image in
            result = image
            loaded.fulfill()
        }
        waitForExpectations(timeout: 10)

        XCTAssertEqual(result?.size.width, 60)
    }

    func testDownloadCarouselMediaDoesNothingWithoutAppGroup() {
        downloadCarouselMedia([downloadUrl], shared: false, stubbing: pngData(width: 60, height: 30))

        XCTAssertFalse(
            FileManager.default.fileExists(atPath: cacheFileUrl(for: downloadUrl).path),
            "the content extension can't see a cache outside the App Group, so nothing should be downloaded")
    }

    func testDownloadCarouselMediaCompletesWhenDownloadFails() throws {
        clearSharedCache()
        defer { clearSharedCache() }

        downloadCarouselMedia([unreachableUrl])

        let file = try XCTUnwrap(sharedCacheFileUrl(for: unreachableUrl))
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
    }

    func testDownloadCarouselMediaRemovesExpiredImagesAndKeepsRecentOnes() throws {
        clearSharedCache()
        defer { clearSharedCache() }
        let expired = try XCTUnwrap(sharedCacheFileUrl(for: cachedUrl))
        let recent = try XCTUnwrap(sharedCacheFileUrl(for: secondDownloadUrl))
        try FileManager.default.createDirectory(at: expired.deletingLastPathComponent(), withIntermediateDirectories: true)
        try pngData(width: 10, height: 10).write(to: expired)
        try pngData(width: 10, height: 10).write(to: recent)
        setModificationDate(Date().addingTimeInterval(-8 * 24 * 60 * 60), of: expired)
        setModificationDate(Date().addingTimeInterval(-6 * 24 * 60 * 60), of: recent)

        downloadCarouselMedia([])

        XCTAssertFalse(FileManager.default.fileExists(atPath: expired.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: recent.path))
    }

    func testDownloadCarouselMediaKeepsCachedImageAndRenewsItsExpiry() throws {
        clearSharedCache()
        defer { clearSharedCache() }
        let file = try XCTUnwrap(sharedCacheFileUrl(for: cachedUrl))
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try pngData(width: 10, height: 10).write(to: file)
        setModificationDate(Date().addingTimeInterval(-6 * 24 * 60 * 60), of: file)

        // No stub: a download attempt would go to the real example.com
        downloadCarouselMedia([cachedUrl])

        let modified = try XCTUnwrap(modificationDate(of: file))
        XCTAssertLessThan(Date().timeIntervalSince(modified), 60, "a cached image still in use should not expire")
    }

    func testUndecodableCachedImageReturnsNil() {
        // A truncated or corrupt cache entry must not be returned as an image. The loader falls
        // through to a download, which is unreachable here, so the result is the placeholder path.
        writeToCache(Data("not an image".utf8), for: unreachableUrl)

        XCTAssertNil(load(unreachableUrl))
    }
}

/// Serves a canned 200 response so the download path can be exercised without a network.
private final class SwrveStubURLProtocol: URLProtocol {

    static var responseData: Data?

    // Downloads run concurrently, so the record is guarded
    private static let lock = NSLock()
    private static var urls: [URL] = []

    static var requestedUrls: [URL] {
        lock.lock()
        defer { lock.unlock() }
        return urls
    }

    static func resetRequestedUrls() {
        lock.lock()
        defer { lock.unlock() }
        urls = []
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if let url = request.url {
            SwrveStubURLProtocol.lock.lock()
            SwrveStubURLProtocol.urls.append(url)
            SwrveStubURLProtocol.lock.unlock()
        }
        guard let data = SwrveStubURLProtocol.responseData, let url = request.url else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "SwrveStubURLProtocol", code: -1))
            return
        }
        guard let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil) else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "SwrveStubURLProtocol", code: -2))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
