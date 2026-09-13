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
    }

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

    // MARK: - The toggle

    /// One tag, one tap: flip whatever the current state is.
    func toggle() {
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
