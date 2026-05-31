import SwiftUI

struct StoryModeResultView: View {
    let setup: ReadingSessionSetup
    let choiceTitle: String
    var onExitToSetup: () -> Void
    var onExitToReading: () -> Void

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ReadingResultHeaderView(
                        icon: "books.vertical.fill",
                        title: "Chapter Complete",
                        subtitle: "Chapter 1 finished with your chosen path.",
                        accent: setup.accent,
                        accentDark: setup.accentDark
                    )

                    ReadingResultSummaryCard(
                        primaryValue: "88%",
                        primaryLabel: "Comprehension",
                        secondaryMetrics: [
                            ("Chapter 1", "Completed"),
                            ("1", "Choice made"),
                            ("380", "Words read")
                        ],
                        accent: setup.accent
                    )

                    ReadingSectionTitle(title: "Story Vocabulary")
                    ForEach(ReadingPlaceholderData.vocabularyItems.prefix(2)) { item in
                        ReadingVocabularyReviewCard(
                            word: item.word,
                            translation: item.translation,
                            example: item.example,
                            accent: setup.accent
                        )
                    }

                    ReadingSectionTitle(title: "Your Path")
                    timelineCard(chapter: "Chapter 1", choice: choiceTitle, result: "The trail grows quieter as Elena moves forward.")

                    ReadingResultActions(
                        primaryTitle: "Continue to Chapter 2",
                        secondaryTitle: "Back to Reading",
                        primaryIcon: "book.fill",
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

    private func timelineCard(chapter: String, choice: String, result: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(chapter)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(setup.accentDark)
            Text("Choice: \(choice)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
            Text(result)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                .stroke(setup.accent.opacity(0.14), lineWidth: 1)
        )
    }
}

#Preview {
    StoryModeResultView(
        setup: ReadingSetupViewModel(config: .storyMode).makeSessionSetup(),
        choiceTitle: "Follow the map",
        onExitToSetup: {},
        onExitToReading: {}
    )
}
