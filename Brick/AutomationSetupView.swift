import SwiftUI
import UIKit

/// Shows the key to paste into the Shortcuts automation.
///
/// Only reachable while unbricked (or before the automation has proved
/// itself) — if you could read the key mid-brick, it would be no more
/// friction than the button it replaced.
struct AutomationSetupView: View {

    let key: String

    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("The key is what keeps a shortcut you throw together in a weak moment from unbricking you. Paste it into the automation once.")
                        .foregroundStyle(.secondary)

                    Text(key)
                        .font(.system(.footnote, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))

                    Button {
                        UIPasteboard.general.string = key
                        copied = true
                    } label: {
                        Label(copied ? "Copied" : "Copy key",
                              systemImage: copied ? "checkmark" : "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    steps
                }
                .padding(24)
            }
            .navigationTitle("Band Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("In Shortcuts")
                .font(.headline)

            ForEach(Array(instructions.enumerated()), id: \.offset) { index, line in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("\(index + 1).")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    Text(line)
                }
            }

            Text("This screen disappears once you're bricked, so the key can't be looked up at the moment you'd most want to cheat. It stays readable inside the automation itself, though — this is friction, not a lock.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    private let instructions = [
        "Automation › your Brick automation › edit its actions.",
        "Replace the action with Brick › Toggle Brick.",
        "Paste the key into the action's Key field.",
        "Leave Run Immediately on and Notify When Run off.",
        "Tap the band to test — nothing should open."
    ]
}
