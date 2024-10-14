import Foundation
import UIKit

@objc public protocol SwrveInAppMessageFocusDelegate: NSObjectProtocol {

    /*!
     Use this delegate in SwrveInAppMessageConfig to configure button focus changes. For tvOS only.
     - parameter context: Provides focus update information.
     - parameter coordinator: Used for focus-related animations.
     - parameter parent: The parent view.
     */
    @objc optional func didUpdateFocus(
        inContext: UIFocusUpdateContext,
        withAnimationCoordinator coordinator: UIFocusAnimationCoordinator,
        parentView parent: UIView)
}
