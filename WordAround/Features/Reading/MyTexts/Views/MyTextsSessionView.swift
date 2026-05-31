import SwiftUI

struct MyTextsSessionView: View {
    let setup: ReadingSessionSetup
    @ObservedObject var viewModel: MyTextsSessionViewModel
    var onExitToSetup: () -> Void
    var onExitToReading: () -> Void

    @State private var showResult = false

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ReadingSessionHeaderView(
                        title: "My Text Practice",
                        subtitle: viewModel.sessionSubtitle,
                        progressText: viewModel.progressText,
                        accent: setup.accent,
                        accentDark: setup.accentDark,
                        onBack: onExitToSetup
                    )

                    ReadingTextCardView(
                        bodyText: viewModel.editorText.isEmpty ? ReadingPlaceholderData.articleBody : viewModel.editorText,
                        highlightedWords: ReadingPlaceholderData.highlightedWords,
                        highlightColor: setup.accent,
                        accent: setup.accent
                    )

                    ReadingQuestionCardView(
                        title: viewModel.currentQuestion.title,
                        question: viewModel.currentQuestion.prompt,
                        showsFindInText: viewModel.currentQuestion.showsFindInText,
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
                trailingTitle: "Check Answer",
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
            MyTextsResultView(
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
        MyTextsSessionView(
            setup: ReadingSetupViewModel(config: .myTexts).makeSessionSetup(),
            viewModel: MyTextsSessionViewModel(setup: ReadingSetupViewModel(config: .myTexts).makeSessionSetup()),
            onExitToSetup: {},
            onExitToReading: {}
        )
    }
}
