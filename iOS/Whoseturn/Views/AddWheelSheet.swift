import SwiftUI

struct AddWheelSheet: View {
    @EnvironmentObject private var store: WhoseturnStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                WTColor.cream.ignoresSafeArea()
                VStack(spacing: 20) {
                    TextField("Wheel name, e.g. Dishes", text: $name)
                        .focused($nameFieldFocused)
                        .font(WTFont.body(17))
                        .padding()
                        .background(WTColor.sand, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .submitLabel(.done)
                        .onSubmit { nameFieldFocused = false }

                    Button("Create Wheel") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        store.addWheel(name: trimmed)
                        dismiss()
                    }
                    .buttonStyle(WTButtonStyle(background: WTColor.marigold))
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Spacer()
                }
                .padding()
            }
            // Real tap-outside-to-dismiss-keyboard: a full-size background beneath the form
            // content that resigns first responder on tap, independent of scroll-based dismissal.
            .dismissesKeyboardOnTap()
            .navigationTitle("New Wheel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
