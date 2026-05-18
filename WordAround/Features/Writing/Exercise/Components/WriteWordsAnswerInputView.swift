import SwiftUI

struct WriteWordsAnswerInputView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @Binding var text: String
    let isCorrect: Bool
    var hintOverlay: String? = nil

    @FocusState private var isFocused: Bool

    private var metrics: ScreenMetrics {
        ScreenMetrics.current(horizontal: horizontalSizeClass, vertical: verticalSizeClass)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: LayoutConstants.WriteWords.answerInputCornerRadius(metrics), style: .continuous)
                .fill(Color.white)

            RoundedRectangle(cornerRadius: LayoutConstants.WriteWords.answerInputCornerRadius(metrics), style: .continuous)
                .stroke(borderColor, lineWidth: LayoutConstants.Common.hairline)

            // Hint letters — semi-transparent, only visible when text field is empty
            if let hint = hintOverlay, text.isEmpty {
                Text(hint)
                    .font(.system(size: LayoutConstants.WriteWords.answerInputFontSize(metrics), weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlue.opacity(0.30))
                    .multilineTextAlignment(.center)
                    .allowsHitTesting(false)
            }

            TextField("Type the translation", text: $text)
                .focused($isFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .keyboardType(.default)
                .textContentType(.none)
                .submitLabel(.done)
                .multilineTextAlignment(.center)
                .font(.system(size: LayoutConstants.WriteWords.answerInputFontSize(metrics), weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
                .padding(.horizontal, LayoutConstants.WriteWords.answerInputHorizontalPadding(metrics))
        }
        .frame(height: LayoutConstants.WriteWords.answerInputHeight(metrics))
        .frame(maxWidth: LayoutConstants.WriteWords.answerInputMaxWidth(metrics))
        .shadow(color: Color.black.opacity(0.035), radius: LayoutConstants.Common.smallSpacing(metrics), x: 0, y: LayoutConstants.Common.hairline * 3)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                isFocused = true
            }
        }
        .onSubmit {
            isFocused = false
        }
    }

    private var borderColor: Color {
        isCorrect
            ? Color(red: 0.63, green: 0.88, blue: 0.67)
            : Color(red: 0.86, green: 0.89, blue: 0.96)
    }
}

#Preview {
    VStack(spacing: 20) {
        WriteWordsAnswerInputView(text: .constant(""), isCorrect: false, hintOverlay: "ябл")
        WriteWordsAnswerInputView(text: .constant("яблуко"), isCorrect: true)
    }
    .padding()
    .background(AppColors.appBackground)
}
