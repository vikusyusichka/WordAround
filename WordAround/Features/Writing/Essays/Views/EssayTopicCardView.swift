import SwiftUI

struct EssayTopicCardView: View {
    let topic: EssayTopic
    let onRefresh: () -> Void

    private var chipColumns: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: Layout.essayTipChipMinWidth),
                spacing: 8,
                alignment: .leading
            )
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.essayCardSpacing) {
            HStack(alignment: .top, spacing: 12) {
                levelBadge

                VStack(alignment: .leading, spacing: 5) {
                    Text(topic.title)
                        .font(.system(size: Layout.essayTopicTitleSize, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlueDark)

                    Label("\(topic.estimatedMinutes) min", systemImage: "clock")
                        .font(.system(size: Layout.essayTopicMetaSize, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer(minLength: 10)

                Button(action: onRefresh) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: Layout.essayTopicRefreshIconSize, weight: .semibold))
                        .foregroundColor(AppColors.primaryBlue)
                        .frame(
                            width: Layout.essayTopicRefreshButtonSize,
                            height: Layout.essayTopicRefreshButtonSize
                        )
                        .background(AppColors.primaryBlue.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Task")
                    .font(.system(size: Layout.essayTopicSectionLabelSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlue)

                Text(topic.taskDescription)
                    .font(.system(size: Layout.essayTopicBodySize, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(3)
            }

            HStack(spacing: 8) {
                Image(systemName: "text.word.spacing")
                    .font(.system(size: 13, weight: .semibold))

                Text(topic.wordRangeText)
                    .font(.system(size: Layout.essayTopicMetaSize, weight: .semibold, design: .rounded))
            }
            .foregroundColor(AppColors.primaryBlue)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppColors.primaryBlue.opacity(0.08))
            .clipShape(Capsule())

            LazyVGrid(columns: chipColumns, alignment: .leading, spacing: 8) {
                ForEach(topic.tips, id: \.self) { tip in
                    Text(tip)
                        .font(.system(size: Layout.essayTipChipTextSize, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlueDark)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background(Color(red: 0.93, green: 0.92, blue: 1.00))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(Layout.essayCardPadding)
        .background(Color.white.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: Layout.essayCardCornerRadius, style: .continuous))
        .shadow(
            color: Color.black.opacity(0.055),
            radius: Layout.essayCardShadowRadius,
            x: 0,
            y: Layout.essayCardShadowYOffset
        )
    }

    private var levelBadge: some View {
        Text(topic.level)
            .font(.system(size: Layout.essayTopicLevelBadgeSize, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.52, green: 0.39, blue: 1.00),
                        Color(red: 0.36, green: 0.58, blue: 1.00)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
    }
}

#Preview {
    EssayTopicCardView(topic: .predefined[0], onRefresh: {})
        .padding()
        .background(AppColors.appBackground)
}
