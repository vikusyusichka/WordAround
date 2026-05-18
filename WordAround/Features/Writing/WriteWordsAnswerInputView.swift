import SwiftUI

struct WriteWordsAnswerInputView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @Binding var text: String
    let isCorrect: Bool

    private var metrics: ScreenMetrics {
        ScreenMetrics.current(horizontal: horizontalSizeClass, vertical: verticalSizeClass)
    }

    var body: some View {
        TextField("Type the translation", text: $text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .multilineTextAlignment(.center)
            .font(.system(size: LayoutConstants.WriteWords.answerInputFontSize(metrics), weight: .bold, design: .rounded))
            .foregroundColor(AppColors.primaryBlueDark)
            .padding(.horizontal, LayoutConstants.WriteWords.answerInputHorizontalPadding(metrics))
            .frame(height: LayoutConstants.WriteWords.answerInputHeight(metrics))
            .frame(maxWidth: LayoutConstants.WriteWords.answerInputMaxWidth(metrics))
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.WriteWords.answerInputCornerRadius(metrics), style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: LayoutConstants.WriteWords.answerInputCornerRadius(metrics), style: .continuous)
                    .stroke(borderColor, lineWidth: LayoutConstants.Common.hairline)
            }
            .shadow(color: Color.black.opacity(0.035), radius: LayoutConstants.Common.smallSpacing(metrics), x: 0, y: LayoutConstants.Common.hairline * 3)
    }

    private var borderColor: Color {
        isCorrect ? Color(red: 0.63, green: 0.88, blue: 0.67) : Color(red: 0.86, green: 0.89, blue: 0.96)
    }
}

#Preview {
    WriteWordsAnswerInputView(text: .constant("manzana"), isCorrect: true)
        .padding()
        .background(AppColors.appBackground)
}
