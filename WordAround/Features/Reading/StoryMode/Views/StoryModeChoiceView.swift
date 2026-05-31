import SwiftUI

struct StoryModeChoiceView: View {
    let setup: ReadingSessionSetup
    @ObservedObject var viewModel: StoryModeSessionViewModel
    var onExitToSetup: () -> Void
    var onExitToReading: () -> Void

    @State private var showResult = false

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ReadingSessionHeaderView(
                        title: "Choose What Happens Next",
                        subtitle: "Your choice shapes the story.",
                        accent: setup.accent,
                        accentDark: setup.accentDark,
                        onBack: onExitToSetup
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Story recap")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(setup.accent)
                        Text(ReadingPlaceholderData.storyRecap)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.primaryBlueDark)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                            .fill(Color.white.opacity(0.94))
                    )

                    ForEach(Array(ReadingPlaceholderData.storyChoices.enumerated()), id: \.offset) { index, choice in
                        ReadingChoiceCard(
                            icon: choice.icon,
                            title: choice.title,
                            hint: choice.hint,
                            isSelected: viewModel.selectedChoiceIndex == index,
                            accent: setup.accent
                        ) {
                            viewModel.selectChoice(index)
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
                title: "Continue",
                icon: "arrow.right",
                accent: setup.accent,
                accentDark: setup.accentDark
            ) {
                showResult = true
            }
            .frame(maxWidth: Layout.convContentMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Layout.homeHorizontalPadding)
            .padding(.bottom, Layout.homeBottomBarBottomPadding)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showResult) {
            StoryModeResultView(
                setup: setup,
                choiceTitle: selectedChoiceTitle,
                onExitToSetup: onExitToSetup,
                onExitToReading: onExitToReading
            )
        }
    }

    private var selectedChoiceTitle: String {
        guard let index = viewModel.selectedChoiceIndex else {
            return ReadingPlaceholderData.storyChoices[0].title
        }
        return ReadingPlaceholderData.storyChoices[index].title
    }
}

#Preview {
    NavigationStack {
        StoryModeChoiceView(
            setup: ReadingSetupViewModel(config: .storyMode).makeSessionSetup(),
            viewModel: StoryModeSessionViewModel(setup: ReadingSetupViewModel(config: .storyMode).makeSessionSetup()),
            onExitToSetup: {},
            onExitToReading: {}
        )
    }
}
