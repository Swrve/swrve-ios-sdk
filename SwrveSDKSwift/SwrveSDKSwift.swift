import Foundation

#if canImport(ActivityKit)
import ActivityKit
#endif

@objc public class SwrveSDKSwift: NSObject { }

#if canImport(ActivityKit)

extension SwrveSDKSwift {
    /**
     Starts tracking an activity with specified attributes.
     
     - Parameter activityId: An identifier for the activity.
     - Parameter activity: The activity object containing details and attributes to be tracked.
     - Returns: Void.
     
     - Usages:
         ```
         let myActivity = Activity<MyAttributes>()
         SwrveSDKSwift.startLiveActivityTracking(activityId: "someId", activity: myActivity)
         ```
     */
    @available(iOSApplicationExtension 10.0, iOS 16.1, *)
    class public func startLiveActivityTracking<T: ActivityAttributes>(activityId: String, activity: Activity<T>) {
        SwrveLiveActivity.startTracking(activityId: activityId, activity: activity)
    }
    
    /**
     Resumes tracking of all activity of given activity type
     
     - Parameter activityType: The activity type containing type of attributes to be tracked.
     - Returns: Void.
     
     - Usage:
         ```
         SwrveSDKSwift.resumeLiveActivityTracking(ofType: Activity<MyAttributes>.self)
         ```
     */
    @available(iOSApplicationExtension 10.0, iOS 16.1, *)
    class public func resumeLiveActivityTracking<T: ActivityAttributes>(ofType activityType: Activity<T>.Type) {
        SwrveLiveActivity.resumeTracking(ofType: activityType)
    }
    
}

#endif
