import SwiftUI

struct EssayTopicCardView: View {
    private let title: String
    private let taskDescription: String
    private let level: String
    private let estimatedMinutes: Int
    private let wordRangeText: String
    private let tips: [String]
    private let isLoading: Bool
    private let errorMessage: String?
    private let onRefresh: () -> Void

    init(
        topic: EssayTopic,
        isLoading: Bool = false,
        errorMessage: String? = nil,
        onRefresh: @escaping () -> Void
    ) {
        self.title = topic.title
        self.taskDescription = topic.taskDescription
        self.level = topic.level
        self.estimatedMinutes = topic.estimatedMinutes
        self.wordRangeText = topic.wordRangeText
        self.tips = topic.tips
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        self.onRefresh = onRefresh
    }

    init(
        task: GeneratedEssayTask,
        isLoading: Bool = false,
        errorMessage: String? = nil,
        onRefresh: @escaping () -> Void
    ) {
        self.title = task.title
        self.taskDescription = task.task
        self.level = task.detectedLevel.rawValue
        self.estimatedMinutes = task.estimatedTimeMinutes
        self.wordRangeText = task.wordRangeText
        self.tips = task.quickTips
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        self.onRefresh = onRefresh
    }

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
                    Text(title)
                        .font(.system(size: Layout.essayTopicTitleSize, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlueDark)

                    Label("\(estimatedMinutes) min", systemImage: "clock")
                        .font(.system(size: Layout.essayTopicMetaSize, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer(minLength: 10)

                Button(action: onRefresh) {
                    Group {
                        if isLoading {
                            ProgressView()
                                .tint(AppColors.primaryBlue)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: Layout.essayTopicRefreshIconSize, weight: .semibold))
                        }
                    }
                    .foregroundColor(AppColors.primaryBlue)
                    .frame(
                        width: Layout.essayTopicRefreshButtonSize,
                        height: Layout.essayTopicRefreshButtonSize
                    )
                    .background(AppColors.primaryBlue.opacity(0.08))
                    .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: Layout.essayTopicMetaSize, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppColors.primaryBlue.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.string("essayTask"))
                    .font(.system(size: Layout.essayTopicSectionLabelSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlue)

                Text(taskDescription)
                    .font(.system(size: Layout.essayTopicBodySize, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(3)
            }

            HStack(spacing: 8) {
                Image(systemName: "text.word.spacing")
                    .font(.system(size: 13, weight: .semibold))

                Text(wordRangeText)
                    .font(.system(size: Layout.essayTopicMetaSize, weight: .semibold, design: .rounded))
            }
            .foregroundColor(AppColors.primaryBlue)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppColors.primaryBlue.opacity(0.08))
            .clipShape(Capsule())

            LazyVGrid(columns: chipColumns, alignment: .leading, spacing: 8) {
                ForEach(tips, id: \.self) { tip in
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
        Text(level)
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

#Preview("Static topic") {
    EssayTopicCardView(topic: .predefined[0], onRefresh: {})
        .padding()
        .background(AppColors.appBackground)
}

#Preview("Generated topic") {
    EssayTopicCardView(
        task: GeneratedEssayTask(
            title: "Learning Languages Online",
            task: "Write about why people learn languages online and give examples from daily life.",
            detectedLevel: .b1,
            estimatedTimeMinutes: 12,
            wordLimitMin: 90,
            wordLimitMax: 150,
            quickTips: ["Use clear examples", "Compare two ideas", "Check verb forms"]
        ),
        onRefresh: {}
    )
    .padding()
    .background(AppColors.appBackground)
}
