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

    private var isPadLike: Bool { Layout.isPadLike }
    private var isCompactPhone: Bool { Layout.isCompactPhone }

    init(
        title: String,
        subtitle: String,
        iconSystemName: String,
        accentColor: Color,
        titleColor: Color,
        backgroundColor: Color,
        trailingText: String? = nil,
        showsArrow: Bool = true,
        blobColor: Color
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
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: isPadLike ? 30 : 22, style: .continuous)
                .fill(backgroundColor)

            HStack {
                Spacer()

                SetCardBlobShape()
                    .fill(blobColor.opacity(0.85))
                    .frame(width: isPadLike ? 130 : 92, height: isPadLike ? 86 : 62)
                    .offset(x: isPadLike ? 28 : 22, y: isPadLike ? 18 : 14)
            }

            content
        }
        .frame(height: isPadLike ? 104 : (isCompactPhone ? 78 : 86))
        .clipShape(RoundedRectangle(cornerRadius: isPadLike ? 30 : 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: isPadLike ? 30 : 22, style: .continuous)
                .stroke(Color.white.opacity(0.95), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 6)
    }

    private var content: some View {
        HStack(spacing: isPadLike ? 16 : 12) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.95))
                    .frame(width: isPadLike ? 62 : 46, height: isPadLike ? 62 : 46)

                Image(systemName: iconSystemName)
                    .font(.system(size: isPadLike ? 24 : 18, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: isPadLike ? 7 : 5) {
                Text(title)
                    .font(.system(size: isPadLike ? 24 : 18, weight: .bold, design: .rounded))
                    .foregroundColor(titleColor)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: isPadLike ? 16 : 13, weight: .medium, design: .rounded))
                    .foregroundColor(accentColor)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            HStack(spacing: 5) {
                if let trailingText {
                    Text(trailingText)
                        .font(.system(size: isPadLike ? 16 : 12, weight: .medium, design: .rounded))
                        .foregroundColor(accentColor)
                }

                if showsArrow {
                    Image(systemName: "chevron.right")
                        .font(.system(size: isPadLike ? 15 : 11, weight: .bold))
                        .foregroundColor(accentColor)
                }
            }
            .fixedSize()
        }
        .padding(.horizontal, isPadLike ? 18 : 14)
        .padding(.vertical, isPadLike ? 18 : 14)
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
