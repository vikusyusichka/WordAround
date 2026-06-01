import SwiftUI

struct ReadingStatisticsCardView: View {
    let correctAnswers: Int
    let totalQuestions: Int
    let formattedTime: String
    let wordsPerMinute: Int
    let mistakeCount: Int
    let accentDark: Color

    private var metrics: [(value: String, label: String)] {
        [
            ("\(correctAnswers) / \(totalQuestions)", "Correct"),
            (formattedTime, "Reading time"),
            ("\(wordsPerMinute)", "WPM"),
            ("\(mistakeCount)", "Mistakes")
        ]
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            metricsRow
            metricsGrid
        }
    }

    private var metricsRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(metrics.enumerated()), id: \.offset) { index, metric in
                if index > 0 {
                    Divider().frame(height: 36)
                }
                metricView(value: metric.value, label: metric.label)
            }
        }
    }

    private var metricsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 14
        ) {
            ForEach(Array(metrics.enumerated()), id: \.offset) { _, metric in
                metricView(value: metric.value, label: metric.label)
            }
        }
    }

    private func metricView(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
