import SwiftUI

struct FlashcardSetDetailCardRowView: View, Equatable {
    let theme: CreateSetTheme
    let card: Flashcard
    let index: Int
    let isMastered: Bool
    let onToggleMastered: () -> Void
    let onSpeak: () -> Void
    let onEdit: () -> Void

    static func == (lhs: FlashcardSetDetailCardRowView, rhs: FlashcardSetDetailCardRowView) -> Bool {
        lhs.card.id == rhs.card.id &&
        lhs.card.word == rhs.card.word &&
        lhs.card.translation == rhs.card.translation &&
        lhs.card.example == rhs.card.example &&
        lhs.card.imageURL == rhs.card.imageURL &&
        lhs.index == rhs.index &&
        lhs.isMastered == rhs.isMastered
    }

    var body: some View {
        VStack(spacing: 0) {
            mainRow
            if !card.example.isEmpty { exampleRow }
        }
    }

    private var mainRow: some View {
        HStack(alignment: .center, spacing: Layout.flashcardDetailRowSpacing) {
            Text("\(index)")
                .font(.system(size: Layout.flashcardDetailRowIndexSize, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.mutedTextColor)
                .frame(width: Layout.flashcardDetailRowIndexWidth)
            smallDivider
            HStack(spacing: 10) { cardImage; cardText }
            Spacer(minLength: 8)
            smallDivider.padding(.leading, Layout.flashcardDetailRowRightDividerLeadingPadding)
            actionButtons
        }
        .padding(.horizontal, Layout.flashcardDetailRowHorizontalPadding)
        .padding(.vertical, Layout.flashcardDetailRowVerticalPadding)
    }

    private var cardText: some View {
        VStack(alignment: .leading, spacing: Layout.flashcardDetailRowTextSpacing) {
            Text(card.word)
                .font(.system(size: Layout.flashcardDetailRowWordSize, weight: .bold, design: .rounded))
                .foregroundStyle(theme.titleColor).lineLimit(1).minimumScaleFactor(0.75)
            Text(card.translation)
                .font(.system(size: Layout.flashcardDetailRowTranslationSize, weight: .medium, design: .rounded))
                .foregroundStyle(theme.mutedTextColor).lineLimit(1).minimumScaleFactor(0.75)
        }
    }

    private var exampleRow: some View {
        Text("Example: \(card.example)")
            .font(.system(size: Layout.flashcardDetailRowExampleSize, weight: .medium, design: .rounded))
            .foregroundStyle(theme.accent.opacity(0.8)).lineLimit(2).minimumScaleFactor(0.75)
            .padding(.vertical, 8).padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(theme.softAccent))
            .padding(.horizontal, Layout.flashcardDetailRowHorizontalPadding).padding(.bottom, 8)
    }

    private var smallDivider: some View {
        Rectangle().fill(theme.borderColor.opacity(0.4)).frame(width: 1, height: 42)
    }

    private var actionButtons: some View {
        HStack(spacing: Layout.flashcardDetailRowIconSpacing) {
            Button(action: onToggleMastered) {
                Image(systemName: isMastered ? "heart.fill" : "heart")
                    .foregroundStyle(isMastered ? theme.accent : theme.mutedTextColor)
            }
            Button(action: onSpeak) { Image(systemName: "speaker.wave.2") }
            Button(action: onEdit) { Image(systemName: "pencil") }
        }
        .buttonStyle(.plain)
        .font(.system(size: Layout.flashcardDetailRowIconSize, weight: .semibold))
        .foregroundStyle(theme.mutedTextColor)
    }

    private var cardImage: some View {
        Group {
            if let imageURL = card.imageURL, !imageURL.isEmpty {
                if imageURL.hasPrefix("http") {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        if case .success(let image) = phase { image.resizable().scaledToFill() }
                        else { imagePlaceholder }
                    }
                } else {
                    if let uiImage = LocalImageStorageService().loadImage(fileName: imageURL) {
                        Image(uiImage: uiImage).resizable().scaledToFill()
                    } else { imagePlaceholder }
                }
            } else { imagePlaceholder }
        }
        .frame(width: Layout.flashcardDetailRowImageSize, height: Layout.flashcardDetailRowImageSize)
        .clipShape(RoundedRectangle(cornerRadius: Layout.flashcardDetailRowImageCornerRadius, style: .continuous))
    }

    private var imagePlaceholder: some View {
        ZStack {
            LinearGradient(colors: [theme.fieldBackground.opacity(0.9), theme.softAccent],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: "hand.wave.fill")
                .font(.system(size: Layout.flashcardDetailRowPlaceholderIconSize, weight: .semibold))
                .foregroundStyle(theme.accent.opacity(0.55))
        }
    }
}
