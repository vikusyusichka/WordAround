import SwiftUI

// MARK: - Shared sheet chrome

private struct HomeSheetHeader: View {
    let icon: String
    let accent: Color
    let title: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(accent.opacity(0.14))
                    .frame(width: 52, height: 52)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(accent)
            }

            Text(title)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)

            Spacer(minLength: 0)
        }
    }
}

private struct HomeSheetContainer<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                content
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppColors.appBackground.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Today's Tip

struct HomeTipSheet: View {
    let tip: DailyTip

    var body: some View {
        HomeSheetContainer {
            HomeSheetHeader(
                icon: "lightbulb.fill",
                accent: AppColors.tipAccent,
                title: L10n.string("homeTipSheetTitle")
            )

            Text(tip.short)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.string("homeTipSheetWhy"))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.tipAccent)
                    .textCase(.uppercase)
                    .tracking(0.4)

                Text(tip.detail)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .homeDashboardSurface(accent: AppColors.tipAccent)
        }
    }
}

// MARK: - Learning Guide

struct HomeGuideSheet: View {
    private struct Step: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let body: String
    }

    private let steps: [Step] = [
        Step(
            icon: "calendar",
            title: L10n.string("homeGuideStep1Title"),
            body: L10n.string("homeGuideStep1Body")
        ),
        Step(
            icon: "rectangle.3.group.fill",
            title: L10n.string("homeGuideStep2Title"),
            body: L10n.string("homeGuideStep2Body")
        ),
        Step(
            icon: "note.text",
            title: L10n.string("homeGuideStep3Title"),
            body: L10n.string("homeGuideStep3Body")
        )
    ]

    var body: some View {
        HomeSheetContainer {
            HomeSheetHeader(
                icon: "map.fill",
                accent: AppColors.guideAccent,
                title: L10n.string("homeGuideSheetTitle")
            )

            Text(L10n.string("homeGuideIntro"))
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 12) {
                ForEach(steps) { step in
                    stepRow(step)
                }
            }
        }
    }

    private func stepRow(_ step: Step) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppColors.guideAccent.opacity(0.12))
                    .frame(width: 46, height: 46)

                Image(systemName: step.icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(AppColors.guideAccent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)

                Text(step.body)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .homeDashboardSurface(accent: AppColors.guideAccent)
    }
}

// MARK: - Streak

struct HomeStreakSheet: View {
    let state: HomeStreakState

    var body: some View {
        HomeSheetContainer {
            HomeSheetHeader(
                icon: "flame.fill",
                accent: AppColors.streakAccent,
                title: L10n.string("homeStreakSheetTitle")
            )

            VStack(spacing: 12) {
                switch state {
                case let .active(days):
                    Image(systemName: "flame.fill")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundColor(AppColors.streakAccent)

                    Text("\(days)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlueDark)

                    Text(String(format: L10n.string("homeStreakSheetActiveFmt"), days))
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                case .empty:
                    Image(systemName: "flame")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary.opacity(0.5))

                    Text(L10n.string("homeStreakEmptyTitle"))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlueDark)

                    Text(L10n.string("homeStreakSheetEmpty"))
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
            .homeDashboardSurface(accent: AppColors.streakAccent)
        }
    }
}

#Preview("Tip") {
    Color.clear.sheet(isPresented: .constant(true)) {
        HomeTipSheet(tip: DailyTip(id: 1, short: "Learn vocabulary in context.", detail: "Words stick better in real sentences."))
    }
}
