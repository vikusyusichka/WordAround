import SwiftUI

struct StatCardView: View {
    let item: StatCardItem

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let isSmall = width < 120
            let cornerRadius: CGFloat = 20

            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(item.backgroundColor)

                StatBlobShape()
                    .fill(item.blobColor.opacity(0.78))
                    .frame(width: isSmall ? 64 : 78, height: isSmall ? 54 : 66)
                    .offset(x: isSmall ? 20 : 24, y: isSmall ? 13 : 16)

                Image(systemName: "sparkle")
                    .font(.system(size: isSmall ? 8 : 10, weight: .bold))
                    .foregroundColor(item.accentColor.opacity(0.42))
                    .offset(x: isSmall ? -20 : -26, y: isSmall ? -80 : -86)

                Image(systemName: "sparkle")
                    .font(.system(size: isSmall ? 6 : 8, weight: .bold))
                    .foregroundColor(item.accentColor.opacity(0.28))
                    .offset(x: isSmall ? -42 : -48, y: isSmall ? -48 : -54)

                Image(systemName: "sparkle")
                    .font(.system(size: isSmall ? 5 : 7, weight: .bold))
                    .foregroundColor(item.accentColor.opacity(0.34))
                    .offset(x: isSmall ? -8 : -12, y: isSmall ? -36 : -40)

                VStack(alignment: .leading, spacing: isSmall ? 5 : 7) {
                    ZStack {
                        Circle()
                            .fill(item.accentColor.opacity(0.9))
                            .frame(width: isSmall ? 34 : 40, height: isSmall ? 34 : 40)

                        Image(systemName: item.iconSystemName)
                            .font(.system(size: isSmall ? 14 : 16, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Text(item.title)
                        .font(.system(size: isSmall ? 10 : 12, weight: .semibold, design: .rounded))
                        .foregroundColor(item.titleColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(item.value)
                        .font(.system(size: isSmall ? 22 : 26, weight: .bold, design: .rounded))
                        .foregroundColor(item.valueColor)
                        .lineLimit(1)

                    Text(item.subtitle)
                        .font(.system(size: isSmall ? 10 : 11, weight: .semibold, design: .rounded))
                        .foregroundColor(item.subtitleColor)
                        .lineLimit(1)
                }
                .padding(.top, isSmall ? 10 : 12)
                .padding(.leading, isSmall ? 11 : 14)
                .padding(.bottom, isSmall ? 12 : 14)
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
        .frame(height: 122)
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
