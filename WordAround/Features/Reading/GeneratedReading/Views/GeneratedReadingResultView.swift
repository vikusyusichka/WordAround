import SwiftUI

struct GeneratedReadingResultView: View {
    let setup: ReadingSessionSetup
    var onExitToSetup: () -> Void
    var onExitToReading: () -> Void

    private let metrics = ReadingPlaceholderData.generatedResult

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ReadingResultHeaderView(
                        icon: "sparkles",
                        title: "Reading Complete",
                        subtitle: "Great work on your generated reading session.",
                        accent: setup.accent,
                        accentDark: setup.accentDark
                    )

                    ReadingResultSummaryCard(
                        primaryValue: metrics.primaryValue,
                        primaryLabel: metrics.primaryLabel,
                        secondaryMetrics: metrics.secondary,
                        accent: setup.accent
                    )

                    ReadingSectionTitle(title: "Vocabulary Review")
                    ForEach(ReadingPlaceholderData.vocabularyItems) { item in
                        ReadingVocabularyReviewCard(
                            word: item.word,
                            translation: item.translation,
                            example: item.example,
                            accent: setup.accent
                        )
                    }

                    ReadingSectionTitle(title: "Mistakes")
                    ForEach(ReadingPlaceholderData.mistakes) { mistake in
                        ReadingMistakeReviewCard(
                            question: mistake.question,
                            yourAnswer: mistake.yourAnswer,
                            correctAnswer: mistake.correctAnswer,
                            accent: setup.accent
                        )
                    }

                    ReadingResultActions(
                        primaryTitle: "Practice Again",
                        secondaryTitle: "Back to Reading",
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
}

#Preview {
    GeneratedReadingResultView(
        setup: ReadingSetupViewModel(config: .generatedReading).makeSessionSetup(),
        onExitToSetup: {},
        onExitToReading: {}
    )
}
