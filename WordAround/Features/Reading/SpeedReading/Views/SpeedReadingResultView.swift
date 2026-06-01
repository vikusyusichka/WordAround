import SwiftUI

struct SpeedReadingResultView: View {
    let result: SpeedReadingResult
    let configuration: SpeedReadingConfiguration
    let accent: Color
    let accentDark: Color
    let onTryAgain: () -> Void
    let onBackToLibrary: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
            ReadingResultHeaderView(
                icon: "bolt.fill",
                title: "Speed Session Complete",
                subtitle: "Your pacing and comprehension summary.",
                accent: accent,
                accentDark: accentDark
            )

            SpeedReadingResultCardView(
                result: result,
                configuration: configuration,
                accent: accent,
                accentDark: accentDark
            )

            ReadingScoreCardView(
                comprehensionPercent: result.comprehensionPercentInt,
                accent: accent
            )

            if !result.mistakes.isEmpty {
                ReadingSectionTitle(title: "Comprehension Check")
                ForEach(result.mistakes) { mistake in
                    ReadingMistakeReviewCard(
                        question: mistake.prompt,
                        yourAnswer: mistake.selectedAnswer,
                        correctAnswer: mistake.correctAnswer,
                        accent: accent
                    )
                }
            }

            let feedbackLines = SpeedReadingMetricsService.feedback(
                result: result,
                configuration: configuration
            )
            if !feedbackLines.isEmpty {
                ReadingSectionTitle(title: "Pacing Feedback")
                ForEach(feedbackLines, id: \.self) { line in
                    Text(line)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                                .fill(Color.white.opacity(0.94))
                        )
                }
            }

            ReadingResultActions(
                primaryTitle: "Try Again",
                secondaryTitle: "Back to Library",
                accent: accent,
                accentDark: accentDark,
                onPrimary: onTryAgain,
                onSecondary: onBackToLibrary
            )
        }
    }
}

#Preview {
    let sample = SpeedReadingResult(
        base: ReadingResult(
            sessionId: "s1",
            textId: "t1",
            comprehensionPercent: 78,
            correctAnswers: 4,
            totalQuestions: 5,
            readingTimeSeconds: 305,
            wordsPerMinute: 232,
            mistakes: [
                ReadingMistake(
                    id: "m1",
                    questionId: "q1",
                    prompt: "What is the passage mostly about?",
                    selectedAnswer: "Cycling rules",
                    correctAnswer: "Reading efficiency",
                    explanation: nil
                )
            ]
        ),
        targetWPM: 240,
        timerViolations: 1,
        rating: .balanced
    )
    return ScrollView {
        SpeedReadingResultView(
            result: sample,
            configuration: SpeedReadingConfiguration(target: .balanced, timer: .strict, length: .five),
            accent: ReadingSetupConfig.speedReading.accent,
            accentDark: ReadingSetupConfig.speedReading.accentDark,
            onTryAgain: {},
            onBackToLibrary: {}
        )
        .padding()
    }
    .background(AppColors.appBackground)
}
