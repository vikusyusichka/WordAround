import SwiftUI

struct SetItemView: View {
    let title: String
    let subtitle: String
    let iconSystemName: String
    let accentColor: Color
    let backgroundColor: Color
    let trailingText: String?
    let showsArrow: Bool
    let blobColor: Color

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || UIScreen.main.bounds.width >= 700
    }

    private var isCompactPhone: Bool {
        !isPadLike && UIScreen.main.bounds.width < 390
    }

    init(
        title: String,
        subtitle: String,
        iconSystemName: String,
        accentColor: Color,
        backgroundColor: Color,
        trailingText: String? = nil,
        showsArrow: Bool = true,
        blobColor: Color
    ) {
        self.title = title
        self.subtitle = subtitle
        self.iconSystemName = iconSystemName
        self.accentColor = accentColor
        self.backgroundColor = backgroundColor
        self.trailingText = trailingText
        self.showsArrow = showsArrow
        self.blobColor = blobColor
    }

    var body: some View {
        let cornerRadius: CGFloat = isPadLike ? 24 : 18

        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(backgroundColor)

            decorativeBlob

            content
        }
        .frame(height: isPadLike ? 92 : 78)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.95), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.045), radius: 10, x: 0, y: 5)
    }

    private var decorativeBlob: some View {
        HStack {
            Spacer()

            SetCardBlobShape()
                .fill(blobColor.opacity(0.78))
                .frame(
                    width: isPadLike ? 170 : 110,
                    height: isPadLike ? 70 : 35
                )
                .padding(.trailing, isPadLike ? 0 : 0)
                .padding(.top, isPadLike ? -40 : -15)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }

    private var content: some View {
        HStack(spacing: isPadLike ? 16 : 12) {
            ZStack {
                Circle()
                    .fill(accentColor)
                    .frame(
                        width: isPadLike ? 52 : 40,
                        height: isPadLike ? 52 : 40
                    )

                Image(systemName: iconSystemName)
                    .font(.system(size: isPadLike ? 21 : 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: isPadLike ? 20 : (isCompactPhone ? 15 : 16), weight: .bold, design: .rounded))
                    .foregroundColor(titleColor)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: isPadLike ? 15 : 12, weight: .medium, design: .rounded))
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

    private var titleColor: Color {
        if title == "Relatives" {
            return Color(red: 0.67, green: 0.39, blue: 0.02)
        } else {
            return Color(red: 0.07, green: 0.55, blue: 0.28)
        }
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

#Preview {
    ZStack {
        Color(red: 0.965, green: 0.965, blue: 0.985)
            .ignoresSafeArea()

        VStack(spacing: 12) {
            SetItemView(
                title: "Relatives",
                subtitle: "18 words",
                iconSystemName: "person.3.fill",
                accentColor: Color(red: 0.97, green: 0.64, blue: 0.06),
                backgroundColor: Color(red: 0.97, green: 0.94, blue: 0.89),
                trailingText: "Review",
                blobColor: Color(red: 0.96, green: 0.86, blue: 0.62)
            )

            SetItemView(
                title: "Travel",
                subtitle: "24 words",
                iconSystemName: "suitcase.fill",
                accentColor: Color(red: 0.16, green: 0.73, blue: 0.40),
                backgroundColor: Color(red: 0.93, green: 0.98, blue: 0.95),
                trailingText: "Review",
                blobColor: Color(red: 0.80, green: 0.93, blue: 0.84)
            )
        }
        .padding()
    }
}
