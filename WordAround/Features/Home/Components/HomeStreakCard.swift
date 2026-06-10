import SwiftUI

struct HomeStreakCard: View {
    let state: HomeStreakState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                switch state {
                case let .active(days):
                    activeContent(days: days)
                case .empty:
                    emptyContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(Layout.homeDashboardCardPadding)
            .homeDashboardSurface(accent: surfaceAccent)
            .contentShape(RoundedRectangle(cornerRadius: Layout.homeDashboardCardCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var surfaceAccent: Color {
        if case .active = state { return AppColors.streakAccent }
        return AppColors.primaryBlue
    }

    private func activeContent(days: Int) -> some View {
        VStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.system(size: Layout.homeDashboardStreakIconSize, weight: .semibold))
                .foregroundColor(AppColors.streakAccent)

            Text("\(days)")
                .font(.system(size: Layout.homeDashboardStreakValueSize, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(L10n.string("homeStreakActiveLabel"))
                .font(.system(size: Layout.homeDashboardSubtitleSize, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private var emptyContent: some View {
        VStack(spacing: 6) {
            Image(systemName: "flame")
                .font(.system(size: Layout.homeDashboardStreakIconSize, weight: .semibold))
                .foregroundColor(AppColors.textSecondary.opacity(0.5))

            Text(L10n.string("homeStreakEmptyTitle"))
                .font(.system(size: Layout.homeDashboardTitleSize, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(L10n.string("homeStreakEmptySubtitle"))
                .font(.system(size: Layout.homeDashboardSubtitleSize, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
        }
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        HStack {
            HomeStreakCard(state: .active(days: 5), action: {})
                .frame(width: 120, height: Layout.homeDashboardSecondaryRowHeight)
            HomeStreakCard(state: .empty, action: {})
                .frame(width: 120, height: Layout.homeDashboardSecondaryRowHeight)
        }
        .padding()
    }
}
