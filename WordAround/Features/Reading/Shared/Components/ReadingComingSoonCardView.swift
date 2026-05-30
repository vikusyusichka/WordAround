import SwiftUI

/// Dimmed, non-interactive card for a Reading mode whose session is not built
/// yet. Shows a "Coming soon" badge.
struct ReadingComingSoonCardView: View {
    let mode: ReadingMode

    var body: some View {
        let cornerRadius = Layout.speakingModeCardCornerRadius

        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(mode.accentColor.opacity(0.12))
                    .frame(width: Layout.speakingModeIconCircleSize, height: Layout.speakingModeIconCircleSize)
                Image(systemName: mode.systemImage)
                    .font(.system(size: Layout.speakingModeIconSize, weight: .semibold))
                    .foregroundColor(mode.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(mode.title)
                    .font(.system(size: Layout.speakingModeTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(mode.subtitle)
                    .font(.system(size: Layout.speakingModeSubtitleSize, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Text("Coming soon")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.mutedText)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(AppColors.mutedText.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(Layout.speakingModeCardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.92), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        .opacity(0.85)
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        ReadingComingSoonCardView(
            mode: ReadingMode(
                id: "interactive-reading",
                title: "Interactive Reading",
                subtitle: "Tap words, answer questions, and explore.",
                systemImage: "hand.tap.fill",
                accentColor: AppColors.greenAccent,
                blobColor: AppColors.blobGreen,
                isComingSoon: true
            )
        )
        .padding(20)
    }
}
