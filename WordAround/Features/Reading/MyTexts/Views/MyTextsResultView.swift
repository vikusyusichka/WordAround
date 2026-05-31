import SwiftUI

struct MyTextsResultView: View {
    let setup: ReadingSessionSetup
    var onExitToSetup: () -> Void
    var onExitToReading: () -> Void

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ReadingResultHeaderView(
                        icon: "doc.text.fill",
                        title: "Practice Complete",
                        subtitle: "Your custom text practice summary.",
                        accent: setup.accent,
                        accentDark: setup.accentDark
                    )

                    ReadingResultSummaryCard(
                        primaryValue: "76%",
                        primaryLabel: "Comprehension",
                        secondaryMetrics: [
                            ("7 / 7", "Answered"),
                            ("3", "Difficult words"),
                            ("420", "Text words")
                        ],
                        accent: setup.accent
                    )

                    ReadingSectionTitle(title: "Words to Review")
                    ForEach(ReadingPlaceholderData.vocabularyItems) { item in
                        ReadingVocabularyReviewCard(
                            word: item.word,
                            translation: item.translation,
                            example: item.example,
                            accent: setup.accent
                        )
                    }

                    ReadingSectionTitle(title: "Text Insights")
                    ForEach(ReadingPlaceholderData.myTextsInsights, id: \.title) { insight in
                        insightCard(title: insight.title, detail: insight.detail)
                    }

                    ReadingSectionTitle(title: "Mistakes")
                    ForEach(ReadingPlaceholderData.mistakes.prefix(1)) { mistake in
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

                    Button("Save Text") {}
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(setup.accentDark)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
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

    private func insightCard(title: String, detail: String) -> some View {
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
    MyTextsResultView(
        setup: ReadingSetupViewModel(config: .myTexts).makeSessionSetup(),
        onExitToSetup: {},
        onExitToReading: {}
    )
}
