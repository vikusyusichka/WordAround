import SwiftUI

struct WritingMenuCardView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let item: WritingMenuItem

    private var metrics: ScreenMetrics {
        ScreenMetrics.current(horizontal: horizontalSizeClass, vertical: verticalSizeClass)
    }

    var body: some View {
        HStack(spacing: LayoutConstants.Writing.menuSpacing(metrics)) {
            RoundedRectangle(cornerRadius: LayoutConstants.Writing.menuIconCornerRadius(metrics), style: .continuous)
                .fill(LinearGradient(colors: item.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(
                    width: LayoutConstants.Writing.menuIconBoxSize(metrics),
                    height: LayoutConstants.Writing.menuIconBoxSize(metrics)
                )
                .overlay(
                    Image(systemName: item.systemImage)
                        .font(.system(size: LayoutConstants.Writing.menuIconSize(metrics), weight: .semibold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: LayoutConstants.Writing.menuSpacing(metrics) / 3) {
                Text(item.title)
                    .font(.system(size: LayoutConstants.Typography.cardTitle(metrics), weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)

                Text(item.subtitle)
                    .font(.system(size: LayoutConstants.Typography.caption(metrics), weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(LayoutConstants.Common.hairline * 2)
            }

            Spacer(minLength: LayoutConstants.Common.smallSpacing(metrics))

            Image(systemName: "chevron.right")
                .font(.system(size: LayoutConstants.Writing.menuChevronSize(metrics), weight: .semibold))
                .foregroundColor(AppColors.textSecondary.opacity(0.75))
        }
        .padding(.horizontal, LayoutConstants.Writing.menuHorizontalPadding(metrics))
        .frame(height: LayoutConstants.Writing.menuHeight(metrics))
        .background(Color.white.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.Writing.menuCornerRadius(metrics), style: .continuous))
        .shadow(color: Color.black.opacity(0.055), radius: Layout.sectionSpacingPhone + 2, x: 0, y: LayoutConstants.Common.smallSpacing(metrics))
    }
}

#Preview {
    WritingMenuCardView(item: WritingViewModel().menuItems[0])
        .padding()
        .background(AppColors.appBackground)
}
