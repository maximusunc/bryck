import SwiftUI

@main
struct BrickApp: App {

    @StateObject private var controller = ShieldController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(controller)
                .onOpenURL { url in
                    // brick://toggle  — fired by the Shortcuts NFC automation.
                    guard url.scheme == "brick", url.host == "toggle" else { return }
                    controller.toggle()
                }
        }
    }
}
