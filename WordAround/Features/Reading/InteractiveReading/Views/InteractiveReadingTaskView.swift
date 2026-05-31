import SwiftUI

struct InteractiveReadingTaskView: View {
    let setup: ReadingSessionSetup
    @ObservedObject var viewModel: InteractiveReadingSessionViewModel
    var onExitToSetup: () -> Void
    var onExitToReading: () -> Void

    @State private var showResult = false

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ReadingSessionHeaderView(
                        title: "Interactive Tasks",
                        subtitle: "Complete mixed interaction challenges.",
                        accent: setup.accent,
                        accentDark: setup.accentDark,
                        onBack: onExitToSetup
                    )

                    ForEach(Array(ReadingPlaceholderData.interactiveTasks.enumerated()), id: \.offset) { index, task in
                        taskSection(index: index, task: task)
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
                centerTitle: "Next",
                trailingTitle: "Check",
                accent: setup.accent,
                accentDark: setup.accentDark,
                onCenter: { showResult = true },
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
            InteractiveReadingResultView(
                setup: setup,
                onExitToSetup: onExitToSetup,
                onExitToReading: onExitToReading
            )
        }
    }

    @ViewBuilder
    private func taskSection(index: Int, task: (title: String, prompt: String, options: [String])) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ReadingQuestionCardView(
                title: task.title,
                question: task.prompt,
                accent: setup.accent
            )

            if index == 1 {
                HStack(spacing: 8) {
                    ForEach(task.options, id: \.self) { word in
                        ReadingWordChip(
                            word: word,
                            isSelected: viewModel.selectedWord == word,
                            accent: setup.accent
                        ) {
                            viewModel.selectWord(word)
                        }
                    }
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(task.options.enumerated()), id: \.offset) { optionIndex, option in
                        ReadingAnswerOptionCard(
                            label: optionLabel(optionIndex),
                            text: option,
                            isSelected: viewModel.selectedTaskAnswerIndex == optionIndex,
                            accent: setup.accent
                        ) {
                            viewModel.selectTaskAnswer(optionIndex)
                        }
                    }
                }
            }
        }
    }

    private func optionLabel(_ index: Int) -> String {
        ["A", "B", "C"][min(index, 2)]
    }
}

#Preview {
    NavigationStack {
        InteractiveReadingTaskView(
            setup: ReadingSetupViewModel(config: .interactiveReading).makeSessionSetup(),
            viewModel: InteractiveReadingSessionViewModel(setup: ReadingSetupViewModel(config: .interactiveReading).makeSessionSetup()),
            onExitToSetup: {},
            onExitToReading: {}
        )
    }
}
