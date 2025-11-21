#if canImport(ActivityKit)
import Foundation
import ActivityKit
import CommonCrypto

#if canImport(SwrveSDK)
import SwrveSDK
#endif

#if canImport(SwrveSDKCommon)
import SwrveSDKCommon
#endif

@available(iOS 16.2, *)
public protocol SwrveLiveActivityAttributes: ActivityAttributes {
    var activityId: String { get set }
    var staleDate: Double? { get set }
}

@objc public class SwrveLiveActivity: NSObject {

    private static let storage = SwrveLiveActivityStorage()
    private static var currentPushToStartToken: String? = {
        return storage.fetchPushToStartToken()
    }()

    private static var activityUpdateTokenDict: [String: String] = [:]
    private static var swrve: SwrveProtocol? {
        guard let sdk = SwrveSDK.sharedInstance else {
            #if DEBUG
            SwrveLogger.logDebug("Please call SwrveSDK.init(...) first")
            #endif
            return nil
        }
        return sdk
    }

    private static var swrveCommon: SwrveCommonDelegate? {
        guard let sdk = SwrveCommon.sharedInstance() else {
            SwrveLogger.logDebug("Unable to get reference to SwrveCommon")
            return nil
        }
        return sdk
    }

    public override init() {}

}

@available(iOS 16.2, *)
extension SwrveLiveActivity {
    enum Constant {
        enum StartEvent {
            static let liveActivity = "Swrve.live_activity_started"

            enum Payload {
                static let attributesType = "attributes_type"
                static let attributesHash = "attributes_hash"
                static let contentHash = "content_state_hash"
                static let uniqueActivityId = "unique_activity_id"
                static let activityId = "activity_id"
            }
        }

        enum UpdateEvent {
            static let liveActivity = "Swrve.live_activity_update"
            static let active = "active"
            static let ended = "ended"
            static let dismissed = "dismissed"
            static let stale = "stale"

            enum Payload {
                static let actionType = "activity_action_type"
                static let uniqueActivityId = "unique_activity_id"
                static let activityId = "activity_id"
                static let token = "token"
            }
        }
    }
}

@available(iOS 16.2, *)

extension SwrveLiveActivity {
    static func registerActivity<T: SwrveLiveActivityAttributes>(ofType attributesType: T.Type) {
        //temporary work around to store the values so they can be read by SwrveDeviceProperites.

        storage.saveFrequentPushEnabled(ActivityAuthorizationInfo().frequentPushesEnabled)
        storage.saveActivitiesEnabled(ActivityAuthorizationInfo().areActivitiesEnabled)
        if #available(iOS 17.2, *) {
            startObservingPushToStartToken(attributesType: attributesType)
        }
        startObservingActivityUpdates(attributesType: attributesType)
        resumeTracking(attributesType: attributesType)
    }

    class func startTracking<T: ActivityAttributes>(activityId: String, activity: Activity<T>) {
        if activityId.isEmpty {
            SwrveLogger.logDebug("\(String(describing: T.self)) will not be tracked as activity id is empty")
            return
        }
        let attributeDict = activity.attributes.dict ?? [:]
        let contentDict = activity.content.state.dict ?? [:]

        sendStartEvent(
            activityId: activityId,
            uniqueActivityId: activity.id,
            attributesType: T.self,
            staticContentDict: attributeDict,
            dynamicContentDict: contentDict
        )
        observePushTokenUpdates(activityId: activityId, activity: activity)
        observeActivityStateUpdates(activityId: activityId, activity: activity)
    }

    class func resumeTracking<T: ActivityAttributes>(attributesType: T.Type) {
        let activeActivities = Activity<T>.activities
        if activeActivities.isEmpty {
            let name = activityName(for: Activity<T>.self)
            storage.remove(withName: name)
            return
        }

        let storedActivitiesData = storage.fetchActivities()

        for activeActivity in activeActivities {
            storedActivitiesData.filter { $0.id == activeActivity.id }.forEach {
                startTracking(activityId: ($0.activityId), activity: activeActivity)
            }
        }
    }

    class func activityName<T: ActivityAttributes>(for activityType: Activity<T>.Type) -> String {
        String(describing: activityType)
    }

    @discardableResult class func sendStartEvent<T: ActivityAttributes>(
        activityId: String,
        uniqueActivityId: String,
        attributesType: T.Type,
        staticContentDict: [String: Any],
        dynamicContentDict: [String: Any]
    ) -> NSMutableDictionary? {
        guard let _ = swrve else { return nil }
        guard let _ = swrveCommon else { return nil }
        if storage.fetchActivity(withUniqueActivityId: uniqueActivityId) != nil {
            // start event has already been sent
            return nil
        }

        let attributeDictWithStringValue = staticContentDict.compactMapValues { String(describing: $0) }
        let hashedAttributes = attributeDictWithStringValue.keys.sorted().joined(separator: ", ").md5()

        let contentDictWithStringValue = dynamicContentDict.compactMapValues { String(describing: $0) }
        let hashedContent = contentDictWithStringValue.keys.sorted().joined(separator: ", ").md5()

        let payload: [String: String] = [
            Constant.StartEvent.Payload.attributesType: String(describing: T.self),
            Constant.StartEvent.Payload.attributesHash: hashedAttributes,
            Constant.StartEvent.Payload.contentHash: hashedContent,
            Constant.StartEvent.Payload.uniqueActivityId: uniqueActivityId,
            Constant.StartEvent.Payload.activityId: activityId
        ]

        let event = sendEvent(name: Constant.StartEvent.liveActivity, payload: payload)
        return event
    }

    @discardableResult class func sendUpdateEvent(
        activityId: String,
        type: String,
        token: String? = nil,
        uniqueActivityId: String
    ) -> NSMutableDictionary? {
        guard let _ = swrve else { return nil }
        guard let _ = swrveCommon else { return nil }

        var payload: [String: String] = [
            Constant.UpdateEvent.Payload.actionType: type,
            Constant.UpdateEvent.Payload.uniqueActivityId: uniqueActivityId,
            Constant.UpdateEvent.Payload.activityId: activityId
        ]

        if let tokenValue = token {
            payload[Constant.UpdateEvent.Payload.token] = tokenValue
        }

        let event = sendEvent(name: Constant.UpdateEvent.liveActivity, payload: payload)
        return event
    }

    @discardableResult class func sendEvent(name: String, payload: [String: String]) -> NSMutableDictionary {
        let eventDict = NSMutableDictionary()
        eventDict["name"] = name
        eventDict["user_initiated"] = "false"
        eventDict["payload"] = payload
        swrveCommon?.queueEvent("event", data: eventDict, triggerCallback: false)
        // Force event sending
        swrveCommon?.sendQueuedEvents()
        return eventDict
    }
}

@available(iOS 16.2, *)
extension SwrveLiveActivity {

    fileprivate class func observePushTokenUpdates<T: ActivityAttributes>(activityId: String, activity: Activity<T>) {
        Task {
            // Save activity
            let activityName = activityName(for: type(of: activity))
            let activityData = SwrveLiveActivityData(
                id: activity.id,
                activityId: activityId,
                activityName: activityName
            )
            storage.save(activityData)

            for await data in activity.pushTokenUpdates {
                let token = data.map { String(format: "%02x", $0) }.joined()
                let lastSavedToken = activityUpdateTokenDict[activity.id]
                // prevent multiple calls with same token.
                if lastSavedToken != token {
                    activityUpdateTokenDict[activity.id] = token
                    sendUpdateEvent(
                        activityId: activityId,
                        type: Constant.UpdateEvent.active,
                        token: token,
                        uniqueActivityId: activity.id
                    )
                }
            }
        }
    }

    fileprivate class func observeActivityStateUpdates<T: ActivityAttributes>(activityId: String, activity: Activity<T>) {
        Task {
            for await update in activity.activityStateUpdates {

                if update == .active {
                    // active event is processed above in pushTokenUpdates
                } else if update == .ended {
                    guard let _ = activityUpdateTokenDict[activity.id] else {
                        // Early exit as end event for this actvity already triggered
                        return
                    }
                    activityUpdateTokenDict.removeValue(forKey: activity.id)
                    sendUpdateEvent(activityId: activityId, type: Constant.UpdateEvent.ended, uniqueActivityId: activity.id)
                    storage.remove(withId: activity.id)
                } else if update == .dismissed {
                    guard let _ = activityUpdateTokenDict[activity.id] else {
                        // Early exit as dismiss event for this actvity already triggered
                        return
                    }
                    activityUpdateTokenDict.removeValue(forKey: activity.id)
                    sendUpdateEvent(activityId: activityId, type: Constant.UpdateEvent.dismissed, uniqueActivityId: activity.id)
                    storage.remove(withId: activity.id)
                }
                if update == .stale {
                    sendUpdateEvent(activityId: activityId, type: Constant.UpdateEvent.stale, uniqueActivityId: activity.id)
                }
            }
        }
    }
}

/*
 // MARK: registerLiveActivity
 */

@available(iOS 16.2, *)
extension SwrveLiveActivity {
    @available(iOS 17.2, *)
    private static func startObservingPushToStartToken<T: SwrveLiveActivityAttributes>(attributesType: T.Type) {
        Task {
            for await data in Activity<T>.pushToStartTokenUpdates {
                let token = data.map { String(format: "%02x", $0) }.joined()
                if currentPushToStartToken == nil
                    || currentPushToStartToken != token
                {
                    currentPushToStartToken = token
                    storage.savePushToStartToken(token)
                    DispatchQueue.main.async {
                        SwrveSDK.sharedInstance.sendDeviceUpdate()
                    }
                } else {
                    // token remains the same, don't do anything
                }
            }
        }
    }

    @available(iOS 16.2, *)
    private static func startObservingActivityUpdates<T: SwrveLiveActivityAttributes>(
        attributesType: T.Type
    ) {
        Task {
            for await activeActivity in Activity<T>.activityUpdates {
                startTracking(
                    activityId: activeActivity.attributes.activityId,
                    activity: activeActivity
                )
                if let unwrappedTimeStamp = activeActivity.attributes.staleDate {
                    Task {
                        let staleDate = Date(timeIntervalSince1970: unwrappedTimeStamp)
                        let contentState = ActivityContent(state: activeActivity.contentState, staleDate: staleDate)
                        await activeActivity.update(contentState)
                    }
                }

            }
        }
    }
}

/*
 // MARK: ActivityAuthorizationInfoProtocol
 */

@objc public protocol ActivityAuthorizationInfoProtocol {
    @available(iOSApplicationExtension 12.0, iOS 16.2, *)
    @objc func areActivitiesEnabled() -> Bool

    @available(iOSApplicationExtension 12.0, iOS 16.2, *)
    @objc func frequentPushesEnabled() -> Bool

    @available(iOS 17.2, *)
    @objc func pushToStartToken() -> String?
}

@available(iOS 16.2, *)
extension SwrveLiveActivity: ActivityAuthorizationInfoProtocol {
    @available(iOS 16.2, *)
    @objc public func areActivitiesEnabled() -> Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    @available(iOS 16.2, *)
    @objc public func frequentPushesEnabled() -> Bool {
        ActivityAuthorizationInfo().frequentPushesEnabled
    }

    @available(iOS 17.2, *)
    @objc public func pushToStartToken() -> String? {
        SwrveLiveActivity.currentPushToStartToken
    }
}

extension Encodable {
    var dict: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else {
            return nil
        }
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }
        return json
    }
}

extension String {

    func md5() -> String {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        guard let messageData = self.data(using: .utf8) else {
            return ""
        }
        var digestData = Data(count: length)

        _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
            messageData.withUnsafeBytes { messageBytes -> UInt8 in
                if let messageBytesBaseAddress = messageBytes.baseAddress,
                    let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress
                {
                    let messageLength = CC_LONG(messageData.count)
                    CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                }
                return 0
            }
        }
        return digestData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

#endif
