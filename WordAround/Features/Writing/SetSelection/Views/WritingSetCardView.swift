import SwiftUI

struct WritingSetCardView: View {
    let item: WritingSetSelectionItem

    private var theme: CreateSetTheme {
        item.theme
    }

    var body: some View {
        HStack(spacing: Layout.setItemContentSpacing) {
            iconView

            VStack(alignment: .leading, spacing: Layout.setItemTextStackSpacing) {
                Text(item.title)
                    .font(.system(size: Layout.setItemTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(theme.titleColor)
                    .lineLimit(1)

                Text(item.subtitle)
                    .font(.system(size: Layout.setItemSubtitleSize, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.mutedTextColor)
                    .lineLimit(1)
            }

            Spacer(minLength: Layout.setItemContentSpacing)

            HStack(spacing: 6) {
                Text("Review")
                    .font(.system(size: Layout.setItemTrailingTextSize, weight: .bold, design: .rounded))
                    .foregroundColor(theme.accent.opacity(0.78))

                Image(systemName: "chevron.right")
                    .font(.system(size: Layout.setItemArrowSize, weight: .bold))
                    .foregroundColor(theme.accent.opacity(0.78))
            }
            .padding(.trailing, Layout.setItemHorizontalPadding)
        }
        .padding(.leading, Layout.setItemHorizontalPadding)
        .padding(.vertical, Layout.setItemVerticalPadding)
        .frame(maxWidth: .infinity, minHeight: Layout.setItemHeight, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Layout.setItemCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.setItemCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.72), lineWidth: 1)
        )
        .shadow(color: theme.shadowColor.opacity(0.68), radius: 18, x: 0, y: 10)
    }

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(theme.accent)
                .frame(width: Layout.setItemIconCircleSize, height: Layout.setItemIconCircleSize)

            Image(systemName: item.iconSystemName)
                .font(.system(size: Layout.setItemIconSize, weight: .bold))
                .foregroundColor(.white)
        }
    }

    private var cardBackground: some View {
        ZStack(alignment: .trailing) {
            theme.sectionBackground

            BlobShape()
                .fill(theme.softAccent.opacity(0.78))
                .frame(width: Layout.setItemBlobSize.width, height: Layout.setItemBlobSize.height)
                .offset(x: Layout.setItemBlobOffset.width, y: Layout.setItemBlobOffset.height)
        }
    }
}

#Preview {
    let set = FlashcardSet(
        id: UUID().uuidString,
        ownerUID: "preview-user",
        ownerEmail: "vika@example.com",
        title: "Spanish A1",
        description: "Basic daily words",
        privacy: "private",
        folderName: nil,
        colorHex: SetColor.purple.hex,
        icon: .systemName("star.fill"),
        cards: [
            Flashcard(id: UUID().uuidString, word: "manzana", translation: "яблуко", example: "apple", imageURL: nil)
        ],
        createdAt: Date(),
        updatedAt: Date()
    )

    WritingSetCardView(
        item: WritingSetSelectionItem(
            id: set.id,
            sourceSet: set,
            title: set.title,
            subtitle: "Basic daily words",
            wordsCountText: "1 words",
            iconSystemName: "star.fill",
            theme: .purple
        )
    )
    .padding()
    .background(AppColors.appBackground)
}
