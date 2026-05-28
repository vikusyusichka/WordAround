import SwiftUI

struct WritingSetCardView: View {
    let item: WritingSetSelectionItem
    let metrics: ScreenMetrics

    private var accent: Color {
        Self.color(from: item.sourceSet.colorHex)
    }

    private var softAccent: Color {
        accent.opacity(0.12)
    }

    init(item: WritingSetSelectionItem, metrics: ScreenMetrics? = nil) {
        self.item = item
        self.metrics = metrics ?? ScreenMetrics.current(horizontal: nil, vertical: nil, containerWidth: 0)
    }

    var body: some View {
        HStack(spacing: LayoutConstants.WritingSetSelection.rowContentSpacing(metrics)) {
            iconView

            VStack(alignment: .leading, spacing: 5) {
                Text(item.title)
                    .font(.system(
                        size: LayoutConstants.WritingSetSelection.titleTextSize(metrics),
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundColor(accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(wordsText)
                    .font(.system(
                        size: LayoutConstants.WritingSetSelection.subtitleTextSize(metrics),
                        weight: .semibold,
                        design: .rounded
                    ))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: LayoutConstants.WritingSetSelection.rowContentSpacing(metrics))

            HStack(spacing: 6) {
                Text("Review")
                    .font(.system(
                        size: LayoutConstants.WritingSetSelection.reviewTextSize(metrics),
                        weight: .bold,
                        design: .rounded
                    ))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Image(systemName: "chevron.right")
                    .font(.system(
                        size: LayoutConstants.WritingSetSelection.reviewArrowSize(metrics),
                        weight: .bold
                    ))
            }
            .foregroundColor(accent)
            .padding(.horizontal, LayoutConstants.WritingSetSelection.reviewHorizontalPadding(metrics))
            .padding(.vertical, LayoutConstants.WritingSetSelection.reviewVerticalPadding(metrics))
            .background(
                Capsule()
                    .fill(softAccent)
            )
        }
        .padding(.horizontal, LayoutConstants.WritingSetSelection.rowHorizontalPadding(metrics))
        .padding(.vertical, LayoutConstants.WritingSetSelection.rowVerticalPadding(metrics))
        .frame(
            maxWidth: .infinity,
            minHeight: LayoutConstants.WritingSetSelection.rowHeight(metrics),
            alignment: .leading
        )
        .background(cardBackground)
        .clipShape(
            RoundedRectangle(
                cornerRadius: LayoutConstants.WritingSetSelection.rowCornerRadius(metrics),
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: LayoutConstants.WritingSetSelection.rowCornerRadius(metrics),
                style: .continuous
            )
            .stroke(Color.white.opacity(0.74), lineWidth: 1)
        )
        .shadow(color: accent.opacity(0.09), radius: 16, x: 0, y: 9)
    }

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(accent)
                .frame(
                    width: LayoutConstants.WritingSetSelection.iconCircleSize(metrics),
                    height: LayoutConstants.WritingSetSelection.iconCircleSize(metrics)
                )

            Image(systemName: item.iconSystemName)
                .font(.system(
                    size: LayoutConstants.WritingSetSelection.iconSize(metrics),
                    weight: .bold
                ))
                .foregroundColor(.white)
        }
    }

    private var cardBackground: some View {
        ZStack(alignment: .trailing) {
            Color.white.opacity(0.90)

            BlobShape()
                .fill(softAccent)
                .frame(
                    width: LayoutConstants.WritingSetSelection.blobSize(metrics).width,
                    height: LayoutConstants.WritingSetSelection.blobSize(metrics).height
                )
                .offset(
                    x: LayoutConstants.WritingSetSelection.blobOffset(metrics).width,
                    y: LayoutConstants.WritingSetSelection.blobOffset(metrics).height
                )
        }
    }

    private var wordsText: String {
        let count = item.sourceSet.cards.count
        return count == 1 ? "1 word" : "\(count) words"
    }

    private static func color(from hex: String) -> Color {
        let trimmed = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        guard trimmed.count == 6,
              let value = UInt64(trimmed, radix: 16) else {
            return Color(hexNameFallback: hex)
        }

        let red = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue = Double(value & 0xFF) / 255.0

        return Color(red: red, green: green, blue: blue)
    }
}

private extension Color {
    init(hexNameFallback value: String) {
        switch value.lowercased() {
        case "red":
            self = .red
        case "purple":
            self = .purple
        case "green":
            self = .green
        case "yellow", "orange":
            self = .orange
        case "cyan":
            self = .cyan
        default:
            self = AppColors.primaryBlue
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
        colorHex: "#B66AF2",
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
            wordsCountText: "1 word",
            iconSystemName: "star.fill",
            theme: .purple
        )
    )
    .padding()
    .background(AppColors.appBackground)
}
