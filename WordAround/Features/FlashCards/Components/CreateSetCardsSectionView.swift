import SwiftUI
import PhotosUI

struct CreateSetCardsSectionView: View {
    @ObservedObject var viewModel: CreateSetViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.createSetCardsSectionSpacing) {
            HStack(spacing: 6) {
                sectionLabel("Cards in this set")

                Text("(\(viewModel.draft.cards.count))")
                    .font(.system(size: Layout.createSetCardsTitleSize, weight: .bold))
                    .foregroundStyle(viewModel.theme.mutedTextColor)
            }

            ForEach($viewModel.draft.cards) { $card in
                cardEditor(card: $card)
            }

            addCardButton
        }
        .padding(Layout.createSetCardsSectionPadding)
        .background(sectionBackground)
    }

    @ViewBuilder
    private func cardEditor(card: Binding<CreateFlashcardDraft>) -> some View {
        if Layout.isPadLike {
            HStack(alignment: .top, spacing: Layout.createSetCardsEditorPadSpacing) {
                VStack(spacing: Layout.createSetCardsInputStackSpacing) {
                    cardInput(title: "Word", placeholder: "e.g. Hola", text: card.word, submitLabel: .next)
                    cardInput(title: "Translation", placeholder: "e.g. Hello", text: card.translation, submitLabel: .next)
                }
                imagePicker(card: card)
            }
            exampleInput(card: card)
        } else {
            VStack(alignment: .leading, spacing: Layout.createSetCardsEditorPhoneSpacing) {
                HStack(alignment: .top, spacing: Layout.createSetCardsPhoneInputImageSpacing) {
                    VStack(spacing: Layout.createSetCardsInputStackSpacing) {
                        cardInput(title: "Word", placeholder: "e.g. Hola", text: card.word, submitLabel: .next)
                        cardInput(title: "Translation", placeholder: "e.g. Hello", text: card.translation, submitLabel: .next)
                    }
                    .frame(maxWidth: .infinity)

                    imagePicker(card: card)
                        .frame(width: Layout.createSetCardsImagePhoneWidth)
                }
                exampleInput(card: card)
            }
        }
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
                            .foregroundColor(viewModel.theme.mutedTextColor.opacity(0.55))
                    }

                    TextField("", text: text)
                        .foregroundColor(viewModel.theme.textColor)
                        .tint(viewModel.theme.accent)
                        // Фікс: правильний тип клавіатури і кнопка переходу
                        .submitLabel(submitLabel)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Image(systemName: "mic.fill")
                    .font(.system(size: Layout.createSetCardsMicIconSize, weight: .bold))
                    .foregroundStyle(viewModel.theme.accent)
            }
            .font(.system(size: Layout.createSetCardsFieldFontSize, weight: .semibold))
            .padding(.horizontal, Layout.createSetCardsFieldHorizontalPadding)
            .frame(height: Layout.createSetCardsFieldHeight)
            .background(viewModel.theme.fieldBackground)
            .clipShape(
                RoundedRectangle(cornerRadius: Layout.createSetCardsFieldCornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Layout.createSetCardsFieldCornerRadius, style: .continuous)
                    .stroke(viewModel.theme.borderColor, lineWidth: 1)
            )
        }
    }

    private func exampleInput(card: Binding<CreateFlashcardDraft>) -> some View {
        VStack(alignment: .leading, spacing: Layout.createSetCardsFieldSpacing) {
            HStack(spacing: 4) {
                sectionLabel("Example")
                optionalText
            }

            ZStack(alignment: .bottomTrailing) {
                ZStack(alignment: .topLeading) {
                    if card.wrappedValue.example.isEmpty {
                        Text("e.g. Hola, ¿cómo estás?")
                            .foregroundColor(viewModel.theme.mutedTextColor.opacity(0.55))
                            .padding(.top, 12)
                            .padding(.leading, 14)
                    }

                    TextField("", text: card.example, axis: .vertical)
                        .foregroundColor(viewModel.theme.textColor)
                        .tint(viewModel.theme.accent)
                        .submitLabel(.done)
                        .padding(.top, 12)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 26)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .frame(minHeight: Layout.createSetCardsExampleMinHeight, alignment: .topLeading)
                .background(viewModel.theme.fieldBackground)
                .clipShape(
                    RoundedRectangle(cornerRadius: Layout.createSetCardsFieldCornerRadius, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.createSetCardsFieldCornerRadius, style: .continuous)
                        .stroke(viewModel.theme.borderColor, lineWidth: 1)
                )

                Text("\(card.wrappedValue.example.count)/150")
                    .font(.system(size: Layout.createSetCardsCounterSize, weight: .semibold))
                    .foregroundStyle(
                        card.wrappedValue.example.count > 150 ? Color.red : viewModel.theme.mutedTextColor
                    )
                    .padding(.trailing, 14)
                    .padding(.bottom, 10)
            }
        }
    }

    private func imagePicker(card: Binding<CreateFlashcardDraft>) -> some View {
        VStack(alignment: .leading, spacing: Layout.createSetCardsFieldSpacing) {
            HStack(spacing: 4) {
                sectionLabel("Image")
                optionalText
            }

            PhotosPicker(
                selection: Binding<PhotosPickerItem?>(
                    get: { nil },
                    set: { item in
                        guard let item else { return }
                        Task {
                            await viewModel.setImage(for: card.wrappedValue.id, from: item)
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
                            .foregroundStyle(viewModel.theme.accent)

                        Text("Add image")
                            .font(.system(size: Layout.createSetCardsImageTitleSize, weight: .bold))
                            .foregroundStyle(viewModel.theme.textColor)
                            .lineLimit(1)

                        Text(Layout.isPadLike ? "Tap to upload or choose from gallery" : "Upload")
                            .font(.system(size: Layout.createSetCardsImageSubtitleSize, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(viewModel.theme.mutedTextColor)
                            .lineLimit(Layout.createSetCardsImageLineLimit)
                    }
                }
                .frame(maxWidth: Layout.createSetCardsImageMaxWidth, minHeight: Layout.createSetCardsImageMinHeight)
                .background(viewModel.theme.imageBackground)
                .clipShape(RoundedRectangle(cornerRadius: Layout.createSetCardsImageCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.createSetCardsImageCornerRadius, style: .continuous)
                        .stroke(viewModel.theme.accent.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [5]))
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var addCardButton: some View {
        Button {
            // Закриваємо клавіатуру перед додаванням нової картки
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                            to: nil, from: nil, for: nil)
            viewModel.addCard()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: Layout.createSetAddCardIconSize, weight: .medium))
                    .foregroundStyle(viewModel.theme.accent)
                    .frame(width: Layout.createSetAddCardIconFrame, height: Layout.createSetAddCardIconFrame)
                    .background(viewModel.theme.softAccent)
                    .clipShape(Circle())

                Text("Add another card")
                    .font(.system(size: Layout.createSetAddCardTextSize, weight: .bold))
                    .foregroundStyle(viewModel.theme.accent)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: Layout.createSetSectionLabelSize, weight: .bold))
            .foregroundStyle(viewModel.theme.titleColor)
    }

    private var optionalText: some View {
        Text("(optional)")
            .font(.system(size: Layout.createSetCardsOptionalTextSize, weight: .semibold))
            .foregroundStyle(viewModel.theme.mutedTextColor)
    }

    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: Layout.createSetCardsSectionCornerRadius, style: .continuous)
            .fill(viewModel.theme.sectionBackground)
            .overlay(
                RoundedRectangle(cornerRadius: Layout.createSetCardsSectionCornerRadius, style: .continuous)
                    .stroke(viewModel.theme.softBorderColor, lineWidth: 1)
            )
    }
}

#Preview {
    let vm: CreateSetViewModel = {
        let vm = CreateSetViewModel()
        vm.selectColor(.blue)
        vm.draft.cards = [
            CreateFlashcardDraft(word: "Hola", translation: "Hello", example: "Hola, ¿cómo estás?"),
            CreateFlashcardDraft(word: "Gracias", translation: "Thank you", example: "Gracias por tu ayuda")
        ]
        return vm
    }()

    CreateSetCardsSectionView(viewModel: vm)
        .padding()
        .background(vm.theme.screenBackground)
}
