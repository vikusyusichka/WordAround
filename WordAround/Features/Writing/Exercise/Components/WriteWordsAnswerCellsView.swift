import SwiftUI

struct WriteWordsAnswerCellsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let letters: [String]

    private var metrics: ScreenMetrics {
        ScreenMetrics.current(horizontal: horizontalSizeClass, vertical: verticalSizeClass)
    }

    var body: some View {
        GeometryReader { proxy in
            let spacing = adaptiveSpacing(for: proxy.size.width)
            let cellSize = adaptiveCellSize(for: proxy.size.width, spacing: spacing)

            HStack(spacing: spacing) {
                ForEach(Array(letters.enumerated()), id: \.offset) { _, letter in
                    Text(letter)
                        .font(.system(size: adaptiveFontSize(cellSize), weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlueDark)
                        .frame(width: cellSize, height: cellSize)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.WriteWords.answerCellCornerRadius(metrics), style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.WriteWords.answerCellCornerRadius(metrics), style: .continuous)
                                .stroke(Color(red: 0.86, green: 0.89, blue: 0.96), lineWidth: LayoutConstants.Common.hairline)
                        )
                        .shadow(
                            color: Color.black.opacity(0.035),
                            radius: LayoutConstants.Common.smallSpacing(metrics) - LayoutConstants.Common.hairline * 2,
                            x: 0,
                            y: LayoutConstants.Common.hairline * 3
                        )
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(height: LayoutConstants.WriteWords.answerCellSize(metrics))
    }

    private func adaptiveSpacing(for width: CGFloat) -> CGFloat {
        guard letters.count > 1 else { return 0 }

        let baseSpacing = LayoutConstants.WriteWords.answerCellSpacing(metrics)
        let maxCellSize = LayoutConstants.WriteWords.answerCellSize(metrics)
        let neededWidth = CGFloat(letters.count) * maxCellSize + CGFloat(letters.count - 1) * baseSpacing

        if neededWidth <= width {
            return baseSpacing
        }

        return metrics.isRegular ? 8 : 6
    }

    private func adaptiveCellSize(for width: CGFloat, spacing: CGFloat) -> CGFloat {
        guard !letters.isEmpty else { return LayoutConstants.WriteWords.answerCellSize(metrics) }

        let maxCellSize = LayoutConstants.WriteWords.answerCellSize(metrics)
        let minCellSize: CGFloat = metrics.isRegular ? 38 : 28
        let availableWidth = width - CGFloat(max(letters.count - 1, 0)) * spacing
        let fittedSize = floor(availableWidth / CGFloat(letters.count))

        return min(maxCellSize, max(minCellSize, fittedSize))
    }

    private func adaptiveFontSize(_ cellSize: CGFloat) -> CGFloat {
        min(LayoutConstants.WriteWords.answerCellFontSize(metrics), cellSize * 0.46)
    }
}

#Preview {
    WriteWordsAnswerCellsView(letters: ["m", "a", "n", "z", "a", "n", "a"])
        .padding()
        .background(AppColors.appBackground)
}
