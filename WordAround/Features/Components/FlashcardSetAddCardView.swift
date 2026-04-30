import SwiftUI
import PhotosUI
import UIKit

struct FlashcardSetAddCardView: View {
    @Environment(\.dismiss) private var dismiss

    let theme: CreateSetTheme
    let onSave: (Flashcard) -> Void

    @State private var draftCards: [DraftFlashcard] = [
        DraftFlashcard()
    ]

    @State private var showValidation = false

    private var isSaveDisabled: Bool {
        draftCards.contains { card in
            card.word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            card.translation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var body: some View {
        ZStack {
            theme.screenBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Layout.createSetCardsSectionSpacing) {
                        ForEach($draftCards) { $card in
                            cardBlock(card: $card)
                        }

                        if showValidation && isSaveDisabled {
                            Text("Word and translation are required for every card.")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(theme.accent)
                                .padding(.top, 2)
                        }

                        addAnotherCardButton
                    }
                    .padding(Layout.createSetCardsSectionPadding)
                    .background(sectionBackground)
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 28)
                }
            }
        }
    }

    private var topBar: some View {
        ZStack {
            Text("Add card")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(theme.titleColor)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(theme.accent)
                        .frame(width: 44, height: 44)
                        .background(theme.sectionBackground)
                        .clipShape(Circle())
                        .overlay(
                            Capsule()
                                .stroke(theme.accent.opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: theme.shadowColor.opacity(0.5), radius: 8, x: 0, y: 5)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    saveCards()
                } label: {
                    Text("Save")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.accent)
                        .padding(.horizontal, 18)
                        .frame(height: 44)
                        .background(theme.sectionBackground)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(theme.accent.opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: theme.shadowColor.opacity(0.5), radius: 8, x: 0, y: 5)
                }
                .buttonStyle(.plain)
                .disabled(isSaveDisabled)
                .opacity(isSaveDisabled ? 0.45 : 1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func cardBlock(card: Binding<DraftFlashcard>) -> some View {
        VStack(alignment: .leading, spacing: Layout.createSetCardsSectionSpacing) {
            if draftCards.count > 1 {
                HStack {
                    Text("Card \(cardNumber(for: card.wrappedValue))")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.titleColor)

                    Spacer()

                    Button {
                        removeCard(card.wrappedValue)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(theme.accent)
                            .frame(width: 34, height: 34)
                            .background(theme.softAccent)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }

            if Layout.isPadLike {
                HStack(alignment: .top, spacing: Layout.createSetCardsEditorPadSpacing) {
                    VStack(spacing: Layout.createSetCardsInputStackSpacing) {
                        cardInput(
                            title: "Word",
                            placeholder: "e.g. Hola",
                            text: card.word,
                            submitLabel: .next
                        )

                        cardInput(
                            title: "Translation",
                            placeholder: "e.g. Hello",
                            text: card.translation,
                            submitLabel: .next
                        )
                    }

                    imagePicker(card: card)
                }

                exampleInput(text: card.example)
            } else {
                VStack(alignment: .leading, spacing: Layout.createSetCardsEditorPhoneSpacing) {
                    HStack(alignment: .top, spacing: Layout.createSetCardsPhoneInputImageSpacing) {
                        VStack(spacing: Layout.createSetCardsInputStackSpacing) {
                            cardInput(
                                title: "Word",
                                placeholder: "e.g. Hola",
                                text: card.word,
                                submitLabel: .next
                            )

                            cardInput(
                                title: "Translation",
                                placeholder: "e.g. Hello",
                                text: card.translation,
                                submitLabel: .next
                            )
                        }
                        .frame(maxWidth: .infinity)

                        imagePicker(card: card)
                            .frame(width: Layout.createSetCardsImagePhoneWidth)
                    }

                    exampleInput(text: card.example)
                }
            }
        }
        .padding(.top, draftCards.count > 1 ? 10 : 0)
    }

    private func cardInput(
        title: String,
        placeholder: String,
        text: Binding<String>,
        submitLabel: SubmitLabel = .done
    ) -> some View {
        VStack(alignment: .leading, spacing: Layout.createSetCardsFieldSpacing) {
            sectionLabel(title)

            HStack {
                ZStack(alignment: .leading) {
                    if text.wrappedValue.isEmpty {
                        Text(placeholder)
                            .foregroundColor(theme.mutedTextColor.opacity(0.55))
                    }

                    TextField("", text: text)
                        .foregroundColor(theme.textColor)
                        .tint(theme.accent)
                        .submitLabel(submitLabel)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Image(systemName: "mic.fill")
                    .font(.system(size: Layout.createSetCardsMicIconSize, weight: .bold))
                    .foregroundStyle(theme.accent)
            }
            .font(.system(size: Layout.createSetCardsFieldFontSize, weight: .semibold))
            .padding(.horizontal, Layout.createSetCardsFieldHorizontalPadding)
            .frame(height: Layout.createSetCardsFieldHeight)
            .background(theme.fieldBackground)
            .clipShape(
                RoundedRectangle(cornerRadius: Layout.createSetCardsFieldCornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Layout.createSetCardsFieldCornerRadius, style: .continuous)
                    .stroke(theme.borderColor, lineWidth: 1)
            )
        }
    }

    private func imagePicker(card: Binding<DraftFlashcard>) -> some View {
        VStack(alignment: .leading, spacing: Layout.createSetCardsFieldSpacing) {
            HStack(spacing: 4) {
                sectionLabel("Image")
                optionalText
            }

            PhotosPicker(
                selection: Binding<PhotosPickerItem?>(
                    get: { card.wrappedValue.selectedImageItem },
                    set: { item in
                        card.wrappedValue.selectedImageItem = item
                        guard let item else { return }

                        Task {
                            if let data = try? await item.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                await MainActor.run {
                                    card.wrappedValue.selectedImage = image
                                }
                            }
                        }
                    }
                ),
                matching: .images
            ) {
                VStack(spacing: Layout.createSetCardsImageContentSpacing) {
                    if let image = card.wrappedValue.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(
                                maxWidth: Layout.createSetCardsImageMaxWidth,
                                minHeight: Layout.createSetCardsImageMinHeight
                            )
                            .clipped()
                    } else {
                        Image(systemName: "photo.fill")
                            .font(.system(size: Layout.createSetCardsImageIconSize))
                            .foregroundStyle(theme.accent)

                        Text("Add image")
                            .font(.system(size: Layout.createSetCardsImageTitleSize, weight: .bold))
                            .foregroundStyle(theme.textColor)
                            .lineLimit(1)

                        Text(Layout.isPadLike ? "Tap to upload or choose from gallery" : "Upload")
                            .font(.system(size: Layout.createSetCardsImageSubtitleSize, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(theme.mutedTextColor)
                            .lineLimit(Layout.createSetCardsImageLineLimit)
                    }
                }
                .frame(
                    maxWidth: Layout.createSetCardsImageMaxWidth,
                    minHeight: Layout.createSetCardsImageMinHeight
                )
                .background(theme.imageBackground)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: Layout.createSetCardsImageCornerRadius,
                        style: .continuous
                    )
                )
                .overlay(
                    RoundedRectangle(
                        cornerRadius: Layout.createSetCardsImageCornerRadius,
                        style: .continuous
                    )
                    .stroke(
                        theme.accent.opacity(0.45),
                        style: StrokeStyle(lineWidth: 1, dash: [5])
                    )
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func exampleInput(text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: Layout.createSetCardsFieldSpacing) {
            HStack(spacing: 4) {
                sectionLabel("Example")
                optionalText
            }

            ZStack(alignment: .bottomTrailing) {
                ZStack(alignment: .topLeading) {
                    if text.wrappedValue.isEmpty {
                        Text("e.g. Hola, ¿cómo estás?")
                            .foregroundColor(theme.mutedTextColor.opacity(0.55))
                            .padding(.top, 12)
                            .padding(.leading, 14)
                    }

                    TextField("", text: text, axis: .vertical)
                        .foregroundColor(theme.textColor)
                        .tint(theme.accent)
                        .submitLabel(.done)
                        .padding(.top, 12)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 26)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .frame(minHeight: Layout.createSetCardsExampleMinHeight, alignment: .topLeading)
                .background(theme.fieldBackground)
                .clipShape(
                    RoundedRectangle(cornerRadius: Layout.createSetCardsFieldCornerRadius, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.createSetCardsFieldCornerRadius, style: .continuous)
                        .stroke(theme.borderColor, lineWidth: 1)
                )

                Text("\(text.wrappedValue.count)/150")
                    .font(.system(size: Layout.createSetCardsCounterSize, weight: .semibold))
                    .foregroundStyle(text.wrappedValue.count > 150 ? Color.red : theme.mutedTextColor)
                    .padding(.trailing, 14)
                    .padding(.bottom, 10)
            }
        }
    }

    private var addAnotherCardButton: some View {
        Button {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )

            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                draftCards.append(DraftFlashcard())
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: Layout.createSetAddCardIconSize, weight: .medium))
                    .foregroundStyle(theme.accent)
                    .frame(
                        width: Layout.createSetAddCardIconFrame,
                        height: Layout.createSetAddCardIconFrame
                    )
                    .background(theme.softAccent)
                    .clipShape(Circle())
            }
            .frame(maxWidth: .infinity)
            .frame(height: Layout.flashcardDetailAddButtonHeight)
            .background(theme.fieldBackground)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Layout.flashcardDetailAddButtonCornerRadius,
                    style: .continuous
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: Layout.flashcardDetailAddButtonCornerRadius,
                    style: .continuous
                )
                .stroke(theme.borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }

    private var optionalText: some View {
        Text("(optional)")
            .font(.system(size: Layout.createSetCardsOptionalTextSize, weight: .semibold))
            .foregroundStyle(theme.mutedTextColor)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: Layout.createSetSectionLabelSize, weight: .bold))
            .foregroundStyle(theme.titleColor)
    }

    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: Layout.createSetCardsSectionCornerRadius, style: .continuous)
            .fill(theme.sectionBackground)
            .overlay(
                RoundedRectangle(cornerRadius: Layout.createSetCardsSectionCornerRadius, style: .continuous)
                    .stroke(theme.softBorderColor, lineWidth: 1)
            )
    }

    private func cardNumber(for card: DraftFlashcard) -> Int {
        guard let index = draftCards.firstIndex(where: { $0.id == card.id }) else {
            return 1
        }

        return index + 1
    }

    private func removeCard(_ card: DraftFlashcard) {
        guard draftCards.count > 1 else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            draftCards.removeAll { $0.id == card.id }
        }
    }

    private func saveCards() {
        guard !isSaveDisabled else {
            showValidation = true
            return
        }

        draftCards.forEach { draft in
            let newCard = Flashcard(
                id: UUID().uuidString,
                word: draft.word.trimmingCharacters(in: .whitespacesAndNewlines),
                translation: draft.translation.trimmingCharacters(in: .whitespacesAndNewlines),
                example: draft.example.trimmingCharacters(in: .whitespacesAndNewlines),
                imageURL: nil
            )

            onSave(newCard)
        }

        dismiss()
    }
}

private struct DraftFlashcard: Identifiable {
    let id = UUID()
    var word = ""
    var translation = ""
    var example = ""
    var selectedImage: UIImage?
    var selectedImageItem: PhotosPickerItem?
}

#Preview {
    FlashcardSetAddCardView(
        theme: .purple,
        onSave: { _ in }
    )
}
