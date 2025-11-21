import Foundation
import UIKit

#if canImport(SwrveSDK)
import SwrveSDK
#endif

#if canImport(SwrveSDKCommon)
import SwrveSDKCommon
#endif

@objc public class SwrveInAppMessageConfig: NSObject {

    /// In-app background color used for the area behind the message
    @objc public var backgroundColor: UIColor?

    /// By default Swrve will choose the status bar appearance when presenting any In-app view controllers.
    /// You can disable this functionality by setting prefersStatusBarHidden to false.
    @objc public var prefersStatusBarHidden: Bool = true

    /// In-app background color used for all personalized text, can be overridden by server value
    @objc public var personalizationBackgroundColor: UIColor?

    /// In-app text color used for all personalized text, can be overridden by server value
    @objc public var personalizationForegroundColor: UIColor?

    /// In-app text font used for all personalized text, can be overridden by server value
    @objc public var personalizationFont: UIFont?

    /// Implement this delegate to intercept IAM calls with personalization.
    @objc public var personalizationCallback: SwrveMessagePersonalizationCallback?

    /// In-app capabilities delegate used by client to notify Swrve of capability request and status
    @objc weak public var inAppCapabilitiesDelegate: SwrveInAppCapabilitiesDelegate?

    /// In-app message delegate to process certain message actions
    @objc weak public var inAppMessageDelegate: SwrveInAppMessageDelegate?

    #if os(tvOS)
    /// In-app message focus delegate to process focus view changes
    @objc weak public var inAppMessageFocusDelegate: SwrveInAppMessageFocusDelegate?
    #endif

    /// Custom dismiss button image to use in in-app story campaigns
    @objc public var storyDismissButton: UIImage?

    /// Custom dismiss button image for highlighted state to use in in-app story campaigns
    @objc public var storyDismissButtonHighlighted: UIImage?

    // MARK: - Initializer

    @objc public override init() {
        super.init()
        self.prefersStatusBarHidden = true
        self.personalizationForegroundColor = UIColor.black
        self.personalizationBackgroundColor = UIColor.clear
        self.personalizationFont = UIFont.systemFont(ofSize: 0)
    }
}
