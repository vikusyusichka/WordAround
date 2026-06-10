import SwiftUI

struct HomeDashboardSection: View {
    let continueItem: ContinueLearningItem?
    let tip: DailyTip
    let streak: HomeStreakState

    let onNote: () -> Void
    let onContinue: () -> Void
    let onTip: () -> Void
    let onGuide: () -> Void
    let onStreak: () -> Void

    private var totalHeight: CGFloat {
        Layout.homeDashboardPrimaryRowHeight
            + Layout.homeDashboardSecondaryRowHeight
            + Layout.homeDashboardRowSpacing
    }

    var body: some View {
        GeometryReader { proxy in
            let spacing = Layout.homeDashboardRowSpacing
            let columnWidth = (proxy.size.width - spacing) * Layout.homeDashboardColumnRatio

            VStack(spacing: spacing) {
                primaryRow(columnWidth: columnWidth, spacing: spacing)
                secondaryRow(columnWidth: columnWidth, spacing: spacing)
            }
            .frame(width: proxy.size.width)
        }
        .frame(maxWidth: .infinity)
        .frame(height: totalHeight)
    }

    // MARK: - Row 1: [Note] [Continue Learning]

    private func primaryRow(columnWidth: CGFloat, spacing: CGFloat) -> some View {
        HStack(spacing: spacing) {
            HomeNoteCard(action: onNote)
                .frame(width: columnWidth)

            HomeContinueLearningCard(item: continueItem, action: onContinue)
                .frame(maxWidth: .infinity)
        }
        .frame(height: Layout.homeDashboardPrimaryRowHeight)
    }

    // MARK: - Row 2: [Today's Tip] [Guide] [Streak]

    private func secondaryRow(columnWidth: CGFloat, spacing: CGFloat) -> some View {
        HStack(spacing: spacing) {
            HomeTipCard(tip: tip, action: onTip)
                .frame(width: columnWidth)

            HStack(spacing: spacing) {
                HomeGuideCard(action: onGuide)
                    .frame(maxWidth: .infinity)

                HomeStreakCard(state: streak, action: onStreak)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: Layout.homeDashboardSecondaryRowHeight)
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        ScrollView {
            HomeDashboardSection(
                continueItem: nil,
                tip: DailyTip(id: 1, short: "Learn vocabulary in context.", detail: ""),
                streak: .active(days: 5),
                onNote: {},
                onContinue: {},
                onTip: {},
                onGuide: {},
                onStreak: {}
            )
            .padding()
        }
    }
}
