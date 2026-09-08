import SwiftUI

/// Assembles the Home dashboard with a clear hierarchy:
/// 1. Continue Learning (hero) 2. Daily Practice 3. Today's Tip 4. Streak/Guide.
///
/// Compact (iPhone): a single focused stack — hero, Daily Practice 2×2,
/// full-width tip, then the Streak + Guide pair.
///
/// Regular (iPad / Mac): a dedicated two-column layout — hero and tip on the
/// left, Daily Practice grid with Streak + Guide on the right — so the extra
/// width is used intentionally instead of stretching the phone design.
struct HomeDashboardSection: View {
    let isCompact: Bool
    let stats: [HomeDailyStat]
    let onSelectStat: ((HomeCategory) -> Void)?
    let continueItem: ContinueLearningItem?
    let tip: DailyTip
    let streak: HomeStreakState

    let onContinue: () -> Void
    let onTip: () -> Void
    let onGuide: () -> Void
    let onStreak: () -> Void

    var body: some View {
        if isCompact {
            compactLayout
        } else {
            regularLayout
        }
    }

    // MARK: - Compact (iPhone)

    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: Layout.homeDashboardRowSpacing) {
            hero

            dailyPracticeTitle
                .padding(.top, Layout.homeSectionTitleTopPadding)

            HomeStatsGridView(stats: stats, onSelect: onSelectStat)

            tipCard
                .padding(.top, 2)

            HStack(spacing: Layout.homeDashboardRowSpacing) {
                HomeStreakCard(state: streak, action: onStreak)
                    .frame(maxWidth: .infinity)
                HomeGuideCard(action: onGuide)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: Layout.homeDashboardDuoRowHeight)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Regular (iPad / Mac)

    private var regularLayout: some View {
        HStack(alignment: .top, spacing: Layout.homeDashboardColumnSpacing) {
            VStack(alignment: .leading, spacing: Layout.homeDashboardRowSpacing) {
                hero
                tipCard
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            VStack(alignment: .leading, spacing: Layout.homeDashboardRowSpacing) {
                dailyPracticeTitle

                HomeStatsGridView(stats: stats, onSelect: onSelectStat, columnCount: 2)

                HStack(spacing: Layout.homeDashboardRowSpacing) {
                    HomeStreakCard(state: streak, action: onStreak)
                        .frame(maxWidth: .infinity)
                    HomeGuideCard(action: onGuide)
                        .frame(maxWidth: .infinity)
                }
                .frame(height: Layout.homeDashboardDuoRowHeight)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    // MARK: - Shared pieces

    private var hero: some View {
        HomeContinueLearningCard(item: continueItem, action: onContinue)
            .frame(maxWidth: .infinity)
    }

    private var tipCard: some View {
        HomeTipCard(tip: tip, action: onTip)
            .frame(maxWidth: .infinity)
            .frame(minHeight: Layout.homeDashboardSupportRowHeight)
    }

    private var dailyPracticeTitle: some View {
        Text(L10n.string("homeDailyPractice"))
            .font(.system(size: Layout.homeSectionTitleSize, weight: .bold, design: .rounded))
            .foregroundColor(AppColors.primaryBlueDark)
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        ScrollView {
            HomeDashboardSection(
                isCompact: true,
                stats: [],
                onSelectStat: nil,
                continueItem: nil,
                tip: DailyTip(id: 1, short: "Learn vocabulary in context.", detail: "Words stick better in real sentences."),
                streak: .active(days: 5),
                onContinue: {},
                onTip: {},
                onGuide: {},
                onStreak: {}
            )
            .padding()
        }
    }
}
