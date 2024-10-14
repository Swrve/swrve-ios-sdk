import Foundation

@objc public enum SwrveTriggerOperator: UInt {
    case and
    case or
    case equals
    case contains
    case numberGT
    case numberLT
    case numberEquals
    case numberBetween
    case numberNotBetween
    case other
}

@objc public class SwrveTriggerCondition: NSObject {

    // MARK: - Properties

    /// The logical operator of the trigger
    @objc public var triggerOperator: SwrveTriggerOperator

    /// The condition operator for the trigger
    @objc public var conditionOperator: SwrveTriggerOperator

    /// The key used in the condition
    @objc public var key: String

    /// The value to be compared in the condition
    @objc public var value: Any

    /// Initializes the trigger condition with a dictionary and operator
    /// - Parameters:
    ///   - dictionary: A dictionary containing the condition data
    ///   - operatorKey: The operator used for the condition

    @objc public init?(dictionary: [String: Any], operatorKey: String?) {
        guard let key = dictionary["key"] as? String,
            let value = dictionary["value"]
        else {
            return nil
        }

        self.key = key
        self.value = value
        self.triggerOperator = SwrveTriggerCondition.determineSwrveOperator(operatorKey)
        self.conditionOperator = SwrveTriggerCondition.determineSwrveOperator(dictionary["op"] as? String)
        super.init()

        if key.isEmpty || self.conditionOperator == .other {
            return nil
        }
    }

    // MARK: - Methods

    /// Determines the Swrve operator based on a string
    /// - Parameter op: The operator string
    /// - Returns: The corresponding `SwrveTriggerOperator`

    private static func determineSwrveOperator(_ op: String?) -> SwrveTriggerOperator {
        switch op {
        case "and":
            return .and
        case "eq":
            return .equals
        case "or":
            return .or
        case "contains":
            return .contains
        case "number_eq":
            return .numberEquals
        case "number_gt":
            return .numberGT
        case "number_lt":
            return .numberLT
        case "number_between":
            return .numberBetween
        case "number_not_between":
            return .numberNotBetween
        default:
            return .other
        }
    }

    /// Checks if the condition has been fulfilled based on the provided payload
    /// - Parameter payload: A dictionary containing the event data
    /// - Returns: Boolean indicating if the condition is fulfilled

    func hasFulfilledCondition(with payload: [AnyHashable: Any]) -> Bool {
        guard let payloadObject = payload[key], !(payloadObject is NSNull) else {
            return false
        }

        let payloadValue: String
        if let strValue = payloadObject as? String {
            payloadValue = strValue
        } else if let numValue = payloadObject as? NSNumber {
            payloadValue = numValue.stringValue
        } else {
            return false
        }

        let valueString = value as? String
        let valueNumber = value as? NSNumber
        let valueDict = value as? [String: Any]

        switch conditionOperator {
        case .contains:
            return payloadValue.localizedCaseInsensitiveContains(valueString ?? "")
        case .equals:
            return payloadValue.caseInsensitiveCompare(valueString ?? "") == .orderedSame
        case .numberGT:
            return (payloadValue as NSString).integerValue > (valueNumber?.intValue ?? 0)
        case .numberLT:
            return (payloadValue as NSString).integerValue < (valueNumber?.intValue ?? 0)
        case .numberEquals:
            return (payloadValue as NSString).integerValue == (valueNumber?.intValue ?? 0)
        case .numberBetween:
            guard let lower = valueDict?["lower"] as? NSNumber, let upper = valueDict?["upper"] as? NSNumber else {
                return false
            }
            let payloadIntValue = (payloadValue as NSString).integerValue
            return payloadIntValue > lower.intValue && payloadIntValue < upper.intValue
        case .numberNotBetween:
            guard let lower = valueDict?["lower"] as? NSNumber, let upper = valueDict?["upper"] as? NSNumber else {
                return false
            }
            let payloadIntValue = (payloadValue as NSString).integerValue
            return payloadIntValue < lower.intValue || payloadIntValue > upper.intValue
        default:
            return false
        }
    }
}
