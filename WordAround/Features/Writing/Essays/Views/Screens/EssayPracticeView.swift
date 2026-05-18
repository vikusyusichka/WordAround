import SwiftUI
import Foundation

struct EssayPracticeView: View {
    @StateObject private var viewModel = EssayPracticeViewModel()
    @FocusState private var isEditorFocused: Bool

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: Layout.essayMainSpacing) {
                    topicSection
                    configurationSection

                    EssayInputSectionView(
                        essayText: $viewModel.essayText,
                        isEditorFocused: $isEditorFocused,
                        wordCount: viewModel.wordCount,
                        validationState: viewModel.validationState,
                        isLoading: viewModel.isLoading,
                        canCheckGrammar: viewModel.canCheckGrammar,
                        hintsLeft: viewModel.hintsLeft,
                        canUseHint: viewModel.canUseHint,
                        canUseTranslation: viewModel.canUseTranslation,
                        canUseSynonym: viewModel.canUseSynonym,
                        assistanceUsageText: viewModel.assistanceUsageText,
                        shownHintItems: viewModel.shownHintItems,
                        onHint: {
                            withAnimation(.easeInOut(duration: 0.22)) {
                                viewModel.showHint()
                            }
                        },
                        onTranslate: {
                            isEditorFocused = false
                            withAnimation(.easeInOut(duration: 0.22)) {
                                viewModel.openTranslateModal()
                            }
                        },
                        onSynonym: {
                            isEditorFocused = false
                            withAnimation(.easeInOut(duration: 0.22)) {
                                viewModel.openSynonymModal()
                            }
                        },
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
                        score: viewModel.score,
                        wordCount: viewModel.wordCount,
                        usedHints: viewModel.usedHints,
                        usedTranslations: viewModel.usedTranslations,
                        usedSynonyms: viewModel.usedSynonyms,
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
            .task {
                if viewModel.currentTask == nil && !Self.isPreview {
                    await viewModel.generateSuggestedTask()
                }
            }
            .onTapGesture {
                isEditorFocused = false
            }

            if let modal = viewModel.activeAssistanceModal {
                EssayAssistanceModalView(
                    type: modal,
                    inputText: $viewModel.assistanceInputText,
                    selectedTargetLanguage: viewModel.selectedLanguage,
                    selectedSourceLanguage: modal == .translate
                        ? viewModel.translationSourceLanguage
                        : viewModel.assistanceSourceLanguage,
                    sourceLanguages: modal == .translate
                        ? viewModel.availableTranslationSourceLanguages
                        : viewModel.availableAssistanceSourceLanguages,
                    resultItems: viewModel.assistanceResultItems,
                    resultMessage: viewModel.assistanceResultMessage,
                    usageText: viewModel.assistanceUsageText,
                    isLoading: viewModel.isAssistanceLoading,
                    onSelectSourceLanguage: { language in
                        switch modal {
                        case .hint:
                            break
                        case .translate:
                            viewModel.selectTranslationSourceLanguage(language)
                        case .synonym:
                            viewModel.selectAssistanceSourceLanguage(language)
                        }
                    },
                    onSubmit: {
                        Task {
                            switch modal {
                            case .hint:
                                break
                            case .translate:
                                await viewModel.performTranslation()
                            case .synonym:
                                await viewModel.performSynonymSearch()
                            }
                        }
                    },
                    onClose: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.closeAssistanceModal()
                        }
                    }
                )
                .zIndex(10)
            }
        }
    }

    private static var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    private var topicSection: some View {
        VStack(alignment: .leading, spacing: Layout.essayTopicModeSpacing) {
            topicModePicker

            switch viewModel.topicMode {
            case .suggested:
                if let task = viewModel.currentTask {
                    EssayTopicCardView(
                        task: task,
                        isLoading: viewModel.isGeneratingTask,
                        errorMessage: viewModel.taskGenerationError,
                        onRefresh: {
                            Task {
                                await viewModel.generateSuggestedTask()
                            }
                        }
                    )
                } else {
                    EssayTopicCardView(
                        topic: viewModel.currentTopic,
                        isLoading: viewModel.isGeneratingTask,
                        errorMessage: viewModel.taskGenerationError,
                        onRefresh: {
                            Task {
                                await viewModel.generateSuggestedTask()
                            }
                        }
                    )
                }
            case .custom:
                CustomEssayTopicInputView(
                    topicText: Binding(
                        get: { viewModel.customTopicText },
                        set: { viewModel.updateCustomTopic($0) }
                    )
                )

                customTopicGenerationButton

                if let task = viewModel.currentTask {
                    EssayTopicCardView(
                        task: task,
                        isLoading: viewModel.isGeneratingTask,
                        errorMessage: viewModel.taskGenerationError,
                        onRefresh: {
                            Task {
                                await viewModel.generateTaskFromCustomTopic()
                            }
                        }
                    )
                } else if let error = viewModel.taskGenerationError {
                    Text(error)
                        .font(.system(size: Layout.essayTopicMetaSize, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Layout.essayCardPadding)
                        .background(Color.white.opacity(0.72))
                        .clipShape(RoundedRectangle(cornerRadius: Layout.essayCardCornerRadius, style: .continuous))
                }
            }
        }
    }


    private var customTopicGenerationButton: some View {
        Button {
            Task {
                await viewModel.generateTaskFromCustomTopic()
            }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isGeneratingTask {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                }

                Text(viewModel.isGeneratingTask ? "Generating" : "Generate essay task")
            }
            .font(.system(size: Layout.essayButtonTextSize, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Layout.essayButtonVerticalPadding)
            .background(AppColors.primaryBlue)
            .clipShape(RoundedRectangle(cornerRadius: Layout.essayButtonCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isGeneratingTask)
    }

    private var topicModePicker: some View {
        HStack(spacing: Layout.essayTopicModeButtonSpacing) {
            ForEach(EssayTopicMode.allCases) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        viewModel.selectTopicMode(mode)
                    }
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: Layout.essayTopicModeTextSize, weight: .bold, design: .rounded))
                        .foregroundColor(viewModel.topicMode == mode ? .white : AppColors.primaryBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Layout.essayTopicModeButtonVerticalPadding)
                        .background(viewModel.topicMode == mode ? AppColors.primaryBlue : Color.white.opacity(0.78))
                        .clipShape(RoundedRectangle(cornerRadius: Layout.essayTopicModeButtonCornerRadius, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Layout.essayTopicModePickerPadding)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: Layout.essayTopicModePickerCornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 6)
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
