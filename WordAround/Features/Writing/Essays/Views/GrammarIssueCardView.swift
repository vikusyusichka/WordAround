import SwiftUI

struct GrammarIssueCardView: View {
    let issue: GrammarIssue

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || UIScreen.main.bounds.width >= 700
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isPadLike ? 14 : 12) {
            feedbackRow(
                title: "Original",
                text: issue.incorrectText,
                systemImage: "exclamationmark.circle.fill",
                tint: Color(red: 0.78, green: 0.55, blue: 0.26),
                background: Color(red: 1.00, green: 0.95, blue: 0.88)
            )

            if issue.hasSuggestion, let suggestion = issue.suggestedCorrection {
                feedbackRow(
                    title: "Suggestion",
                    text: suggestion,
                    systemImage: "checkmark.circle.fill",
                    tint: AppColors.primaryBlue,
                    background: AppColors.primaryBlue.opacity(0.08)
                )
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Reason")
                    .font(.system(size: isPadLike ? 13 : 12, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)

                Text(issue.message)
                    .font(.system(size: isPadLike ? 14 : 13, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(3)
            }
        }
        .padding(isPadLike ? 18 : 15)
        .background(Color.white.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.045), radius: 14, x: 0, y: 8)
    }

    private func feedbackRow(
        title: String,
        text: String,
        systemImage: String,
        tint: Color,
        background: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: isPadLike ? 16 : 14, weight: .semibold))
                .foregroundColor(tint)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: isPadLike ? 12 : 11, weight: .bold, design: .rounded))
                    .foregroundColor(tint)

                Text(text)
                    .font(.system(size: isPadLike ? 15 : 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)
                    .textSelection(.enabled)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    GrammarIssueCardView(
        issue: GrammarIssue(
            message: "Use the past tense form here.",
            incorrectText: "go",
            suggestedCorrection: "went",
            offset: 0,
            length: 2
        )
    )
    .padding()
    .background(AppColors.appBackground)
}
