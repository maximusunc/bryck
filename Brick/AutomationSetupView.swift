import SwiftUI
import UIKit

/// Shows the keyed URL to paste into the Shortcuts automation.
///
/// Only reachable while unbricked (or before the automation has proved
/// itself) — if you could read the key mid-brick, it would be no more
/// friction than the button it replaced.
struct AutomationSetupView: View {

    let url: String

    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("The key is what keeps anything else from unbricking you. Without it, typing a URL into Safari would be enough.")
                        .foregroundStyle(.secondary)

                    Text(url)
                        .font(.system(.footnote, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))

                    Button {
                        UIPasteboard.general.string = url
                        copied = true
                    } label: {
                        Label(copied ? "Copied" : "Copy URL",
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

            Text("This screen disappears once you're bricked, so the key can't be looked up at the moment you'd most want to cheat. Keep a copy somewhere if that worries you.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    private let instructions = [
        "Automation › your Brick automation › the Open URLs action.",
        "Replace the URL with the one above.",
        "Leave Run Immediately on and Notify When Run off.",
        "Tap the band to test — the status should flip."
    ]
}
