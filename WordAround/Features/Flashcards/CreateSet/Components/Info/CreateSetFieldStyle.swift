import SwiftUI

struct CreateSetFieldStyle: ViewModifier {
    let height: CGFloat
    let fontSize: CGFloat
    let theme: CreateSetTheme

    func body(content: Content) -> some View {
        content
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundColor(theme.textColor)
            .tint(theme.accent)
            .padding(.horizontal, 14)
            .frame(minHeight: height)
            .background(theme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(theme.borderColor, lineWidth: 1)
            )
    }
}

extension View {
    func createSetFieldStyle(
        height: CGFloat,
        fontSize: CGFloat,
        theme: CreateSetTheme
    ) -> some View {
        modifier(
            CreateSetFieldStyle(
                height: height,
                fontSize: fontSize,
                theme: theme
            )
        )
    }
}

#Preview {
    TextField("Example", text: .constant(""))
        .createSetFieldStyle(height: 48, fontSize: 14, theme: .blue)
        .padding()
        .background(CreateSetTheme.blue.screenBackground)
}
