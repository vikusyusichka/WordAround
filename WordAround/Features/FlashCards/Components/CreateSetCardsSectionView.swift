import SwiftUI

struct CreateSetCardsSectionView: View {
    @ObservedObject var viewModel: CreateSetViewModel

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || UIScreen.main.bounds.width >= 700
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isPadLike ? 18 : 14) {
            HStack(spacing: 6) {
                sectionLabel("Cards in this set")

                Text("(\(viewModel.draft.cards.count))")
                    .font(.system(size: isPadLike ? 16 : 14, weight: .bold))
                    .foregroundStyle(AppColors.createSetTextMuted)
            }

            ForEach($viewModel.draft.cards) { $card in
                cardEditor(card: $card)
            }

            addCardButton
        }
        .padding(isPadLike ? 22 : 14)
        .background(sectionBackground)
    }

    @ViewBuilder
    private func cardEditor(card: Binding<CreateFlashcardDraft>) -> some View {
        if isPadLike {
            HStack(alignment: .top, spacing: 24) {
                VStack(spacing: 16) {
                    cardInput(title: "Word", placeholder: "e.g. Hola", text: card.word)
                    cardInput(title: "Translation", placeholder: "e.g. Hello", text: card.translation)
                }

                imagePickerPlaceholder
            }

            exampleInput(card: card)
        } else {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(spacing: 12) {
                        cardInput(title: "Word", placeholder: "e.g. Hola", text: card.word)
                        cardInput(title: "Translation", placeholder: "e.g. Hello", text: card.translation)
                    }
                    .frame(maxWidth: .infinity)

                    imagePickerPlaceholder
                        .frame(width: 116)
                }

                exampleInput(card: card)
            }
        }
    }

    private func cardInput(
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(title)

            HStack {
                ZStack(alignment: .leading) {
                    if text.wrappedValue.isEmpty {
                        Text(placeholder)
                            .foregroundColor(.gray.opacity(0.75))
                    }

                    TextField("", text: text)
                        .foregroundColor(AppColors.createSetDarkText)
                        .tint(AppColors.createSetRed)
                }

                Image(systemName: "mic.fill")
                    .font(.system(size: isPadLike ? 18 : 15, weight: .bold))
                    .foregroundStyle(AppColors.createSetRed)
            }
            .font(.system(size: isPadLike ? 16 : 14, weight: .semibold))
            .padding(.horizontal, isPadLike ? 18 : 14)
            .frame(height: isPadLike ? 54 : 48)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: isPadLike ? 18 : 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: isPadLike ? 18 : 16, style: .continuous)
                    .stroke(AppColors.createSetBorder, lineWidth: 1)
            )
        }
    }

    private func exampleInput(card: Binding<CreateFlashcardDraft>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                sectionLabel("Example")
                optionalText
            }

            ZStack(alignment: .bottomTrailing) {

                ZStack(alignment: .topLeading) {
                    if card.wrappedValue.example.isEmpty {
                        Text("e.g. Hola, ¿cómo estás?")
                            .foregroundColor(.gray.opacity(0.75))
                            .padding(.top, 12)
                            .padding(.leading, 14)
                    }

                    TextField("", text: card.example, axis: .vertical)
                        .foregroundColor(AppColors.createSetDarkText)
                        .tint(AppColors.createSetRed)
                        .padding(.top, 12)
                        .padding(.horizontal, 14)
                        .frame(maxHeight: .infinity, alignment: .topLeading)
                }
                .frame(height: isPadLike ? 84 : 76)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: isPadLike ? 18 : 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: isPadLike ? 18 : 16, style: .continuous)
                        .stroke(AppColors.createSetBorder, lineWidth: 1)
                )

                Text("\(card.wrappedValue.example.count)/150")
                    .font(.system(size: isPadLike ? 14 : 12, weight: .semibold))
                    .foregroundStyle(AppColors.createSetTextMuted)
                    .padding(.trailing, 14)
                    .padding(.bottom, 10)
            }
        }
    }

    private var imagePickerPlaceholder: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                sectionLabel("Image")
                optionalText
            }

            VStack(spacing: isPadLike ? 12 : 6) {
                Image(systemName: "photo.fill")
                    .font(.system(size: isPadLike ? 42 : 24))
                    .foregroundStyle(AppColors.createSetRed)

                Text("Add image")
                    .font(.system(size: isPadLike ? 17 : 12, weight: .bold))
                    .foregroundStyle(AppColors.createSetDarkText)
                    .lineLimit(1)

                Text(isPadLike ? "Tap to upload or choose from gallery" : "Upload")
                    .font(.system(size: isPadLike ? 14 : 10, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppColors.createSetTextMuted)
                    .lineLimit(isPadLike ? 2 : 1)
            }
            .frame(
                maxWidth: isPadLike ? 220 : .infinity,
                minHeight: isPadLike ? 220 : 126
            )
            .background(AppColors.createSetImageBackground)
            .clipShape(RoundedRectangle(cornerRadius: isPadLike ? 20 : 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: isPadLike ? 20 : 16, style: .continuous)
                    .stroke(
                        AppColors.createSetBorderRed,
                        style: StrokeStyle(lineWidth: 1, dash: [5])
                    )
            )
        }
    }

    private var addCardButton: some View {
        Button {
            viewModel.addCard()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: isPadLike ? 22 : 18, weight: .medium))
                    .foregroundStyle(AppColors.createSetRed)
                    .frame(width: isPadLike ? 48 : 38, height: isPadLike ? 48 : 38)
                    .background(AppColors.createSetSoftRed)
                    .clipShape(Circle())

                Text("Add another card")
                    .font(.system(size: isPadLike ? 17 : 15, weight: .bold))
                    .foregroundStyle(AppColors.createSetRed)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: isPadLike ? 16 : 13, weight: .bold))
            .foregroundStyle(AppColors.createSetDarkRed)
    }

    private var optionalText: some View {
        Text("(optional)")
            .font(.system(size: isPadLike ? 13 : 11, weight: .semibold))
            .foregroundStyle(AppColors.createSetTextMuted)
    }

    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: isPadLike ? 26 : 22, style: .continuous)
            .fill(Color.white.opacity(0.72))
            .overlay(
                RoundedRectangle(cornerRadius: isPadLike ? 26 : 22, style: .continuous)
                    .stroke(AppColors.createSetSoftBorder, lineWidth: 1)
            )
    }
}

#Preview {
    let vm = CreateSetViewModel()

    vm.draft.cards = [
        CreateFlashcardDraft(
            word: "Hola",
            translation: "Hello",
            example: "Hola, ¿cómo estás?"
        ),
        CreateFlashcardDraft(
            word: "Gracias",
            translation: "Thank you",
            example: "Gracias por tu ayuda"
        )
    ]

    return CreateSetCardsSectionView(viewModel: vm)
        .padding()
        .background(AppColors.createSetBackground)
}
