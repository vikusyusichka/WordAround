import SwiftUI

struct HomeTipCard: View {
    let tip: DailyTip
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                iconChip

                Spacer(minLength: 10)

                Text(L10n.string("homeTipTitle"))
                    .font(.system(size: Layout.homeDashboardTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)
                    .lineLimit(1)

                Text(tip.short)
                    .font(.system(size: Layout.homeDashboardSubtitleSize, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(Layout.homeDashboardCardPadding)
            .homeDashboardSurface(accent: AppColors.tipAccent)
            .contentShape(RoundedRectangle(cornerRadius: Layout.homeDashboardCardCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var iconChip: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColors.tipSoft)
                .frame(
                    width: Layout.homeDashboardIconChipSize,
                    height: Layout.homeDashboardIconChipSize
                )

            Image(systemName: "lightbulb.fill")
                .font(.system(size: Layout.homeDashboardIconSize, weight: .semibold))
                .foregroundColor(AppColors.tipAccent)
        }
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        HomeTipCard(tip: DailyTip(id: 1, short: "Learn vocabulary in context.", detail: ""), action: {})
            .frame(width: 130, height: Layout.homeDashboardSecondaryRowHeight)
            .padding()
    }
}
