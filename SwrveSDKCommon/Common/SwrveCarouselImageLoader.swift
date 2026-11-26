#if os(iOS)

import ImageIO
import UIKit

/// Downloads, caches and decodes carousel item images for a notification content extension.
///
/// Downloads are cached on disk because collapsing and re-expanding a notification re-instantiates
/// the extension, which would otherwise re-download every image.
///
/// Exposed to Objective-C only so the SDK's service extension code can download into the same cache.
/// The content extension that displays the images is Swift only.
@objc(SwrveCarouselImageLoader)
public class SwrveCarouselImageLoader: NSObject {

    /// Wall-clock deadline for one image download. A content extension is expected to render
    /// promptly, so a slow image is abandoned rather than delaying the carousel.
    ///
    /// Applied when the session is first used, so set it before the first `loadImage` call.
    @objc public var timeout: TimeInterval = 5

    /// Longest edge, in pixels, an image is decoded to. Content extensions run under a tight memory
    /// limit, so images are never fully decoded at their original size.
    public var maximumPixelDimension: Int = 1024

    /// Downloads larger than this are discarded rather than decoded.
    @objc public var maximumDownloadBytes: Int = 10 * 1024 * 1024

    /// Cached media older than this is deleted by `downloadCarouselMedia`.
    private let maximumCacheAge: TimeInterval = 7 * 24 * 60 * 60

    private let cacheDirectory: URL?
    private let isCacheShared: Bool
    private let configuration: URLSessionConfiguration
    private let decodeQueue = DispatchQueue(label: "com.swrve.carousel.imageloader", qos: .userInitiated)

    /// Created lazily so `timeout` can be set after init and still take effect.
    private lazy var session: URLSession = {
        // `timeoutIntervalForRequest` alone is an inactivity timeout — a server trickling bytes can
        // hold a task open indefinitely. `timeoutIntervalForResource` is the wall-clock deadline.
        let sessionConfiguration = (configuration.copy() as? URLSessionConfiguration) ?? configuration
        sessionConfiguration.timeoutIntervalForRequest = timeout
        sessionConfiguration.timeoutIntervalForResource = timeout
        return URLSession(configuration: sessionConfiguration)
    }()

    /// - Parameter appGroupIdentifier: when supplied, images are cached in the shared container so
    ///   the cache is visible to the host app and service extension. Without it the cache falls back
    ///   to the extension's own caches directory, which still survives collapse and re-expansion.
    @objc(initWithAppGroupIdentifier:)
    public convenience init(appGroupIdentifier: String?) {
        self.init(appGroupIdentifier: appGroupIdentifier, configuration: .ephemeral)
    }

    @objc(initWithAppGroupIdentifier:configuration:)
    public convenience init(appGroupIdentifier: String?, configuration: URLSessionConfiguration) {
        self.init(
            sharedContainer: SwrveCarouselImageLoader.sharedContainer(appGroupIdentifier: appGroupIdentifier),
            configuration: configuration)
    }

    /// Tests pass a directory of their own as `sharedContainer`, as they have no App Group.
    init(sharedContainer: URL?, configuration: URLSessionConfiguration) {
        let cacheDirectory = SwrveCarouselImageLoader.makeCacheDirectory(sharedContainer: sharedContainer)
        self.cacheDirectory = cacheDirectory
        self.isCacheShared = sharedContainer != nil && cacheDirectory != nil
        self.configuration = configuration
        super.init()
    }

    /// Loads an image, from the disk cache when present. `completion` is always called exactly once,
    /// on the main queue, with `nil` when the image could not be fetched or decoded.
    public func loadImage(fromUrl urlString: String, completion: @escaping (UIImage?) -> Void) {
        let finish: (UIImage?) -> Void = { image in
            DispatchQueue.main.async { completion(image) }
        }

        guard let url = URL(string: urlString) else {
            SwrveLogger.logError("SwrveCarouselImageLoader: could not parse image url \(urlString)")
            finish(nil)
            return
        }

        let cachedFile = cachedFileUrl(for: urlString)
        decodeQueue.async { [weak self] in
            guard let self = self else {
                finish(nil)
                return
            }

            if let cachedFile = cachedFile,
                FileManager.default.fileExists(atPath: cachedFile.path),
                let image = self.decodeImage(at: cachedFile)
            {
                finish(image)
                return
            }

            self.download(url, into: cachedFile) { file in
                // ImageIO downsamples straight from the file, so the full-size bitmap is never
                // held in memory — and `downloadTask` already streamed the bytes there.
                guard let file = file, let image = self.decodeImage(at: file) else {
                    SwrveLogger.logError("SwrveCarouselImageLoader: could not decode image from \(urlString)")
                    finish(nil)
                    return
                }
                finish(image)
            }
        }
    }

    // MARK: - Service extension

    /// Downloads a carousel push's media into the App Group cache without decoding it, so the content
    /// extension finds it on disk. `completion` is called once every download has finished or failed.
    @objc(downloadCarouselMediaFromSwrvePayload:completion:)
    public func downloadCarouselMedia(fromSwrvePayload swrvePayload: [AnyHashable: Any]?, completion: @escaping () -> Void) {
        guard isCacheShared else {
            SwrveLogger.logWarning("SwrveCarouselImageLoader: no App Group container, carousel media downloads when the notification is expanded")
            completion()
            return
        }
        // Payload order, so the first item, on screen when the notification expands, starts first
        var seen = Set<String>()
        let urlStrings = (SwrveCarouselItem.items(fromSwrvePayload: swrvePayload)?.map { $0.imageUrl } ?? [])
            .filter { seen.insert($0).inserted }

        decodeQueue.async {
            self.removeExpiredImages()

            let group = DispatchGroup()
            for urlString in urlStrings {
                guard let url = URL(string: urlString), let cachedFile = self.cachedFileUrl(for: urlString) else {
                    continue
                }
                if FileManager.default.fileExists(atPath: cachedFile.path) {
                    // Renew its expiry, as it is still in use
                    try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: cachedFile.path)
                    continue
                }
                group.enter()
                self.download(url, into: cachedFile) { file in
                    if let file = file, file != cachedFile {
                        try? FileManager.default.removeItem(at: file)
                    }
                    group.leave()
                }
            }
            // Downloads only hold the loader weakly
            group.notify(queue: .global(qos: .userInitiated)) {
                withExtendedLifetime(self) { completion() }
            }
        }
    }

    private func removeExpiredImages() {
        guard let cacheDirectory = cacheDirectory,
            let files = try? FileManager.default.contentsOfDirectory(
                at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey])
        else { return }
        let oldestKept = Date().addingTimeInterval(-maximumCacheAge)
        for file in files {
            guard let modified = try? file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
                modified < oldestKept
            else { continue }
            try? FileManager.default.removeItem(at: file)
        }
    }

    // MARK: - Download

    /// Streams the download to disk rather than materialising it as `Data`, so peak memory stays
    /// flat regardless of asset size. Mirrors `SwrveNotificationManager.downloadAttachment:`.
    private func download(_ url: URL, into cachedFile: URL?, completion: @escaping (URL?) -> Void) {
        session.downloadTask(with: url) { [weak self] location, response, error in
            guard let self = self else {
                completion(nil)
                return
            }
            if let error = error {
                SwrveLogger.logError("SwrveCarouselImageLoader: image download failed for \(url) - \(error.localizedDescription)")
                completion(nil)
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                SwrveLogger.logError("SwrveCarouselImageLoader: image download for \(url) returned status \(httpResponse.statusCode)")
                completion(nil)
                return
            }
            guard let location = location else {
                completion(nil)
                return
            }
            let size = (try? FileManager.default.attributesOfItem(atPath: location.path)[.size] as? Int) ?? nil
            if let size = size, size > self.maximumDownloadBytes {
                SwrveLogger.logError("SwrveCarouselImageLoader: image at \(url) is \(size) bytes, over the \(self.maximumDownloadBytes) byte limit")
                completion(nil)
                return
            }
            // `location` is deleted as soon as this handler returns, so it has to be moved now.
            completion(self.retain(location, as: cachedFile))
        }.resume()
    }

    // MARK: - Cache

    private static func sharedContainer(appGroupIdentifier: String?) -> URL? {
        guard let appGroupIdentifier = appGroupIdentifier, !appGroupIdentifier.isEmpty else { return nil }
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }

    private static func makeCacheDirectory(sharedContainer: URL?) -> URL? {
        let fileManager = FileManager.default
        var root: URL?
        if let container = sharedContainer {
            // Under Library/Caches, not the container root: these are replaceable downloads, so they
            // should be purgeable by the system and excluded from backup.
            root = container.appendingPathComponent("Library/Caches", isDirectory: true)
        } else {
            root = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
        }
        guard let root = root else { return nil }

        let directory = root.appendingPathComponent("com.swrve.carousel", isDirectory: true)
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            SwrveLogger.logError("SwrveCarouselImageLoader: could not create image cache directory - \(error.localizedDescription)")
            return nil
        }
        return directory
    }

    /// Height over width of the first of these images already in the cache, read from the file's header
    /// without decoding it. `nil` when none is cached.
    func cachedImageHeightRatio(forUrls urlStrings: [String]) -> CGFloat? {
        for urlString in urlStrings {
            guard let file = cachedFileUrl(for: urlString),
                FileManager.default.fileExists(atPath: file.path),
                let source = CGImageSourceCreateWithURL(file as CFURL, nil),
                let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                let width = properties[kCGImagePropertyPixelWidth] as? CGFloat, width > 0,
                let height = properties[kCGImagePropertyPixelHeight] as? CGFloat, height > 0
            else { continue }
            // Orientations 5 to 8 are rotated a quarter turn, so the stored width is the displayed height
            let orientation = properties[kCGImagePropertyOrientation] as? Int ?? 1
            return orientation >= 5 ? width / height : height / width
        }
        return nil
    }

    /// Keyed on the SHA1 of the url string, matching how the SDK names externally hosted assets.
    private func cachedFileUrl(for urlString: String) -> URL? {
        guard let cacheDirectory = cacheDirectory,
            let urlData = urlString.data(using: .utf8)
        else { return nil }
        return cacheDirectory.appendingPathComponent(SwrveUtils.sha1(urlData))
    }

    /// Moves the freshly downloaded file somewhere that outlives the completion handler — the cache
    /// when it is usable, and a temporary file otherwise so an uncacheable image still renders.
    private func retain(_ downloaded: URL, as cachedFile: URL?) -> URL? {
        let fileManager = FileManager.default
        if let cachedFile = cachedFile {
            try? fileManager.removeItem(at: cachedFile)
            do {
                try fileManager.moveItem(at: downloaded, to: cachedFile)
                return cachedFile
            } catch {
                SwrveLogger.logWarning("SwrveCarouselImageLoader: could not cache image - \(error.localizedDescription)")
            }
        }

        let temporaryFile = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        do {
            try fileManager.moveItem(at: downloaded, to: temporaryFile)
            return temporaryFile
        } catch {
            SwrveLogger.logError("SwrveCarouselImageLoader: could not move downloaded image - \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Decode

    private func decodeImage(at fileUrl: URL) -> UIImage? {
        guard let source = CGImageSourceCreateWithURL(fileUrl as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumPixelDimension
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}

#endif
