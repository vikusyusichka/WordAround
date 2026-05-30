import SwiftUI

/// Full-width gradient CTA used at the bottom of every Reading setup screen.
/// Width is constrained by the caller via `convContentMaxWidth` for iPad/Mac.
struct ReadingPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var accent: Color
    var accentDark: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: Layout.convSetupStartButtonTextSize - 2, weight: .bold))
                }
                Text(title)
                    .font(.system(size: Layout.convSetupStartButtonTextSize, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: Layout.convSetupStartButtonHeight + (Layout.isPadLike ? 6 : 0))
            .background(
                LinearGradient(colors: [accent, accentDark], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: Layout.convSetupStartButtonCornerRadius, style: .continuous))
            .shadow(color: accent.opacity(0.30), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .hoverEffect(.lift)
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        ReadingPrimaryButton(
            title: "Generate Reading",
            icon: "sparkles",
            accent: AppColors.primaryBlue,
            accentDark: AppColors.primaryBlueDark
        ) {}
        .padding()
    }
}
