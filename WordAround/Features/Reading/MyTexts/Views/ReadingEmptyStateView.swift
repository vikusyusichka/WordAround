import SwiftUI

struct ReadingEmptyStateView: View {
    let onAddText: () -> Void

    private let accent = ReadingMyTextsTheme.accent
    private let accentDark = ReadingMyTextsTheme.accentDark

    var body: some View {
        VStack(spacing: Layout.isPadLike ? 20 : 16) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.12))
                    .frame(width: Layout.isPadLike ? 72 : 60, height: Layout.isPadLike ? 72 : 60)

                Image(systemName: "doc.text.fill")
                    .font(.system(size: Layout.isPadLike ? 28 : 24, weight: .semibold))
                    .foregroundColor(accent)
            }

            VStack(spacing: 6) {
                Text(L10n.string("readingEmptyNoTextsTitle"))
                    .font(.system(size: Layout.isPadLike ? 20 : 17, weight: .bold, design: .rounded))
                    .foregroundColor(accentDark)
                    .multilineTextAlignment(.center)

                Text(L10n.string("readingEmptyNoTextsSubtitle"))
                    .font(.system(size: Layout.isPadLike ? 15 : 13, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: Layout.isPadLike ? 420 : 300)
            }

            Button(action: onAddText) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text(L10n.string("readingAddFirstText"))
                        .font(.system(size: Layout.isPadLike ? 15 : 14, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .frame(height: Layout.isPadLike ? 48 : 44)
                .background(accent)
                .clipShape(Capsule())
                .shadow(color: accent.opacity(0.28), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
        }
        .padding(Layout.isPadLike ? 28 : 22)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .stroke(accent.opacity(0.10), lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        ReadingEmptyStateView(onAddText: {})
            .padding()
    }
}
