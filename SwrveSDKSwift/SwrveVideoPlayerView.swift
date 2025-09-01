import AVFoundation
import AVKit
import UIKit

@objc public protocol SwrveVideoPlayerViewDelegate: NSObjectProtocol {
    func videoDidStartPlaying()
    func videoDidFinishPlaying()
}

@objc public class SwrveVideoPlayerView: UIView {

    private var hasStartedPlaying = false
    @objc public var hasSetupObservers = false
    @objc public var player: AVPlayer?
    @objc public var playerViewController: AVPlayerViewController?
    @objc public var videoURL: URL
    @objc public var videoSettings: SwrveVideoSettings
    @objc public weak var delegate: SwrveVideoPlayerViewDelegate?
    private var rateObservation: NSKeyValueObservation?
    private var thumbnailImageView: UIImageView?

    @objc public init(
        frame: CGRect, videoSettings: SwrveVideoSettings, videoURL: URL, controller: UIViewController, delegate: SwrveVideoPlayerViewDelegate?
    ) {
        self.delegate = delegate
        self.videoSettings = videoSettings
        self.videoURL = videoURL
        super.init(frame: frame)
        backgroundColor = .clear
        clipsToBounds = true
        setupPlayer(with: controller)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPlayer(with controller: UIViewController) {
        cleanupPlayer()

        self.player = AVPlayer(url: videoURL)
        self.playerViewController = AVPlayerViewController()
        if videoSettings.fillScreen {
            self.playerViewController?.videoGravity = .resizeAspectFill
            self.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        }

        addThumbnail()

        self.playerViewController?.player = self.player
        self.playerViewController?.showsPlaybackControls = videoSettings.showControls
        self.playerViewController?.view.translatesAutoresizingMaskIntoConstraints = false
        self.playerViewController?.view.backgroundColor = .clear

        guard let playerViewController = self.playerViewController, let playerView = playerViewController.view else { return }
        controller.addChild(playerViewController)
        self.addSubview(playerView)

        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
            playerView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0),
            playerView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
            playerView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0)
        ])

        playerViewController.didMove(toParent: controller)

        rateObservation = self.player?.observe(\.rate, options: [.old, .new]) { [weak self] player, change in
            guard let self = self else { return }
            if player.rate > 0 {
                if !self.hasStartedPlaying {
                    self.hasStartedPlaying = true
                    self.delegate?.videoDidStartPlaying()
                }
            }
        }

        if !hasSetupObservers {
            NotificationCenter.default.addObserver(
                self, selector: #selector(videoFinishedPlaying), name: .AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem)
            NotificationCenter.default.addObserver(
                self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)

            hasSetupObservers = true
        }

        #if os(tvOS)
        if videoSettings.fillScreen && !videoSettings.showControls {
            //this will allow focus on other buttons that are added to the view
            playerView.isUserInteractionEnabled = false
        }
        #endif

        if videoSettings.autoPlay {
            self.play()
        }
    }

    private func addThumbnail() {
        // Set background image from first frame
        if let thumbnail = generateThumbnail(url: videoURL) {
            let imageView = UIImageView(image: thumbnail)
            if videoSettings.fillScreen {
                imageView.contentMode = .scaleAspectFill
            } else {
                imageView.contentMode = .scaleAspectFit
            }

            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.clipsToBounds = true
            self.insertSubview(imageView, at: 0)
            self.thumbnailImageView = imageView

            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: self.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
            ])
        }
    }

    private func generateThumbnail(url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: 0, preferredTimescale: 600)
        do {
            let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            return nil
        }
    }

    @objc public func videoFinishedPlaying() {
        delegate?.videoDidFinishPlaying()
        if videoSettings.loop {
            self.player?.seek(to: .zero)
            self.player?.play()
        }
    }

    @objc private func appDidBecomeActive() {
        if videoSettings.autoPlay {
            self.player?.play()
        }
    }

    @objc public func cleanupPlayer() {
        if hasSetupObservers {
            NotificationCenter.default.removeObserver(self)
        }

        self.player?.pause()
        self.playerViewController?.willMove(toParent: nil)
        self.playerViewController?.view.removeFromSuperview()
        self.playerViewController?.removeFromParent()
        self.playerViewController = nil
        self.player = nil
        rateObservation?.invalidate()
        rateObservation = nil

        self.thumbnailImageView?.removeFromSuperview()
        self.thumbnailImageView = nil
    }

    @objc public func play() {
        self.player?.play()
    }

    @objc public func pause() {
        self.player?.pause()
    }

    deinit {
        cleanupPlayer()
    }
}
