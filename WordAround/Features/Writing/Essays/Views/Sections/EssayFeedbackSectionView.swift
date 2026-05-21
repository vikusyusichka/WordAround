import SwiftUI

struct EssayFeedbackSectionView: View {
    let state: EssayPracticeViewModel.FeedbackState
    let issues: [GrammarIssue]
    let score: EssayScore?
    let wordCount: Int
    let usedHints: Int
    let usedTranslations: Int
    let usedSynonyms: Int
    let onRetry: () async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.essayFeedbackSectionSpacing) {
            HStack {
                Text("Grammar feedback")
                    .font(.system(size: Layout.essayFeedbackTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)

                Spacer(minLength: 0)

                if let score {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(score.total)/100")
                            .font(.system(size: Layout.essayFeedbackScoreMiniValueSize, weight: .black, design: .rounded))
                            .foregroundColor(AppColors.primaryBlue)

                        Text(score.qualityLabel)
                            .font(.system(size: Layout.essayFeedbackScoreMiniLabelSize, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }

            if let score {
                EssayScoreCardView(
                    score: score,
                    wordCount: wordCount,
                    issues: issues,
                    usedHints: usedHints,
                    usedTranslations: usedTranslations,
                    usedSynonyms: usedSynonyms
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            content
        }
        .animation(.easeInOut(duration: 0.25), value: issues)
        .animation(.easeInOut(duration: 0.25), value: state)
        .animation(.easeInOut(duration: 0.25), value: score)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .idle:
            emptyCard(
                icon: "text.magnifyingglass",
                title: "No feedback yet",
                message: "Write your essay and check grammar when it is ready."
            )

        case .loading:
            loadingCard

        case .success:
            VStack(spacing: Layout.essayFeedbackCardSpacing) {
                ForEach(issues) { issue in
                    GrammarIssueCardView(issue: issue)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }

        case .emptyResult:
            emptyCard(
                icon: "checkmark.seal.fill",
                title: "No grammar issues found",
                message: "Your essay looks clean. Human civilization survives one more paragraph."
            )

        case .error(let message):
            VStack(alignment: .leading, spacing: Layout.essayFeedbackCardSpacing) {
                emptyCard(icon: "wifi.exclamationmark", title: "Grammar check failed", message: message)

                Button {
                    Task {
                        await onRetry()
                    }
                } label: {
                    Text("Try again")
                        .font(.system(size: Layout.essayButtonTextSize, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Layout.essayButtonVerticalPadding)
                        .background(AppColors.primaryBlue)
                        .clipShape(RoundedRectangle(cornerRadius: Layout.essayButtonCornerRadius, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var loadingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(AppColors.primaryBlue)

            Text("Checking grammar...")
                .font(.system(size: Layout.essayFeedbackBodySize, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)

            Spacer(minLength: 0)
        }
        .padding(Layout.essayFeedbackCardPadding)
        .background(Color.white.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: Layout.essayFeedbackCardCornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.045), radius: 14, x: 0, y: 8)
    }

    private func emptyCard(icon: String, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColors.primaryBlue.opacity(0.08))
                .frame(width: Layout.essayFeedbackIconBoxSize, height: Layout.essayFeedbackIconBoxSize)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: Layout.essayFeedbackIconSize, weight: .semibold))
                        .foregroundColor(AppColors.primaryBlue)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: Layout.essayFeedbackEmptyTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)

                Text(message)
                    .font(.system(size: Layout.essayFeedbackBodySize, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(3)
            }

            Spacer(minLength: 0)
        }
        .padding(Layout.essayFeedbackCardPadding)
        .background(Color.white.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: Layout.essayFeedbackCardCornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.045), radius: 14, x: 0, y: 8)
    }
}

#Preview {
    EssayFeedbackSectionView(
        state: .success,
        issues: [
            GrammarIssue(message: "Use the past tense form here.", incorrectText: "go", suggestedCorrection: "went", offset: 0, length: 2)
        ],
        score: EssayScore(total: 86, grammar: 90, vocabulary: 80, length: 100, complexity: 70, relevance: 80, independence: 90, cefrLevel: "B2", qualityLabel: "Excellent"),
        wordCount: 120,
        usedHints: 1,
        usedTranslations: 1,
        usedSynonyms: 0,
        onRetry: {}
    )
    .padding()
    .background(AppColors.appBackground)
}
