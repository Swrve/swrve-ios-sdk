#if canImport(ActivityKit)
import Foundation
import ActivityKit

#if canImport(SwrveSDK)
import SwrveSDK
#endif

#if canImport(SwrveSDKCommon)
import SwrveSDKCommon
#endif

@objc public class SwrveLiveActivity: NSObject {
    
    private static let storage = SwrveLiveActivityStorage()
    
    public override init() { }
    
}

@available(iOS 16.1, *)
extension SwrveLiveActivity {
    enum Constant {
        enum Event {
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


@available(iOS 16.1, *)
extension SwrveLiveActivity {

    class func startTracking<T: ActivityAttributes>(activityId: String, activity: Activity<T>) {
        observePushTokenUpdates(activityId, activity)
        observeActivityStateUpdates(activityId, activity)
    }
    
    class func resumeTracking<T: ActivityAttributes>(ofType activityType: Activity<T>.Type) {
        let activeActivities = activityType.activities
        if activeActivities.isEmpty {
            let name = activityName(for: activityType)
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
}

@available(iOS 16.1, *)
private extension SwrveLiveActivity {
    
    class func activityName<T: ActivityAttributes>(for activityType: Activity<T>.Type) -> String {
        return String(describing: activityType)
    }
    
    class func observePushTokenUpdates<T: ActivityAttributes>(_ activityId: String, _ activity: Activity<T>) {
        Task {
            // Save activity
            let actvityName = activityName(for: type(of: activity))
            let actvityData = SwrveLiveActivityData(
                id: activity.id,
                activityId: activityId,
                activityName: actvityName
            )
            storage.save(actvityData)
            
            var dedupeToken: String? = nil
            for await data in activity.pushTokenUpdates {
                let token = data.map {String(format: "%02x", $0)}.joined()
                // prevent multiple calls with same token.
                if (dedupeToken != token) {
                    dedupeToken = token
                    sendEvent(
                        activity,
                        activityId: activityId,
                        type: Constant.Event.active,
                        token: token
                    )
                }
            }
        }
    }
    
    class func observeActivityStateUpdates<T: ActivityAttributes>(_ activityId: String, _ activity: Activity<T>) {
        Task {
            for await update in activity.activityStateUpdates {
                
                if update == .active {
                    // active event is processed above in pushTokenUpdates
                }
                else if update == .ended {
                    sendEvent(activity, activityId: activityId, type: Constant.Event.ended, token: nil)
                    storage.remove(withId: activity.id)
                }
                else if update == .dismissed {
                    sendEvent(activity, activityId: activityId, type: Constant.Event.dismissed, token: nil)
                    storage.remove(withId: activity.id)
                }
                if #available(iOS 16.2, *) {
                    if update == .stale {
                        sendEvent(activity, activityId: activityId, type: Constant.Event.stale, token: nil)
                        storage.remove(withId: activity.id)
                    }
                }
            }
        }
    }
    
    class func sendEvent<T: ActivityAttributes>(_ activity: Activity<T>, activityId: String, type: String, token: String?) {
        guard let _ = SwrveSDK.sharedInstance() else {
#if DEBUG
            print("SwrveSDK: Please call SwrveSDK.init(...) first")
#endif
            return
        }
        
        guard let swrveCommon = SwrveCommon.sharedInstance() else {
#if DEBUG
            print("SwrveSDK: Unable to get reference to SwrveCommon")
#endif
            return
        }
        
        var payload: [String: Any] = [
            Constant.Event.Payload.actionType: type,
            Constant.Event.Payload.uniqueActivityId: activity.id,
            Constant.Event.Payload.activityId: activityId
        ]
        
        if let tokenValue = token {
            payload[Constant.Event.Payload.token] = tokenValue
        }
        
        swrveCommon.eventInternal(
            Constant.Event.liveActivity,
            payload: payload,
            triggerCallback: false
        )
    }
}

/*
 // MARK: ActivityAuthorizationInfoProtocol
 */

@objc public protocol ActivityAuthorizationInfoProtocol {
    @available(iOSApplicationExtension 10.0, iOS 16.1, *)
    @objc func areActivitiesEnabled() -> Bool
    
    @available(iOSApplicationExtension 10.0, iOS 16.2, *)
    @objc func frequentPushesEnabled() -> Bool
}

@available(iOS 16.1, *)
extension SwrveLiveActivity: ActivityAuthorizationInfoProtocol {
    @available(iOS 16.1, *)
    @objc public func areActivitiesEnabled() -> Bool {
        return ActivityAuthorizationInfo().areActivitiesEnabled
    }
    
    @available(iOS 16.2, *)
    @objc public func frequentPushesEnabled() -> Bool {
        return ActivityAuthorizationInfo().frequentPushesEnabled
    }
}

#endif

