import SwiftUI

enum ProgressCardLayout {
    case goal
    case action
}

struct ProgressCardView: View {
    let layout: ProgressCardLayout

    let title: String
    let valueText: String
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

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || UIScreen.main.bounds.width >= 700
    }

    private var isCompactPhone: Bool {
        !isPadLike && UIScreen.main.bounds.width < 390
    }

    init(
        layout: ProgressCardLayout = .goal,
        title: String,
        valueText: String,
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
        self.valueText = valueText
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
        Group {
            switch layout {
            case .goal:
                HStack {
                    Spacer()

                    ProgressBlobShape()
                        .fill(blobColor.opacity(0.92))
                        .frame(
                            width: isPadLike ? 250 : (isCompactPhone ? 118 : 200),
                            height: isPadLike ? 280 : (isCompactPhone ? 112 : 200)
                        )
                        .padding(.trailing, isPadLike ? -20 : -30)
                        .padding(.top, isPadLike ? 42 : 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            case .action:
                HStack {
                    Spacer()

                    ProgressBlobShape()
                        .fill(blobColor.opacity(0.88))
                        .frame(
                            width: isPadLike ? 270 : 180,
                            height: isPadLike ? 70 : 56
                        )
                        .padding(.trailing, isPadLike ? -30 : -20)
                        .padding(.top, isPadLike ? -10 : -18)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
    }

    private var goalLayout: some View {
        ZStack(alignment: .trailing) {
            VStack(alignment: .leading, spacing: isPadLike ? 12 : 8) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: isPadLike ? 21 : 15, weight: .semibold, design: .rounded))
                        .foregroundColor(titleColor)
                        .lineLimit(2)

                    Image(systemName: "sparkles")
                        .font(.system(size: isPadLike ? 12 : 9, weight: .medium))
                        .foregroundColor(Color(red: 0.66, green: 0.72, blue: 1.0))
                }

                valueLine
                    .frame(maxWidth: isPadLike ? 230 : 190, alignment: .leading)

                progressSection
                    .frame(width: isPadLike ? 190 : 116, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, isPadLike ? 28 : 18)
            .padding(.trailing, isPadLike ? 180 : 112)
            .padding(.vertical, isPadLike ? 24 : 16)

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.96))
                    .frame(
                        width: isPadLike ? 98 : (isCompactPhone ? 72 : 78),
                        height: isPadLike ? 98 : (isCompactPhone ? 72 : 78)
                    )
                    .shadow(color: Color.white.opacity(0.85), radius: 10, x: 0, y: 0)

                Image(systemName: iconSystemName)
                    .font(.system(size: isPadLike ? 34 : (isCompactPhone ? 27 : 29), weight: .medium))
                    .foregroundColor(tint)

                decorativeSparkles
            }
            .frame(
                width: isPadLike ? 180 : (isCompactPhone ? 126 : 136),
                height: isPadLike ? 180 : (isCompactPhone ? 126 : 136)
            )
            .padding(.trailing, isPadLike ? 18 : 8)
        }
    }
    private var actionLayout: some View {
        HStack(spacing: isPadLike ? 20 : 12) {
            ZStack {
                Circle()
                    .fill(iconBackground)
                    .frame(
                        width: isPadLike ? 74 : 52,
                        height: isPadLike ? 74 : 52
                    )

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

                Text(valueText)
                    .font(.system(size: isPadLike ? 18 : 15, weight: .medium, design: .rounded))
                    .foregroundColor(subtitleColor)
            }

            Spacer(minLength: 8)

            if let actionSystemName {
                Button(action: {}) {
                    ZStack {
                        RoundedRectangle(cornerRadius: isPadLike ? 18 : 14, style: .continuous)
                            .fill(tint)
                            .frame(
                                width: isPadLike ? 62 : 46,
                                height: isPadLike ? 62 : 46
                            )

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
        HStack(alignment: .lastTextBaseline, spacing: isPadLike ? 5 : 3) {
            let parts = valueText
                .split(separator: "/")
                .map { String($0).trimmingCharacters(in: .whitespaces) }

            if let first = parts.first {
                Text(first)
                    .font(.system(size: isPadLike ? 56 : 38, weight: .bold, design: .rounded))
                    .foregroundColor(valueColor)
                    .lineLimit(1)
            }

            if parts.count > 1 {
                Text("/ \(parts[1])")
                    .font(.system(size: isPadLike ? 25 : 15, weight: .medium, design: .rounded))
                    .foregroundColor(subtitleColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .allowsTightening(true)
            }
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

    private var decorativeSparkles: some View {
        ZStack {
            Image(systemName: "sparkles")
                .font(.system(size: isPadLike ? 40 : 25, weight: .medium))
                .foregroundColor(Color.white.opacity(0.95))
                .offset(x: isPadLike ? -72 : -55, y: isPadLike ? -38 : -16)

            Image(systemName: "sparkles")
                .font(.system(size: isPadLike ? 50 : 35, weight: .medium))
                .foregroundColor(Color(red: 0.66, green: 0.72, blue: 1.0))
                .offset(x: isPadLike ? 70 : 50, y: isPadLike ? 48 : 30)

            Image(systemName: "sparkles")
                .font(.system(size: isPadLike ? 30 : 20, weight: .medium))
                .foregroundColor(Color(red: 0.66, green: 0.72, blue: 1.0))
                .offset(x: isPadLike ? -4 : 10, y: isPadLike ? -72 : -50)
        }
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

#Preview {
    ZStack {
        Color(red: 0.965, green: 0.965, blue: 0.985)
            .ignoresSafeArea()

        VStack(spacing: 16) {
            ProgressCardView(
                layout: .goal,
                title: "Today's goal",
                valueText: "24 / 30 words",
                subtitle: "6 words left",
                progress: 0.80,
                tint: Color(red: 0.17, green: 0.36, blue: 0.98),
                backgroundColor: Color(red: 0.95, green: 0.96, blue: 1.0),
                progressBackgroundColor: Color(red: 0.85, green: 0.88, blue: 0.97),
                titleColor: Color(red: 0.13, green: 0.29, blue: 0.82),
                valueColor: Color(red: 0.12, green: 0.28, blue: 0.80),
                subtitleColor: Color(red: 0.55, green: 0.59, blue: 0.70),
                iconSystemName: "book.closed",
                iconBackground: Color.white,
                blobColor: Color(red: 0.82, green: 0.86, blue: 0.98)
            )

            ProgressCardView(
                layout: .action,
                title: "Food",
                valueText: "18 / 30 words",
                subtitle: "In progress",
                progress: 0.68,
                tint: Color(red: 1.0, green: 0.45, blue: 0.46),
                backgroundColor: Color(red: 1.0, green: 0.94, blue: 0.95),
                progressBackgroundColor: Color(red: 0.96, green: 0.84, blue: 0.85),
                titleColor: Color(red: 0.63, green: 0.11, blue: 0.21),
                valueColor: Color(red: 0.63, green: 0.11, blue: 0.21),
                subtitleColor: Color(red: 0.52, green: 0.58, blue: 0.69),
                iconSystemName: "fork.knife",
                iconBackground: Color(red: 0.99, green: 0.50, blue: 0.51),
                blobColor: Color(red: 0.98, green: 0.82, blue: 0.84),
                actionSystemName: "arrow.right"
            )
        }
        .padding()
    }
}
