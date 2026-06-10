import SwiftUI

struct ListeningResultView: View {
    let result: ListeningResult
    let subtitle: String
    let chips: [String]
    var accent: Color = ListeningTheme.accent
    var accentDark: Color = ListeningTheme.accentDark
    let practiceAgainTitle: String
    let backButtonTitle: String
    var secondaryCTATitle: String? = nil
    var secondaryCTAIcon: String = "arrow.right"
    var onSecondaryCTA: (() -> Void)? = nil
    let onPracticeAgain: () -> Void
    let onBack: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var contentMaxWidth: CGFloat {
        horizontalSizeClass == .regular ? Layout.convContentMaxWidth : .infinity
    }

    private var formattedTime: String {
        let minutes = result.listeningTimeSeconds / 60
        let seconds = result.listeningTimeSeconds % 60
        return "\(minutes)m \(seconds)s"
    }

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    resultHeader
                    summaryCard

                    if !result.mistakes.isEmpty {
                        sectionTitle("Mistakes")
                        ForEach(result.mistakes) { mistake in
                            mistakeCard(mistake)
                        }
                    }

                    actions
                }
                .frame(maxWidth: contentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
                .padding(.bottom, Layout.homeBottomSafeSpacing)
            }
        }
        .navigationBarBackButtonHidden(true)
        .tint(accentDark)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var resultHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.14))
                    .frame(width: 64, height: 64)
                Image(systemName: "headphones")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(accent)
            }

            Text(L10n.string("readingPracticeComplete"))
                .font(.system(size: Layout.homeHeaderTitleSize, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)

            Text(subtitle)
                .font(.system(size: Layout.homeHeaderSubtitleSize, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.mutedText)
                .multilineTextAlignment(.center)

            HStack(spacing: 6) {
                ForEach(chips, id: \.self) { chip in
                    ListeningMetadataChip(text: chip, accent: accent)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var summaryCard: some View {
        VStack(spacing: 18) {
            if result.hasQuestions {
                ReadingScoreCardView(comprehensionPercent: result.comprehensionPercent, accent: accent)
                ListeningStatisticsCardView(
                    correctAnswers: result.correctAnswers,
                    totalQuestions: result.totalQuestions,
                    formattedTime: formattedTime,
                    speedLabel: result.speedLabel,
                    mistakeCount: result.mistakeCount,
                    accentDark: accentDark
                )
            } else {
                watchOnlySummary
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
        )
    }

    private var watchOnlySummary: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40, weight: .semibold))
                .foregroundColor(accent)
            Text(L10n.string("listeningCompleted"))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)
            Text(String(format: L10n.string("listeningListenedForFormat"), formattedTime))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
            Text(L10n.string("listeningNoQuestionsScore"))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.mutedText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var actions: some View {
        VStack(spacing: 10) {
            if let secondaryCTATitle, let onSecondaryCTA {
                ListeningPrimaryButton(
                    title: secondaryCTATitle,
                    icon: secondaryCTAIcon,
                    accent: accent,
                    accentDark: accentDark,
                    action: onSecondaryCTA
                )
            }

            ListeningPrimaryButton(
                title: practiceAgainTitle,
                icon: "arrow.clockwise",
                accent: accent,
                accentDark: accentDark,
                action: onPracticeAgain
            )

            Button(action: onBack) {
                Text(backButtonTitle)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(accentDark)
                    .frame(maxWidth: .infinity)
                    .frame(height: Layout.convSetupStartButtonHeight)
                    .background(accent.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: Layout.convSetupStartButtonCornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: Layout.homeSectionTitleSize, weight: .bold, design: .rounded))
            .foregroundColor(accentDark)
    }

    private func mistakeCard(_ mistake: ListeningMistake) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(mistake.prompt)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(accentDark)
            HStack(spacing: 6) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color(red: 0.95, green: 0.42, blue: 0.40))
                Text(mistake.selectedAnswer)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(accent)
                Text(mistake.correctAnswer)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(accent)
            }
            if let explanation = mistake.explanation {
                Text(explanation)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.mutedText)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
        )
    }
}

#Preview {
    ListeningResultView(
        result: ListeningPlaceholderData.sampleResult,
        subtitle: "Listening Practice",
        chips: ["English", "B1", "Listen from Text"],
        practiceAgainTitle: "Practice Again",
        backButtonTitle: "Back to Listening",
        onPracticeAgain: {},
        onBack: {}
    )
}
