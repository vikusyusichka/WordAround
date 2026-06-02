import SwiftUI

/// One day's practice metric for a single learning section, shown in the Home
/// dashboard grid. Values are produced by `HomeViewModel` from the real
/// `DailyPracticeStatsService` / listening session store — they are never
/// hardcoded outside of previews.
struct HomeDailyStat: Identifiable {
    /// Reuses the learning-section identity so the card maps 1:1 to a section.
    let id: HomeCategory
    let title: String
    let value: String
    let label: String
    let iconSystemName: String
}

/// White, blue-accented stat card. No gradients: a soft blue icon chip and a
/// subtle shadow keep it aligned with the rest of the WordAround card style.
struct HomeStatCardView: View {
    let stat: HomeDailyStat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            iconChip

            Spacer(minLength: 8)

            Text(stat.value)
                .font(.system(size: Layout.homeDailyStatValueSize, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(stat.title)
                .font(.system(size: Layout.homeDailyStatTitleSize, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(stat.label)
                .font(.system(size: Layout.homeDailyStatLabelSize, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(Layout.homeDailyStatCardPadding)
        .frame(height: Layout.homeDailyStatCardHeight)
        .background(
            RoundedRectangle(cornerRadius: Layout.homeDailyStatCardCornerRadius, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Layout.homeDailyStatCardCornerRadius, style: .continuous)
                .stroke(AppColors.primaryBlue.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
    }

    private var iconChip: some View {
        ZStack {
            Circle()
                .fill(AppColors.primaryBlue.opacity(0.12))
                .frame(
                    width: Layout.homeDailyStatIconCircleSize,
                    height: Layout.homeDailyStatIconCircleSize
                )

            Image(systemName: stat.iconSystemName)
                .font(.system(size: Layout.homeDailyStatIconSize, weight: .semibold))
                .foregroundColor(AppColors.primaryBlue)
        }
    }
}

/// Adaptive grid of daily-practice stat cards.
/// - iPhone → 2×2
/// - iPad / Mac → one row of four
/// Cards are equal width (flexible columns) and equal height (fixed height).
struct HomeStatsGridView: View {
    let stats: [HomeDailyStat]

    private var columns: [GridItem] {
        let count = Layout.isPadLike ? 4 : 2
        return Array(
            repeating: GridItem(.flexible(), spacing: Layout.homeDailyStatGridSpacing),
            count: count
        )
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: Layout.homeDailyStatGridSpacing) {
            ForEach(stats) { stat in
                HomeStatCardView(stat: stat)
            }
        }
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()

        HomeStatsGridView(stats: [
            HomeDailyStat(id: .speaking, title: "Speaking", value: "12", label: "minutes", iconSystemName: HomeCategory.speaking.icon),
            HomeDailyStat(id: .listening, title: "Listening", value: "8", label: "minutes", iconSystemName: HomeCategory.listening.icon),
            HomeDailyStat(id: .reading, title: "Reading", value: "15", label: "minutes", iconSystemName: HomeCategory.reading.icon),
            HomeDailyStat(id: .writing, title: "Writing", value: "240", label: "words", iconSystemName: HomeCategory.writing.icon)
        ])
        .padding()
    }
}
