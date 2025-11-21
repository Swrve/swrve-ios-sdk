import Foundation

@objc public class SwrveTrigger: NSObject {

    static let triggerEventListKey = "triggers"
    let triggerEventNameKey = "event_name"
    let triggerEventConditionsKey = "conditions"

    /// Event name for the trigger
    @objc public private(set) var eventName: String

    /// Conditions for the trigger
    @objc public var conditions: [SwrveTriggerCondition]

    /// Indicates if this is a valid trigger
    @objc public var isValidTrigger: Bool = true

    /// Initializes triggers from a dictionary
    /// - Parameter dictionary: The dictionary containing trigger information
    class func initTriggers(from dictionary: [String: Any]) -> [SwrveTrigger]? {
        guard let jsonTriggers = dictionary[triggerEventListKey] as? [[String: Any]] else {
            return nil
        }
        var resultantTriggers = [SwrveTrigger]()
        for triggerData in jsonTriggers {
            if let swrveTrigger = SwrveTrigger(dictionary: triggerData) {
                resultantTriggers.append(swrveTrigger)
            }
        }
        return resultantTriggers
    }

    /// Initializes a trigger from a dictionary
    /// - Parameter dictionary: The dictionary containing trigger information
    @objc public init?(dictionary: [String: Any]) {
        guard let eventName = dictionary[triggerEventNameKey] as? String else {
            return nil
        }

        self.eventName = eventName.lowercased()
        self.conditions = []
        super.init()

        if let conditionData = dictionary[triggerEventConditionsKey] as? [String: Any] {
            self.conditions = produceConditions(from: conditionData) ?? []
        }

        if !self.isValidTrigger {
            return nil
        }
    }

    // MARK: - Private Methods

    /// Produces conditions from a dictionary
    /// - Parameter dictionary: The dictionary containing condition information
    private func produceConditions(from dictionary: [String: Any]) -> [SwrveTriggerCondition]? {
        var resultantConditions = [SwrveTriggerCondition]()
        guard !dictionary.isEmpty else {
            return nil
        }
        let triggerOperator: String = dictionary["op"] as? String ?? ""

        if ["eq", "contains", "number_gt", "number_eq", "number_lt", "number_between", "number_not_between"].contains(triggerOperator) {
            if let condition = SwrveTriggerCondition(dictionary: dictionary, operatorKey: nil) {
                resultantConditions.append(condition)
            } else {
                isValidTrigger = false
                return nil
            }

        } else if triggerOperator == "and" || triggerOperator == "or" {
            guard let arguments = dictionary["args"] as? [[String: Any]] else {
                isValidTrigger = false
                return nil
            }
            for triggerConditionData in arguments {
                if let condition = SwrveTriggerCondition(dictionary: triggerConditionData, operatorKey: triggerOperator) {
                    resultantConditions.append(condition)
                }
            }
        } else {
            isValidTrigger = false
            return nil
        }

        for condition in resultantConditions {
            switch condition.triggerOperator {
            case .and:
                if resultantConditions.count <= 1 {
                    isValidTrigger = false
                }
            case .or:
                if resultantConditions.isEmpty {
                    isValidTrigger = false
                }
            case .other:
                if resultantConditions.count > 1 {
                    isValidTrigger = false
                }

            default:
                break
            }

            switch condition.conditionOperator {
            case .other:
                isValidTrigger = false
            default:
                break
            }
        }

        return resultantConditions
    }

    /// Checks if the trigger can fire based on a payload
    /// - Parameter payload: The payload containing event information
    /// - Returns: Boolean indicating if the trigger can fire
    @objc public func canTrigger(withPayload payload: [AnyHashable: Any]) -> Bool {
        var canTrigger = true

        if !conditions.isEmpty {
            for condition in conditions {
                canTrigger = condition.hasFulfilledCondition(with: payload)

                if condition.triggerOperator == .or {
                    if canTrigger { return true }
                } else if condition.triggerOperator == .and {
                    if !canTrigger { return false }
                } else {
                    return canTrigger
                }
            }
        }

        return canTrigger
    }

    /// Checks if this is a valid trigger
    /// - Returns: Boolean indicating if the trigger is valid
    func isValid() -> Bool {
        isValidTrigger
    }
}
