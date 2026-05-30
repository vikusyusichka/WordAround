import SwiftUI

struct ConversationMetricCardView: View {
    let metric: ConversationMetric

    var body: some View {
        let corner = Layout.convResultMetricCornerRadius

        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(Color.white)

            StatBlobShape()
                .fill(metric.blobColor.opacity(0.65))
                .frame(width: 60, height: 48)
                .offset(x: 12, y: 10)

            HStack(alignment: .top, spacing: Layout.isPadLike ? 14 : 12) {
                ZStack {
                    Circle()
                        .fill(metric.accentColor.opacity(0.12))
                        .frame(
                            width: Layout.convResultMetricIconCircleSize,
                            height: Layout.convResultMetricIconCircleSize
                        )

                    Image(systemName: metric.icon)
                        .font(.system(
                            size: Layout.convResultMetricIconSize,
                            weight: .semibold
                        ))
                        .foregroundColor(metric.accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(metric.title)
                        .font(.system(
                            size: Layout.convResultMetricTitleSize,
                            weight: .bold,
                            design: .rounded
                        ))
                        .foregroundColor(AppColors.primaryBlueDark)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Text(metric.rating)
                        .font(.system(
                            size: Layout.convResultMetricRatingSize,
                            weight: .semibold,
                            design: .rounded
                        ))
                        .foregroundColor(metric.accentColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if metric.score > 0 {
                    Text("\(metric.score)%")
                        .font(.system(
                            size: Layout.isPadLike ? 22 : 20,
                            weight: .heavy,
                            design: .rounded
                        ))
                        .foregroundColor(metric.accentColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .fixedSize(horizontal: true, vertical: false)
                        .accessibilityLabel("\(metric.title) score \(metric.score) percent")
                }
            }
            .padding(Layout.convResultMetricPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(Color.white.opacity(0.90), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
        ForEach(ConversationMetric.placeholderMetrics) { metric in
            ConversationMetricCardView(metric: metric)
        }
    }
    .padding(20)
    .background(AppColors.appBackground)
}
