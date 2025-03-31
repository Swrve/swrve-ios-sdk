import Foundation

#if canImport(SwrveSDK)
import SwrveSDK
#endif

/// Swrve stack names.
@objc public enum SwrveStack: Int {
    /// Swrve US stack.
    case us
    /// Swrve EU stack.
    case eu
}

/// Swrve init modes.
@objc public enum SwrveInitMode: Int {
    /// This is the default mode and automatically tracks when your app appears in the foreground.
    case auto
    /// This mode should be configured to manage setting the userId and manage how it starts.
    /// See autoStartLastUser configuration also.
    case managed
}

@objc public protocol SwrveDeeplinkDelegate: NSObjectProtocol {

    /// The Swrve SDK currently processes deeplinks with openUrl. This may not work if the the link is a universal link.
    /// Use this delegate to override that processing and use your own implementation
    /// - Parameter url: NSURL to be processed
    @objc optional func handleDeeplink(_ url: NSURL)
}

/// Defines the block signature for being notified when the resources have been updated with new content.
public typealias SwrveResourcesUpdatedListener = () -> Void

/// Configuration options for the Swrve SDK
@objc public class SwrveConfig: NSObject {

    /// The supported orientations of the app.
    @objc public var orientation: SwrveInterfaceOrientation = SWRVE_ORIENTATION_BOTH

    /// By default, Swrve will read the application version from the current application bundle.
    /// This is used to allow you to test and target users with a particular application version.
    /// If you use a different application versioning system, you can specify this here.
    @objc public var appVersion: String?

    /// Swrve will read the language from the current device using the `NSLocale.preferredLanguages` API.
    /// If your app has a custom mechanism to allow users to change their language, then you should set this property.
    /// The language value here should be a valid IETF language tag.
    /// Typical values are codes such as `en_US`, `en_GB`, or `fr_FR`.
    @objc public var language: String?

    /// Controls if resources and in-app messages are automatically downloaded.
    @objc public var autoDownloadCampaignsAndResources: Bool = true

    /// In-app message configuration.
    @objc public var inAppMessageConfig: SwrveInAppMessageConfig = SwrveInAppMessageConfig()

    /// Embedded message configuration.
    @objc public var embeddedMessageConfig: SwrveEmbeddedMessageConfig = SwrveEmbeddedMessageConfig()

    /// Session timeout time in seconds. User activity after this time will be considered a new session.
    @objc public var newSessionInterval: TimeInterval = 30

    /// A callback to get notified when user resources have been updated.
    /// If `autoDownloadCampaignsAndResources` is true, user resources will be kept up to date automatically
    /// and this listener will be called whenever there has been a change.
    /// Instead of using the listener, you could use the `SwrveResourceManager` to get
    /// the latest value for each attribute at the time you need it. Resources and attributes in the resourceManager
    /// are kept up to date.
    /// When `autoDownloadCampaignsAndResources` is false, resources will not be kept up to date, and you will have
    /// to manually call `refreshCampaignsAndResources` - which will call this listener on completion.
    @objc public var resourcesUpdatedCallback: (() -> Void)?

    /// Controls if `sendEvents` is automatically called when the app resumes in the foreground.
    @objc public var autoSendEventsOnResume: Bool = true

    /// Controls if `saveEvents` is automatically called when the app resigns to the background.
    @objc public var autoSaveEventsOnResign: Bool = true

    #if os(iOS)

    /// Controls if `UNAuthorizationOptionProvidesAppNotificationSettings` is added to push options when requesting push permissions.
    /// Default is false. If set to true, the `SwrvePushResponseDelegate` will include a callback to `openSettingsForNotification:`.
    @objc public var providesAppNotificationSettings: Bool = false

    /// Controls if push notifications are enabled.
    @objc public var pushEnabled: Bool = false

    /// The set of Swrve events that will trigger a provisional push notifications request on iOS 12+.
    /// If you want to request it at app start, set the value to a set with "Swrve.session.start".
    @objc public var provisionalPushNotificationEvents: Set<String>?

    /// The set of Swrve events that will trigger a push notifications request. By default, it will not request the permission.
    @objc public var pushNotificationPermissionEvents: Set<String>?

    /// Controls if the SDK automatically collects the push device token.
    /// To manually set the device token yourself, set to false.
    @objc public var autoCollectDeviceToken: Bool = true

    /// Set of iOS 10+ interactive push notification categories (UNUser).
    /// Initialize this set only if running on an iOS 10+ device with the interactive actions that your app supports for push notifications.
    /// Will be used when registering for notification permissions with `UNUserNotificationCenter`.
    @objc public var notificationCategories: Set<UNNotificationCategory>?

    /// This is an optional delegate that can be extended to fire rich push responses from a class of your choice.
    /// For this to work effectively, please ensure it is added before Swrve initialization and initialization happens before the application has finished loading.
    @objc public weak var pushResponseDelegate: SwrvePushResponseDelegate?

    #endif  // os(iOS)

    /// Identifier which refers to the app group that stores settings information.
    /// Initialize this if you are using extensions and want to share data across to Swrve.
    /// The `appGroupIdentifier` must match the one used in the accompanying extension to be shared correctly.
    @objc public var appGroupIdentifier: String?

    /// Maximum delay for in-app messages to appear after initialization.
    @objc public var autoShowMessagesMaxDelay: Int64 = 5000

    /// Specify the number of seconds to wait before considering a request as 'timed out'.
    /// Typically, a value between 5 and 20 seconds should suffice.
    @objc public var httpTimeoutSeconds: Int32 = 60

    /// Set to override the default location of the server to which Swrve will send analytics events.
    /// If your company has a special API end-point enabled, then you should specify it here.
    /// You should only need to change this value if you are working with Swrve support on a specific support issue.
    @objc public var eventsServer: String?

    /// Set to override the default location of the server from which Swrve will receive personalized content.
    /// If your company has a special API end-point enabled, then you should specify it here.
    /// You should only need to change this value if you are working with Swrve support on a specific support issue.
    @objc public var contentServer: String?

    /// Set to override the default location of the server from which Swrve will identify users.
    /// If your company has a special API end-point enabled, then you should specify it here.
    /// You should only need to change this value if you are working with Swrve support on a specific support issue.
    @objc public var identityServer: String?

    /// The stack your app resides in.
    @objc public var stack: SwrveStack = .us

    /// Default mode is `SwrveInitMode (Auto)` which automatically starts when UI is shown.
    /// Set `initMode` to `SwrveInitMode (Managed)` to delay starting the SDK until the `start` API is called.
    @objc public var initMode: SwrveInitMode = .auto

    /// If true, the SDK will delay starting until the `start` API is called and the userId is set.
    /// Once set, it will auto-start when UI is shown. Set to false to force the SDK to always delay tracking until a
    /// `start` API is called.
    @objc public var autoStartLastUser: Bool = true

    /// Obtain information about the AB Tests a user is part of.
    @objc public var abTestDetailsEnabled: Bool = false

    /// Implement this delegate in your app to be able to report on permissions and use them as message actions.
    @objc public weak var permissionsDelegate: SwrvePermissionsDelegate?

    /// Implement this delegate to override deep link handling.
    @objc public weak var deeplinkDelegate: SwrveDeeplinkDelegate?

    /// Controls if we auto collect and send the IDFV as a device property.
    @objc public var autoCollectIDFV: Bool = false

    /// Implement this delegate to listen to our rest client calls for authentication challenges.
    @objc public weak var urlSessionDelegate: URLSessionDelegate?

    @objc public override init() {
        self.language = Locale.preferredLanguages.first
        self.resourcesUpdatedCallback = {
            // Do nothing by default.
        }
    }
}
