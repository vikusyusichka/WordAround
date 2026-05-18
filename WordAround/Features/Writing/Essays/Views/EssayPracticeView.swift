import SwiftUI

struct EssayPracticeView: View {
    @StateObject private var viewModel = EssayPracticeViewModel()
    @FocusState private var isEditorFocused: Bool

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
        VStack(alignment: .leading, spacing: Layout.essaySetupSpacing) {
            HStack(spacing: Layout.essaySetupHeaderSpacing) {
                Image(systemName: "wand.and.stars.inverse")
                    .font(.system(size: Layout.essaySetupIconSize, weight: .semibold))
                    .foregroundColor(AppColors.primaryBlue)

                Text("Writing setup")
                    .font(.system(size: Layout.essaySetupTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)

                Spacer(minLength: 0)

                Text("Hints left: \(viewModel.hintsLeft)")
                    .font(.system(size: Layout.essayHintsBadgeTextSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlue)
                    .padding(.horizontal, Layout.essayHintsBadgeHorizontalPadding)
                    .padding(.vertical, Layout.essayHintsBadgeVerticalPadding)
                    .background(AppColors.primaryBlue.opacity(0.08))
                    .clipShape(Capsule())
            }

            if Layout.isPadLike {
                HStack(alignment: .top, spacing: Layout.essaySetupSelectorColumnsSpacing) {
                    languageSelector
                    difficultySelector
                }
            } else {
                VStack(spacing: Layout.essaySetupSelectorStackSpacing) {
                    languageSelector
                    difficultySelector
                }
            }

            Text(viewModel.privacyNoticeText)
                .font(.system(size: Layout.essayPrivacyNoticeTextSize, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(Layout.essayPrivacyNoticeLineSpacing)
                .padding(.top, Layout.essayPrivacyNoticeTopPadding)
        }
        .padding(Layout.essayCardPadding)
        .background(Color.white.opacity(Layout.essaySetupCardOpacity))
        .clipShape(RoundedRectangle(cornerRadius: Layout.essayCardCornerRadius, style: .continuous))
        .shadow(
            color: Color.black.opacity(Layout.essaySetupShadowOpacity),
            radius: Layout.essaySetupShadowRadius,
            x: 0,
            y: Layout.essaySetupShadowYOffset
        )
    }

    private var languageSelector: some View {
        LanguageSelectorView(
            selectedLanguage: viewModel.selectedLanguage,
            onSelect: { language in
                viewModel.selectLanguage(language)
            }
        )
    }

    private var difficultySelector: some View {
        DifficultySelectorView(
            selectedDifficulty: viewModel.selectedDifficulty,
            onSelect: { difficulty in
                viewModel.selectDifficulty(difficulty)
            }
        )
    }
}

#Preview {
    NavigationStack {
        EssayPracticeView()
    }
}
