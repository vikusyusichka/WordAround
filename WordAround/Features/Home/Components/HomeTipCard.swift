import SwiftUI

/// Today's Tip — the content-rich support card. Horizontal layout: lightbulb
/// chip, then an uppercase eyebrow above the tip text itself, so the card
/// reads dense and useful instead of leaving an empty corner.
struct HomeTipCard: View {
    let tip: DailyTip
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Layout.homeDashboardCardPadding) {
                HomeDashboardIconChip(systemName: "lightbulb.fill", accent: AppColors.tipAccent)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.string("homeTipTitle"))
                        .font(.system(size: Layout.homeDashboardEyebrowSize, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.tipAccent)
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .lineLimit(1)

                    Text(tip.short)
                        .font(.system(size: Layout.homeDashboardTitleSize, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlueDark)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if !tip.detail.isEmpty {
                        Text(tip.detail)
                            .font(.system(size: Layout.homeDashboardSubtitleSize, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: Layout.homeDashboardChevronSize, weight: .bold))
                    .foregroundColor(AppColors.tipAccent.opacity(0.55))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(Layout.homeDashboardCardPadding)
            .homeDashboardSurface(accent: AppColors.tipAccent)
            .contentShape(RoundedRectangle(cornerRadius: Layout.homeDashboardCardCornerRadius, style: .continuous))
        }
        .buttonStyle(HomeCardPressStyle())
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        HomeTipCard(tip: DailyTip(id: 1, short: "Say new words out loud.", detail: ""), action: {})
            .frame(height: Layout.homeDashboardSupportRowHeight)
            .padding()
    }
}
