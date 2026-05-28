import SwiftUI

struct EssaySetHintCardRowView: View {
    let item: EssaySetHintItem
    let isSelected: Bool
    let metrics: ScreenMetrics
    let onToggle: () -> Void

    init(
        item: EssaySetHintItem,
        isSelected: Bool,
        metrics: ScreenMetrics? = nil,
        onToggle: @escaping () -> Void
    ) {
        self.item = item
        self.isSelected = isSelected
        self.metrics = metrics ?? ScreenMetrics.current(horizontal: nil, vertical: nil, containerWidth: 0)
        self.onToggle = onToggle
    }

    private var cleanExample: String? {
        guard let example = item.example?.trimmingCharacters(in: .whitespacesAndNewlines),
              !example.isEmpty else {
            return nil
        }

        return example
    }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: LayoutConstants.WritingSetSelection.rowContentSpacing(metrics)) {
                thumbnail

                VStack(alignment: .leading, spacing: 5) {
                    Text(item.word)
                        .font(.system(
                            size: LayoutConstants.WritingSetSelection.titleTextSize(metrics),
                            weight: .bold,
                            design: .rounded
                        ))
                        .foregroundColor(AppColors.primaryBlueDark)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text(item.translation)
                        .font(.system(
                            size: LayoutConstants.WritingSetSelection.subtitleTextSize(metrics),
                            weight: .semibold,
                            design: .rounded
                        ))
                        .foregroundColor(AppColors.primaryBlue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    if let cleanExample {
                        Text(cleanExample)
                            .font(.system(
                                size: LayoutConstants.WritingSetSelection.exampleTextSize(metrics),
                                weight: .medium,
                                design: .rounded
                            ))
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: LayoutConstants.WritingSetSelection.rowContentSpacing(metrics))

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(
                        size: LayoutConstants.WritingSetSelection.iconSize(metrics),
                        weight: .bold
                    ))
                    .foregroundColor(isSelected ? AppColors.primaryBlue : AppColors.textSecondary.opacity(0.45))
            }
            .padding(.horizontal, LayoutConstants.WritingSetSelection.rowHorizontalPadding(metrics))
            .padding(.vertical, LayoutConstants.WritingSetSelection.rowVerticalPadding(metrics))
            .frame(
                maxWidth: .infinity,
                minHeight: LayoutConstants.WritingSetSelection.rowHeight(metrics),
                alignment: .leading
            )
            .background(Color.white.opacity(isSelected ? 0.96 : 0.88))
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
                .stroke(AppColors.primaryBlue.opacity(isSelected ? 0.22 : 0.06), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let imageURL = item.imageURL,
           let url = URL(string: imageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    placeholder
                }
            }
            .frame(
                width: LayoutConstants.WritingSetSelection.iconCircleSize(metrics),
                height: LayoutConstants.WritingSetSelection.iconCircleSize(metrics)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: LayoutConstants.WritingSetSelection.thumbnailCornerRadius(metrics),
                    style: .continuous
                )
            )
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            Circle()
                .fill(AppColors.primaryBlue.opacity(0.10))
                .frame(
                    width: LayoutConstants.WritingSetSelection.iconCircleSize(metrics),
                    height: LayoutConstants.WritingSetSelection.iconCircleSize(metrics)
                )

            Image(systemName: "text.book.closed.fill")
                .font(.system(
                    size: LayoutConstants.WritingSetSelection.iconSize(metrics),
                    weight: .bold
                ))
                .foregroundColor(AppColors.primaryBlue)
        }
    }
}

#Preview {
    EssaySetHintCardRowView(
        item: EssaySetHintItem(
            id: UUID().uuidString,
            word: "manzana",
            translation: "яблуко",
            example: "Me gusta la manzana.",
            imageURL: nil
        ),
        isSelected: true,
        onToggle: {}
    )
    .padding()
    .background(AppColors.appBackground)
}
