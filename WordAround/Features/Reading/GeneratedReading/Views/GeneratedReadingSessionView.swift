import SwiftUI

struct GeneratedReadingSessionView: View {
    let setup: ReadingSessionSetup
    var onExitToSetup: () -> Void
    var onExitToReading: () -> Void

    @StateObject private var viewModel: GeneratedReadingSessionViewModel
    @State private var showResult = false

    init(setup: ReadingSessionSetup, onExitToSetup: @escaping () -> Void, onExitToReading: @escaping () -> Void) {
        self.setup = setup
        self.onExitToSetup = onExitToSetup
        self.onExitToReading = onExitToReading
        _viewModel = StateObject(wrappedValue: GeneratedReadingSessionViewModel(setup: setup))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ReadingSessionHeaderView(
                        title: "Generated Reading",
                        subtitle: viewModel.sessionSubtitle,
                        progressText: viewModel.progressText,
                        accent: setup.accent,
                        accentDark: setup.accentDark,
                        onBack: onExitToSetup
                    )

                    ReadingProgressBar(
                        progress: Double(viewModel.currentQuestionIndex + 1) / Double(viewModel.questions.count),
                        accent: setup.accent
                    )

                    ReadingTextCardView(
                        title: ReadingPlaceholderData.articleTitle,
                        bodyText: ReadingPlaceholderData.articleBody,
                        highlightedWords: ReadingPlaceholderData.highlightedWords,
                        highlightColor: setup.accent,
                        helperButtons: ["Translate", "Vocabulary", "Read aloud"],
                        accent: setup.accent
                    )

                    ReadingQuestionCardView(
                        title: viewModel.currentQuestion.title,
                        question: viewModel.currentQuestion.prompt,
                        accent: setup.accent
                    )

                    VStack(spacing: 10) {
                        ForEach(Array(viewModel.currentQuestion.options.enumerated()), id: \.offset) { index, option in
                            ReadingAnswerOptionCard(
                                label: optionLabel(index),
                                text: option,
                                isSelected: viewModel.selectedAnswerIndex == index,
                                accent: setup.accent
                            ) {
                                viewModel.selectAnswer(index)
                            }
                        }
                    }

                    Spacer().frame(height: Layout.convSetupStartButtonHeight + 24)
                }
                .frame(maxWidth: Layout.convContentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
                .padding(.bottom, Layout.homeBottomSafeSpacing)
            }

            ReadingBottomActionBar(
                leadingTitle: viewModel.currentQuestionIndex > 0 ? "Previous" : nil,
                centerTitle: viewModel.isLastQuestion ? "Finish Reading" : "Next",
                trailingTitle: "Check Answer",
                accent: setup.accent,
                accentDark: setup.accentDark,
                onLeading: viewModel.currentQuestionIndex > 0 ? { viewModel.goBack() } : nil,
                onCenter: {
                    if viewModel.isLastQuestion {
                        showResult = true
                    } else {
                        viewModel.goNext()
                    }
                },
                onTrailing: {}
            )
            .frame(maxWidth: Layout.convContentMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Layout.homeHorizontalPadding)
            .padding(.bottom, Layout.homeBottomBarBottomPadding)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showResult) {
            GeneratedReadingResultView(
                setup: setup,
                onExitToSetup: onExitToSetup,
                onExitToReading: onExitToReading
            )
        }
    }

    private func optionLabel(_ index: Int) -> String {
        ["A", "B", "C", "D"][min(index, 3)]
    }
}

#Preview {
    NavigationStack {
        GeneratedReadingSessionView(
            setup: ReadingSetupViewModel(config: .generatedReading).makeSessionSetup(),
            onExitToSetup: {},
            onExitToReading: {}
        )
    }
}
