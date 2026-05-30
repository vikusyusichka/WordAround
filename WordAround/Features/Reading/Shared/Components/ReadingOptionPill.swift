import SwiftUI

/// A single selectable option pill, themed by the mode's accent.
struct ReadingOptionPill: View {
    let title: String
    let isSelected: Bool
    var accent: Color
    var accentDark: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: Layout.convSetupDurationChipTextSize, weight: .bold, design: .rounded))
                .foregroundColor(isSelected ? .white : accentDark)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: Layout.convSetupDurationChipHeight)
                .background(isSelected ? accent : accent.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                        .stroke(isSelected ? Color.clear : accent.opacity(0.22), lineWidth: 1)
                )
                .shadow(
                    color: isSelected ? accent.opacity(0.22) : Color.clear,
                    radius: isSelected ? 10 : 0, x: 0, y: isSelected ? 4 : 0
                )
        }
        .buttonStyle(.plain)
        .hoverEffect(.lift)
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        HStack {
            ReadingOptionPill(title: "Short", isSelected: false, accent: AppColors.primaryBlue, accentDark: AppColors.primaryBlueDark) {}
            ReadingOptionPill(title: "Medium", isSelected: true, accent: AppColors.primaryBlue, accentDark: AppColors.primaryBlueDark) {}
        }
        .padding()
    }
}
