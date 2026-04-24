import SwiftUI

enum ProgressCardLayout {
    case goal
    case action
}

struct ProgressCardView: View {
    let layout: ProgressCardLayout

    let title: String
    let currentValue: Int
    let totalValue: Int
    let unit: String
    let subtitle: String
    let progress: Double

    let tint: Color
    let backgroundColor: Color
    let progressBackgroundColor: Color
    let titleColor: Color
    let valueColor: Color
    let subtitleColor: Color

    let iconSystemName: String
    let iconBackground: Color
    let blobColor: Color

    let actionSystemName: String?

    private var isPadLike: Bool { Layout.isPadLike }
    private var isCompactPhone: Bool { Layout.isCompactPhone }

    init(
        layout: ProgressCardLayout = .goal,
        title: String,
        currentValue: Int,
        totalValue: Int,
        unit: String,
        subtitle: String,
        progress: Double,
        tint: Color,
        backgroundColor: Color,
        progressBackgroundColor: Color,
        titleColor: Color,
        valueColor: Color,
        subtitleColor: Color,
        iconSystemName: String,
        iconBackground: Color,
        blobColor: Color,
        actionSystemName: String? = nil
    ) {
        self.layout = layout
        self.title = title
        self.currentValue = currentValue
        self.totalValue = totalValue
        self.unit = unit
        self.subtitle = subtitle
        self.progress = progress
        self.tint = tint
        self.backgroundColor = backgroundColor
        self.progressBackgroundColor = progressBackgroundColor
        self.titleColor = titleColor
        self.valueColor = valueColor
        self.subtitleColor = subtitleColor
        self.iconSystemName = iconSystemName
        self.iconBackground = iconBackground
        self.blobColor = blobColor
        self.actionSystemName = actionSystemName
    }

    var body: some View {
        let cornerRadius: CGFloat = isPadLike ? 30 : 22

        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(backgroundColor)

            decorativeBlob

            switch layout {
            case .goal:
                goalLayout
            case .action:
                actionLayout
            }
        }
        .frame(height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.95), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.035), radius: 10, x: 0, y: 6)
    }

    private var cardHeight: CGFloat {
        switch layout {
        case .goal:
            return isPadLike ? 230 : (isCompactPhone ? 154 : 170)
        case .action:
            return isPadLike ? 190 : 130
        }
    }

    private var decorativeBlob: some View {
        HStack {
            Spacer()

            ProgressBlobShape()
                .fill(blobColor.opacity(0.9))
                .frame(
                    width: layout == .goal ? (isPadLike ? 250 : 170) : (isPadLike ? 270 : 180),
                    height: layout == .goal ? (isPadLike ? 280 : 170) : (isPadLike ? 70 : 56)
                )
                .padding(.trailing, isPadLike ? -24 : -24)
                .padding(.top, layout == .goal ? 20 : -16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }

    private var goalLayout: some View {
        ZStack(alignment: .trailing) {
            VStack(alignment: .leading, spacing: isPadLike ? 12 : 8) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: isPadLike ? 21 : 15, weight: .semibold, design: .rounded))
                        .foregroundColor(titleColor)

                    Image(systemName: "sparkles")
                        .font(.system(size: isPadLike ? 12 : 9, weight: .medium))
                        .foregroundColor(Color(red: 0.66, green: 0.72, blue: 1.0))
                }

                valueLine

                progressSection
                    .frame(width: isPadLike ? 190 : 116, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, isPadLike ? 28 : 18)
            .padding(.trailing, isPadLike ? 180 : 112)
            .padding(.vertical, isPadLike ? 24 : 16)

            ZStack {
                Circle()
                    .fill(iconBackground.opacity(0.96))
                    .frame(width: isPadLike ? 98 : 78, height: isPadLike ? 98 : 78)

                Image(systemName: iconSystemName)
                    .font(.system(size: isPadLike ? 34 : 29, weight: .medium))
                    .foregroundColor(tint)
            }
            .frame(width: isPadLike ? 180 : 136, height: isPadLike ? 180 : 136)
            .padding(.trailing, isPadLike ? 18 : 8)
        }
    }

    private var actionLayout: some View {
        HStack(spacing: isPadLike ? 20 : 12) {
            ZStack {
                Circle()
                    .fill(iconBackground)
                    .frame(width: isPadLike ? 74 : 52, height: isPadLike ? 74 : 52)

                Image(systemName: iconSystemName)
                    .font(.system(size: isPadLike ? 28 : 20, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: isPadLike ? 10 : 6) {
                Text(title)
                    .font(.system(size: isPadLike ? 34 : 25, weight: .bold, design: .rounded))
                    .foregroundColor(titleColor)

                Text(subtitle)
                    .font(.system(size: isPadLike ? 20 : 17, weight: .medium, design: .rounded))
                    .foregroundColor(tint)

                progressBar

                Text("\(currentValue) / \(totalValue) \(unit)")
                    .font(.system(size: isPadLike ? 18 : 15, weight: .medium, design: .rounded))
                    .foregroundColor(subtitleColor)
            }

            Spacer(minLength: 8)

            if let actionSystemName {
                Button(action: {}) {
                    ZStack {
                        RoundedRectangle(cornerRadius: isPadLike ? 18 : 14, style: .continuous)
                            .fill(tint)
                            .frame(width: isPadLike ? 62 : 46, height: isPadLike ? 62 : 46)

                        Image(systemName: actionSystemName)
                            .font(.system(size: isPadLike ? 24 : 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, isPadLike ? 24 : 16)
        .padding(.vertical, isPadLike ? 24 : 18)
    }

    private var valueLine: some View {
        HStack(alignment: .lastTextBaseline, spacing: 3) {
            Text("\(currentValue)")
                .font(.system(size: isPadLike ? 56 : 38, weight: .bold, design: .rounded))
                .foregroundColor(valueColor)

            Text("/ \(totalValue) \(unit)")
                .font(.system(size: isPadLike ? 25 : 15, weight: .medium, design: .rounded))
                .foregroundColor(subtitleColor)
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: isPadLike ? 10 : 6) {
            progressBar

            Text(subtitle)
                .font(.system(size: isPadLike ? 18 : 15, weight: .medium, design: .rounded))
                .foregroundColor(tint)
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(progressBackgroundColor)

                Capsule()
                    .fill(tint)
                    .frame(width: geo.size.width * max(0, min(progress, 1)))
            }
        }
        .frame(height: isPadLike ? 10 : 7)
    }
}

struct ProgressBlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX + rect.width * 0.05, y: rect.minY + rect.height * 0.48))

        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.33, y: rect.minY + rect.height * 0.10),
            control1: CGPoint(x: rect.minX + rect.width * 0.04, y: rect.minY + rect.height * 0.25),
            control2: CGPoint(x: rect.minX + rect.width * 0.16, y: rect.minY + rect.height * 0.08)
        )

        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.75, y: rect.minY + rect.height * 0.06),
            control1: CGPoint(x: rect.minX + rect.width * 0.50, y: rect.minY + rect.height * 0.12),
            control2: CGPoint(x: rect.minX + rect.width * 0.58, y: rect.minY - rect.height * 0.03)
        )

        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.44),
            control1: CGPoint(x: rect.minX + rect.width * 0.92, y: rect.minY + rect.height * 0.15),
            control2: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.24)
        )

        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.82, y: rect.maxY),
            control1: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.74),
            control2: CGPoint(x: rect.minX + rect.width * 0.98, y: rect.maxY)
        )

        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.maxY))

        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.05, y: rect.minY + rect.height * 0.48),
            control1: CGPoint(x: rect.minX + rect.width * 0.06, y: rect.maxY),
            control2: CGPoint(x: rect.minX - rect.width * 0.02, y: rect.minY + rect.height * 0.75)
        )

        path.closeSubpath()
        return path
    }
}
