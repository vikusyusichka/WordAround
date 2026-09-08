import SwiftUI

/// Compact streak card: flame chip, "N day streak" + encouragement, and a
/// 7-day dot trail (rightmost dot = today). Since the streak is consecutive
/// days ending today, filling the trailing `min(days, 7)` dots is honest data.
struct HomeStreakCard: View {
    let state: HomeStreakState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                leadingIcon

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: Layout.homeDashboardTitleSize, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlueDark)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(subtitle)
                        .font(.system(size: Layout.homeDashboardSubtitleSize, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    dotTrail
                        .padding(.top, 2)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: Layout.homeDashboardChevronSize, weight: .bold))
                    .foregroundColor(surfaceAccent.opacity(0.55))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(Layout.homeDashboardCardPadding)
            .homeDashboardSurface(accent: surfaceAccent)
            .contentShape(RoundedRectangle(cornerRadius: Layout.homeDashboardCardCornerRadius, style: .continuous))
        }
        .buttonStyle(HomeCardPressStyle())
    }

    private var surfaceAccent: Color {
        if case .active = state { return AppColors.streakAccent }
        return AppColors.primaryBlue
    }

    private var activeDays: Int {
        if case let .active(days) = state { return days }
        return 0
    }

    private var title: String {
        switch state {
        case let .active(days):
            return String(format: L10n.string("homeStreakDaysFmt"), days)
        case .empty:
            return L10n.string("homeStreakEmptyTitle")
        }
    }

    private var subtitle: String {
        switch state {
        case .active:
            return L10n.string("homeStreakKeepItUp")
        case .empty:
            return L10n.string("homeStreakEmptySubtitle")
        }
    }

    @ViewBuilder
    private var leadingIcon: some View {
        switch state {
        case .active:
            HomeDashboardIconChip(systemName: "flame.fill", accent: AppColors.streakAccent)
        case .empty:
            Image(systemName: "flame")
                .font(.system(size: Layout.homeDashboardStreakIconSize, weight: .semibold))
                .foregroundColor(AppColors.textSecondary.opacity(0.5))
                .frame(
                    width: Layout.homeDashboardIconChipSize,
                    height: Layout.homeDashboardIconChipSize
                )
        }
    }

    /// Last 7 days, oldest → today. Today gets a faint ring so the trail
    /// reads as a timeline, not just decoration.
    private var dotTrail: some View {
        let filled = min(activeDays, 7)

        return HStack(spacing: Layout.homeDashboardStreakDotSpacing) {
            ForEach(0..<7, id: \.self) { index in
                let isFilled = index >= 7 - filled
                let isToday = index == 6

                Circle()
                    .fill(
                        isFilled
                        ? AppColors.streakAccent
                        : AppColors.streakAccent.opacity(0.16)
                    )
                    .frame(
                        width: Layout.homeDashboardStreakDotSize,
                        height: Layout.homeDashboardStreakDotSize
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                isToday ? AppColors.streakAccent.opacity(0.35) : .clear,
                                lineWidth: 2
                            )
                            .padding(-2)
                    )
            }
        }
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        HStack {
            HomeStreakCard(state: .active(days: 5), action: {})
                .frame(width: 200, height: Layout.homeDashboardDuoRowHeight)
            HomeStreakCard(state: .empty, action: {})
                .frame(width: 200, height: Layout.homeDashboardDuoRowHeight)
        }
        .padding()
    }
}
