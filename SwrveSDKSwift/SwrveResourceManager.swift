import Foundation

@objc public class SwrveResourceManager: NSObject {
    @objc public dynamic var resources: [String: [String: Any]] = [:]
    private var abTestDetailsArray: [SwrveABTestDetails] = []

    @objc public override init() {
    }

    /// Set resources from an array of dictionaries
    ///
    /// - Parameter resourcesArray: Array of dictionaries representing resources
    @objc public func setResources(fromArray resourcesArray: [[String: Any]]) {
        var resourcesDict = [String: [String: Any]]()
        for resource in resourcesArray {
            if let itemName = resource["uid"] as? String {
                resourcesDict[itemName] = resource
            }
        }
        resources = resourcesDict
    }

    /// Get a resource identified by the given uid.
    ///
    /// - Parameter resourceId: Unique resource identifier.
    /// - Returns: The resource with the given uid or nil.
    @objc public func resource(withId resourceId: String) -> SwrveResource? {
        if let resourceDict = resources[resourceId] {
            return SwrveResource(resourceAttributes: resourceDict)
        }
        return nil
    }

    @objc public func attributeAsString(_ attributeId: String, fromResourceWithId resourceId: String, withDefault defaultValue: String) -> String {
        guard let resource = resource(withId: resourceId) else { return defaultValue }
        return resource.attributeAsString(attributeId, withDefault: defaultValue)
    }

    /// Get an attribute of the resource as an integer.
    ///
    /// - Parameters:
    ///   - attributeId: Attribute identifier.
    ///   - resourceId: Resource unique identifier.
    ///   - defaultValue: Default attribute value.
    /// - Returns: The value of the attribute or the default value provided.
    @objc public func attributeAsInt(_ attributeId: String, fromResourceWithId resourceId: String, withDefault defaultValue: Int) -> Int {
        guard let resource = resource(withId: resourceId) else { return defaultValue }
        return resource.attributeAsInt(attributeId, withDefault: defaultValue)
    }

    /// Get an attribute of the resource as an float.
    ///
    /// - Parameters:
    ///   - attributeId: Attribute identifier.
    ///   - resourceId: Resource unique identifier.
    ///   - defaultValue: Default attribute value.
    /// - Returns: The value of the attribute or the default value provided.
    @objc public func attributeAsFloat(_ attributeId: String, fromResourceWithId resourceId: String, withDefault defaultValue: Float) -> Float {
        guard let resource = resource(withId: resourceId) else { return defaultValue }
        return resource.attributeAsFloat(attributeId, withDefault: defaultValue)
    }

    /// Get an attribute of the resource as an bool.
    ///
    /// - Parameters:
    ///   - attributeId: Attribute identifier.
    ///   - resourceId: Resource unique identifier.
    ///   - defaultValue: Default attribute value.
    /// - Returns: The value of the attribute or the default value provided.
    @objc public func attributeAsBool(_ attributeId: String, fromResourceWithId resourceId: String, withDefault defaultValue: Bool) -> Bool {
        guard let resource = resource(withId: resourceId) else { return defaultValue }
        return resource.attributeAsBool(attributeId, withDefault: defaultValue)
    }

    /// Set the AB test details from a dictionary
    ///
    /// - Parameter abTestDetailsListDic: Dictionary of AB test details
    @objc public func setABTestDetails(fromDictionary abTestDetailsListDic: [String: [String: Any]]) {
        var abTestDetailsArray: [SwrveABTestDetails] = []

        for (abTestId, abTestDetailsDic) in abTestDetailsListDic {
            if let abTestName = abTestDetailsDic["name"] as? String,
                let abTestCaseIndex = abTestDetailsDic["case_index"] as? Int
            {
                let abDetails = SwrveABTestDetails(id: abTestId, name: abTestName, caseIndex: abTestCaseIndex)
                abTestDetailsArray.append(abDetails)
            }
        }

        self.abTestDetailsArray = abTestDetailsArray
    }

    /// Get information about the AB Tests a user is part of.
    ///
    /// - Returns: Array of SwrveABTestDetails.
    @objc public func abTestDetails() -> [SwrveABTestDetails] {
        abTestDetailsArray
    }
}

@objc public class SwrveResource: NSObject {
    private var attributes: [String: Any]

    /// Initialize with a dictionary of resource attributes
    ///
    /// - Parameter resourceAttributes: The attributes for this resource
    @objc public init(resourceAttributes: [String: Any]) {
        self.attributes = resourceAttributes
        super.init()
    }

    /// Get an array containing the attribute keys.
    ///
    /// - Returns: The attribute keys.
    @objc public func attributeKeys() -> [String] {
        Array(attributes.keys)
    }

    /// Get an attribute of the resource as a string.
    ///
    /// - Parameters:
    ///   - attributeId: Attribute identifier.
    ///   - defaultValue: Default attribute value.
    /// - Returns: The value of the attribute or the default value provided.
    @objc public func attributeAsString(_ attributeId: String, withDefault defaultValue: String) -> String {
        attributes[attributeId] as? String ?? defaultValue
    }

    /// Get an attribute of the resource as an integer.
    ///
    /// - Parameters:
    ///   - attributeId: Attribute identifier.
    ///   - defaultValue: Default attribute value.
    /// - Returns: The value of the attribute or the default value provided.
    @objc public func attributeAsInt(_ attributeId: String, withDefault defaultValue: Int) -> Int {
        if let attribute = attributes[attributeId] as? Int {
            return attribute
        } else if let attribute = attributes[attributeId] as? Double {
            return Int(attribute)
        } else if let attribute = attributes[attributeId] as? NSNumber {
            return attribute.intValue
        } else if let attribute = attributes[attributeId] as? String, let intValue = Int(attribute) {
            return intValue
        }
        return defaultValue
    }

    /// Get an attribute of the resource as a float.
    ///
    /// - Parameters:
    ///   - attributeId: Attribute identifier.
    ///   - defaultValue: Default attribute value.
    /// - Returns: The value of the attribute or the default value provided.
    @objc public func attributeAsFloat(_ attributeId: String, withDefault defaultValue: Float) -> Float {
        if let attribute = attributes[attributeId] as? Float {
            return attribute
        } else if let attribute = attributes[attributeId] as? Double {
            return Float(attribute)
        } else if let attribute = attributes[attributeId] as? NSNumber {
            return attribute.floatValue
        } else if let attribute = attributes[attributeId] as? String, let floatValue = Float(attribute) {
            return floatValue
        }
        return defaultValue
    }

    /// Get an attribute of the resource as a boolean.
    ///
    /// - Parameters:
    ///   - attributeId: Attribute identifier.
    ///   - defaultValue: Default attribute value.
    /// - Returns: The value of the attribute or the default value provided.
    @objc public func attributeAsBool(_ attributeId: String, withDefault defaultValue: Bool) -> Bool {
        if let attribute = attributes[attributeId] as? String {
            return (attribute.caseInsensitiveCompare("true") == .orderedSame || attribute.caseInsensitiveCompare("yes") == .orderedSame)
        }
        return defaultValue
    }
}

@objc public class SwrveABTestDetails: NSObject {
    @objc public dynamic var id: String = ""
    @objc public dynamic var name: String = ""
    @objc public dynamic var caseIndex: Int = 0
    /// Create an instance with the given attributes.
    ///
    /// - Parameters:
    ///   - id: Id of the test.
    ///   - name: Name of the test.
    ///   - caseIndex: Case index assigned to the user.
    /// - Returns: New AB Test information instance with the given attributes.
    @objc public convenience init(id: String, name: String, caseIndex: Int) {
        self.init()
        self.id = id
        self.name = name
        self.caseIndex = caseIndex
    }
}
