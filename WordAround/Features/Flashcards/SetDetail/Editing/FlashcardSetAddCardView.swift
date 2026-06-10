import SwiftUI

struct FlashcardSetAddCardView: View {
    let theme: CreateSetTheme
    let onSave: (Flashcard) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var word = ""
    @State private var translation = ""
    @State private var example = ""

    var body: some View {
        NavigationStack {
            ZStack {
                theme.screenBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        field(L10n.string("commonWord"), text: $word)
                        field(L10n.string("commonTranslation"), text: $translation)
                        field(L10n.string("flashcardExampleOptional"), text: $example, axis: .vertical)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 22)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle(L10n.string("flashcardAddCardTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string("commonCancel")) { dismiss() }
                        .foregroundStyle(theme.mutedTextColor)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.string("commonSave")) {
                        let card = Flashcard(
                            id: UUID().uuidString,
                            word: word.trimmingCharacters(in: .whitespacesAndNewlines),
                            translation: translation.trimmingCharacters(in: .whitespacesAndNewlines),
                            example: example.trimmingCharacters(in: .whitespacesAndNewlines),
                            imageURL: nil
                        )
                        onSave(card)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.accent)
                    .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        !word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func field(_ title: String, text: Binding<String>, axis: Axis = .horizontal) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.mutedTextColor)

            TextField(title, text: text, axis: axis)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(theme.titleColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(theme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(theme.borderColor.opacity(0.35), lineWidth: 1)
                }
        }
    }
}

#Preview {
    FlashcardSetAddCardView(theme: .purple, onSave: { _ in })
}
