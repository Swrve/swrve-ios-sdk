import Foundation
import UIKit

#if canImport(SwrveSDK)
import SwrveSDK
#endif

#if canImport(SwrveSDKCommon)
import SwrveSDKCommon
#endif

@objc public class SwrveThemedUIButton: SwrveUIButton {

    // MARK: - Properties

    @objc public let theme: SwrveButtonTheme
    @objc public let calibration: SwrveCalibration?
    @objc public let renderScale: Double

    // MARK: - Init

    @objc public init(
        theme: SwrveButtonTheme,
        text: String?,
        frame: CGRect,
        calibration: SwrveCalibration?,
        renderScale: Double
    ) {

        self.theme = theme
        self.calibration = calibration
        self.renderScale = renderScale
        super.init(frame: frame)

        setTitle(text, for: .normal)
        applyTextAlignment()
        applyPadding()
        applyFont()
        applyFontColor()
        applyCornerRadius()
        applyBorder()
        applyBackground()

        clipsToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Highlight state

    @objc public override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                if let bg = theme.pressedState.bgColor {
                    backgroundColor = SwrveUtils.processHexColorValue(bg)
                }
                if let bc = theme.pressedState.borderColor {
                    layer.borderColor = SwrveUtils.processHexColorValue(bc).cgColor
                }
            } else {
                if let bg = theme.bgColor {
                    backgroundColor = SwrveUtils.processHexColorValue(bg)
                }
                if let bc = theme.borderColor {
                    layer.borderColor = SwrveUtils.processHexColorValue(bc).cgColor
                }
            }
        }
    }

    // MARK: - Apply helpers

    private func applyTextAlignment() {
        guard let align = theme.hAlign else { return }
        switch align {
        case "LEFT": contentHorizontalAlignment = .left
        case "CENTER": contentHorizontalAlignment = .center
        case "RIGHT": contentHorizontalAlignment = .right
        default: break
        }
    }

    private func applyFont() {
        let baseSize = CGFloat(truncating: theme.fontSize ?? 0)
        let defaultFont = UIFont.systemFont(ofSize: baseSize)
        let titleFont = SwrveSDKUtils.font(
            fromFile: theme.fontFile ?? "",
            postscriptName: theme.fontPostscriptName ?? "",
            size: baseSize,
            style: theme.fontNativeStyle ?? "",
            withFallback: defaultFont)

        var scaledPointSize = baseSize
        if let calibration {
            scaledPointSize = SwrveSDKUtils.scale(
                titleFont,
                calibration: calibration,
                swrveFontSize: baseSize,
                renderScale: CGFloat(renderScale))
        }
        titleLabel?.font = titleFont.withSize(scaledPointSize)

        if theme.truncate {
            titleLabel?.lineBreakMode = .byTruncatingTail
        } else {
            titleLabel?.numberOfLines = 1
            titleLabel?.lineBreakMode = .byWordWrapping
            var log = "SwrveThemedUIButton initial size: \(titleLabel?.font.pointSize ?? 0)"
            SwrveLogger.logDebug(log)
            scaleDownText(beginSize: scaledPointSize)
            log = "SwrveThemedUIButton after scale down size: \(titleLabel?.font.pointSize ?? 0)"
            SwrveLogger.logDebug(log)
            titleLabel?.adjustsFontSizeToFitWidth = true
        }
    }

    private func scaleDownText(beginSize: CGFloat) {
        guard let text = titleLabel?.text, !text.isEmpty, !bounds.size.equalTo(.zero) else { return }

        let left = CGFloat(truncating: theme.leftPadding ?? 0)
        let right = CGFloat(truncating: theme.rightPadding ?? 0)
        let top = CGFloat(truncating: theme.topPadding ?? 0)
        let bottom = CGFloat(truncating: theme.bottomPadding ?? 0)
        let border = CGFloat(truncating: theme.borderWidth ?? 0)

        let widthPaddingOffset = (left + right + border) * renderScale
        let heightPaddingOffset = (top + bottom + border) * renderScale

        let width = frame.size.width - widthPaddingOffset
        let height = frame.size.height - heightPaddingOffset
        guard width > 0, height > 0 else { return }

        let constraint = CGSize(width: width, height: height)
        var size = beginSize

        while size > 1 {
            if let currentFont = titleLabel?.font {
                titleLabel?.font = currentFont.withSize(size)
            }
            let textRect = titleLabel?.sizeThatFits(constraint) ?? .zero
            if ceil(textRect.height) <= height && ceil(textRect.width) <= width {
                break
            }
            size -= 1.0
        }
    }

    private func applyFontColor() {
        if let fc = theme.fontColor {
            setTitleColor(SwrveUtils.processHexColorValue(fc), for: .normal)
        }
        if let pc = theme.pressedState.fontColor {
            setTitleColor(SwrveUtils.processHexColorValue(pc), for: .highlighted)
        }
        if let focused = theme.focusedState?.fontColor {
            if #available(iOS 9.0, tvOS 9.0, *) {
                setTitleColor(SwrveUtils.processHexColorValue(focused), for: .focused)
            }
        }
    }

    private func applyCornerRadius() {
        var radius = CGFloat(truncating: theme.cornerRadius ?? 0) * renderScale
        radius = min(radius, frame.size.height / 2.0, frame.size.width / 2.0)
        layer.cornerRadius = radius
    }

    private func applyBorder() {
        let bw = CGFloat(truncating: theme.borderWidth ?? 0)
        guard bw > 0 else { return }
        if let borderColor = theme.borderColor {
            layer.borderColor = SwrveUtils.processHexColorValue(borderColor).cgColor
        }
        layer.borderWidth = bw * CGFloat(renderScale)
    }

    private func applyBackground() {
        if let bg = theme.bgColor, !bg.isEmpty {
            backgroundColor = SwrveUtils.processHexColorValue(bg)
        } else {
            setBackgroundImage(createUIImage(assetName: theme.bgImage), for: .normal)
            setBackgroundImage(createUIImage(assetName: theme.pressedState.bgImage), for: .highlighted)
            if let _ = theme.focusedState?.bgImage, #available(iOS 9.0, tvOS 9.0, *) {
                setBackgroundImage(createUIImage(assetName: theme.focusedState?.bgImage), for: .focused)
            }
        }
    }

    private func createUIImage(assetName: String?) -> UIImage? {
        guard let name = assetName, !name.isEmpty else { return nil }
        let cacheFolder = SwrveLocalStorage.swrveCacheFolder()
        let target = (cacheFolder! as NSString).appendingPathComponent(name)
        let url = URL(fileURLWithPath: target)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private func applyPadding() {
        let bw = CGFloat(truncating: theme.borderWidth ?? 0)
        let scaleValue = CGFloat(renderScale)
        let top = (CGFloat(truncating: theme.topPadding ?? 0) + bw) * scaleValue
        let left = (CGFloat(truncating: theme.leftPadding ?? 0) + bw) * scaleValue
        let bottom = (CGFloat(truncating: theme.bottomPadding ?? 0) + bw) * scaleValue
        let right = (CGFloat(truncating: theme.rightPadding ?? 0) + bw) * scaleValue
        contentEdgeInsets = UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
    }
}
