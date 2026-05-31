import SwiftUI

struct ReadingSessionView: View {
    let userText: ReadingUserText
    var onExitToLibrary: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var generation = 0

    var body: some View {
        ReadingSessionContentView(
            userText: userText,
            onExit: { dismiss() },
            onExitToLibrary: onExitToLibrary,
            onRestart: { generation += 1 }
        )
        .id(generation)
    }
}

// MARK: - Session content

private struct ReadingSessionContentView: View {
    let userText: ReadingUserText
    let onExit: () -> Void
    let onExitToLibrary: () -> Void
    let onRestart: () -> Void

    @StateObject private var viewModel: ReadingSessionViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var accent: Color { ReadingMyTextsTheme.sessionAccent(for: userText) }
    private var accentDark: Color { ReadingMyTextsTheme.sessionAccentDark(for: userText) }

    init(
        userText: ReadingUserText,
        onExit: @escaping () -> Void,
        onExitToLibrary: @escaping () -> Void,
        onRestart: @escaping () -> Void
    ) {
        self.userText = userText
        self.onExit = onExit
        self.onExitToLibrary = onExitToLibrary
        self.onRestart = onRestart
        _viewModel = StateObject(wrappedValue: ReadingSessionViewModel(userText: userText))
    }

    private var contentMaxWidth: CGFloat {
        horizontalSizeClass == .regular ? Layout.convContentMaxWidth : .infinity
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            if viewModel.isLoadingSession {
                ProgressView("Preparing session…")
                    .tint(accent)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                        ReadingSetupHeaderView(
                            title: viewModel.session?.title ?? userText.title,
                            subtitle: sessionSubtitle,
                            accent: accent,
                            accentDark: accentDark,
                            trailingIcon: sessionTrailingIcon,
                            trailingText: sessionTrailingText,
                            onBack: {
                                viewModel.onDisappear()
                                onExit()
                            }
                        )

                        if let content = viewModel.session?.content {
                            ReadingReadingToolbarView(
                                content: content,
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

                        if viewModel.currentPhase == .questions, let question = viewModel.currentQuestion {
                            ReadingQuestionSectionView(
                                question: question,
                                showVocabularyHints: viewModel.assistance.vocabularyHints,
                                selectedAnswer: viewModel.selectedAnswer,
                                accent: accent,
                                accentDark: accentDark,
                                onSelect: { viewModel.selectAnswer($0) }
                            )
                        } else if viewModel.currentPhase == .reading && !viewModel.hasQuestions {
                            emptyQuestionsNotice
                        }

                        Spacer().frame(height: Layout.convSetupStartButtonHeight + 24)
                    }
                    .frame(maxWidth: contentMaxWidth)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, Layout.homeHorizontalPadding)
                    .padding(.top, Layout.homeTopSpacing)
                    .padding(.bottom, Layout.homeBottomSafeSpacing)
                }

                bottomBar
                    .frame(maxWidth: contentMaxWidth)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, Layout.homeHorizontalPadding)
                    .padding(.bottom, Layout.homeBottomBarBottomPadding)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.loadSession() }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .navigationDestination(isPresented: $viewModel.navigateToResult) {
            if let result = viewModel.result {
                ReadingResultView(
                    result: result,
                    title: viewModel.session?.title ?? userText.title,
                    levelTitle: userText.levelTitle,
                    focusTitle: userText.focusTitle,
                    accent: accent,
                    accentDark: accentDark,
                    onReadAgain: {
                        viewModel.navigateToResult = false
                        onRestart()
                    },
                    onBackToLibrary: {
                        viewModel.navigateToResult = false
                        viewModel.onDisappear()
                        onExitToLibrary()
                    }
                )
            }
        }
    }

    private var sessionSubtitle: String {
        "\(userText.language.title) • \(userText.level.title) • \(userText.focusTitle) • ~\(userText.estimatedReadingMinutes) min"
    }

    private var sessionTrailingIcon: String? {
        switch viewModel.currentPhase {
        case .reading where viewModel.showTimer:
            return "clock.fill"
        default:
            return nil
        }
    }

    private var sessionTrailingText: String? {
        switch viewModel.currentPhase {
        case .reading:
            return viewModel.showTimer ? viewModel.formattedTime : nil
        case .questions:
            guard viewModel.hasQuestions else { return nil }
            return viewModel.progressText
        case .completed:
            return nil
        }
    }

    private var emptyQuestionsNotice: some View {
        Text("This text is too short for generated questions. You can still finish the reading session.")
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundColor(AppColors.textSecondary)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.94))
            )
    }

    @ViewBuilder
    private var bottomBar: some View {
        switch viewModel.currentPhase {
        case .reading:
            ReadingPrimaryButton(
                title: viewModel.hasQuestions ? "Start Questions" : "Finish",
                icon: viewModel.hasQuestions ? "questionmark.circle.fill" : "checkmark",
                accent: accent,
                accentDark: accentDark
            ) {
                if viewModel.hasQuestions {
                    viewModel.startQuestions()
                } else {
                    viewModel.finishSession()
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
                    viewModel.finishSession()
                } else {
                    viewModel.goToNextQuestion()
                }
            }
            .opacity(viewModel.selectedAnswer == nil ? 0.55 : 1)
            .disabled(viewModel.selectedAnswer == nil)
        case .completed:
            EmptyView()
        }
    }
}

#Preview {
    NavigationStack {
        ReadingSessionView(userText: ReadingMyTextsPreviewData.mediumText)
    }
}
