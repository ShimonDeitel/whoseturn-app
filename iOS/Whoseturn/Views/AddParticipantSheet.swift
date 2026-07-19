import SwiftUI

struct AddParticipantSheet: View {
    let wheelID: UUID
    @EnvironmentObject private var store: WhoseturnStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @FocusState private var nameFieldFocused: Bool

    private var wheel: Wheel? {
        store.data.wheels.first { $0.id == wheelID }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                WTColor.cream.ignoresSafeArea()
                VStack(spacing: 20) {
                    TextField("Participant name", text: $name)
                        .focused($nameFieldFocused)
                        .font(WTFont.body(17))
                        .padding()
                        .background(WTColor.sand, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .submitLabel(.done)
                        .onSubmit { nameFieldFocused = false }

                    Button("Add Participant") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty, let wheel else { return }
                        store.addParticipant(name: trimmed, to: wheel)
                        dismiss()
                    }
                    .buttonStyle(WTButtonStyle(background: WTColor.sage))
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Spacer()
                }
                .padding()
            }
            .dismissesKeyboardOnTap()
            .navigationTitle("Add Participant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
