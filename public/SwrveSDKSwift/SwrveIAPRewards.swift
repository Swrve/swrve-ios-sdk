import Foundation

#if canImport(SwrveSDKCommon)
import SwrveSDKCommon
#endif

/// SwrveIAPRewards contains additional IAP rewards that you want to send to Swrve.
///
/// If the IAP represents a bundle containing a few reward items and/or
/// in-app currencies you can create a SwrveIAPRewards object and call
/// `addCurrency(_:withAmount:)` and `addItem(_:withQuantity:)` for each element contained in the bundle.
/// By including this when recording an IAP event with Swrve you will be able to track
/// individual bundle items as well as the bundle purchase itself.

@objcMembers public class SwrveIAPRewards: NSObject {

    @objc public var rewards: NSMutableDictionary

    @objc public override init() {
        self.rewards = NSMutableDictionary()
        super.init()
    }

    /// Add a purchased item
    ///
    /// - Parameters:
    ///   - resourceName: The name of the resource item with which the user was rewarded.
    ///   - quantity: The quantity purchased
    @objc public func addItem(_ resourceName: String, withQuantity quantity: Int) {
        addObject(resourceName, withQuantity: quantity, ofType: "item")
    }

    /// Add an in-app currency purchase
    ///
    /// - Parameters:
    ///   - currencyName: The name of the in-app currency with which the user was rewarded.
    ///   - amount: The amount of in-app currency with which the user was rewarded.
    @objc public func addCurrency(_ currencyName: String, withAmount amount: Int) {
        addObject(currencyName, withQuantity: amount, ofType: "currency")
    }

    private func addObject(_ name: String, withQuantity quantity: Int, ofType type: String) {
        if !checkArguments(name: name, quantity: quantity, type: type) {
            SwrveLogger.logError("ERROR: SwrveIAPRewards has not been added because it received an illegal argument")
            return
        }

        let item: [String: Any] = ["amount": quantity, "type": type]
        rewards[name] = item
    }

    private func checkArguments(name: String, quantity: Int, type: String) -> Bool {
        if name.isEmpty {
            SwrveLogger.logError("SwrveIAPRewards illegal argument: reward name cannot be empty")
            return false
        }
        if quantity <= 0 {
            SwrveLogger.logError("SwrveIAPRewards illegal argument: reward amount must be greater than zero")
            return false
        }
        if type.isEmpty {
            SwrveLogger.logError("SwrveIAPRewards illegal argument: type cannot be empty")
            return false
        }
        return true
    }
}
