import SwiftUI

struct FlashcardSetDetailCardRowView: View {
    let theme: CreateSetTheme
    let card: Flashcard
    let index: Int
    let isMastered: Bool
    let onToggleMastered: () -> Void
    let onSpeak: () -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            mainRow

            if !card.example.isEmpty {
                exampleRow
            }
        }
    }

    private var mainRow: some View {
        HStack(alignment: .center, spacing: Layout.flashcardDetailRowSpacing) {
            Text("\(index)")
                .font(.system(size: Layout.flashcardDetailRowIndexSize, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.mutedTextColor)
                .frame(width: Layout.flashcardDetailRowIndexWidth)

            smallDivider

            HStack(spacing: 10) {
                cardImage
                cardText
            }

            Spacer(minLength: 8)

            smallDivider
                .padding(.leading, Layout.flashcardDetailRowRightDividerLeadingPadding)

            actionButtons
        }
        .padding(.horizontal, Layout.flashcardDetailRowHorizontalPadding)
        .padding(.vertical, Layout.flashcardDetailRowVerticalPadding)
    }

    private var cardText: some View {
        VStack(alignment: .leading, spacing: Layout.flashcardDetailRowTextSpacing) {
            Text(card.word)
                .font(.system(size: Layout.flashcardDetailRowWordSize, weight: .bold, design: .rounded))
                .foregroundStyle(theme.titleColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(card.translation)
                .font(.system(size: Layout.flashcardDetailRowTranslationSize, weight: .medium, design: .rounded))
                .foregroundStyle(theme.mutedTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    private var exampleRow: some View {
        Text("Example: \(card.example)")
            .font(.system(size: Layout.flashcardDetailRowExampleSize, weight: .medium, design: .rounded))
            .foregroundStyle(theme.accent.opacity(0.8))
            .lineLimit(2)
            .minimumScaleFactor(0.75)
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.softAccent)
            )
            .padding(.horizontal, Layout.flashcardDetailRowHorizontalPadding)
            .padding(.bottom, 8)
    }

    private var smallDivider: some View {
        Rectangle()
            .fill(theme.borderColor.opacity(0.4))
            .frame(width: 1, height: 42)
    }

    private var actionButtons: some View {
        HStack(spacing: Layout.flashcardDetailRowIconSpacing) {
            Button(action: onToggleMastered) {
                Image(systemName: isMastered ? "heart.fill" : "heart")
            }

            Button(action: onSpeak) {
                Image(systemName: "speaker.wave.2")
            }

            Button(action: onEdit) {
                Image(systemName: "pencil")
            }
        }
        .buttonStyle(.plain)
        .font(.system(size: Layout.flashcardDetailRowIconSize, weight: .semibold))
        .foregroundStyle(theme.mutedTextColor)
    }

    private var cardImage: some View {
        Group {
            if let imageURL = card.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        imagePlaceholder
                    }
                }
            } else {
                imagePlaceholder
            }
        }
        .frame(width: Layout.flashcardDetailRowImageSize, height: Layout.flashcardDetailRowImageSize)
        .clipShape(
            RoundedRectangle(
                cornerRadius: Layout.flashcardDetailRowImageCornerRadius,
                style: .continuous
            )
        )
    }

    private var imagePlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [
                    theme.fieldBackground.opacity(0.9),
                    theme.softAccent
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "hand.wave.fill")
                .font(.system(size: Layout.flashcardDetailRowPlaceholderIconSize, weight: .semibold))
                .foregroundStyle(theme.accent.opacity(0.55))
        }
    }
}

#Preview {
    ZStack {
        CreateSetTheme.yellow.screenBackground
            .ignoresSafeArea()

        FlashcardSetDetailCardRowView(
            theme: .yellow,
            card: Flashcard(
                id: UUID().uuidString,
                word: "Hola",
                translation: "Hello",
                example: "Hola, ¿cómo estás?",
                imageURL: nil
            ),
            index: 1,
            isMastered: false,
            onToggleMastered: {},
            onSpeak: {},
            onEdit: {}
        )
        .background(CreateSetTheme.yellow.sectionBackground)
        .clipShape(
            RoundedRectangle(
                cornerRadius: Layout.flashcardDetailListCornerRadius,
                style: .continuous
            )
        )
        .padding(.horizontal, 10)
    }
}
