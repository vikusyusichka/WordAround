import SwiftUI

struct HomeDailyStat: Identifiable {
    let id: HomeCategory
    let title: String
    let value: String
    let label: String
    let iconSystemName: String
}

struct HomeStatCardView: View {
    let stat: HomeDailyStat

    /// On compact layouts the cards double as navigation into each module, so
    /// they show a subtle chevron to communicate they're tappable. On regular
    /// layouts (`false`) they stay pure statistics, exactly as before.
    var isInteractive: Bool = false

    /// Each skill gets its own accent so the Daily Practice row reads as a
    /// lively, colorful set of stats rather than four identical blue boxes.
    private var accent: Color {
        switch stat.id {
        case .speaking:  return AppColors.primaryBlue
        case .listening: return AppColors.createSetPurple
        case .reading:   return AppColors.orangeAccent
        case .writing:   return AppColors.greenAccent
        case .notes:     return AppColors.notesAccent
        }
    }

    private let corner = Layout.homeDailyStatCardCornerRadius

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            iconChip

            Spacer(minLength: 6)

            HStack(alignment: .bottom, spacing: 4) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(stat.value)
                        .font(.system(size: Layout.homeDailyStatValueSize, weight: .bold, design: .rounded))
                        .foregroundColor(accent)
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

                Spacer(minLength: 4)

                if isInteractive {
                    chevronCircle
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(Layout.homeDailyStatCardPadding)
        .frame(height: Layout.homeDailyStatCardHeight)
        // Same layered surface as the dashboard cards below, so Daily
        // Practice and the dashboard read as one design family.
        .homeDashboardSurface(accent: accent, cornerRadius: corner)
    }

    private var iconChip: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.88), accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(
                    width: Layout.homeDailyStatIconCircleSize,
                    height: Layout.homeDailyStatIconCircleSize
                )
                .shadow(color: accent.opacity(0.25), radius: 6, x: 0, y: 3)

            Circle()
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
                .frame(
                    width: Layout.homeDailyStatIconCircleSize,
                    height: Layout.homeDailyStatIconCircleSize
                )

            Image(systemName: stat.iconSystemName)
                .font(.system(size: Layout.homeDailyStatIconSize, weight: .bold))
                .foregroundColor(.white)
        }
    }

    /// Soft accent circle with a chevron — the tap affordance on compact,
    /// echoing the rounded button language used across the app.
    private var chevronCircle: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.12))
                .frame(
                    width: Layout.homeDailyStatChevronCircleSize,
                    height: Layout.homeDailyStatChevronCircleSize
                )

            Image(systemName: "chevron.right")
                .font(.system(size: Layout.homeDailyStatLabelSize, weight: .bold))
                .foregroundColor(accent)
        }
    }
}

struct HomeStatsGridView: View {
    let stats: [HomeDailyStat]

    /// When provided (compact layouts), each stat card becomes a navigation
    /// element into its module. When `nil` (regular layouts) the cards remain
    /// non-interactive statistics, preserving the iPad / Mac experience.
    var onSelect: ((HomeCategory) -> Void)? = nil

    /// 2×2 by default — both on iPhone and inside the iPad dashboard column.
    var columnCount: Int = 2

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: Layout.homeDailyStatGridSpacing),
            count: columnCount
        )
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: Layout.homeDailyStatGridSpacing) {
            ForEach(stats) { stat in
                if let onSelect {
                    Button {
                        onSelect(stat.id)
                    } label: {
                        HomeStatCardView(stat: stat, isInteractive: true)
                    }
                    .buttonStyle(HomeCardPressStyle())
                } else {
                    HomeStatCardView(stat: stat)
                }
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
