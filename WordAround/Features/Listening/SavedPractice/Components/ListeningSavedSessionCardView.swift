import SwiftUI

struct ListeningSavedSessionCardView: View {
    let session: ListeningSavedSession
    let onContinue: () -> Void
    var onReview: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var accent: Color = ListeningTheme.accent
    var accentDark: Color = ListeningTheme.accentDark

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(session.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(accentDark)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        ListeningMetadataChip(text: session.modeTitle, accent: accent)
                        ListeningMetadataChip(text: session.languageTitle, accent: accent)
                        ListeningMetadataChip(text: session.levelTitle, accent: accent)
                    }
                }

                Spacer(minLength: 0)

                Menu {
                    if let onReview {
                        Button(L10n.string("listenReviewResult"), action: onReview)
                    }
                    if let onDelete {
                        Button(L10n.string("listenDeleteSession"), role: .destructive, action: onDelete)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppColors.mutedText)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                }
            }

            HStack {
                if let score = session.score {
                    Text("\(score)%")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(accent)
                } else {
                    Text(session.status)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                Text(session.dateText)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.mutedText)
            }

            Button(action: onContinue) {
                Text(session.isInProgress ? L10n.string("commonContinue") : L10n.string("writingReview"))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(accentDark)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(accent.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
}
