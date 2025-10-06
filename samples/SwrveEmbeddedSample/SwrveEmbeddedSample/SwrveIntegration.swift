import Foundation
import SwrveSDK

enum SwrveCredentialStore {
    private static let appIdKey = "SwrveSample_AppID"
    private static let apiKeyKey = "SwrveSample_ApiKey"
    private static let stackKey = "SwrveSample_Stack"  // "us" or "eu"
    private static let offlineModeKey = "SwrveSample_OfflineMode"  // Bool

    static let defaultAppId: Int = 123
    static let defaultApiKey: String = "api_key"
    static let defaultStack: String = "us"
    static let defaultAppInstallTime: String = "1750959353"

    static func load() -> (appId: Int, apiKey: String) {
        let storedAppId = UserDefaults.standard.object(forKey: appIdKey) as? NSNumber
        let storedApiKey = UserDefaults.standard.string(forKey: apiKeyKey)
        let appId = storedAppId?.intValue ?? defaultAppId
        let apiKey = storedApiKey?.isEmpty == false ? storedApiKey! : defaultApiKey
        return (appId, apiKey)
    }

    static func save(appId: Int, apiKey: String) {
        UserDefaults.standard.set(appId, forKey: appIdKey)
        UserDefaults.standard.set(apiKey, forKey: apiKeyKey)
    }

    static func loadStack() -> String {
        let stored = UserDefaults.standard.string(forKey: stackKey)?.lowercased()
        return (stored == "eu" || stored == "us" || stored == "fs") ? stored! : defaultStack
    }

    static func loadAll() -> (appId: Int, apiKey: String, stack: String) {
        let creds = load()
        return (creds.appId, creds.apiKey, loadStack())
    }

    static var hasCustomCredentials: Bool {
        (UserDefaults.standard.object(forKey: appIdKey) != nil) || (UserDefaults.standard.string(forKey: apiKeyKey) != nil)
    }

    static func setOfflineMode(_ enabled: Bool) { UserDefaults.standard.set(enabled, forKey: offlineModeKey) }
    static func isOfflineMode() -> Bool {
        if UserDefaults.standard.object(forKey: offlineModeKey) == nil {
            return true  // Default to true (offline) if not set yet
        }
        return UserDefaults.standard.bool(forKey: offlineModeKey)
    }
}

// Notification name for embedded messages
extension Notification.Name {
    static let SwrveEmbeddedMessageReceived = Notification.Name("SwrveEmbeddedMessageReceived")
}

enum SwrveIntegration {

    static func initialize() {
        // Determine if offline mode is enabled (forces default credentials)
        var all = SwrveCredentialStore.loadAll()
        if SwrveCredentialStore.isOfflineMode() {
            all.appId = SwrveCredentialStore.defaultAppId
            all.apiKey = SwrveCredentialStore.defaultApiKey
        }

        let config = SwrveConfig()
        switch all.stack {
        case "eu":
            config.stack = .eu
        case "fs":
            config.contentServer = "https://us-fs26-content.swrve.com"
            config.eventsServer = "https://us-fs26-api.swrve.com"
            config.identityServer = "https://us-fs26-identity.swrve.com"
        default:
            config.stack = .us
        }

        let embeddedConfig = SwrveEmbeddedMessageConfig()
        embeddedConfig.embeddedCallback = { message, personalizationProperties, isControl in

            if isControl {
                SwrveSDK.embeddedControlMessageImpressionEvent(message)
                return
            }

            guard let personalizedData = SwrveSDK.personalizeEmbeddedMessageData(message, withPersonalization: personalizationProperties) else {
                return
            }
            let userInfo: [AnyHashable: Any] = ["data": personalizedData, "message": message]
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .SwrveEmbeddedMessageReceived, object: nil, userInfo: userInfo)
            }
        }
        config.embeddedMessageConfig = embeddedConfig

        SwrveSDK.sharedInstance(withAppID: all.appId, apiKey: all.apiKey, config: config)

        if SwrveCredentialStore.isOfflineMode() {
            // Inject offline demo content after sharedInstance is called so that userId has been created
            injectOfflineDemoContent(SwrveSDK.userID())
        }
    }

    // For offline mode, copy bundled demo_campaigns.json to the swrve app support folder. Do not use in production.
    private static func injectOfflineDemoContent(_ userId: String) {
        let fileManager = FileManager.default
        if let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let swrveFolderURL = appSupportURL.appendingPathComponent("swrve", isDirectory: true)
            do {
                try fileManager.createDirectory(at: swrveFolderURL, withIntermediateDirectories: true, attributes: nil)  // create swrve folder if not exists
            } catch {
                print("Failed to create swrve folder: \(error)")
            }
            if let sourceURL = Bundle.main.url(forResource: "demo_campaigns", withExtension: "json") {
                let destinationURL = swrveFolderURL.appendingPathComponent(userId + "cmcc2.json")
                do {
                    if fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.removeItem(at: destinationURL)
                    }
                    try fileManager.copyItem(at: sourceURL, to: destinationURL)
                } catch {
                    print("Failed to copy demo campaigns content: \(error)")
                }
            } else {
                print("demo_campaigns.json not found in bundle; skipping offline campaign copy")
            }
            if let txtSourceURL = Bundle.main.url(forResource: "demo_campaigns", withExtension: "txt") {
                let txtDestinationURL = swrveFolderURL.appendingPathComponent(userId + "cmccsgt2.txt")
                do {
                    if fileManager.fileExists(atPath: txtDestinationURL.path) {
                        try fileManager.removeItem(at: txtDestinationURL)
                    }
                    try fileManager.copyItem(at: txtSourceURL, to: txtDestinationURL)
                } catch {
                    print("Failed to copy demo campaigns txt content: \(error)")
                }
            } else {
                print("demo_campaigns.txt not found in bundle; skipping offline campaign txt copy")
            }
        }

        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let installFileURL = documentsURL.appendingPathComponent("swrve_install.txt")
            let content = SwrveCredentialStore.defaultAppInstallTime
            do {
                if !fileManager.fileExists(atPath: installFileURL.path) {
                    fileManager.createFile(atPath: installFileURL.path, contents: nil, attributes: nil)
                }
                try content.write(to: installFileURL, atomically: true, encoding: .utf8)
            } catch {
                print("Failed to write swrve_install.txt content: \(error)")
            }
        }
        SwrveSDK.stopTracking()
        SwrveSDK.start()
    }
}
