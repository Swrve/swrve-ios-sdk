import SwiftUI
import SwrveSDK

@main
struct SwrveEmbeddedSampleApp: App {
    init() {
        SwrveIntegration.initialize()
    }
    var body: some Scene {
        WindowGroup {
            MainMenuView()
        }
    }
}
