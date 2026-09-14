import Foundation
import Combine
import FamilyControls
import ManagedSettings

extension ManagedSettingsStore.Name {
    static let brick = Self("brick")
}

@MainActor
final class ShieldController: ObservableObject {

    private let store = ManagedSettingsStore(named: .brick)
    private let defaults = UserDefaults.standard

    private enum Key {
        static let selection = "brick.selection"
        static let isBricked = "brick.isBricked"
        static let token = "brick.token"
        static let tokenProven = "brick.tokenProven"
    }

    /// Secret the Shortcuts automation has to present. Generated once, on
    /// first launch, and never shown while bricked.
    let token: String

    /// Set the first time a correctly-keyed URL actually arrives, which is
    /// proof the automation has been updated. Until then the setup screen
    /// stays reachable even while bricked, so installing this build in the
    /// middle of a brick can't strand you with an automation that no longer
    /// works and no way to read the new URL.
    @Published private(set) var tokenProven: Bool

    /// The apps / categories / sites the user picked.
    @Published var selection: FamilyActivitySelection {
        didSet {
            persistSelection()
            if isBricked { applyShield() }   // changing the list while bricked re-applies it
        }
    }

    @Published private(set) var isBricked: Bool {
        didSet { defaults.set(isBricked, forKey: Key.isBricked) }
    }

    @Published private(set) var isAuthorized = false

    init() {
        let saved = defaults.string(forKey: Key.token)
        token = (saved?.isEmpty == false) ? saved! : UUID().uuidString.lowercased()
        if saved != token { defaults.set(token, forKey: Key.token) }
        tokenProven = defaults.bool(forKey: Key.tokenProven)

        // Property observers don't fire during init, so read straight into storage.
        if let data = defaults.data(forKey: Key.selection),
           let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = decoded
        } else {
            selection = FamilyActivitySelection()
        }
        isBricked = defaults.bool(forKey: Key.isBricked)
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved

        // The app may have been cold-launched by the NFC automation, so make the
        // real shield match what we last recorded before anything else runs.
        reconcile()
    }

    var selectedCount: Int {
        selection.applicationTokens.count
            + selection.categoryTokens.count
            + selection.webDomainTokens.count
    }

    // MARK: - Authorization

    func refreshAuthorizationStatus() {
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = true
        } catch {
            isAuthorized = false
            print("Brick: authorization failed — \(error)")
        }
    }

    // MARK: - The key

    /// Drives the setup button. Stays up until the band has actually worked
    /// once — including while bricked, so updating the app mid-brick can't
    /// strand you with a stale automation and no way to read the new key.
    var needsBandSetup: Bool { !tokenProven }

    /// Afterwards the key comes off the main screen for good; there's no
    /// reason to look at it again. Long-pressing the status icon brings it
    /// back if the automation ever needs rebuilding — but never while
    /// bricked, which is the only time the key is worth anything.
    var canRevealKeyOnDemand: Bool { tokenProven && !isBricked }

    /// The only way in. Returns false — and changes nothing — if the key is
    /// wrong, which is what a shortcut built without it will hit.
    @discardableResult
    func toggle(withKey key: String) -> Bool {
        guard key == token else { return false }

        if !tokenProven {
            tokenProven = true
            defaults.set(true, forKey: Key.tokenProven)
        }
        toggle()
        return true
    }

    /// Picks up a toggle made by the App Intent, which runs in its own
    /// process and so can't reach this instance.
    func refreshFromStorage() {
        let stored = defaults.bool(forKey: Key.isBricked)
        if stored != isBricked { isBricked = stored }
        tokenProven = defaults.bool(forKey: Key.tokenProven)
    }

    // MARK: - The toggle

    /// One tag, one tap: flip whatever the current state is.
    private func toggle() {
        isBricked.toggle()
        reconcile()
    }

    private func reconcile() {
        isBricked ? applyShield() : clearShield()
    }

    private func applyShield() {
        // nil means "shield nothing" — an empty Set would shield *everything*.
        store.shield.applications =
            selection.applicationTokens.isEmpty ? nil : selection.applicationTokens

        store.shield.applicationCategories =
            selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)

        store.shield.webDomains =
            selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }

    private func clearShield() {
        store.clearAllSettings()
    }

    private func persistSelection() {
        if let data = try? JSONEncoder().encode(selection) {
            defaults.set(data, forKey: Key.selection)
        }
    }
}
