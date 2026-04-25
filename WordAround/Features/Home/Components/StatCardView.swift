import SwiftUI

struct StatCardView: View {
    let item: StatCardItem

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let isSmall = width < Layout.statCardSmallWidthThreshold
            let cornerRadius: CGFloat = Layout.statCardCornerRadius

            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(item.backgroundColor)

                StatBlobShape()
                    .fill(item.blobColor.opacity(0.78))
                    .frame(width: Layout.statBlobSize(isSmall: isSmall).width, height: Layout.statBlobSize(isSmall: isSmall).height)
                    .offset(x: Layout.statBlobOffset(isSmall: isSmall).width, y: Layout.statBlobOffset(isSmall: isSmall).height)

                Image(systemName: "sparkle")
                    .font(.system(size: Layout.statSparkleSize(index: 1, isSmall: isSmall), weight: .bold))
                    .foregroundColor(item.accentColor.opacity(0.42))
                    .offset(x: Layout.statSparkleOffset(index: 1, isSmall: isSmall).width, y: Layout.statSparkleOffset(index: 1, isSmall: isSmall).height)

                Image(systemName: "sparkle")
                    .font(.system(size: Layout.statSparkleSize(index: 2, isSmall: isSmall), weight: .bold))
                    .foregroundColor(item.accentColor.opacity(0.28))
                    .offset(x: Layout.statSparkleOffset(index: 2, isSmall: isSmall).width, y: Layout.statSparkleOffset(index: 2, isSmall: isSmall).height)

                Image(systemName: "sparkle")
                    .font(.system(size: Layout.statSparkleSize(index: 3, isSmall: isSmall), weight: .bold))
                    .foregroundColor(item.accentColor.opacity(0.34))
                    .offset(x: Layout.statSparkleOffset(index: 3, isSmall: isSmall).width, y: Layout.statSparkleOffset(index: 3, isSmall: isSmall).height)

                VStack(alignment: .leading, spacing: Layout.statTextStackSpacing(isSmall: isSmall)) {
                    ZStack {
                        Circle()
                            .fill(item.accentColor.opacity(0.9))
                            .frame(width: Layout.statIconCircleSize(isSmall: isSmall), height: Layout.statIconCircleSize(isSmall: isSmall))

                        Image(systemName: item.iconSystemName)
                            .font(.system(size: Layout.statIconSize(isSmall: isSmall), weight: .bold))
                            .foregroundColor(.white)
                    }

                    Text(item.title)
                        .font(.system(size: Layout.statTitleSize(isSmall: isSmall), weight: .semibold, design: .rounded))
                        .foregroundColor(item.titleColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(item.value)
                        .font(.system(size: Layout.statValueSize(isSmall: isSmall), weight: .bold, design: .rounded))
                        .foregroundColor(item.valueColor)
                        .lineLimit(1)

                    Text(item.subtitle)
                        .font(.system(size: Layout.statSubtitleSize(isSmall: isSmall), weight: .semibold, design: .rounded))
                        .foregroundColor(item.subtitleColor)
                        .lineLimit(1)
                }
                .padding(.top, Layout.statTopPadding(isSmall: isSmall))
                .padding(.leading, Layout.statLeadingPadding(isSmall: isSmall))
                .padding(.bottom, Layout.statBottomPadding(isSmall: isSmall))
                .padding(.trailing, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.95), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
        }
        .frame(height: Layout.statCardHeight)
    }
}

struct StatBlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(
            to: CGPoint(
                x: rect.minX + rect.width * 0.12,
                y: rect.minY + rect.height * 0.52
            )
        )

        path.addCurve(
            to: CGPoint(
                x: rect.minX + rect.width * 0.36,
                y: rect.minY + rect.height * 0.14
            ),
            control1: CGPoint(
                x: rect.minX + rect.width * 0.08,
                y: rect.minY + rect.height * 0.28
            ),
            control2: CGPoint(
                x: rect.minX + rect.width * 0.20,
                y: rect.minY + rect.height * 0.14
            )
        )

        path.addCurve(
            to: CGPoint(
                x: rect.minX + rect.width * 0.78,
                y: rect.minY + rect.height * 0.10
            ),
            control1: CGPoint(
                x: rect.minX + rect.width * 0.52,
                y: rect.minY + rect.height * 0.14
            ),
            control2: CGPoint(
                x: rect.minX + rect.width * 0.58,
                y: rect.minY + rect.height * 0.00
            )
        )

        path.addCurve(
            to: CGPoint(
                x: rect.maxX,
                y: rect.minY + rect.height * 0.48
            ),
            control1: CGPoint(
                x: rect.minX + rect.width * 0.96,
                y: rect.minY + rect.height * 0.20
            ),
            control2: CGPoint(
                x: rect.maxX,
                y: rect.minY + rect.height * 0.30
            )
        )

        path.addCurve(
            to: CGPoint(
                x: rect.minX + rect.width * 0.82,
                y: rect.maxY
            ),
            control1: CGPoint(
                x: rect.maxX,
                y: rect.minY + rect.height * 0.72
            ),
            control2: CGPoint(
                x: rect.minX + rect.width * 0.98,
                y: rect.maxY
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.minX + rect.width * 0.30,
                y: rect.maxY
            )
        )

        path.addCurve(
            to: CGPoint(
                x: rect.minX + rect.width * 0.12,
                y: rect.minY + rect.height * 0.52
            ),
            control1: CGPoint(
                x: rect.minX + rect.width * 0.08,
                y: rect.maxY
            ),
            control2: CGPoint(
                x: rect.minX,
                y: rect.minY + rect.height * 0.76
            )
        )

        path.closeSubpath()
        return path
    }
}

#Preview {
    ZStack {
        AppColors.appBackground
            .ignoresSafeArea()

        HStack(spacing: 8) {
            StatCardView(
                item: StatCardItem(
                    title: "Learned today",
                    value: "24",
                    subtitle: "words",
                    iconSystemName: "chart.bar.fill",
                    accentColor: Color(red: 0.64, green: 0.54, blue: 0.98),
                    titleColor: Color(red: 0.58, green: 0.47, blue: 0.98),
                    valueColor: AppColors.primaryBlueDark,
                    subtitleColor: AppColors.textSecondary,
                    backgroundColor: Color(red: 0.96, green: 0.94, blue: 1.0),
                    blobColor: Color(red: 0.86, green: 0.81, blue: 1.0)
                )
            )

            StatCardView(
                item: StatCardItem(
                    title: "Accuracy",
                    value: "87%",
                    subtitle: "Great job!",
                    iconSystemName: "target",
                    accentColor: Color(red: 0.42, green: 0.80, blue: 0.67),
                    titleColor: Color(red: 0.33, green: 0.73, blue: 0.58),
                    valueColor: AppColors.primaryBlueDark,
                    subtitleColor: Color(red: 0.10, green: 0.66, blue: 0.38),
                    backgroundColor: Color(red: 0.93, green: 0.99, blue: 0.97),
                    blobColor: Color(red: 0.77, green: 0.92, blue: 0.85)
                )
            )

            StatCardView(
                item: StatCardItem(
                    title: "Streak",
                    value: "5",
                    subtitle: "days",
                    iconSystemName: "flame.fill",
                    accentColor: Color(red: 0.98, green: 0.68, blue: 0.20),
                    titleColor: Color(red: 0.67, green: 0.36, blue: 0.02),
                    valueColor: Color(red: 0.67, green: 0.36, blue: 0.02),
                    subtitleColor: AppColors.textSecondary,
                    backgroundColor: Color(red: 1.0, green: 0.96, blue: 0.89),
                    blobColor: Color(red: 0.98, green: 0.86, blue: 0.62)
                )
            )
        }
        .padding()
    }
}
