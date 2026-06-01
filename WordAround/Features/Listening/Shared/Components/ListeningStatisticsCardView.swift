import SwiftUI

struct ListeningStatisticsCardView: View {
    let correctAnswers: Int
    let totalQuestions: Int
    let formattedTime: String
    let speedLabel: String
    let mistakeCount: Int
    var accentDark: Color = ListeningTheme.accentDark

    private var metrics: [(value: String, label: String)] {
        [
            ("\(correctAnswers) / \(totalQuestions)", "Correct"),
            (formattedTime, "Listening time"),
            (speedLabel, "Speed"),
            ("\(mistakeCount)", mistakeCount == 1 ? "Mistake" : "Mistakes")
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
                if index > 0 { Divider().frame(height: 36) }
                metricView(value: metric.value, label: metric.label)
            }
        }
    }

    private var metricsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
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
