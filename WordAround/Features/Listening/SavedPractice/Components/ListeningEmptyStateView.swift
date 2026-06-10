import SwiftUI

struct ListeningEmptyStateView: View {
    let onStart: () -> Void
    var accent: Color = ListeningTheme.accent
    var accentDark: Color = ListeningTheme.accentDark

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.12))
                    .frame(width: 72, height: 72)
                Image(systemName: "headphones")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(accent)
            }

            Text(L10n.string("listeningNoSavedPractice"))
                .font(.system(size: Layout.homeSectionTitleSize, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)
                .multilineTextAlignment(.center)

            Text(L10n.string("listeningNoSavedSubtitle"))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Button(action: onStart) {
                Text(L10n.string("listeningStartListening"))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 44)
                    .background(accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
        )
    }
}
