import UIKit

@objc public protocol SwrveInAppStorySegmentDelegate {
    func segmentFinished(atIndex index: Int)
}

@objc public class SwrveInAppStoryView: UIView {

    @objc public var currentIndex: Int = 0

    private weak var segmentDelegate: SwrveInAppStorySegmentDelegate?
    private var storySettings: SwrveStorySettings
    private var segmentProgressViews: [UIView] = []
    private var timer: Timer?
    private var segmentMaxWidth: CGFloat = 0
    private var numberOfSegments: Int = 0
    private var renderScale: CGFloat = 1.0
    private var pageDurations: [NSNumber]?

    private let PROGRESS_SPEED: CGFloat = 1000.0

    @objc(initWithFrame:delegate:storySettings:numberOfSegments:renderScale:pageDurations:)
    public init(
        frame: CGRect,
        delegate: SwrveInAppStorySegmentDelegate,
        storySettings: SwrveStorySettings,
        numberOfSegments: Int,
        renderScale: CGFloat,
        pageDurations: [NSNumber]?
    ) {
        self.segmentDelegate = delegate
        self.storySettings = storySettings
        self.numberOfSegments = numberOfSegments
        self.renderScale = renderScale
        self.pageDurations = pageDurations
        super.init(frame: frame)
        self.drawSegments()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func drawSegments() {
        let progressColor = SwrveUtils.processHexColorValue(storySettings.barColor) ?? UIColor.clear
        let trackColor = SwrveUtils.processHexColorValue(storySettings.barBgColor) ?? UIColor.clear

        let paddingBetweenSegments = CGFloat(storySettings.segmentGap.floatValue) * renderScale
        let remainingWidth = frame.size.width - (paddingBetweenSegments * CGFloat(numberOfSegments - 1))
        let widthOfSegment = remainingWidth / CGFloat(numberOfSegments)
        let heightOfSegment = frame.size.height
        let cornerRadius = heightOfSegment / 2
        segmentMaxWidth = widthOfSegment

        for index in 0..<numberOfSegments {
            let originX = CGFloat(index) * (widthOfSegment + paddingBetweenSegments)
            let trackFrame = CGRect(x: originX, y: 0, width: widthOfSegment, height: heightOfSegment)
            let trackView = createSegmentView(backgroundColor: trackColor, cornerRadius: cornerRadius)
            trackView.frame = trackFrame
            addSubview(trackView)

            let progressView = createSegmentView(backgroundColor: progressColor, cornerRadius: cornerRadius)
            progressView.frame = CGRect(x: 0, y: 0, width: 0, height: heightOfSegment)
            trackView.addSubview(progressView)

            segmentProgressViews.append(progressView)
        }
    }

    private func createSegmentView(backgroundColor: UIColor, cornerRadius: CGFloat) -> UIView {
        let segment = UIView()
        segment.layer.cornerRadius = cornerRadius
        segment.clipsToBounds = true
        segment.isUserInteractionEnabled = false
        segment.backgroundColor = backgroundColor
        return segment
    }

    @objc public func startSegment(atIndex index: Int) {
        guard index >= 0 && index < segmentProgressViews.count else { return }

        if index > currentIndex {
            for i in currentIndex..<index {
                updateWidth(for: segmentProgressViews[i], newWidth: segmentMaxWidth)
            }
        } else if index <= currentIndex {
            for i in stride(from: currentIndex, through: index, by: -1) {
                updateWidth(for: segmentProgressViews[i], newWidth: 0)
            }
        }

        currentIndex = index
        animateSegment()
        setUpTimer()
    }

    private func animateSegment() {
        guard currentIndex < segmentProgressViews.count else { return }

        let progressView = segmentProgressViews[currentIndex]
        let lastWidth = progressView.frame.size.width
        let newWidth = lastWidth + progressIntervalWidth()
        updateWidth(for: progressView, newWidth: newWidth)

        if newWidth >= segmentMaxWidth {
            let finishedIndex = currentIndex
            if currentIndex < numberOfSegments - 1 {
                currentIndex += 1
                updateWidth(for: segmentProgressViews[currentIndex], newWidth: 0)
            } else {
                timer?.invalidate()
                timer = nil
            }

            segmentDelegate?.segmentFinished(atIndex: finishedIndex)
        }
    }

    private func updateWidth(for view: UIView, newWidth: CGFloat) {
        var frame = view.frame
        frame.size.width = newWidth
        view.frame = frame
    }

    private func progressIntervalWidth() -> CGFloat {
        let pageDuration: NSNumber
        if let pageDurations = pageDurations, !pageDurations.isEmpty {
            pageDuration = pageDurations[currentIndex]
        } else {
            pageDuration = storySettings.pageDuration
        }
        let pageDurationSeconds = pageDuration.doubleValue / 1000.0
        let value = CGFloat(pageDurationSeconds) * PROGRESS_SPEED
        return segmentMaxWidth / value
    }

    private func setUpTimer() {
        guard timer == nil else { return }
        let interval = 1.0 / Double(PROGRESS_SPEED)
        timer = Timer.scheduledTimer(
            timeInterval: interval,
            target: self,
            selector: #selector(animateSegmentTick),
            userInfo: nil,
            repeats: true)
    }

    @objc private func animateSegmentTick() {
        animateSegment()
    }

    @objc public func stop() {
        timer?.invalidate()
        timer = nil
    }
}
