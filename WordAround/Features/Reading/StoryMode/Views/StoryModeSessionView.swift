import SwiftUI

struct StoryModeSessionView: View {
    let setup: ReadingSessionSetup
    var onExitToSetup: () -> Void
    var onExitToReading: () -> Void

    @StateObject private var viewModel: StoryModeSessionViewModel
    @State private var showChoice = false

    init(setup: ReadingSessionSetup, onExitToSetup: @escaping () -> Void, onExitToReading: @escaping () -> Void) {
        self.setup = setup
        self.onExitToSetup = onExitToSetup
        self.onExitToReading = onExitToReading
        _viewModel = StateObject(wrappedValue: StoryModeSessionViewModel(setup: setup))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ReadingSessionHeaderView(
                        title: "Story Mode",
                        subtitle: "\(viewModel.storyType) • \(viewModel.chapterTitle)",
                        progressText: viewModel.chapterProgress,
                        accent: setup.accent,
                        accentDark: setup.accentDark,
                        onBack: onExitToSetup
                    )

                    ReadingSessionTextCardView(
                        title: ReadingPlaceholderData.storyChapterTitle,
                        bodyText: ReadingPlaceholderData.storyText,
                        highlightedWords: ["map", "stranger", "trouble"],
                        highlightColor: setup.accent,
                        accent: setup.accent
                    )

                    ReadingQuestionCardView(
                        title: "Mini comprehension check",
                        question: viewModel.miniQuestion,
                        accent: setup.accent
                    )

                    VStack(spacing: 10) {
                        ForEach(Array(viewModel.miniOptions.enumerated()), id: \.offset) { index, option in
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

            ReadingContinueButton(
                title: "Continue Story",
                icon: "book.fill",
                accent: setup.accent,
                accentDark: setup.accentDark
            ) {
                showChoice = true
            }
            .frame(maxWidth: Layout.convContentMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Layout.homeHorizontalPadding)
            .padding(.bottom, Layout.homeBottomBarBottomPadding)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showChoice) {
            StoryModeChoiceView(
                setup: setup,
                viewModel: viewModel,
                onExitToSetup: onExitToSetup,
                onExitToReading: onExitToReading
            )
        }
    }

    private func optionLabel(_ index: Int) -> String {
        ["A", "B", "C"][min(index, 2)]
    }
}

#Preview {
    NavigationStack {
        StoryModeSessionView(
            setup: ReadingSetupViewModel(config: .storyMode).makeSessionSetup(),
            onExitToSetup: {},
            onExitToReading: {}
        )
    }
}
