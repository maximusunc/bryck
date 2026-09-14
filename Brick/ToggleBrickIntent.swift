import AppIntents

/// The band's entry point. Runs from the Shortcuts NFC automation without
/// bringing Brick to the foreground — the point being that once the app list
/// is set, you never have to open the app again.
struct ToggleBrickIntent: AppIntent {

    // Computed and nonisolated so these satisfy AppIntent's requirements
    // regardless of the target's default actor isolation.
    nonisolated static var title: LocalizedStringResource { "Toggle Brick" }

    nonisolated static var description: IntentDescription {
        IntentDescription("Bricks or unbricks your chosen apps. Needs the key from Brick's Band setup screen.")
    }

    /// The whole reason this intent exists. With this true, iOS would
    /// foreground the app on every tap.
    nonisolated static var openAppWhenRun: Bool { false }

    @Parameter(title: "Key")
    var key: String

    @MainActor
    func perform() async throws -> some IntentResult {
        // The app itself may not be running, so this intent works through its
        // own controller. State lives in UserDefaults and ManagedSettings,
        // both of which outlive any one process.
        let controller = ShieldController()
        guard controller.toggle(withKey: key) else {
            throw ToggleBrickError.wrongKey
        }
        return .result()
    }
}

enum ToggleBrickError: Error, CustomLocalizedStringResourceConvertible {
    case wrongKey

    var localizedStringResource: LocalizedStringResource {
        "That key doesn't match this installation of Brick."
    }
}
