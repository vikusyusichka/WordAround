import SwiftUI

struct SpeedReadingResultCardView: View {
    let result: SpeedReadingResult
    let configuration: SpeedReadingConfiguration
    let accent: Color
    let accentDark: Color

    private var formattedReadingTime: String {
        let minutes = result.readingTimeSeconds / 60
        let seconds = result.readingTimeSeconds % 60
        if minutes > 0 { return "\(minutes)m \(seconds)s" }
        return "\(seconds)s"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ratingBadge

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: L10n.string("readingWPMFmt"), result.wordsPerMinute))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(accent)
                    Text(L10n.string("readingAveragePace"))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: L10n.string("readingWPMFmt"), result.targetWPM))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(accentDark)
                    Text(L10n.string("readingTarget"))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Divider().opacity(0.4)

            HStack(spacing: 0) {
                metric(value: formattedReadingTime, label: L10n.string("readingReadingTime"))
                Divider().frame(height: 36).opacity(0.4)
                metric(value: "\(result.comprehensionPercentInt)%", label: L10n.string("readingComprehension"))
                if configuration.timer.penalisesViolations {
                    Divider().frame(height: 36).opacity(0.4)
                    metric(value: "\(result.timerViolations)", label: L10n.string("readingTimerMisses"))
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: accent.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .stroke(accent.opacity(0.14), lineWidth: 1)
        )
    }

    private var ratingBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: result.rating.systemImage)
                .font(.system(size: 13, weight: .bold))
            Text(result.rating.label)
                .font(.system(size: 13, weight: .bold, design: .rounded))
        }
        .foregroundColor(accent)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(accent.opacity(0.12))
        .clipShape(Capsule())
    }

    private func metric(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
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
            mistakes: []
        ),
        targetWPM: 240,
        timerViolations: 1,
        rating: .balanced
    )
    return SpeedReadingResultCardView(
        result: sample,
        configuration: SpeedReadingConfiguration(target: .balanced, timer: .strict, length: .five),
        accent: ReadingSetupConfig.speedReading.accent,
        accentDark: ReadingSetupConfig.speedReading.accentDark
    )
    .padding()
    .background(AppColors.appBackground)
}
