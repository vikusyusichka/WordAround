import SwiftUI

struct InteractiveReadingResultView: View {
    let setup: ReadingSessionSetup
    var onExitToSetup: () -> Void
    var onExitToReading: () -> Void

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ReadingResultHeaderView(
                        icon: "hand.tap.fill",
                        title: "Interactive Reading Complete",
                        subtitle: "You explored the text through taps and tasks.",
                        accent: setup.accent,
                        accentDark: setup.accentDark
                    )

                    ReadingResultSummaryCard(
                        primaryValue: "15",
                        primaryLabel: "Interactions completed",
                        secondaryMetrics: [
                            ("11 / 13", "Correct"),
                            ("6", "Tapped words"),
                            ("4", "New vocabulary")
                        ],
                        accent: setup.accent
                    )

                    ReadingSectionTitle(title: "Words You Explored")
                    ForEach(ReadingPlaceholderData.vocabularyItems) { item in
                        ReadingVocabularyReviewCard(
                            word: item.word,
                            translation: item.translation,
                            example: item.example,
                            accent: setup.accent
                        )
                    }

                    ReadingSectionTitle(title: "Tasks Summary")
                    taskSummaryCard("Choose paths", detail: "3 completed")
                    taskSummaryCard("Tap words", detail: "6 explored")
                    taskSummaryCard("Solve tasks", detail: "4 answered")

                    ReadingResultActions(
                        primaryTitle: "Start Another",
                        secondaryTitle: "Back to Reading",
                        primaryIcon: "arrow.clockwise",
                        accent: setup.accent,
                        accentDark: setup.accentDark,
                        onPrimary: onExitToSetup,
                        onSecondary: onExitToReading
                    )
                }
                .frame(maxWidth: Layout.convContentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
                .padding(.bottom, Layout.homeBottomSafeSpacing)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func taskSummaryCard(_ title: String, detail: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
            Spacer()
            Text(detail)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(setup.accent)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
        )
    }
}

#Preview {
    InteractiveReadingResultView(
        setup: ReadingSetupViewModel(config: .interactiveReading).makeSessionSetup(),
        onExitToSetup: {},
        onExitToReading: {}
    )
}
