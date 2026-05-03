import SwiftUI

// MARK: - Edit Card Sheet

struct FlashcardEditView: View {
    @Environment(\.dismiss) private var dismiss

    let theme: CreateSetTheme
    let card: Flashcard
    let onSave: (Flashcard) -> Void
    let onDelete: (Flashcard) -> Void

    @State private var word: String
    @State private var translation: String
    @State private var example: String
    @State private var showDeleteAlert = false

    init(theme: CreateSetTheme, card: Flashcard,
         onSave: @escaping (Flashcard) -> Void,
         onDelete: @escaping (Flashcard) -> Void) {
        self.theme = theme
        self.card = card
        self.onSave = onSave
        self.onDelete = onDelete
        _word = State(initialValue: card.word)
        _translation = State(initialValue: card.translation)
        _example = State(initialValue: card.example)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.screenBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        field(title: "Word", text: $word, placeholder: "e.g. Hola")
                        field(title: "Translation", text: $translation, placeholder: "e.g. Hello")
                        field(title: "Example (optional)", text: $example, placeholder: "e.g. Hola, ¿cómo estás?", isMultiline: true)

                        Button {
                            showDeleteAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete card")
                            }
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.fieldBackground)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(theme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(theme.accent.opacity(0.4), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.screenBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(theme.accent)
                        .font(.system(size: 16, weight: .bold))
                }

                ToolbarItem(placement: .principal) {
                    Text("Edit card")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.titleColor)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let updated = Flashcard(
                            id: card.id,
                            word: word.trimmingCharacters(in: .whitespacesAndNewlines),
                            translation: translation.trimmingCharacters(in: .whitespacesAndNewlines),
                            example: example.trimmingCharacters(in: .whitespacesAndNewlines),
                            imageURL: card.imageURL
                        )
                        onSave(updated)
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(theme.accent)
                    .disabled(word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Delete card?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    onDelete(card)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    private func field(title: String, text: Binding<String>, placeholder: String, isMultiline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(theme.titleColor)

            ZStack(alignment: isMultiline ? .topLeading : .leading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(theme.mutedTextColor.opacity(0.5))
                        .padding(.top, isMultiline ? 14 : 0)
                        .padding(.leading, isMultiline ? 14 : 0)
                }

                if isMultiline {
                    TextField("", text: text, axis: .vertical)
                        .foregroundStyle(theme.textColor)
                        .tint(theme.accent)
                        .submitLabel(.done)
                        .padding(14)
                        .frame(minHeight: 90, alignment: .topLeading)
                } else {
                    TextField("", text: text)
                        .foregroundStyle(theme.textColor)
                        .tint(theme.accent)
                        .submitLabel(.next)
                        .autocorrectionDisabled()
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .padding(.horizontal, isMultiline ? 0 : 14)
            .frame(minHeight: isMultiline ? 90 : 50)
            .background(theme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(theme.borderColor, lineWidth: 1)
            )
        }
    }
}

#Preview {
    FlashcardEditView(
        theme: .purple,
        card: Flashcard(
            id: UUID().uuidString,
            word: "Hola",
            translation: "Привіт",
            example: "Hola, ¿cómo estás?",
            imageURL: nil
        ),
        onSave: { _ in },
        onDelete: { _ in }
    )
}
