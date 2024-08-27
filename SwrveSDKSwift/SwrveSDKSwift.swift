import Foundation

#if canImport(ActivityKit)
    import ActivityKit
#endif

@objc public class SwrveSDKSwift: NSObject {}

#if canImport(ActivityKit)

    extension SwrveSDKSwift {

        /**
     Starts observing an activity with specified attributes. Please note that Live Activity being started with empty actvity id will not be tracked.

     - Parameter attributeType: A attributes type of activity which must conform to SwrveLiveActivityAttributes.
     - Returns: Void.

     - Usages:
         ```
        SwrveSDKSwift.registerLiveActivity(ofType: MyAttributes.self)

         ```
     */

        @available(iOS 16.2, *)
        class public func registerLiveActivity<T: SwrveLiveActivityAttributes>(
            ofType attributesType: T.Type
        ) {
            SwrveLiveActivity.registerActivity(ofType: attributesType)
        }

    }

#endif
