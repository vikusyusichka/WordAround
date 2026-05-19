import SwiftUI

struct EssaySetHintCardRowView: View {
    let item: EssaySetHintItem
    let isSelected: Bool
    let onToggle: () -> Void

    private var cleanExample: String? {
        guard let example = item.example?.trimmingCharacters(in: .whitespacesAndNewlines),
              !example.isEmpty else {
            return nil
        }

        return example
    }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Layout.setItemContentSpacing) {
                thumbnail

                VStack(alignment: .leading, spacing: Layout.setItemTextStackSpacing) {
                    Text(item.word)
                        .font(.system(size: Layout.setItemTitleSize, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlueDark)
                        .lineLimit(1)

                    Text(item.translation)
                        .font(.system(size: Layout.setItemSubtitleSize, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlue)
                        .lineLimit(1)

                    if let cleanExample {
                        Text(cleanExample)
                            .font(.system(size: Layout.essayHintExampleSize, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: Layout.setItemContentSpacing)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: Layout.setItemIconSize, weight: .bold))
                    .foregroundColor(isSelected ? AppColors.primaryBlue : AppColors.textSecondary.opacity(0.45))
            }
            .padding(.horizontal, Layout.setItemHorizontalPadding)
            .padding(.vertical, Layout.setItemVerticalPadding)
            .frame(maxWidth: .infinity, minHeight: Layout.setItemHeight, alignment: .leading)
            .background(Color.white.opacity(isSelected ? 0.96 : 0.82))
            .clipShape(RoundedRectangle(cornerRadius: Layout.setItemCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Layout.setItemCornerRadius, style: .continuous)
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
            .frame(width: Layout.setItemIconCircleSize, height: Layout.setItemIconCircleSize)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            Circle()
                .fill(AppColors.primaryBlue.opacity(0.10))
                .frame(width: Layout.setItemIconCircleSize, height: Layout.setItemIconCircleSize)

            Image(systemName: "text.book.closed.fill")
                .font(.system(size: Layout.setItemIconSize, weight: .bold))
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
