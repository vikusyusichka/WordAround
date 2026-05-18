import SwiftUI

struct EssayPracticeView: View {
    @StateObject private var viewModel = EssayPracticeViewModel()
    @FocusState private var isEditorFocused: Bool

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || UIScreen.main.bounds.width >= 700
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Layout.essayMainSpacing) {
                EssayTopicCardView(
                    topic: viewModel.currentTopic,
                    onRefresh: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            viewModel.selectRandomTopic()
                        }
                    }
                )

                configurationSection

                EssayInputSectionView(
                    essayText: $viewModel.essayText,
                    isEditorFocused: $isEditorFocused,
                    wordCount: viewModel.wordCount,
                    validationState: viewModel.validationState,
                    isLoading: viewModel.isLoading,
                    canCheckGrammar: viewModel.canCheckGrammar,
                    onReset: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.resetEssay()
                            isEditorFocused = false
                        }
                    },
                    onCheckGrammar: {
                        isEditorFocused = false

                        Task {
                            await viewModel.checkGrammar()
                        }
                    }
                )

                EssayFeedbackSectionView(
                    state: viewModel.feedbackState,
                    issues: viewModel.grammarIssues,
                    onRetry: {
                        await viewModel.retryGrammarCheck()
                    }
                )
            }
            .frame(maxWidth: Layout.essayContentMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Layout.essayScreenHorizontalPadding)
            .padding(.vertical, Layout.essayScreenVerticalPadding)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(AppColors.appBackground.ignoresSafeArea())
        .navigationTitle("Essay Practice")
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            isEditorFocused = false
        }
    }

    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: isPadLike ? 12 : 10) {
            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars.inverse")
                    .font(.system(size: isPadLike ? 15 : 13, weight: .semibold))
                    .foregroundColor(AppColors.primaryBlue)

                Text("Writing setup")
                    .font(.system(size: isPadLike ? 16 : 15, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)

                Spacer(minLength: 0)

                Text("Hints left: \(viewModel.hintsLeft)")
                    .font(.system(size: isPadLike ? 12 : 11, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppColors.primaryBlue.opacity(0.08))
                    .clipShape(Capsule())
            }

            if isPadLike {
                HStack(alignment: .top, spacing: 12) {
                    LanguageSelectorView(
                        selectedLanguage: viewModel.selectedLanguage,
                        onSelect: { language in
                            viewModel.selectLanguage(language)
                        }
                    )

                    DifficultySelectorView(
                        selectedDifficulty: viewModel.selectedDifficulty,
                        onSelect: { difficulty in
                            viewModel.selectDifficulty(difficulty)
                        }
                    )
                }
            } else {
                VStack(spacing: 10) {
                    LanguageSelectorView(
                        selectedLanguage: viewModel.selectedLanguage,
                        onSelect: { language in
                            viewModel.selectLanguage(language)
                        }
                    )

                    DifficultySelectorView(
                        selectedDifficulty: viewModel.selectedDifficulty,
                        onSelect: { difficulty in
                            viewModel.selectDifficulty(difficulty)
                        }
                    )
                }
            }

            Text(viewModel.privacyNoticeText)
                .font(.system(size: isPadLike ? 12 : 11, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(3)
                .padding(.top, 2)
        }
        .padding(Layout.essayCardPadding)
        .background(Color.white.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: Layout.essayCardCornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.035), radius: 14, x: 0, y: 8)
    }
}

#Preview {
    NavigationStack {
        EssayPracticeView()
    }
}
