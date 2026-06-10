import SwiftUI

struct HomeGuideCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    iconChip
                    Spacer(minLength: 0)
                    chevron
                }

                Spacer(minLength: 10)

                Text(L10n.string("homeGuideTitle"))
                    .font(.system(size: Layout.homeDashboardTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)
                    .lineLimit(1)

                Text(L10n.string("homeGuideSubtitle"))
                    .font(.system(size: Layout.homeDashboardSubtitleSize, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(Layout.homeDashboardCardPadding)
            .homeDashboardSurface(accent: AppColors.guideAccent)
            .contentShape(RoundedRectangle(cornerRadius: Layout.homeDashboardCardCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var iconChip: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColors.guideSoft)
                .frame(
                    width: Layout.homeDashboardIconChipSize,
                    height: Layout.homeDashboardIconChipSize
                )

            Image(systemName: "map.fill")
                .font(.system(size: Layout.homeDashboardIconSize, weight: .semibold))
                .foregroundColor(AppColors.guideAccent)
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
        HomeGuideCard(action: {})
            .frame(width: 130, height: Layout.homeDashboardSecondaryRowHeight)
            .padding()
    }
}
