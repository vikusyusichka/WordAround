import SwiftUI

struct ListeningContinueCardView: View {
    let session: ListeningSavedSession
    let onContinue: () -> Void
    var accent: Color = ListeningTheme.accent
    var accentDark: Color = ListeningTheme.accentDark

    private var progressPercent: Int { Int((session.progress * 100).rounded()) }

    private var progressLabel: String {
        if session.isInProgress && progressPercent >= 99 && session.score == nil {
            return L10n.string("listenReadyToFinish")
        }
        return String(format: L10n.string("listenPercentCompleteFmt"), progressPercent)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(accent.opacity(0.16))
                        .frame(width: 48, height: 48)
                    Image(systemName: "headphones")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.string("listenContinueListening"))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(accent)
                        .textCase(.uppercase)

                    Text(session.title)
                        .font(.system(size: Layout.isPadLike ? 18 : 16, weight: .bold, design: .rounded))
                        .foregroundColor(accentDark)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                ListeningMetadataChip(text: session.modeTitle, accent: accent)
                ListeningMetadataChip(text: session.languageTitle, accent: accent)
                ListeningMetadataChip(text: session.levelTitle, accent: accent)
                Spacer(minLength: 0)
                Text(String(format: L10n.string("listenOpenedFmt"), session.dateText))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.mutedText)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(progressLabel)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(accent.opacity(0.14)).frame(height: 6)
                        Capsule()
                            .fill(accent)
                            .frame(width: max(6, geo.size.width * session.progress), height: 6)
                    }
                }
                .frame(height: 6)
            }

            Button(action: onContinue) {
                HStack(spacing: 6) {
                    Text(L10n.string("commonContinue"))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .frame(height: 40)
                .background(accent)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.96))
                .shadow(color: accent.opacity(0.12), radius: 14, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .stroke(accent.opacity(0.22), lineWidth: 1)
        )
    }
}
