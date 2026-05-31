import SwiftUI

struct SpeedReadingResultView: View {
    let setup: ReadingSessionSetup
    var onExitToSetup: () -> Void
    var onExitToReading: () -> Void

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ReadingResultHeaderView(
                        icon: "bolt.fill",
                        title: "Speed Session Complete",
                        subtitle: "Your pacing and comprehension summary.",
                        accent: setup.accent,
                        accentDark: setup.accentDark
                    )

                    ReadingResultSummaryCard(
                        primaryValue: "232 WPM",
                        primaryLabel: "Average pace",
                        secondaryMetrics: [
                            ("240 WPM", "Target"),
                            ("78%", "Comprehension"),
                            ("5 min", "Time spent")
                        ],
                        accent: setup.accent
                    )

                    ReadingSectionTitle(title: "Comprehension Check")
                    ForEach(Array(ReadingPlaceholderData.speedComprehensionResults.enumerated()), id: \.offset) { _, item in
                        HStack {
                            Text(item.question)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(AppColors.primaryBlueDark)
                            Spacer()
                            Image(systemName: item.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(item.correct ? setup.accent : Color(red: 0.95, green: 0.42, blue: 0.40))
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                                .fill(Color.white.opacity(0.94))
                        )
                    }

                    ReadingSectionTitle(title: "Pacing Feedback")
                    ForEach(ReadingPlaceholderData.pacingFeedback, id: \.self) { feedback in
                        Text(feedback)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                                    .fill(Color.white.opacity(0.94))
                            )
                    }

                    ReadingResultActions(
                        primaryTitle: "Try Again",
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
    SpeedReadingResultView(
        setup: ReadingSetupViewModel(config: .speedReading).makeSessionSetup(),
        onExitToSetup: {},
        onExitToReading: {}
    )
}
