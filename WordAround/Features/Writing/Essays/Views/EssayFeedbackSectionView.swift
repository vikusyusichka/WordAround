import SwiftUI

struct EssayFeedbackSectionView: View {
    let state: EssayPracticeViewModel.FeedbackState
    let issues: [GrammarIssue]
    let onRetry: () async -> Void

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || UIScreen.main.bounds.width >= 700
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isPadLike ? 14 : 12) {
            Text("Grammar feedback")
                .font(.system(size: isPadLike ? 20 : 17, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)

            content
        }
        .animation(.easeInOut(duration: 0.25), value: issues)
        .animation(.easeInOut(duration: 0.25), value: state)
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
            VStack(spacing: isPadLike ? 12 : 10) {
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
            VStack(alignment: .leading, spacing: 12) {
                emptyCard(icon: "wifi.exclamationmark", title: "Grammar check failed", message: message)

                Button {
                    Task {
                        await onRetry()
                    }
                } label: {
                    Text("Try again")
                        .font(.system(size: isPadLike ? 15 : 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isPadLike ? 14 : 13)
                        .background(AppColors.primaryBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                .font(.system(size: isPadLike ? 15 : 14, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)

            Spacer(minLength: 0)
        }
        .padding(isPadLike ? 18 : 16)
        .background(Color.white.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.045), radius: 14, x: 0, y: 8)
    }

    private func emptyCard(icon: String, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColors.primaryBlue.opacity(0.08))
                .frame(width: isPadLike ? 42 : 38, height: isPadLike ? 42 : 38)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: isPadLike ? 18 : 16, weight: .semibold))
                        .foregroundColor(AppColors.primaryBlue)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: isPadLike ? 16 : 15, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)

                Text(message)
                    .font(.system(size: isPadLike ? 14 : 13, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(3)
            }

            Spacer(minLength: 0)
        }
        .padding(isPadLike ? 18 : 16)
        .background(Color.white.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.045), radius: 14, x: 0, y: 8)
    }
}

#Preview {
    EssayFeedbackSectionView(
        state: .success,
        issues: [
            GrammarIssue(message: "Use the past tense form here.", incorrectText: "go", suggestedCorrection: "went", offset: 0, length: 2)
        ],
        onRetry: {}
    )
    .padding()
    .background(AppColors.appBackground)
}
