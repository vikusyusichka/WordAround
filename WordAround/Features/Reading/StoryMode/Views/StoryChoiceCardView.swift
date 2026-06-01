import SwiftUI

struct StoryChoiceCardView: View {
    let choice: StoryChoice
    let isSelected: Bool
    let isDisabled: Bool
    let isGenerating: Bool
    let accent: Color
    let accentDark: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.14))
                        .frame(width: 36, height: 36)
                    Image(systemName: choice.iconName ?? "arrow.turn.up.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(choice.label)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlueDark)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let hint = choice.hint, !hint.isEmpty {
                        Text(hint)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                if isGenerating {
                    ProgressView().tint(accent)
                } else {
                    Image(systemName: isSelected ? "largecircle.fill.circle" : "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isSelected ? accent : AppColors.mutedText)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                    .fill(isSelected ? accent.opacity(0.12) : Color.white.opacity(0.94))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                    .stroke(isSelected ? accent : Color.black.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled && !isSelected ? 0.5 : 1)
    }
}
