import SwiftUI

/// "Study smarter" guide entry — compact horizontal action card (chip →
/// text → chevron), paired with the Streak card in a half-width row.
struct HomeGuideCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Layout.homeDashboardCardPadding) {
                HomeDashboardIconChip(systemName: "map.fill", accent: AppColors.guideAccent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.string("homeGuideTitle"))
                        .font(.system(size: Layout.homeDashboardTitleSize, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlueDark)
                        .lineLimit(1)

                    Text(L10n.string("homeGuideSubtitle"))
                        .font(.system(size: Layout.homeDashboardSubtitleSize, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: Layout.homeDashboardChevronSize, weight: .bold))
                    .foregroundColor(AppColors.guideAccent.opacity(0.55))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(Layout.homeDashboardCardPadding)
            .homeDashboardSurface(accent: AppColors.guideAccent)
            .contentShape(RoundedRectangle(cornerRadius: Layout.homeDashboardCardCornerRadius, style: .continuous))
        }
        .buttonStyle(HomeCardPressStyle())
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        HomeGuideCard(action: {})
            .frame(height: Layout.homeDashboardActionRowHeight)
            .padding()
    }
}
