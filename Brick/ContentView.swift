import SwiftUI
import FamilyControls

struct ContentView: View {

    @EnvironmentObject private var controller: ShieldController
    @State private var showPicker = false
    @State private var showSetup = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            status

            // No toggle here on purpose. The band is the only switch — an
            // on-screen button is always easier to reach than the band, which
            // defeats the point of having one.

            Button {
                showPicker = true
            } label: {
                Label(pickerLabel, systemImage: "square.grid.2x2")
            }
            .disabled(!controller.isAuthorized || controller.isBricked)

            if controller.canRevealAutomationURL {
                Button {
                    showSetup = true
                } label: {
                    Label("Band setup", systemImage: "wave.3.right")
                }
            }

            if !controller.isAuthorized {
                Button("Grant Screen Time access") {
                    Task { await controller.requestAuthorization() }
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            Text(hint)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .familyActivityPicker(isPresented: $showPicker, selection: $controller.selection)
        .sheet(isPresented: $showSetup) {
            AutomationSetupView(url: controller.automationURL)
        }
        .task {
            controller.refreshAuthorizationStatus()
            if !controller.isAuthorized {
                await controller.requestAuthorization()
            }
        }
    }

    private var pickerLabel: String {
        controller.selectedCount == 0
            ? "Choose apps to block"
            : "\(controller.selectedCount) selected"
    }

    private var hint: String {
        guard controller.isAuthorized else {
            return "Brick needs Screen Time access before it can block anything."
        }
        if controller.isBricked {
            return "Tap the MagicBand to the top back of the phone to unbrick.\nThe app list stays locked until you do."
        }
        return controller.selectedCount == 0
            ? "Pick some apps, then tap the MagicBand to the top back of the phone to brick."
            : "Tap the MagicBand to the top back of the phone to brick."
    }

    private var status: some View {
        VStack(spacing: 8) {
            Image(systemName: controller.isBricked ? "lock.fill" : "lock.open")
                .font(.system(size: 56))
                .foregroundStyle(controller.isBricked ? .red : .secondary)

            Text(controller.isBricked ? "Bricked" : "Open")
                .font(.largeTitle.weight(.bold))
        }
    }
}
