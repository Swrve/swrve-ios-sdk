import Foundation

/// Debug aid for this sample only — none of this is needed to integrate Swrve. It records what the app
/// and extension did with each push, so the relays are visible on screen.
///
/// Compiled into both the app and the service extension, which run as separate processes, so it writes
/// through the app group — the same mechanism Swrve uses to carry influence data back to the app.
enum PushActivityLog {

    private static let key = "PushActivityLog"
    private static let limit = 10

    static var entries: [String] {
        store?.stringArray(forKey: key) ?? []
    }

    static func record(_ message: String) {
        guard let store else { return }
        var updated = store.stringArray(forKey: key) ?? []
        updated.insert("\(timestamp())  \(message)", at: 0)
        store.set(Array(updated.prefix(limit)), forKey: key)
    }

    static func clear() {
        store?.removeObject(forKey: key)
    }

    private static var store: UserDefaults? {
        UserDefaults(suiteName: APP_GROUP)
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
}
