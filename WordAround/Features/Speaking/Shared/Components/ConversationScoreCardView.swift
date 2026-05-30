import SwiftUI

struct ConversationScoreCardView: View {
    let score: Int
    let summary: String

    var body: some View {
        HStack(alignment: .center, spacing: Layout.isPadLike ? 28 : 20) {
            scoreCircle

            VStack(alignment: .leading, spacing: 8) {
                Text("Overall Score")
                    .font(.system(
                        size: Layout.isPadLike ? 18 : 16,
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundColor(AppColors.primaryBlueDark)

                Text(summary)
                    .font(.system(
                        size: Layout.isPadLike ? 15 : 13,
                        weight: .medium,
                        design: .rounded
                    ))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(Layout.isPadLike ? 24 : 20)
        .background(Color.white.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.90), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 9)
    }

    private var scoreCircle: some View {
        ZStack {
            Circle()
                .stroke(
                    AppColors.primaryBlue.opacity(0.10),
                    lineWidth: Layout.convResultScoreStrokeWidth
                )

            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(
                    AppColors.primaryBlue,
                    style: StrokeStyle(
                        lineWidth: Layout.convResultScoreStrokeWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(score)%")
                    .font(.system(
                        size: Layout.convResultScoreValueSize,
                        weight: .black,
                        design: .rounded
                    ))
                    .foregroundColor(AppColors.primaryBlueDark)

                Text("score")
                    .font(.system(
                        size: Layout.convResultScoreLabelSize,
                        weight: .semibold,
                        design: .rounded
                    ))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .frame(
            width: Layout.convResultScoreCircleSize,
            height: Layout.convResultScoreCircleSize
        )
    }
}

#Preview {
    ConversationScoreCardView(
        score: 82,
        summary: "Nice work. Your answers were clear and natural."
    )
    .padding(20)
    .background(AppColors.appBackground)
}
