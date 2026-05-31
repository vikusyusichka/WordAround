import SwiftUI

/// Result summary after completing a My Texts reading session.
struct ReadingResultView: View {
    let result: ReadingResult
    let title: String
    let onReadAgain: () -> Void
    let onBackToLibrary: () -> Void

    private let accent = ReadingSetupConfig.myTexts.accent
    private let accentDark = ReadingSetupConfig.myTexts.accentDark

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

    private var resultHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.14))
                    .frame(width: 64, height: 64)
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(accent)
            }

            Text("Practice Complete")
                .font(.system(size: Layout.homeHeaderTitleSize, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)

            Text(title)
                .font(.system(size: Layout.homeHeaderSubtitleSize, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.mutedText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var summaryCard: some View {
        VStack(spacing: 18) {
            VStack(spacing: 4) {
                Text("\(result.comprehensionPercentInt)%")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
                Text("Comprehension")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }

            HStack(spacing: 0) {
                metric(value: "\(result.correctAnswers) / \(result.totalQuestions)", label: "Correct")
                Divider().frame(height: 36)
                metric(value: formattedTime, label: "Reading time")
                Divider().frame(height: 36)
                metric(value: "\(result.wordsPerMinute)", label: "WPM")
                Divider().frame(height: 36)
                metric(value: "\(result.mistakes.count)", label: "Mistakes")
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

    private var actions: some View {
        VStack(spacing: 10) {
            ReadingPrimaryButton(
                title: "Read again",
                icon: "arrow.clockwise",
                accent: accent,
                accentDark: accentDark,
                action: onReadAgain
            )

            Button(action: onBackToLibrary) {
                Text("Back to My Texts")
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

    private func metric(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func mistakeCard(_ mistake: ReadingMistake) -> some View {
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

    private var formattedTime: String {
        let minutes = result.readingTimeSeconds / 60
        let seconds = result.readingTimeSeconds % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}

#Preview {
    ReadingResultView(
        result: ReadingResult(
            sessionId: "s1",
            textId: "t1",
            comprehensionPercent: 80,
            correctAnswers: 4,
            totalQuestions: 5,
            readingTimeSeconds: 125,
            wordsPerMinute: 142,
            mistakes: []
        ),
        title: ReadingMyTextsPreviewData.mediumText.title,
        onReadAgain: {},
        onBackToLibrary: {}
    )
}
