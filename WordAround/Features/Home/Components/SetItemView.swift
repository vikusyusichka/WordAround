import SwiftUI

struct SetItemView: View {
    let title: String
    let subtitle: String
    let iconSystemName: String
    let accentColor: Color
    let titleColor: Color
    let backgroundColor: Color
    let trailingText: String?
    let showsArrow: Bool
    let blobColor: Color
    let height: CGFloat

    init(
        title: String,
        subtitle: String,
        iconSystemName: String,
        accentColor: Color,
        titleColor: Color,
        backgroundColor: Color,
        trailingText: String? = nil,
        showsArrow: Bool = true,
        blobColor: Color,
        height: CGFloat = Layout.setItemHeight
    ) {
        self.title = title
        self.subtitle = subtitle
        self.iconSystemName = iconSystemName
        self.accentColor = accentColor
        self.titleColor = titleColor
        self.backgroundColor = backgroundColor
        self.trailingText = trailingText
        self.showsArrow = showsArrow
        self.blobColor = blobColor
        self.height = height
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Layout.setItemCornerRadius, style: .continuous)
                .fill(backgroundColor)

            HStack {
                Spacer()

                SetCardBlobShape()
                    .fill(blobColor.opacity(0.85))
                    .frame(
                        width: Layout.setItemBlobSize.width,
                        height: Layout.setItemBlobSize.height
                    )
                    .offset(
                        x: Layout.setItemBlobOffset.width,
                        y: Layout.setItemBlobOffset.height
                    )
            }

            content
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: Layout.setItemCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.setItemCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.95), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 6)
    }

    private var content: some View {
        HStack(spacing: Layout.setItemContentSpacing) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.95))
                    .frame(
                        width: Layout.setItemIconCircleSize,
                        height: Layout.setItemIconCircleSize
                    )

                Image(systemName: iconSystemName)
                    .font(.system(size: Layout.setItemIconSize, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: Layout.setItemTextStackSpacing) {
                Text(title)
                    .font(.system(size: Layout.setItemTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(titleColor)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: Layout.setItemSubtitleSize, weight: .medium, design: .rounded))
                    .foregroundColor(accentColor)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            HStack(spacing: 5) {
                if let trailingText {
                    Text(trailingText)
                        .font(.system(size: Layout.setItemTrailingTextSize, weight: .medium, design: .rounded))
                        .foregroundColor(accentColor)
                }

                if showsArrow {
                    Image(systemName: "chevron.right")
                        .font(.system(size: Layout.setItemArrowSize, weight: .bold))
                        .foregroundColor(accentColor)
                }
            }
            .fixedSize()
        }
        .padding(.horizontal, Layout.setItemHorizontalPadding)
        .padding(.vertical, Layout.setItemVerticalPadding)
    }
}

struct SetCardBlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX + rect.width * 0.04, y: rect.minY + rect.height * 0.42))

        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.30, y: rect.minY + rect.height * 0.10),
            control1: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.20),
            control2: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.08)
        )

        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.70, y: rect.minY + rect.height * 0.02),
            control1: CGPoint(x: rect.minX + rect.width * 0.45, y: rect.minY + rect.height * 0.12),
            control2: CGPoint(x: rect.minX + rect.width * 0.54, y: rect.minY - rect.height * 0.04)
        )

        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.34),
            control1: CGPoint(x: rect.minX + rect.width * 0.86, y: rect.minY + rect.height * 0.08),
            control2: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.12)
        )

        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.86, y: rect.minY + rect.height * 0.78),
            control1: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.56),
            control2: CGPoint(x: rect.minX + rect.width * 0.98, y: rect.minY + rect.height * 0.74)
        )

        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.44, y: rect.maxY),
            control1: CGPoint(x: rect.minX + rect.width * 0.72, y: rect.minY + rect.height * 0.82),
            control2: CGPoint(x: rect.minX + rect.width * 0.62, y: rect.maxY)
        )

        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.04, y: rect.minY + rect.height * 0.42),
            control1: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.maxY),
            control2: CGPoint(x: rect.minX - rect.width * 0.04, y: rect.minY + rect.height * 0.72)
        )

        path.closeSubpath()
        return path
    }
}
