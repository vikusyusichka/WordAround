import SwiftUI

struct WriteWordsAnswerCellsView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let letters: [String]

    private var metrics: ScreenMetrics {
        ScreenMetrics.current(horizontal: horizontalSizeClass, vertical: verticalSizeClass)
    }

    var body: some View {
        HStack(spacing: LayoutConstants.WriteWords.answerCellSpacing(metrics)) {
            ForEach(Array(letters.enumerated()), id: \.offset) { _, letter in
                Text(letter)
                    .font(.system(size: LayoutConstants.WriteWords.answerCellFontSize(metrics), weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)
                    .frame(
                        width: LayoutConstants.WriteWords.answerCellSize(metrics),
                        height: LayoutConstants.WriteWords.answerCellSize(metrics)
                    )
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.WriteWords.answerCellCornerRadius(metrics), style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.WriteWords.answerCellCornerRadius(metrics), style: .continuous)
                            .stroke(Color(red: 0.86, green: 0.89, blue: 0.96), lineWidth: LayoutConstants.Common.hairline)
                    )
                    .shadow(color: Color.black.opacity(0.035), radius: LayoutConstants.Common.smallSpacing(metrics) - LayoutConstants.Common.hairline * 2, x: 0, y: LayoutConstants.Common.hairline * 3)
            }
        }
    }
}

#Preview {
    WriteWordsAnswerCellsView(letters: ["m", "a", "n", "z", "a", "n", "a"])
        .padding()
        .background(AppColors.appBackground)
}
