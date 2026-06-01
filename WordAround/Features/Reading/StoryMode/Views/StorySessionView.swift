import SwiftUI

struct StorySessionView: View {
    var onExitToSetup: () -> Void
    var onExitToReading: () -> Void

    @StateObject private var viewModel: StorySessionViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Init (new story from setup)

    init(setup: ReadingSessionSetup, onExitToSetup: @escaping () -> Void, onExitToReading: @escaping () -> Void) {
        self.onExitToSetup = onExitToSetup
        self.onExitToReading = onExitToReading
        _viewModel = StateObject(wrappedValue: StorySessionViewModel(setup: setup))
    }

    // MARK: - Init (existing story from library)

    init(item: ReadingLibraryItem, onExitToSetup: @escaping () -> Void, onExitToReading: @escaping () -> Void) {
        self.onExitToSetup = onExitToSetup
        self.onExitToReading = onExitToReading
        _viewModel = StateObject(wrappedValue: StorySessionViewModel(item: item))
    }

    private var accent: Color { viewModel.accent }
    private var accentDark: Color { viewModel.accentDark }

    private var contentMaxWidth: CGFloat {
        horizontalSizeClass == .regular ? Layout.convContentMaxWidth : .infinity
    }

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            if viewModel.isLoading {
                loadingState
            } else if viewModel.session == nil, let error = viewModel.errorMessage {
                errorState(error)
            } else {
                sessionContent
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .onDisappear { viewModel.onDisappear() }
        .navigationDestination(isPresented: $viewModel.navigateToResult) {
            if let result = viewModel.result {
                ReadingResultView(
                    result: result,
                    title: viewModel.chapterTitle,
                    levelTitle: viewModel.difficultyTitle,
                    focusTitle: viewModel.chapterProgressText,
                    accent: accent,
                    accentDark: accentDark,
                    readAgainTitle: viewModel.postResultPrimaryActionTitle,
                    backButtonTitle: "Back to Library",
                    onReadAgain: {
                        let route = viewModel.handlePostResultPrimaryAction()
                        if route == .exitToLibrary {
                            viewModel.onDisappear()
                            onExitToReading()
                        }
                    },
                    onBackToLibrary: {
                        viewModel.dismissResult(showChoices: false)
                        viewModel.onDisappear()
                        onExitToReading()
                    }
                )
            }
        }
    }

    // MARK: - Loading / error

    private var loadingState: some View {
        VStack(spacing: 18) {
            ProgressView()
                .scaleEffect(1.3)
                .tint(accent)
            Text(viewModel.session?.hasGeneratedContent == true ? "Loading story…" : "Creating your story…")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorState(_ message: String) -> some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ReadingSetupHeaderView(
                        title: "Story Mode",
                        subtitle: "Something went wrong.",
                        accent: accent,
                        accentDark: accentDark,
                        onBack: onExitToReading
                    )
                    errorBanner(message)
                }
                .frame(maxWidth: contentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
            }

            ReadingPrimaryButton(
                title: "Try Again",
                icon: "arrow.clockwise",
                accent: accent,
                accentDark: accentDark
            ) { Task { await viewModel.retryGeneration() } }
            .frame(maxWidth: contentMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Layout.homeHorizontalPadding)
            .padding(.bottom, Layout.homeBottomBarBottomPadding)
        }
    }

    // MARK: - Session content

    private var sessionContent: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ReadingSetupHeaderView(
                        title: "Story Mode",
                        subtitle: sessionSubtitle,
                        accent: accent,
                        accentDark: accentDark,
                        trailingIcon: trailingIcon,
                        trailingText: trailingText,
                        onBack: {
                            viewModel.onDisappear()
                            onExitToReading()
                        }
                    )

                    StoryChapterProgressCardView(
                        storyTitle: viewModel.storyTitle,
                        typeTitle: viewModel.typeTitle,
                        difficultyTitle: viewModel.difficultyTitle,
                        languageTitle: viewModel.languageTitle,
                        lengthTitle: viewModel.lengthTitle,
                        chapterProgressText: viewModel.chapterProgressText,
                        overallProgress: viewModel.overallProgress,
                        accent: accent,
                        accentDark: accentDark
                    )

                    if let chapter = viewModel.currentChapter {
                        StoryChapterHeaderView(
                            chapterTitle: chapter.title,
                            chapterNumber: chapter.chapterIndex,
                            summary: chapterSummary(for: chapter),
                            accent: accent,
                            accentDark: accentDark
                        )
                    }

                    if viewModel.showChoiceSection {
                        choiceSection
                    } else {
                        readingAndQuestionsSection
                    }

                    if let error = viewModel.errorMessage, viewModel.session != nil {
                        errorBanner(error)
                    }

                    Spacer().frame(height: Layout.convSetupStartButtonHeight + 24)
                }
                .frame(maxWidth: contentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
                .padding(.bottom, Layout.homeBottomSafeSpacing)
            }

            if !viewModel.showChoiceSection {
                bottomBar
                    .frame(maxWidth: contentMaxWidth)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, Layout.homeHorizontalPadding)
                    .padding(.bottom, Layout.homeBottomBarBottomPadding)
            }
        }
    }

    @ViewBuilder
    private var readingAndQuestionsSection: some View {
        if !viewModel.chapterContent.isEmpty {
            ReadingReadingToolbarView(
                content: viewModel.chapterContent,
                highlightOnTap: viewModel.assistance.highlightUnknownWords,
                showVocabularyHints: viewModel.assistance.vocabularyHints,
                translationOnTap: viewModel.assistance.translationOnTap,
                sourceLanguage: viewModel.translationSourceLanguage,
                translationTargetLanguage: viewModel.translationTargetLanguage,
                selectedWord: viewModel.selectedWord,
                translatedWord: viewModel.translatedWord,
                selectedWordRange: viewModel.selectedWordRange,
                isTranslatingWord: viewModel.isTranslatingWord,
                translationError: viewModel.translationError,
                accent: accent,
                accentDark: accentDark,
                onWordTap: { viewModel.handleWordTap($0, range: $1) },
                onSelectTranslationTarget: { viewModel.selectTranslationTarget($0) }
            )
        }

        if viewModel.phase == .questions, let question = viewModel.currentQuestion {
            ReadingQuestionSectionView(
                question: question,
                showVocabularyHints: viewModel.assistance.vocabularyHints,
                selectedAnswer: viewModel.selectedAnswer,
                accent: accent,
                accentDark: accentDark,
                onSelect: { viewModel.selectAnswer($0) }
            )
        } else if viewModel.phase == .reading && !viewModel.hasQuestions && !viewModel.chapterContent.isEmpty {
            emptyQuestionsNotice
        }
    }

    private var choiceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What happens next?")
                .font(.system(size: Layout.homeSectionTitleSize, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)

            if viewModel.availableChoices.isEmpty {
                Text("No choices are available for this chapter yet. Try again in a moment.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                            .fill(Color.white.opacity(0.94))
                    )
            } else {
                ForEach(viewModel.availableChoices) { choice in
                    StoryChoiceCardView(
                        choice: choice,
                        isSelected: viewModel.selectedChoice?.id == choice.id,
                        isDisabled: viewModel.isGeneratingNextChapter || (viewModel.selectedChoice != nil && viewModel.selectedChoice?.id != choice.id),
                        isGenerating: viewModel.isGeneratingNextChapter && viewModel.selectedChoice?.id == choice.id,
                        accent: accent,
                        accentDark: accentDark
                    ) {
                        Task { await viewModel.selectChoice(choice) }
                    }
                }
            }

            if viewModel.isInfinite {
                Button {
                    Task {
                        await viewModel.endStory()
                        viewModel.onDisappear()
                        onExitToReading()
                    }
                } label: {
                    Text("End Story")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(accentDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(accent.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Bottom bar

    @ViewBuilder
    private var bottomBar: some View {
        switch viewModel.phase {
        case .reading:
            if viewModel.isStoryCompleted {
                ReadingPrimaryButton(
                    title: "Back to Library",
                    icon: "books.vertical.fill",
                    accent: accent,
                    accentDark: accentDark,
                    action: {
                        viewModel.onDisappear()
                        onExitToReading()
                    }
                )
            } else {
                ReadingPrimaryButton(
                    title: viewModel.hasQuestions ? "Start Questions" : "Finish",
                    icon: viewModel.hasQuestions ? "questionmark.circle.fill" : "checkmark",
                    accent: accent,
                    accentDark: accentDark
                ) {
                    if viewModel.hasQuestions {
                        viewModel.startQuestions()
                    } else {
                        Task { await viewModel.finishReadingWithoutQuestions() }
                        viewModel.navigateToResult = true
                    }
                }
            }
        case .questions:
            ReadingPrimaryButton(
                title: viewModel.isLastQuestion ? "Finish" : "Next",
                icon: viewModel.isLastQuestion ? "checkmark" : "arrow.right",
                accent: accent,
                accentDark: accentDark
            ) {
                guard viewModel.selectedAnswer != nil else { return }
                if viewModel.isLastQuestion {
                    Task {
                        await viewModel.submitAnswers()
                        viewModel.navigateToResult = true
                    }
                } else {
                    viewModel.goToNextQuestion()
                }
            }
            .opacity(viewModel.selectedAnswer == nil ? 0.55 : 1)
            .disabled(viewModel.selectedAnswer == nil)
        case .results:
            if viewModel.isShortStory || viewModel.isStoryCompleted {
                ReadingPrimaryButton(
                    title: "Back to Library",
                    icon: "books.vertical.fill",
                    accent: accent,
                    accentDark: accentDark
                ) {
                    viewModel.onDisappear()
                    onExitToReading()
                }
            } else if viewModel.branches {
                ReadingPrimaryButton(
                    title: viewModel.isGeneratingNextChapter ? "Generating next chapter…" : "Choose What Happens Next",
                    icon: "arrow.triangle.branch",
                    accent: accent,
                    accentDark: accentDark
                ) {
                    viewModel.showChoiceSection = true
                }
                .disabled(viewModel.isGeneratingNextChapter)
            }
        }
    }

    // MARK: - Helpers

    private var sessionSubtitle: String {
        "\(viewModel.typeTitle) • \(viewModel.chapterProgressText)"
    }

    private var trailingIcon: String? {
        switch viewModel.phase {
        case .reading where viewModel.showTimer:
            return "clock.fill"
        default:
            return nil
        }
    }

    private var trailingText: String? {
        switch viewModel.phase {
        case .reading:
            return viewModel.showTimer ? viewModel.formattedTime : nil
        case .questions:
            return viewModel.hasQuestions ? viewModel.questionProgressText : nil
        case .results:
            return nil
        }
    }

    private func chapterSummary(for chapter: StoryChapter) -> String? {
        let trimmed = chapter.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != chapter.text else { return nil }
        return trimmed
    }

    private var emptyQuestionsNotice: some View {
        Text("This chapter is too short for generated questions. You can still finish the chapter.")
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundColor(AppColors.textSecondary)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.94))
            )
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.orange)
            Text(message)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        StorySessionView(
            setup: ReadingSetupViewModel(config: .storyMode).makeSessionSetup(),
            onExitToSetup: {},
            onExitToReading: {}
        )
    }
}
