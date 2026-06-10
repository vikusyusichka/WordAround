import SwiftUI

struct ConversationCorrectionCardView: View {
    let correction: ConversationCorrection

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.isPadLike ? 14 : 12) {
            feedbackRow(
                title: L10n.string("spkYouSaid"),
                text: correction.youSaid,
                icon: "exclamationmark.circle.fill",
                tint: Color(red: 0.78, green: 0.55, blue: 0.26),
                background: Color(red: 1.00, green: 0.95, blue: 0.88)
            )

            feedbackRow(
                title: L10n.string("spkBetter"),
                text: correction.better,
                icon: "checkmark.circle.fill",
                tint: AppColors.primaryBlue,
                background: AppColors.primaryBlue.opacity(0.07)
            )

            VStack(alignment: .leading, spacing: 5) {
                Text(L10n.string("spkWhy"))
                    .font(.system(
                        size: Layout.isPadLike ? 13 : 12,
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundColor(AppColors.primaryBlueDark)

                Text(correction.explanation)
                    .font(.system(
                        size: Layout.isPadLike ? 14 : 13,
                        weight: .medium,
                        design: .rounded
                    ))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(3)
            }
        }
        .padding(Layout.isPadLike ? 18 : 15)
        .background(Color.white.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.045), radius: 14, x: 0, y: 8)
    }

    private func feedbackRow(
        title: String,
        text: String,
        icon: String,
        tint: Color,
        background: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(
                    size: Layout.isPadLike ? 16 : 14,
                    weight: .semibold
                ))
                .foregroundColor(tint)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(
                        size: Layout.isPadLike ? 12 : 11,
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundColor(tint)

                Text(text)
                    .font(.system(
                        size: Layout.isPadLike ? 15 : 14,
                        weight: .semibold,
                        design: .rounded
                    ))
                    .foregroundColor(AppColors.primaryBlueDark)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(ConversationCorrection.placeholderCorrections) { c in
            ConversationCorrectionCardView(correction: c)
        }
    }
    .padding(20)
    .background(AppColors.appBackground)
}
