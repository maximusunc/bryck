import SwiftUI

@main
struct BrickApp: App {

    @StateObject private var controller = ShieldController()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(controller)
                .onChange(of: scenePhase) { _, phase in
                    // The band toggles via ToggleBrickIntent, in a separate
                    // process, so this instance can be stale on return.
                    if phase == .active { controller.refreshFromStorage() }
                }
        }
    }
}
