import SwiftUI

struct FolderCardView: View {
    let title: String
    let setsCount: Int
    let colorHex: String

    private var accentColor: Color {
        Color(hex: colorHex) ?? AppColors.primaryBlue
    }

    var body: some View {
        ZStack {
            FolderShape()
                .fill(accentColor.opacity(0.12))
                .overlay(
                    FolderShape()
                        .stroke(accentColor.opacity(0.14), lineWidth: 1)
                )

            GeometryReader { proxy in
                ZStack {
                    BottomRightWaveShape()
                        .fill(accentColor.opacity(0.13))
                        .frame(width: 140, height: 70)
                        .position(
                            x: proxy.size.width - 50,
                            y: proxy.size.height - 32
                        )

                    Image(systemName: "sparkle")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(accentColor.opacity(0.22))
                        .position(x: proxy.size.width * 0.7, y: proxy.size.height * 0.45)

                    Image(systemName: "sparkle")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(accentColor.opacity(0.22))
                        .position(x: proxy.size.width * 0.78, y: proxy.size.height * 0.62)
                }
            }
            .clipShape(FolderShape())

            HStack(spacing: 18) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(accentColor)
                    .frame(width: 54, height: 54)

                VStack(alignment: .leading, spacing: 7) {
                    Text(title)
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .foregroundColor(accentColor)
                        .lineLimit(1)

                    Text("\(setsCount) sets")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                // СТРІЛКА ЗАМІСТЬ ...
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(accentColor)
                    .opacity(0.7)
            }
            .padding(.horizontal, 26)
            .padding(.top, 18)
        }
        .frame(height: 128)
    }
}

private struct FolderShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let corner: CGFloat = 18
        let tabWidth: CGFloat = rect.width * 0.32
        let tabHeight: CGFloat = 26

        path.move(to: CGPoint(x: corner, y: 0))

        path.addLine(to: CGPoint(x: tabWidth - 20, y: 0))

        path.addQuadCurve(
            to: CGPoint(x: tabWidth, y: tabHeight),
            control: CGPoint(x: tabWidth - 2, y: 0)
        )

        path.addLine(to: CGPoint(x: rect.width - corner, y: tabHeight))

        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: tabHeight + corner),
            control: CGPoint(x: rect.width, y: tabHeight)
        )

        path.addLine(to: CGPoint(x: rect.width, y: rect.height - corner))

        path.addQuadCurve(
            to: CGPoint(x: rect.width - corner, y: rect.height),
            control: CGPoint(x: rect.width, y: rect.height)
        )

        path.addLine(to: CGPoint(x: corner, y: rect.height))

        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.height - corner),
            control: CGPoint(x: 0, y: rect.height)
        )

        path.addLine(to: CGPoint(x: 0, y: corner))

        path.addQuadCurve(
            to: CGPoint(x: corner, y: 0),
            control: CGPoint(x: 0, y: 0)
        )

        path.closeSubpath()
        return path
    }
}

private struct BottomRightWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 0, y: rect.height))

        path.addCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.2),
            control1: CGPoint(x: rect.width * 0.3, y: rect.height * 0.25),
            control2: CGPoint(x: rect.width * 0.7, y: rect.height * 0.95)
        )

        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()

        return path
    }
}

#Preview {
    ZStack {
        AppColors.appBackground
            .ignoresSafeArea()

        VStack(spacing: 18) {
            FolderCardView(title: "Spanish", setsCount: 12, colorHex: "#4169F5")
            FolderCardView(title: "Grammar", setsCount: 8, colorHex: "#FF5759")
            FolderCardView(title: "Listening", setsCount: 5, colorHex: "#3CCF91")
        }
        .padding(.horizontal, 24)
    }
}
