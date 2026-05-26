import SwiftUI

struct GrammarQuickPrimaryButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .black, design: .rounded))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: Layout.grammarQuickActionHeight)
            .background(tint.opacity(configuration.isPressed ? 0.78 : 1))
            .clipShape(RoundedRectangle(cornerRadius: Layout.grammarQuickActionCornerRadius, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeInOut(duration: 0.14), value: configuration.isPressed)
    }
}

struct GrammarQuickSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .black, design: .rounded))
            .foregroundStyle(AppColors.primaryBlueDark)
            .frame(maxWidth: .infinity)
            .frame(height: Layout.grammarQuickActionHeight)
            .background(Color.white.opacity(configuration.isPressed ? 0.62 : 0.86))
            .clipShape(RoundedRectangle(cornerRadius: Layout.grammarQuickActionCornerRadius, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeInOut(duration: 0.14), value: configuration.isPressed)
    }
}
