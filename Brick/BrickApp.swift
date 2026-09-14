import SwiftUI

@main
struct BrickApp: App {

    @StateObject private var controller = ShieldController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(controller)
                .onOpenURL { url in
                    // brick://toggle?key=...  — fired by the Shortcuts NFC
                    // automation. An unkeyed URL is ignored.
                    controller.handleToggleURL(url)
                }
        }
    }
}
