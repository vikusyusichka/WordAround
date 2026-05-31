import SwiftUI

struct ReadingFromSetsSessionView: View {
    let setup: ReadingSessionSetup
    var onExitToSetup: () -> Void
    var onExitToReading: () -> Void

    @StateObject private var viewModel: ReadingFromSetsSessionViewModel
    @State private var showResult = false

    init(setup: ReadingSessionSetup, onExitToSetup: @escaping () -> Void, onExitToReading: @escaping () -> Void) {
        self.setup = setup
        self.onExitToSetup = onExitToSetup
        self.onExitToReading = onExitToReading
        _viewModel = StateObject(wrappedValue: ReadingFromSetsSessionViewModel(setup: setup))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ReadingSessionHeaderView(
                        title: "Reading From Set",
                        subtitle: "\(viewModel.setName) • \(viewModel.styleLabel)",
                        progressText: viewModel.progressText,
                        trailingText: viewModel.questionProgress,
                        accent: setup.accent,
                        accentDark: setup.accentDark,
                        onBack: onExitToSetup
                    )

                    ReadingTextCardView(
                        bodyText: ReadingPlaceholderData.setPreviewText,
                        highlightedWords: ReadingPlaceholderData.setHighlightedWords,
                        highlightColor: setup.accent,
                        legend: "Highlighted = from your set",
                        accent: setup.accent
                    )

                    vocabularyFocusPanel

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
                leadingTitle: nil,
                centerTitle: viewModel.isLastQuestion ? "Finish" : "Next",
                trailingTitle: "Check",
                accent: setup.accent,
                accentDark: setup.accentDark,
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
            ReadingFromSetsResultView(
                setup: setup,
                onExitToSetup: onExitToSetup,
                onExitToReading: onExitToReading
            )
        }
    }

    private var vocabularyFocusPanel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ReadingPlaceholderData.setWords.prefix(3)) { word in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(word.word)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(setup.accentDark)
                        Text(word.translation)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(setup.accent)
                        Text(word.example)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(2)
                    }
                    .padding(12)
                    .frame(width: 200, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                            .fill(Color.white.opacity(0.94))
                    )
                }
            }
        }
    }

    private func optionLabel(_ index: Int) -> String {
        ["A", "B", "C", "D"][min(index, 3)]
    }
}

#Preview {
    NavigationStack {
        ReadingFromSetsSessionView(
            setup: ReadingSetupViewModel(config: .readingFromSets).makeSessionSetup(),
            onExitToSetup: {},
            onExitToReading: {}
        )
    }
}
