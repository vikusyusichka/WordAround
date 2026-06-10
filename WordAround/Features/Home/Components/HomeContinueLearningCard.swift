import SwiftUI

struct HomeContinueLearningCard: View {
    let item: ContinueLearningItem?
    let action: () -> Void

    private let accent = AppColors.greenAccent
    private var icon: String { item?.icon ?? "play.circle.fill" }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    iconChip
                    Spacer(minLength: 0)
                    chevron
                }

                Spacer(minLength: 10)

                Text(L10n.string("homeContinueLearning"))
                    .font(.system(size: Layout.homeDashboardEyebrowSize, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
                    .textCase(.uppercase)
                    .tracking(0.4)
                    .lineLimit(1)

                Text(activityTitle)
                    .font(.system(size: Layout.homeDashboardActivitySize, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.greenTitle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(activitySubtitle)
                    .font(.system(size: Layout.homeDashboardSubtitleSize, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(Layout.homeDashboardCardPadding)
            .homeDashboardSurface(accent: accent)
            .contentShape(RoundedRectangle(cornerRadius: Layout.homeDashboardCardCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var activityTitle: String {
        item?.title ?? L10n.string("homeContinueLearningEmptyTitle")
    }

    private var activitySubtitle: String {
        item?.subtitle ?? L10n.string("homeContinueLearningEmptySubtitle")
    }

    private var iconChip: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(accent.opacity(0.14))
                .frame(
                    width: Layout.homeDashboardIconChipSize,
                    height: Layout.homeDashboardIconChipSize
                )

            Image(systemName: icon)
                .font(.system(size: Layout.homeDashboardIconSize, weight: .semibold))
                .foregroundColor(accent)
        }
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: Layout.homeDashboardChevronSize, weight: .bold))
            .foregroundColor(AppColors.textSecondary.opacity(0.6))
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        VStack {
            HomeContinueLearningCard(item: nil, action: {})
                .frame(height: Layout.homeDashboardPrimaryRowHeight)
        }
        .padding()
    }
}
