import SwiftUI
import FamilyControls

struct ContentView: View {

    @EnvironmentObject private var controller: ShieldController
    @State private var showPicker = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            status

            Button {
                controller.toggle()
            } label: {
                Text(controller.isBricked ? "Unbrick" : "Brick")
                    .font(.title2.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(controller.isBricked ? .green : .red)
            .disabled(!controller.isAuthorized || controller.selectedCount == 0)

            Button {
                showPicker = true
            } label: {
                Label(pickerLabel, systemImage: "square.grid.2x2")
            }
            .disabled(!controller.isAuthorized)

            if !controller.isAuthorized {
                Button("Grant Screen Time access") {
                    Task { await controller.requestAuthorization() }
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            Text("Tap the MagicBand to the top back of the phone to toggle.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .familyActivityPicker(isPresented: $showPicker, selection: $controller.selection)
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
